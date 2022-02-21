#include "./VaultCommonUtils.ligo"

function get_invest_dex(
  const token_address   : address)
                        : contract(nat) is
  case (Tezos.get_entrypoint_opt(
    "%investLiquidity",
    token_address)      : option(contract(nat))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-invest-liquidity-contract")
  end;

function get_divest_dex(
  const token_address   : address)
                        : contract(divest_liquidity_t) is
  case (Tezos.get_entrypoint_opt(
    "%divestLiquidity",
    token_address)      : option(contract(divest_liquidity_t))) of
  | Some(contr) -> contr
  | None -> failwith("Vault/not-divest-liquidity-contract")
  end;

function transfer_deposit_token(
  const sender_          : address;
  const receiver         : address;
  const amount_          : nat;
  const s                : storage_t)
                         : operation is
    case s.deposit_token of
    | Fa12(_) -> Tezos.transaction(
        (sender_,
        (receiver, amount_)),
        0mutez,
        get_transfer_fa12_contract(s.service.deposit_dex_address))
    | Fa2(_) -> transfer_fa2(
        sender_,
        receiver,
        amount_,
        lp_token_id,
        s.service.deposit_dex_address)
    end;