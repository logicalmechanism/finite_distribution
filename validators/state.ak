use aiken/list
use aiken/transaction.{ScriptContext, Spend}
use aiken/transaction/value
use finite_distribution/helper
use finite_distribution/state_validator
use finite_distribution/types.{Datum}

validator(starter_pid: ByteArray, starter_tkn: ByteArray) {
  fn params(datum: Datum, _redeemer: Void, context: ScriptContext) -> Bool {
    when context.purpose is {
      Spend(output_reference) -> {
        // used by both redeemers
        let tx =
          context.transaction
        let validating_input =
          helper.get_validating_input(tx.inputs, output_reference)
        let validating_value =
          validating_input.output.value
        // UTxO must hold the starter token
        let value_check =
          value.quantity_of(validating_value, starter_pid, starter_tkn) == 1
        expect cont_datum: Datum =
          helper.get_outbound_datum(tx, validating_input)
        list.and(
          [
            // must hold starter nft
            value_check,
            // datum increments by one
            types.correct_datum_increase(datum, cont_datum),
            // the state validator
            state_validator.state_validation(
              tx,
              validating_input,
              datum.number,
              datum.pid,
              datum.tkn,
            ),
          ],
        )
      }
      _ ->
        False
    }
  }
}
