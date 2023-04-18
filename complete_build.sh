#!/bin/bash
set -e

mkdir -p contracts
mkdir -p hashes

# build out the entire script
echo -e "\033[1;34m\nBuilding Contracts\n\033[0m"
aiken build

# the reference token
pid=$(jq -r '.starterPid' ./start_info.json)
tkn=$(jq -r '.starterTkn' ./start_info.json)

pid_cbor=$(python3 ./convert_to_cbor.py ${pid})
tkn_cbor=$(python3 ./convert_to_cbor.py ${tkn})

# build the state contract
echo -e "\033[1;33m\nConvert State Contract \033[0m"
aiken blueprint apply -o plutus.json -v state.params "${pid_cbor}" .
aiken blueprint apply -o plutus.json -v state.params "${tkn_cbor}" .
aiken blueprint convert -v state.params > contracts/state_contract.plutus

cardano-cli transaction policyid --script-file contracts/state_contract.plutus > hashes/state.hash

echo -e "\033[1;36mState Contract Hash: $(cat hashes/state.hash) \033[0m"

ref=$(cat hashes/state.hash)
ref_cbor=$(python3 ./convert_to_cbor.py ${ref})

# build the mint contract
echo -e "\033[1;33m\nConvert Mint Contract \033[0m"
aiken blueprint apply -o plutus.json -v minter.params "${ref_cbor}" .
aiken blueprint convert -v minter.params > contracts/mint_contract.plutus
cardano-cli transaction policyid --script-file contracts/mint_contract.plutus > hashes/policy.hash

# update the datum file for the starter token
pid=$(cat hashes/policy.hash)
echo -e "\033[1;36mMint Contract Policy: $(cat hashes/policy.hash) \033[0m"

amt=0
tkn="43757272656e6379"
jq \
--argjson amt "$amt" \
--arg pid "$pid" \
--arg tkn "$tkn" \
'.fields[0].int=$amt | .fields[1].bytes=$pid | .fields[2].bytes=$tkn' \
./scripts/data/datum.json | sponge ./scripts/data/datum.json

amt=1
tkn="43757272656e6379"
jq \
--argjson amt "$amt" \
--arg pid "$pid" \
--arg tkn "$tkn" \
'.fields[0].int=$amt | .fields[1].bytes=$pid | .fields[2].bytes=$tkn' \
./scripts/data/next_datum.json | sponge ./scripts/data/next_datum.json

echo -e "\033[1;32m\nBuild Complete! \033[0m"
