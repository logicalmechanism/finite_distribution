#!/usr/bin/bash
set -e

source .env

#
script_path="../contracts/state_contract.plutus"
script_address=$(${cli} address build --payment-script-file ${script_path} ${network})

#
buyer_address=$(cat wallets/buyer-wallet/payment.addr)
reference_address=$(cat wallets/reference-wallet/payment.addr)
collat_address=$(cat wallets/collat-wallet/payment.addr)

#
${cli} query protocol-parameters ${network} --out-file tmp/protocol.json
${cli} query tip ${network} | jq

#
echo -e "\033[1;35m Script Address:" 
echo -e "\n${script_address}\n";
${cli} query utxo --address ${script_address} ${network}
echo -e "\033[0m"

#
echo -e "\033[1;36m Buyer Address:" 
echo -e "\n${buyer_address}\n";
${cli} query utxo --address ${buyer_address} ${network}
echo -e "\033[0m"

#
echo -e "\033[1;34m Reference Address:" 
echo -e "\n \033[1;34m ${reference_address}\n";
${cli} query utxo --address ${reference_address} ${network}
echo -e "\033[0m"

#
echo -e "\033[1;33m Collateral Address:" 
echo -e "\n${collat_address}\n";
${cli} query utxo --address ${collat_address} ${network}
echo -e "\033[0m"