
function iterate_transfer (
  var result            : return_t;
  const trx_params      : transfer_param_t)
                        : return_t is
  block {

    
    function make_transfer(
      var result        : return_t;
      var transfer      : transfer_destination_t)
                        : return_t is
      block {
        var operations := result.0;
        var s := result.1;
        var sender_account : account_t := get_account(trx_params.from_, s);

        
        if trx_params.from_ =/= Tezos.sender
          and Set.mem (Tezos.sender, sender_account.permits )
        then failwith("FA2_NOT_OPERATOR")
        else skip;

        if transfer.amount = 0n
        then failwith("Vault/zero-amount-in")
        else skip;

        
        if sender_account.balance < transfer.amount
        then failwith("FA2_INSUFFICIENT_BALANCE")
        else skip;

        const amount_ = transfer.amount * s.total_deposit / (s.total_supply * accuracy);
        const burn_fee = amount_ * s.fees.withdraw_burn;
        const dev_fee = amount_ * s.fees.withdraw_dev;
        const total_fee = burn_fee + dev_fee;

        const out = abs(amount_ * accuracy - total_fee);
        const out_shares = out * s.total_supply / s.total_deposit;

        
        s.fee_balances.dev := s.fee_balances.dev + dev_fee;
        s.fee_balances.withdraw_burn := s.fee_balances.withdraw_burn + burn_fee;

        
        sender_account.balance := abs(sender_account.balance - transfer.amount);
        s.accounts[Tezos.sender] := sender_account;

        
        var destination_account : account_t :=
          get_account(transfer.to_, s);

        
        destination_account.balance := destination_account.balance + out_shares;
        s.accounts[transfer.to_] := destination_account;

        
        s.total_deposit := abs(s.total_deposit - total_fee);

    } with (operations, s);
} with List.fold (make_transfer, trx_params.txs, result)


function iterate_update_operators(
  var s                 : storage_t;
  const params          : update_operator_param_t)
                        : storage_t is
  block {
    case params of
    | Add_operator(param) -> block {
      
      if Tezos.sender =/= param.owner
      then failwith("FA2_NOT_OWNER")
      else skip;

      var account : account_t := get_account(param.owner, s);
      
      account.permits := Set.add(param.operator, account.permits);

      
      s.accounts[param.owner] := account;
    }
    | Remove_operator(param) -> block {
      
      if Tezos.sender =/= param.owner
      then failwith("FA2_NOT_OWNER")
      else skip;

      var account : account_t := get_account(param.owner, s);
      
      account.permits := Set.remove(param.operator, account.permits);

      
      s.accounts[param.owner] := account;
    }
    end
  } with s


function get_balance_of(
  const s               : storage_t;
  const balance_params  : balance_params_t)
                        : list(operation) is
  block {
    
    function look_up_balance(
      const l           : list(balance_of_response_t);
      const request     : balance_of_request_t)
                        : list(balance_of_response_t) is
      block {
        
        const user : account_t = get_account(request.owner, s);

        
        var response : balance_of_response_t := record [
            request = request;
            balance = user.balance;
          ];
      } with response # l;

    
    const accumulated_response : list(balance_of_response_t) =
      List.fold(
        look_up_balance,
        balance_params.requests,
        (nil: list(balance_of_response_t)));
  } with list [Tezos.transaction(
    accumulated_response,
    0tz,
    balance_params.callback
  )]

function update_operators(
  const s               : storage_t;
  const params          : update_operator_params_t)
                        : storage_t is
  block {
    skip
  } with List.fold(iterate_update_operators, params, s)

function transfer(
  const s               : storage_t;
  const params          : transfer_params_t)
                        : return_t is
  block {
    skip
  } with List.fold(iterate_transfer, params, (no_operations, s));

