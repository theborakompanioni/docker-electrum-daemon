#!/bin/sh
set -e

# network switch
if [ "${ELECTRUM_NETWORK}" = "mainnet" ]; then
  FLAGS=''
elif [ "${ELECTRUM_NETWORK}" = "testnet4" ]; then
  FLAGS='--testnet4'
elif [ "${ELECTRUM_NETWORK}" = "testnet" ]; then
  FLAGS='--testnet'
elif [ "${ELECTRUM_NETWORK}" = "regtest" ]; then
  FLAGS='--regtest'
elif [ "${ELECTRUM_NETWORK}" = "simnet" ]; then
  FLAGS='--simnet'
elif [ "${ELECTRUM_NETWORK}" = "signet" ]; then
  FLAGS='--signet'
fi

function trap_sigterm() {
  echo "Stopping electrum..."
  electrum "${FLAGS}" stop
  echo "Successfully stopped electrum."
  exit 0
}

# enable graceful shutdown
trap 'trap_sigterm' SIGHUP SIGINT SIGQUIT SIGTERM

# stop daemon if running (removes lingering lockfile for daemon)
electrum "${FLAGS}" stop > /dev/null || :

# setup config
echo "electrum --offline ${FLAGS} setconfig rpcuser ${ELECTRUM_RPCUSER}"
electrum --offline "${FLAGS}" setconfig rpcuser ${ELECTRUM_RPCUSER}

echo "electrum --offline ${FLAGS} setconfig rpcpassword *****"
electrum --offline "${FLAGS}" setconfig rpcpassword ${ELECTRUM_RPCPASSWORD}

echo "electrum --offline ${FLAGS} setconfig rpchost 0.0.0.0"
electrum --offline "${FLAGS}" setconfig rpchost 0.0.0.0

echo "electrum --offline ${FLAGS} setconfig rpcport ${ELECTRUM_RPCPORT}"
electrum --offline "${FLAGS}" setconfig rpcport ${ELECTRUM_RPCPORT}

for var in $(env | grep '^ELECTRUM_CONFIG_'); do
  var_name=$(echo "${var}" | cut -d= -f1)
  var_value=$(echo "${var}" | cut -d= -f2-)
  stripped_var=$(echo "${var_name}" | sed 's/^ELECTRUM_CONFIG_//')
  lowercase_var=$(echo "${stripped_var}" | tr '[:upper:]' '[:lower:]')
  echo "electrum --offline ${FLAGS} setconfig ${lowercase_var} ${var_value}"
  electrum --offline "${FLAGS}" setconfig "${lowercase_var}" "${var_value}"
done

# XXX: check load wallet or create

# run application (not as daemon, as we want the logs)
electrum "${FLAGS}" daemon -v &
ELECTRUM_PID=${!}

if [ "${DRY_RUN}" = "true" ]; then
  :
else
  # wait forever
  while true; do
    tail -f /dev/null & wait ${ELECTRUM_PID}
  done
fi
