#!/usr/bin/env sh
set -ex

# network switch
if [ "$ELECTRUM_NETWORK" = "mainnet" ]; then
  FLAGS='--mainnet'
elif [ "$ELECTRUM_NETWORK" = "testnet" ]; then
  FLAGS='--testnet'
elif [ "$ELECTRUM_NETWORK" = "regtest" ]; then
  FLAGS='--regtest'
elif [ "$ELECTRUM_NETWORK" = "simnet" ]; then
  FLAGS='--simnet'
fi

function trap_sigterm() {
  echo "Stopping electrum..."
  electrum $FLAGS stop
  exit 0
}

# enable graceful shutdown
trap 'trap_sigterm' SIGINT SIGTERM SIGKILL

# stop daemon if running (removes lingering lockfile for daemon)
electrum $FLAGS stop > /dev/null || :

# setup config
electrum --offline $FLAGS setconfig rpcuser ${ELECTRUM_RPCUSER}
electrum --offline $FLAGS setconfig rpcpassword ${ELECTRUM_RPCPASSWORD}
electrum --offline $FLAGS setconfig rpchost 0.0.0.0
electrum --offline $FLAGS setconfig rpcport 7000
electrum --offline $FLAGS setconfig check_updates false
electrum --offline $FLAGS setconfig log_to_file false
electrum --offline $FLAGS setconfig dont_show_testnet_warning true
electrum --offline $FLAGS setconfig auto_connect true
electrum --offline $FLAGS setconfig oneserver true

# XXX: Check load wallet or create

# run application (not as daemon, as we want the logs)
electrum $FLAGS daemon -v &

# wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
