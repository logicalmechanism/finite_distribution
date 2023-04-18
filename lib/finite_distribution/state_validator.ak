use aiken/list
use aiken/transaction.{Input, Transaction}
use aiken/transaction/value.{AssetName, PolicyId}
use finite_distribution/helper
use finite_distribution/reward

pub fn state_validation(
  tx: Transaction,
  validating_input: Input,
  number: Int,
  pid: PolicyId,
  tkn: AssetName,
) -> Bool {
  let validating_value =
    validating_input.output.value
  let script_addr =
    validating_input.output.address
  // get reward amount from the number
  let reward =
    reward.reward_amount(number)
  // check that the reward amount is minted
  let mint_check =
    when
      tx.mint
        |> value.without_lovelace()
        |> value.flatten()
    is {
      [(policy, token_name, quantity)] ->
        list.and([policy == pid, token_name == tkn, quantity == reward])
      _ ->
        False
    }
  list.and(
    [
      // conservation equation
      helper.find_exact_payout(script_addr, validating_value, tx.outputs),
      // check for logical reward
      reward > 0,
      // everything being minted is minted
      mint_check,
      // only spend 1 input
      helper.count_script_inputs(tx.inputs, script_addr, 0) == 1,
      // only cont 1 output
      helper.count_script_outputs(tx.outputs, script_addr, 0) == 1,
    ],
  )
}
