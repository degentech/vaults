
function deposit (
  const amount_         : nat;
  var s                 : storage_t)
                        : return_t is
  block {
    const new_shares = if s.total_deposit = 0n
    then amount_
    else amount_ * accuracy * s.total_supply / s.total_deposit;

    var account : account_t := get_account(Tezos.sender, s);
    account.balance := account.balance + new_shares;
    s.total_deposit := s.total_deposit + amount_ * accuracy;
    s.total_supply := s.total_supply + new_shares;
    s.accounts[Tezos.sender] := account;

    const operations : list(operation) = if amount_ > 0n
      then list [
        transfer_deposit_token(
          Tezos.sender,
          Tezos.self_address,
          amount_,
          s
        );
        Tezos.transaction(
          (s.service.farm_id, amount_),
          0mutez,
          get_invest_contract(s.service.farm_address)
        );
      ]
      else nil;
} with (operations, s)


function withdraw (
  var burnt_shares      : nat;
  var s                 : storage_t)
                        : return_t is
  block {
    var account : account_t := get_account(Tezos.sender, s);

    if account.balance < burnt_shares
    then failwith("Vault/insufficient-balance");
    else skip;

    
    const amount_ = burnt_shares * s.total_deposit / (s.total_supply * accuracy);
    const burn_fee = amount_ * s.fees.withdraw_burn;
    const dev_fee = amount_ * s.fees.withdraw_dev;
    const total_fee = burn_fee + dev_fee;
    const out = abs(amount_ * accuracy - total_fee) / accuracy;

    
    s.fee_balances.dev := s.fee_balances.dev + dev_fee;
    s.fee_balances.withdraw_burn := s.fee_balances.withdraw_burn + burn_fee;

    
    s.total_deposit := abs(s.total_deposit - out * accuracy - total_fee);
    s.total_supply := abs(s.total_supply - burnt_shares);

    
    account.balance := abs(account.balance - burnt_shares);
    s.accounts[Tezos.sender] := account;

    
    const operations : list(operation) = if amount_ > 0n
      then list [
        Tezos.transaction(
          (s.service.farm_id, amount_),
          0mutez,
          get_withdraw_contract(s.service.farm_address)
        );
        transfer_deposit_token(
          Tezos.self_address,
          Tezos.sender,
          out,
          s
        );
      ]
      else nil;
} with (operations, s)


function reinvest (
  var s                 : storage_t)
                        : return_t is
  block {
    const operation_1 : operation = Tezos.transaction(
      s.service.farm_id,
      0mutez,
      get_harvest_contract(s.service.farm_address)
    );
    
    const operation_2 : operation = typed_get_balance(s.reward_token);
    s.await_balance.current := Reward_balance;
  } with (list[operation_1; operation_2], s)


function handle_reward_balance(
  var amount_           : nat;
  var s                 : storage_t)
                        : return_t is
  block {
    
    if amount_ = 0n
    then failwith("Vault/not-reward")
    else skip;

    
    const reward_token = get_token_info(s.reward_token);
    if Tezos.sender =/= reward_token.address
    then failwith("Vault/unknown-sender")
    else skip;

    
    const reinvest_reward = amount_ * s.fees.reinvest / accuracy;
    amount_ := abs(amount_ - reinvest_reward);

    
    var operations : list(operation) := if reinvest_reward >= 0n
      then list[
          wrap_transfer(
            Tezos.self_address,
            Tezos.source,
            reinvest_reward,
            s.reward_token
          )
        ]
      else nil;

    
    s.await_xtz := Reinvest_;

    
    operations :=  Tezos.transaction(
      record[
        amount   = amount_;
        min_out  = min_out;
        receiver = Tezos.self_address;
      ],
      0mutez,
      get_token_to_tez(s.service.reward_dex_address)
    ) # operations;
  } with (operations, s)


function handle_deposit_balance(
  var _amount           : nat;
  var s                 : storage_t )
                        : return_t is
  block {
    const deposit_token = get_token_info(s.deposit_token);
    if Tezos.sender =/= deposit_token.address
    then failwith("Vault/unknown-sender")
    else skip;

    var operations := no_operations;
    
    _amount := abs(_amount * accuracy - s.fee_balances.dev - s.fee_balances.withdraw_burn) / accuracy;
    if _amount = 0n then failwith("Vault/zero-reinvest")
    else {
      s.total_deposit := s.total_deposit + _amount * accuracy;

      operations := Tezos.transaction(
        (s.service.farm_id, _amount),
        0mutez,
        get_invest_contract(s.service.farm_address)
      ) # operations;
      };

    (* Returns the default entrypoint operating mode,
    buying and burning paules *)
    s.await_xtz := Default_;
    s.await_balance.current := s.await_balance.next;
  } with (operations, s)


function handle_paul_balance(
  var amount_           : nat;
  var s                 : storage_t )
                        : return_t is
  block {
    const paul_token = get_token_info(s.paul_token);
    if Tezos.sender =/= paul_token.address
    then failwith("Vault/unknown-sender")
    else skip;

    const operation = wrap_transfer(
      Tezos.self_address,
      zero_address,
      amount_,
      s.paul_token
    );
    s.await_balance.current := Deposit_balance;
  } with (list[operation], s)


function withdraw_dev_fee (
  const receiver        : address;
  var s                 : storage_t)
                        : return_t is
  block {
    
    is_owner(s);

    const out = s.fee_balances.dev / accuracy;

    if out = 0n then failwith("Vault/not-dev-fee")
    else skip;
    const operation = wrap_transfer(
          Tezos.self_address,
          receiver,
          out,
          s.deposit_token
        );
    s.fee_balances.dev := abs(s.fee_balances.dev - out * accuracy);
} with (list[operation], s)


function change_fee (
  const new_fees        : change_fee_t;
  var s                 : storage_t)
                        : storage_t is
  block {
    
    is_owner(s);
    s.fees := new_fees;
} with s


function change_address (
  const params          : change_addr_t;
  var s                 : storage_t)
                        : storage_t is
  block {
    
    is_owner(s);

    case params of
    | Dex (addresses) -> s.service := s.service with record[
        paul_dex_address = addresses.paul_dex_address;
        deposit_dex_address = addresses.deposit_dex_address;
        reward_dex_address = addresses.reward_dex_address;
      ]
    | Owner (address_)      -> s.service.owner := address_
    end;

} with s


function approve_token (
  const token_address   : address;
  const params          : approve_token_t;
  const _s              : storage_t)
                        : return_t is
  block {
    
    is_owner(_s);
    const operation = case params of
    | Fa12_ (approve_param)-> Tezos.transaction(
          approve_param,
          0mutez,
          get_approve_fa12_token_contract(token_address)
        )
    | Fa2_ (approve_param)  -> Tezos.transaction(
          approve_param,
          0mutez,
          get_approve_fa2_token_contract(token_address)
        )
    end
  } with (list[operation], _s)