use finite_distribution/types.{Datum}

pub fn datum(n: Int) -> Datum {
  Datum { number: n, pid: #"acab", tkn: #"beef" }
}

test good_datum() {
  let a =
    datum(0)
  let b =
    datum(1)
  types.correct_datum_increase(a, b) == True
}

test bad_datum() {
  let a =
    datum(0)
  let b =
    datum(2)
  types.correct_datum_increase(a, b) == False
}
