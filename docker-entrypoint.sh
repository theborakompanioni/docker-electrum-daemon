#!/usr/bin/env sh
set -ex

# Network switch
if [ "$TESTNET" = true ] || [ "$ELECTRUM_NETWORK" = "testnet" ]; then
  FLAGS='--testnet'
elif [ "$ELECTRUM_NETWORK" = "regtest" ]; then
  FLAGS='--regtest'
elif [ "$ELECTRUM_NETWORK" = "simnet" ]; then
  FLAGS='--simnet'
fi


# Graceful shutdown
trap 'pkill -TERM -P1; electrum daemon stop; exit 0' SIGTERM

# Set config
electrum $FLAGS setconfig rpcuser ${ELECTRUM_USER}
electrum $FLAGS setconfig rpcpassword ${ELECTRUM_PASSWORD}
electrum $FLAGS setconfig rpchost 0.0.0.0
electrum $FLAGS setconfig rpcport 7000

# Run application
electrum daemon start $FLAGS
ELECTRUM_PID=${!}

# let daemon start
sleep 3

# check if wallet exists TODO: use ELECTRUM_HOME var
if [ "$ELECTRUM_NETWORK" = "mainnet" ] && [ -f /home/electrum/.electrum/wallets/default_wallet ]; then
  WALLET_EXISTS=true;
elif [ "$ELECTRUM_NETWORK" = "testnet" ] && [ -f /home/electrum/.electrum/testnet/wallets/default_wallet ]; then
  WALLET_EXISTS=true;
elif [ "$ELECTRUM_NETWORK" = "regtest" ] && [ -f /home/electrum/.electrum/regtest/wallets/default_wallet ]; then
  WALLET_EXISTS=true;
elif [ "$ELECTRUM_NETWORK" = "simnet" ] && [ -f /home/electrum/.electrum/simnet/wallets/default_wallet ]; then
  WALLET_EXISTS=true;
else
  WALLET_EXISTS=false
fi

# If wallet file exists, try to load it at startup.
# (so that an external application doesn't need to try to load wallet before evey single use,
# as the application doesn't know if the container was restarted in the meantime.)
: '
if [ "$WALLET_EXISTS" = false ]; then
    echo "*"
    echo " Note: Wallet file does not exist (yet). You need to create a wallet manually."
    echo "*"
else
    retry=0
    until electrum $FLAGS daemon status | grep "wallets/default_wallet"
    do
        electrum $FLAGS daemon load_wallet
        electrum $FLAGS daemon status
        retry=$(expr $retry + 1)
        if [ $retry -gt 5 ];
        then
            echo "unable to start daemon!"
            exit 1
        fi;
        sleep 1;
    done

    echo "Wallet loaded. :-)"
    echo "is_synchronized:"
    electrum $FLAGS is_synchronized
fi
'

# Wait forever
while true; do
  tail -f /dev/null & wait ${ELECTRUM_PID}
done
