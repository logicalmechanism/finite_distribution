# finite-distribution

An example contract that distributes a token as a logirthmic decreases from an initial value.

Place the starter token information inside the `start_file.json` file and run `complete_build.sh`. This will auto populate the datum files required for minting. The next step is running the scripts in order inside the `scripts` folder. First, create the script reference then create the starter utxo. After that an individual mint can be ran with script 2 and a chained tx mint can be ran with script 3.

Script 3 mimics a mining of this token.