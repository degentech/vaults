#include "../partial/CommonTypes.ligo"
#include "../partial/VaultFA2Types.ligo"
#include "../partial/VaultLpTypes.ligo"

#include "../partial/VaultLpUtils.ligo"
#include "../partial/VaultFA2Methods.ligo"
#include "../partial/VaultLpMethods.ligo"

type parameter_t        is
    Deposit               of nat
  | Withdraw              of nat
  | Reinvest              of reinvest_t

  | Change_fee            of change_fee_t
  | Change_address        of change_addr_t
  | Withdraw_dev          of address
  | Approve_token         of (address * approve_token_t)

  | Callback_balance_fa12 of receive_fa12_balance_t
  | Callback_balance_fa2  of receive_fa2_balance_t

  | Transfer              of transfer_params_t
  | Update_operators      of update_operator_params_t
  | Balance_of            of balance_params_t

  | Default               of unit

function main(
  const action          : parameter_t;
  const s               : storage_t)
                        : return_t is
  case action of
    Deposit (params)         -> deposit (params, s)
  | Withdraw (params)        -> withdraw (params, s)
  | Reinvest                 -> reinvest (s)

  | Change_fee (params)      -> (no_operations, change_fee (params, s))
  | Change_address (params)  -> (no_operations, change_address (params, s))
  | Withdraw_dev (params)    -> withdraw_dev_fee (params, s)
  | Approve_token (params)   -> approve_token(params.0, params.1, s)

  
  | Callback_balance_fa12 (params) -> handle_balance_fa12 (params, s)
  | Callback_balance_fa2 (params)  -> handle_balance_fa2 (params, s)

  
  | Transfer (params)          -> transfer(s, params)
  | Update_operators (params)  -> (no_operations, update_operators(s, params))
  | Balance_of (params)        -> (get_balance_of(s, params), s)

  | Default                    -> default(s)
  end
