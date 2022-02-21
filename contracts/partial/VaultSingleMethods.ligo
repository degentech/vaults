#include "./VaultCommonMethods.ligo"


function default(
  var s                 : storage_t)
                        : return_t is
  block {
  var operations := no_operations;
  case s.await_xtz of
    
  | Reinvest_ -> {
      
      const withdraw_burn = s.fee_balances.withdraw_burn / accuracy;
      if withdraw_burn > 0n
      then {
        operations :=  Tezos.transaction(
          record[
            amount   = withdraw_burn;
            min_out  = min_out;
            receiver = Tezos.self_address;
          ],
          0mutez,
          get_token_to_tez(s.service.deposit_dex_address)
        ) # operations;

        
        s.fee_balances.withdraw_burn :=
          abs(s.fee_balances.withdraw_burn - withdraw_burn * accuracy);
      } else skip;

      
      operations := typed_get_balance(s.paul_token) # operations;

      
      const reinvest_burn : tez = Tezos.amount * s.fees.reinvest_burn / accuracy;
      operations := swap_xtz_token(
        reinvest_burn,
        s.service.paul_dex_address) # operations;

      
      operations := typed_get_balance(s.deposit_token) # operations;

      
      const tez_amount = Tezos.amount - reinvest_burn;
      operations := swap_xtz_token(
        tez_amount,
        s.service.deposit_dex_address) # operations;

      s.await_balance.next := Paul_balance;
      s.await_balance.current := Deposit_balance;
    }
    (* XTZ to buy a deposit tokens and invest in a farm
    from baker rewards/XTZ donations/withdraw_burn_fee *)
  | Default_ -> {
      (* Swap xtz to Paul for burning and
        Receiving balance after exchange *)
      operations := list [
        swap_xtz_token(
          Tezos.amount,
          s.service.paul_dex_address);
        typed_get_balance(s.paul_token);
      ];
      s.await_balance.current := Paul_balance;
    }
  end;
  } with (operations, s)

function handle_balance_fa12(
  var amount_           : receive_fa12_balance_t;
  var s                 : storage_t )
                        : return_t is
  block {
    const result = case s.await_balance.current of
    | Deposit_balance -> handle_deposit_balance(amount_, s)
    | Reward_balance  -> handle_reward_balance(amount_, s)
    | Paul_balance    -> handle_paul_balance(amount_, s)
    | None_ -> (failwith("Vault-not-expected-balance") : return_t)
    end;
  } with result

function handle_balance_fa2(
  var amount_           : receive_fa2_balance_t;
  var s                 : storage_t )
                        : return_t is
  block {
    amount_ := case List.head_opt(amount_) of
    | Some (response) -> response.balance
    | None -> 0n
    end;
    const result = case s.await_balance.current of
    | Deposit_balance -> handle_deposit_balance(amount_, s)
    | Reward_balance  -> handle_reward_balance(amount_, s)
    | Paul_balance    -> handle_paul_balance(amount_, s)
    | None_ -> (failwith("Vault-not-expected-balance") : return_t)
    end;
  } with result
