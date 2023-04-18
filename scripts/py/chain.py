import subprocess

def build_raw(seller_tx_in, script_tx_in, change, fee):
    # just hardcode these
    seller_address = "addr_test1vz3ppzmmzuz0nlsjeyrqjm4pvdxl3cyfe8x06eg6htj2gwgv02qjt"
    
    script_address = "addr_test1wqsyvhay7nj8u7eyxcsn0p4ln6ljvlg745awf50dqa5mcagy0yk5p"
    script_ref_utxo = "97ae46ee7c1cf6685946dc30e3700b28b8e519dd093ee3f8781cab5672c7fdfb#1"
    
    # calc the outs
    script_out = script_address + " + " + str(change)

    cmd = [
        'cardano-cli',
        'transaction',
        'build-raw',
        '--babbage-era',
        '--protocol-params-file', './tmp/protocol.json',
        '--out-file', './tmp/tx.draft',
        '--tx-in-collateral', seller_tx_in,
        '--tx-in', script_tx_in,
        '--spending-tx-in-reference', script_ref_utxo,
        '--spending-plutus-script-v2',
        '--spending-reference-tx-in-inline-datum-present',
        '--spending-reference-tx-in-execution-units', '(9999999999, 2634)',
        '--spending-reference-tx-in-redeemer-value', '1',
        '--tx-out', script_out,
        '--tx-out-inline-datum-file', './data/datum.json',
        '--fee', str(fee)
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        return False

def sign_tx(counter):
    cmd = [
        'cardano-cli',
        'transaction',
        'sign',
        '--signing-key-file', './wallets/seller-wallet/payment.skey',
        '--tx-body-file', './tmp/tx.draft',
        '--out-file', './tmp/tx-'+str(counter)+'.signed',
        '--testnet-magic', '1'
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')

def submit_tx(counter):
    cmd = [
        'cardano-cli',
        'transaction',
        'submit',
        '--testnet-magic', '1',
        '--tx-file', './tmp/tx-'+str(counter)+'.signed',
    ]
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
        print(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')
        exit()

def tx_hash():
    cmd = [
        'cardano-cli',
        'transaction',
        'txid',
        '--tx-body-file', './tmp/tx.draft'
    ]
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')

if __name__ == "__main__":
    # 2 tx per block, 1 block is ~20 sec,
    # 20 is ~3 mins; 100 is ~15 mins; 360 is ~ 1 hr
    n_tx = 100
    # hardcode the lovelace fee
    fee = 891097
    
    # get starting info
    with open('./tmp/seller.txin', "r") as f:
        seller_tx_in = f.readline().strip('\n')
    
    with open('./tmp/script.txin', "r") as f:
        script_tx_in = f.readline().strip('\n')
    
    with open('./tmp/start.lovelace', "r") as f:
        change = int(f.readline().strip('\n'))

    # build and sign n_tx transactions
    for i in range(n_tx):
        change = change - fee
        output = build_raw(seller_tx_in, script_tx_in, change, fee)
        if output is False:
            n_tx = i -1
            break
        sign_tx(i)
        nextHash = tx_hash()
        script_tx_in = nextHash + "#0"
    
    
    
    # submit n_tx transactions
    for i in range(n_tx):
        submit_tx(i)
        