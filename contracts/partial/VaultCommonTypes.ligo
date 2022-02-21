type fees_t             is [@layout:comb] record [
  reinvest                : nat;
  reinvest_burn           : nat;
  withdraw_burn           : nat;
  withdraw_dev            : nat;
]

type token_t            is [@layout:comb] record[
  address                 : address;
  id                      : nat;
]


type token_standard_t   is
| Fa12                     of address
| Fa2                      of token_t

type reinvest_t         is unit

type change_fee_t       is fees_t

type change_dex_addr_t  is [@layout:comb] record[
  paul_dex_address          : address;
  deposit_dex_address       : address;
  reward_dex_address        : address;
]

type change_addr_t      is
| Dex                     of change_dex_addr_t
| Owner                   of address


type account_t          is [@layout:comb] record [
  balance                 : nat; 
  permits                 : set(address);
]

type fee_balance_t      is [@layout:comb] record [
  withdraw_burn           : nat;
  dev                     : nat;
]

type service_t          is [@layout:comb] record [
  owner                   : address;
  farm_address            : address;
  farm_id                 : nat;
  reward_dex_address      : address; 
  deposit_dex_address     : address; 
  paul_dex_address        : address; 
]

const accuracy = 1000000n;
const zero_address = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);
const min_out = 1n;

type help_reward_t      is [@layout:comb] record [
  account                 : account_t;
  operations              : list(operation);
]

type receive_fa12_balance_t is nat
type receive_fa2_balance_t is list(balance_of_response_t)

type approve_fa12_token_t is michelson_pair(address, "spender", nat, "value")
type approve_fa2_token_t  is update_operator_params_t

type approve_token_t is
| Fa12_                   of approve_fa12_token_t
| Fa2_                    of approve_fa2_token_t

type token_id_t         is nat

type token_metadata_info_t is [@layout:comb] record [
    token_id      : token_id_t;
    token_info    : map (string, bytes);
  ]