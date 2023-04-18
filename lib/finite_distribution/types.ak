use aiken/list
use aiken/transaction/value.{AssetName, PolicyId}

pub type Datum {
  number: Int,
  pid: PolicyId,
  tkn: AssetName,
}

pub fn correct_datum_increase(a: Datum, b: Datum) -> Bool {
  // old is a new is b
  list.and([a.number + 1 == b.number, a.pid == b.pid, a.tkn == b.tkn])
}
