use aiken/math

pub const scale =
  1000000

pub fn calculate_reward(num: Int) -> Int {
  let start_amt =
    18
  ( start_amt - math.log(num, 2) ) * scale
}

pub fn reward_amount(num: Int) -> Int {
  let reward =
    calculate_reward(num)
  if reward < scale {
    0
  } else {
    reward
  }
}
