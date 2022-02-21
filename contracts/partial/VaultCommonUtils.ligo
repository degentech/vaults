
function get_transfer_fa12_contract(
  const token_address   : address)
                        : contract(fa12_transfer_t) is
  case (Tezos.get_entrypoint_opt("%transfer", token_address) : option(contract(fa12_transfer_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-dep-fa12-contract")
  end


function get_transfer_fa2_contract(
  const token_address   : address)
                        : contract(fa2_transfer_t) is
  case (Tezos.get_entrypoint_opt("%transfer", token_address) : option(contract(fa2_transfer_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-dep-contract")
  end


function get_invest_contract(
  const farm_address   : address)
                        : contract(nat * nat) is
  case (Tezos.get_entrypoint_opt("%deposit", farm_address) : option(contract(nat * nat))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-invest-contract")
  end;


function get_withdraw_contract(
  const farm_address   : address)
                        : contract(nat * nat) is
  case (Tezos.get_entrypoint_opt("%withdraw", farm_address) : option(contract(nat * nat))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-withdraw-contract")
  end;


function get_harvest_contract(
  const farm_address   : address)
                        : contract(nat) is
  case (Tezos.get_entrypoint_opt("%harvest", farm_address) : option(contract(nat))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-harvest-contract")
  end;


function get_balance_fa12_contract(
  const token_address   : address)
                        : contract(fa12_balance_param_t) is
  case (Tezos.get_entrypoint_opt("%getBalance", token_address) : option(contract(fa12_balance_param_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-balance-fa12")
  end;


function get_balance_fa2_contract(
  const token_address   : address)
                        : contract(balance_params_t) is
  case (Tezos.get_entrypoint_opt(
    "%balance_of",
    token_address) : option(contract(balance_params_t))) of
  | Some(contr) -> contr
  | None -> (failwith("Vault/not-balance-fa2") : contract(balance_params_t) )
  end;


function get_balance_fa12_callback(
  const token_address   : address)
                        : contract(receive_fa12_balance_t) is
  case (Tezos.get_entrypoint_opt(
    "%callback_balance_fa12",
    token_address)      : option(contract(receive_fa12_balance_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-fa12-balance-callback")
  end;

  
function get_balance_fa2_callback(
  const token_address   : address)
                        : contract(receive_fa2_balance_t) is
  case (Tezos.get_entrypoint_opt(
    "%callback_balance_fa2",
    token_address)      : option(contract(receive_fa2_balance_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-fa2-balance-callback")
  end;

function get_token_to_tez(
  const dex_address     : address)
                        : contract(token_to_tez_t) is
  case (Tezos.get_entrypoint_opt(
    "%tokenToTezPayment",
    dex_address)        : option(contract(token_to_tez_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-tokenToTez-contract")
  end;


function get_tez_to_token(
  const token_address   : address)
                        : contract(tez_to_token_t) is
  case (Tezos.get_entrypoint_opt(
    "%tezToTokenPayment",
    token_address)      : option(contract(tez_to_token_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-tezToToken-contract")
  end;

function get_approve_fa12_token_contract(
  const token_address   : address)
                        : contract(approve_fa12_token_t) is
  case (Tezos.get_entrypoint_opt(
    "%approve",
    token_address)      : option(contract(approve_fa12_token_t))) of
    Some(contr) -> contr
  | None -> failwith("Vault/not-fa12-approve")
  end;

function get_approve_fa2_token_contract(
  const token_address   : address)
                        : contract(approve_fa2_token_t) is
  case (Tezos.get_entrypoint_opt(
    "%update_operators",
    token_address)      : option(contract(approve_fa2_token_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-fa2-approve")
  end;


function is_owner (
  const s               : storage_t)
                        : unit is
  block {
    if Tezos.sender =/= s.service.owner
    then failwith("Vault/not-owner")
    else skip;
} with unit


function get_account(
    const addr          : address;
    const s             : storage_t)
                        : account_t is
  case s.accounts[addr] of
  | None -> record[
      balance  = 0n;
      permits  = (set[]: set(address));
    ]
  | Some(acc) -> acc
  end


function wrap_fa2_transfer_trx(
    const from_         : address;
    const to_           : address;
    const amount_       : nat;
    const token_id      : nat)
                        : fa2_transfer_t is
  block {
    const transfer_destination : transfer_destination_t = record [
      to_               = to_;
      token_id          = token_id;
      amount            = amount_;
    ];
    const transfer_param : fa2_transfer_param_t = record [
      from_             = from_;
      txs               = list[transfer_destination];
    ];
  } with list[transfer_param]


function transfer_fa2(
  const sender_         : address;
  const receiver        : address;
  const amount_         : nat;
  const token_id        : nat;
  const contract_address : address) : operation is
  Tezos.transaction(
    wrap_fa2_transfer_trx(
      sender_,
      receiver,
      amount_,
      token_id),
    0mutez,
    get_transfer_fa2_contract(contract_address)
  );

function wrap_transfer(
  const sender_          : address;
  const receiver         : address;
  const amount_          : nat;
  const token            : token_standard_t)
                         : operation is
    case token of
    | Fa12(address_) -> Tezos.transaction(
        (sender_,
        (receiver, amount_)),
        0mutez,
        get_transfer_fa12_contract(address_))
    | Fa2(token_) -> transfer_fa2(
        sender_,
        receiver,
        amount_,
        token_.id,
        token_.address)
    end;

function typed_get_balance(
  const token            : token_standard_t)
                         : operation is
  case token of
  | Fa12(address_) -> Tezos.transaction(
          (Tezos.self_address,
          get_balance_fa12_callback(Tezos.self_address)),
          0mutez,
          get_balance_fa12_contract(address_)
        )
  | Fa2(token) -> Tezos.transaction(
        record [
          requests = list[record[
            owner = Tezos.self_address;
            token_id = token.id]
          ];
          callback = get_balance_fa2_callback(Tezos.self_address);
        ],
        0mutez,
        get_balance_fa2_contract(token.address)
        )
    end

function get_token_info(
  const token           : token_standard_t)
                        : token_t is
  case token of
  | Fa2(token_) -> token_
  | Fa12(addr) -> record[
                    address = addr;
                    id      = 0n;
                 ]
  end

function swap_xtz_token(
  const amount_        : tez;
  const dex_address    : address)
                       : operation is
  Tezos.transaction(
    record[
      min_out  = 1n;
      receiver = Tezos.self_address;
      ],
    amount_,
    get_tez_to_token(dex_address)
  ) ;
