use aiken/transaction.{InlineDatum, Input, Output, OutputReference, Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{Value}

pub fn count_script_inputs(
  inputs: List<Input>,
  script_addr: Address,
  counter: Int,
) -> Int {
  when inputs is {
    [input, ..rest] ->
      if input.output.address == script_addr {
        count_script_inputs(rest, script_addr, counter + 1)
      } else {
        count_script_inputs(rest, script_addr, counter)
      }
    [] ->
      counter
  }
}

// need function that counts script outputs
pub fn count_script_outputs(
  outputs: List<Output>,
  script_addr: Address,
  counter: Int,
) -> Int {
  when outputs is {
    [output, ..rest] ->
      if output.address == script_addr {
        count_script_outputs(rest, script_addr, counter + 1)
      } else {
        count_script_outputs(rest, script_addr, counter)
      }
    [] ->
      counter
  }
}

pub fn get_validating_input(
  inputs: List<Input>,
  out_ref: OutputReference,
) -> Input {
  when inputs is {
    [input, ..rest] ->
      if input.output_reference == out_ref {
        input
      } else {
        get_validating_input(rest, out_ref)
      }
    [] ->
      error @"no script input found"
  }
}

pub fn find_exact_payout(
  pay_address: Address,
  pay_value: Value,
  outputs: List<Output>,
) -> Bool {
  when outputs is {
    [output, ..rest] ->
      if output.address == pay_address && output.value == pay_value {
        True
      } else {
        find_exact_payout(pay_address, pay_value, rest)
      }
    [] ->
      False
  }
}

pub fn find_script_output(outputs: List<Output>, script_addr: Address) -> Output {
  when outputs is {
    [output, ..rest] ->
      if output.address == script_addr {
        output
      } else {
        find_script_output(rest, script_addr)
      }
    [] ->
      error @"no script output found"
  }
}

pub fn create_wallet_address(pkh: ByteArray, sc: ByteArray) -> Address {
  // empty bytearrays means dont add the sc to the pkh
  if sc == #"" {
    credential.from_verification_key(pkh)
  } else {
    credential.from_verification_key(pkh)
      |> credential.with_delegation_key(sc)
  }
}

pub fn find_outbound_datum(possible_output: Output) -> Data {
  when possible_output.datum is {
    InlineDatum(outbound_datum) ->
      outbound_datum
    _ ->
      error @"expected outbound inline datum"
  }
}

pub fn get_outbound_datum(tx: Transaction, validating_input: Input) -> Data {
  let script_addr =
    validating_input.output.address
  let outbound_output =
    find_script_output(tx.outputs, script_addr)
  find_outbound_datum(outbound_output)
}
