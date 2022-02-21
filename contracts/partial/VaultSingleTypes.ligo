#include "./VaultCommonTypes.ligo"

type await_xtz_t        is
| Reinvest_
| Default_ 

type await_t            is
| Deposit_balance
| Reward_balance
| Paul_balance
| None_

type await_balance_t    is [@layout:comb] record [
  current                 : await_t;
  next                    : await_t;
]

type storage_t          is [@layout:comb] record [
  service                 : service_t;
  accounts                : big_map(address, account_t);
  fees                    : fees_t;
  fee_balances            : fee_balance_t;
  total_supply            : nat;
  total_deposit           : nat;
  await_xtz               : await_xtz_t;
  await_balance           : await_balance_t;
  deposit_token           : token_standard_t;
  reward_token            : token_standard_t;
  paul_token              : token_standard_t;
  metadata                : big_map(string, bytes);
  token_metadata          : big_map(token_id_t, token_metadata_info_t);
]

type return_t           is list (operation) * storage_t

