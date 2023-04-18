use aiken/list
use aiken/transaction.{Mint, ScriptContext}
use aiken/transaction/credential.{Address}
use finite_distribution/helper

pub fn validation(context: ScriptContext, script_addr: Address) -> Bool {
  when context.purpose is {
    // only allowed to mint
    Mint(_) -> {
      let tx =
        context.transaction
      list.and(
        [
          // must be spending something from lock script
          helper.count_script_inputs(tx.inputs, script_addr, 0) == 1,
        ],
      )
    }
    // Everything else fails
    _ ->
      False
  }
}
