#define VAULT_LP
#include "../partial/FactoryTypes.ligo"
#include "../partial/FactoryMethods.ligo"

type parameter_t        is
  | Deploy                of deploy_t
  | Change_owner          of address

function main(
  const action          : parameter_t;
  const s               : factory_storage_t)
                        : return_t is
  case action of
  | Deploy(params)       -> create_vault(params, s)
  | Change_owner(params) -> change_owner(params, s)

  end
