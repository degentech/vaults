#include "./VaultCommonUtils.ligo"

function transfer_deposit_token(
  const sender_          : address;
  const receiver         : address;
  const amount_          : nat;
  const s                : storage_t)
                         : operation is
    case s.deposit_token of
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