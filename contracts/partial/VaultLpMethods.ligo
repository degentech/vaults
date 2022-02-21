#include "./VaultCommonMethods.ligo"


function default(
  var s                 : storage_t)
                        : return_t is
  block {
  var operations := no_operations;
  case s.await_xtz of
    
  | Reinvest_ -> {
      
      operations := typed_get_balance(s.paul_token) # operations;

      
      const reinvest_burn : tez = Tezos.amount * s.fees.reinvest_burn / accuracy;
      operations := swap_xtz_token(
        reinvest_burn,
        s.service.paul_dex_address) # operations;

      
      operations := typed_get_balance(s.deposit_token) # operations;

      
      const tez_amount = (Tezos.amount - reinvest_burn) / 2n;
      operations := Tezos.transaction(
        min_shares,
        tez_amount,
        get_invest_dex(s.service.deposit_dex_address)
      ) # operations;

      
      operations := swap_xtz_token(
        tez_amount,
        s.service.deposit_dex_address) # operations;

      s.await_balance.next := Paul_balance;
      s.await_balance.current := Deposit_balance;

      
      const withdraw_burn = s.fee_balances.withdraw_burn / accuracy;
      if withdraw_burn > 0n
      then {
        operations :=  Tezos.transaction(
          record[
            min_tez     = min_out;
            min_tokens  = min_out;
            shares      = withdraw_burn;
          ],
          0mutez,
          get_divest_dex(s.service.deposit_dex_address)
        ) # operations;

        
        s.fee_balances.withdraw_burn :=
          abs(s.fee_balances.withdraw_burn - withdraw_burn * accuracy);
        s.await_xtz := Burn_fee_;
      
      } else skip;
    }
  | Burn_fee_ -> {
      s.xtz_cache := Tezos.amount;
      s.await_balance.current := Token_a_balance;
      operations := typed_get_balance(s.deposit_token) # operations;
    }
    (* XTZ to buy a deposit tokens and invest in a farm
    from baker rewards/XTZ donations/withdraw_burn_fee *)
  | Default_ -> {
      
      operations := typed_get_balance(s.paul_token) # operations;
      
      operations := swap_xtz_token(
        Tezos.amount + s.xtz_cache,
        s.service.paul_dex_address) # operations;
      s.await_balance.current := Paul_balance;
    }
  end;
  } with (operations, s)


function handle_token_a_balance(
  var amount_           : nat;
  var s                 : storage_t )
                        : return_t is
  block {
    const deposit_token = get_token_info(s.deposit_token);
    if Tezos.sender =/= deposit_token.address
    then failwith("Vault/unknown-sender")
    else skip;

    
    const operation =  Tezos.transaction(
      record[
        amount   = amount_;
        min_out  = min_out;
        receiver = Tezos.self_address;
      ],
      0mutez,
      get_token_to_tez(s.service.deposit_dex_address)
    );

    s.await_xtz := Default_;
  } with (list[operation], s)

function handle_balance_fa12(
  var amount_           : receive_fa12_balance_t;
  var s                 : storage_t )
                        : return_t is
  block {
    const result = case s.await_balance.current of
    | Deposit_balance -> handle_deposit_balance(amount_, s)
    | Reward_balance  -> handle_reward_balance(amount_, s)
    | Paul_balance    -> handle_paul_balance(amount_, s)
    | Token_a_balance -> handle_token_a_balance(amount_, s)
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
    | Token_a_balance -> handle_token_a_balance(amount_, s)
    | None_ -> (failwith("Vault-not-expected-balance") : return_t)
    end;
  } with result
