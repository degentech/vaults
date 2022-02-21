#include "../partial/CommonTypes.ligo"
#include "../partial/VaultFA2Types.ligo"

#if VAULT_SINGLE
#include "../partial/VaultSingleTypes.ligo"
#else
#include "../partial/VaultLpTypes.ligo"
#endif

type vault_storage_t    is storage_t

type factory_storage_t  is [@layout:comb] record [
  owner                   : address;
  contracts               : big_map(nat, address);
  id_count                : nat;
  paul_dex_address        : address;
  paul_token              : token_standard_t;
  metadata                : big_map(string, bytes);
]

type return_t           is list (operation) * factory_storage_t

type deploy_t           is [@layout:comb] record [
  farm_address            : address;
  farm_id                 : nat;
  reward_dex_address      : address;
  deposit_dex_address     : address;
  fees                    : fees_t;
  deposit_token           : token_standard_t;
  reward_token            : token_standard_t;
  metadata                : big_map(string, bytes);
  token_metadata          : big_map(token_id_t, token_metadata_info_t);
]

type create_vault_func_t is (option(key_hash) * tez * vault_storage_t) -> (operation * address)
