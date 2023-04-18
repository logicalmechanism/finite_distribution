#!/bin/bash
set -e

source .env

# Addresses
sender_address=$(cat wallets/buyer-wallet/payment.addr)
# receiver_address=$(cat wallets/buyer-wallet/payment.addr)
receiver_address="addr_test1qrvnxkaylr4upwxfxctpxpcumj0fl6fdujdc72j8sgpraa9l4gu9er4t0w7udjvt2pqngddn6q4h8h3uv38p8p9cq82qav4lmp"

#
# exit
#
echo -e "\033[0;36m Gathering UTxO Information  \033[0m"
${cli} query utxo \
    ${network} \
    --address ${sender_address} \
    --out-file tmp/sender_utxo.json

TXNS=$(jq length tmp/sender_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${sender_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' tmp/sender_utxo.json)
buyer_tx_in=${TXIN::-8}

ft_pid=$(jq -r '.fields[1].bytes' ./data/datum.json)
ft_tkn=$(jq -r '.fields[2].bytes' ./data/datum.json)
current_tkn_amount=$(jq -r --arg pid "${ft_pid}" --arg tkn "${ft_tkn}" 'reduce to_entries[] as $item ( []; if $item.value.value[$pid][$tkn] then . + [$item.value.value[$pid][$tkn]] else . end) | add' tmp/sender_utxo.json)

# Define Asset to be printed here
assetA="${current_tkn_amount} ${ft_pid}.${ft_tkn}"

min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file tmp/protocol.json \
    --tx-out="${receiver_address} + 5000000 + ${assetA}" | tr -dc '0-9')

change_to_be_traded="${receiver_address} + ${min_utxo} + ${assetA}"
echo $change_to_be_traded


echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} transaction build \
    --babbage-era \
    --protocol-params-file tmp/protocol.json \
    --out-file tmp/tx.draft \
    --change-address ${sender_address} \
    --tx-in ${buyer_tx_in} \
    --tx-out="${change_to_be_traded}" \
    ${network})

    # --tx-out="${token_to_be_traded}" \
    # --tx-out-inline-datum-file data/datum/attack_book_datum.json \
IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"
FEE=${FEE[1]}
echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file wallets/buyer-wallet/payment.skey \
    --tx-body-file tmp/tx.draft \
    --out-file tmp/tx.signed \
    ${network}
#
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} transaction submit \
    ${network} \
    --tx-file tmp/tx.signed