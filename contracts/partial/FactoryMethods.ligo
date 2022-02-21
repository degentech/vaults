const create_dex : create_vault_func_t =
[%Michelson ( {| { UNPPAIIR ;
                  CREATE_CONTRACT

#if VAULT_SINGLE
#include "../main/VaultSingle.tz"
#else
#include "../main/VaultLp.tz"
#endif
        ;
          PAIR } |}
 : create_vault_func_t)];

const default_storage : vault_storage_t = record [
  service                 = record[
    owner                  = zero_address;
    farm_address           = zero_address;
    farm_id                = 0n;
    reward_dex_address     = zero_address;
    deposit_dex_address    = zero_address;
    paul_dex_address       = zero_address;
    ];
  accounts                = (big_map[]: big_map(address, account_t));
  fees                    = record[
    reinvest               = 0n;
    reinvest_burn          = 0n;
    withdraw_burn          = 0n;
    withdraw_dev           = 0n;
  ];
  fee_balances            = record[
    withdraw_burn          = 0n;
    dev                    = 0n;
  ];
  total_supply           = 0n;
  total_deposit          = 0n;
  await_xtz              = Default_;
  await_balance          = record[
    current               = None_;
    next                  = None_;
  ];
  deposit_token           = Fa12(zero_address);
  reward_token            = Fa12(zero_address);
  paul_token              = Fa12(zero_address);
#if VAULT_LP
  xtz_cache               = 0tez;
#endif
  metadata                = (big_map[]: big_map(string, bytes));
  token_metadata          = (big_map[]: big_map(token_id_t, token_metadata_info_t));
];

function create_vault(
  const deploy_p        : deploy_t;
  var s                 : factory_storage_t)
                        : return_t is
  block {
    if Tezos.sender =/= s.owner
    then failwith("Factory/not-owner")
    else skip;

    const new_storage = default_storage with record[
      service = record[
        owner                = s.owner;
        farm_address         = deploy_p.farm_address;
        farm_id              = deploy_p.farm_id;
        reward_dex_address   = deploy_p.reward_dex_address;
        deposit_dex_address  = deploy_p.deposit_dex_address;
        paul_dex_address     = s.paul_dex_address;
      ];
      fees = deploy_p.fees;
      deposit_token = deploy_p.deposit_token;
      reward_token = deploy_p.reward_token;
      paul_token = s.paul_token;
      metadata = deploy_p.metadata;
      token_metadata = deploy_p.token_metadata;
    ];

    const origination : (operation * address) =
      create_dex((None : option(key_hash)), Tezos.amount, new_storage);
    s.contracts[s.id_count] := origination.1;
    s.id_count := s.id_count + 1n;

  } with (list[origination.0], s)

function change_owner(
  const new_owner       : address;
  var s                 : factory_storage_t)
                        : return_t is
  block {
    if Tezos.sender =/= s.owner
    then failwith("Factory/not-owner")
    else skip;

    s.owner := new_owner;
  } with ((nil : list(operation)), s)