#!/bin/bash
set -e

source .env

# script info
script_path="../contracts/state_contract.plutus"
script_address=$(${cli} address build --payment-script-file ${script_path} ${network})

# buyer
buyer_address=$(cat wallets/buyer-wallet/payment.addr)
buyer_pkh=$(${cli} address key-hash --payment-verification-key-file wallets/buyer-wallet/payment.vkey)

number=$(jq -r '.fields[0].int' ./data/datum.json)
ft_pid=$(jq -r '.fields[1].bytes' ./data/datum.json)
ft_tkn=$(jq -r '.fields[2].bytes' ./data/datum.json)

# starter asset
pid=$(jq -r '.starterPid' ../start_info.json)
tkn=$(jq -r '.starterTkn' ../start_info.json)
asset="1 ${pid}.${tkn}"

if [[ $# -lt 5 ]] ; then
    echo -e "\033[0;36m Gathering Buyer UTxO Information  \033[0m"
    ${cli} query utxo \
        ${network} \
        --address ${buyer_address} \
        --out-file tmp/buyer_utxo.json
    TXNS=$(jq length tmp/buyer_utxo.json)
    if [ "${TXNS}" -eq "0" ]; then
    echo -e "\n \033[0;31m NO UTxOs Found At ${buyer_address} \033[0m \n";
    exit;
    fi
    alltxin=""
    TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' tmp/buyer_utxo.json)
    buyer_tx_in=${TXIN::-8}

    current_tkn_amount=$(jq -r --arg pid "${ft_pid}" --arg tkn "${ft_tkn}" 'reduce to_entries[] as $item ( []; if $item.value.value[$pid][$tkn] then . + [$item.value.value[$pid][$tkn]] else . end) | add' tmp/buyer_utxo.json)

    if [ -z "${current_tkn_amount}" ] || [ "${current_tkn_amount}" = "null" ]; then
        current_tkn_amount=0
    fi

    lovelace=$(jq -r 'reduce to_entries[] as $item ( []; if $item.value.value.lovelace then . + [$item.value.value.lovelace] else . end) | add' tmp/buyer_utxo.json)
    # lovelace=$(jq -r 'to_entries[] | .value.value.lovelace' tmp/buyer_utxo.json)

    echo -e "\033[0;36m Gathering Script UTxO Information  \033[0m"
    ${cli} query utxo \
        --address ${script_address} \
        ${network} \
        --out-file tmp/script_utxo.json

    # transaction variables
    TXNS=$(jq length tmp/script_utxo.json)
    if [ "${TXNS}" -eq "0" ]; then
    echo -e "\n \033[0;31m NO UTxOs Found At ${script_address} \033[0m \n";
    exit;
    fi
    alltxin=""
    TXIN=$(jq -r --arg alltxin "" --arg pid "${pid}" --arg tkn "${tkn}" 'to_entries[] | select(.value.value[$pid][$tkn] == 1) | .key | . + $alltxin + " --tx-in"' tmp/script_utxo.json)
    script_tx_in=${TXIN::-8}

    current_value=$(jq -r --arg pid "${pid}" --arg tkn "${tkn}" 'to_entries[] | select(.value.value[$pid][$tkn] == 1) | .value.value.lovelace' tmp/script_utxo.json)

else
    lovelace=${1}
    buyer_tx_in="${2} --tx-in ${3}"
    script_tx_in=${4}
    current_tkn_amount=${5}
    current_value=1530050
fi

echo "Calculating Token Reward"
reward=$(python3 -c "from py.reward_calculation import amount;n=${number};print(amount(n))")

fee=270000

# collateral
collat_address=$(cat wallets/collat-wallet/payment.addr)
collat_pkh=$(${cli} address key-hash --payment-verification-key-file wallets/collat-wallet/payment.vkey)

# new incoming assets
total=$((${current_tkn_amount} + ${reward}))
new_assets="${reward} ${ft_pid}.${ft_tkn}"
return_assets="${total} ${ft_pid}.${ft_tkn}"

# echo $new_assets
utxo_value=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file tmp/protocol.json \
    --tx-out="${buyer_address} + 5000000 + ${return_assets}" | tr -dc '0-9')

change=$((${lovelace} - ${fee} - ${utxo_value}))

buyer_address_out="${buyer_address} + ${utxo_value} + ${return_assets}"
buyer_change_out="${buyer_address} + ${change}"
echo -e "\nMint OUTPUT: "${buyer_address_out}
echo -e "\nChange OUTPUT: "${buyer_change_out}


script_address_out="${script_address} + ${current_value} + ${asset}"

echo -e "\nScript OUTPUT: "${script_address_out}
#
# exit
#

echo -e "\033[0;36m Gathering Collateral UTxO Information  \033[0m"
${cli} query utxo \
    ${network} \
    --address ${collat_address} \
    --out-file tmp/collat_utxo.json
TXNS=$(jq length tmp/collat_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${collat_address} \033[0m \n";
   exit;
fi
collat_utxo=$(jq -r 'keys[0]' tmp/collat_utxo.json)

script_ref_utxo=$(${cli} transaction txid --tx-file tmp/tx-reference-utxo.signed)

echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file tmp/protocol.json \
    --out-file tmp/tx.draft \
    --tx-in-collateral="${collat_utxo}" \
    --tx-in ${buyer_tx_in} \
    --tx-in ${script_tx_in} \
    --spending-tx-in-reference="${script_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-execution-units '(230000000, 700000)' \
    --spending-reference-tx-in-redeemer-file data/redeemer.json \
    --tx-out="${buyer_change_out}" \
    --tx-out="${buyer_address_out}" \
    --tx-out="${script_address_out}" \
    --tx-out-inline-datum-file data/next_datum.json  \
    --mint="${new_assets}" \
    --mint-reference-tx-in-execution-units '(40000000, 100000)' \
    --mint-tx-in-reference="${script_ref_utxo}#2" \
    --mint-plutus-script-v2 \
    --policy-id="${ft_pid}" \
    --mint-reference-tx-in-redeemer-file data/redeemer.json \
    --required-signer-hash ${buyer_pkh} \
    --required-signer-hash ${collat_pkh} \
    --fee ${fee})

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
    --signing-key-file wallets/collat-wallet/payment.skey \
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

cp data/next_datum.json data/datum.json

amt=$((${number} + 2))
jq \
--argjson amt "$amt" \
'.fields[0].int=$amt' \
./data/next_datum.json | sponge ./data/next_datum.json

txid=$(${cli} transaction txid --tx-file tmp/tx.signed)

change=$((${lovelace} - ${fee}))

./03_chainUTxO.sh ${change} "${txid}#0" "${txid}#1" "${txid}#2" ${total}
