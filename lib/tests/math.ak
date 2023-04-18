use aiken/math
use aiken/string
use finite_distribution/reward

test log_values() {
  math.log(14, 2) == 3
}

test log_distr() {
  let num =
    0
  reward.calculate_reward(num) == 18000000
}

test log_distr2() {
  let num =
    10
  reward.calculate_reward(num) == 15000000
}

test log_distr3() {
  let num =
    0
  reward.reward_amount(num) == 18000000
}

test log_distr4() {
  let num =
    1234567890
  reward.reward_amount(num) == 0
}

fn count_blocks(num: Int) -> Int {
  let reward =
    reward.reward_amount(num)
  if reward > 0 {
    count_blocks(num + 1)
  } else {
    num
  }
}

fn count_rewards(num: Int, total: Int) -> Int {
  let reward =
    reward.reward_amount(num)
  if reward > 0 {
    count_rewards(num + 1, total + reward)
  } else {
    total
  }
}

test total_blocks() {
  let total =
    count_blocks(0)
  trace string.from_int(total)
  total == 262144
}

test total_rewards() {
  let total =
    count_rewards(0, 0)
  trace string.from_int(total)
  total == 524286000000
}
