type transfer_destination_t is [@layout:comb] record [
    to_                   : address;
    token_id              : nat;
    amount                : nat;
  ]

type fa2_transfer_param_t is [@layout:comb] record [
    from_                   : address;
    txs                     : list(transfer_destination_t);
  ]

type fa2_transfer_t     is list(fa2_transfer_param_t)


type fa12_transfer_t    is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")

type fa12_balance_param_t is michelson_pair(address, "owner", contract(nat), "")

type receive_balance_t  is nat

type token_to_tez_t     is record [
  amount                  : nat; 
  min_out                 : nat; 
  receiver                : address; 
]

type tez_to_token_t     is record [
  min_out                 : nat; 
  receiver                : address; 
]

type use_params_t       is
| TezToTokenPayment       of tez_to_token_t   
| TokenToTezPayment       of token_to_tez_t  

[@inline] const no_operations : list(operation) = nil;
