#!/bin/sh

# Concatenate EXTRA_OPTS string
[ -n "$CHECKPOINT_SYNC_URL" ] && EXTRA_OPTS="${EXTRA_OPTS} --checkpointSyncUrl=${CHECKPOINT_SYNC_URL}"

case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_HOLESKY in
"holesky-geth.dnp.dappnode.eth")
    HTTP_ENGINE="http://holesky-geth.dappnode:8551"
    ;;
"holesky-nethermind.dnp.dappnode.eth")
    HTTP_ENGINE="http://holesky-nethermind.dappnode:8551"
    ;;
"holesky-besu.dnp.dappnode.eth")
    HTTP_ENGINE="http://holesky-besu.dappnode:8551"
    ;;
"holesky-erigon.dnp.dappnode.eth")
    HTTP_ENGINE="http://holesky-erigon.dappnode:8551"
    ;;
*)
    echo "Unknown value for _DAPPNODE_GLOBAL_EXECUTION_CLIENT_HOLESKY: $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_HOLESKY"
    HTTP_ENGINE=$_DAPPNODE_GLOBAL_EXECUTION_CLIENT_HOLESKY
    ;;
esac

# MEV-Boost: https://chainsafe.github.io/lodestar/beacon-management/mev-and-builder-integration/
if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_HOLESKY" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_HOLESKY" = "true" ]; then
    echo "MEV-Boost is enabled"
    MEVBOOST_URL="http://mev-boost.mev-boost-holesky.dappnode:18550"
    if curl --retry 5 --retry-delay 5 --retry-all-errors "${MEVBOOST_URL}"; then
        EXTRA_OPTS="--builder --builder.url=${MEVBOOST_URL} ${EXTRA_OPTS}"
    else
        echo "MEV-Boost is enabled but the Holesky MEV-Boost package at ${MEVBOOST_URL} is not reachable"
        curl -X POST -G 'http://my.dappnode/notification-send' --data-urlencode 'type=danger' --data-urlencode title="${MEVBOOST_URL} can not be reached" --data-urlencode 'body=Make sure the Holesky MEV-Boost DNP is available and running'
    fi
fi

exec node --max-old-space-size="${MEMORY_LIMIT}" /usr/app/node_modules/.bin/lodestar \
    beacon \
    --network=holesky \
    --suggestedFeeRecipient="${FEE_RECIPIENT_ADDRESS}" \
    --jwt-secret=/jwtsecret \
    --execution.urls="${HTTP_ENGINE}" \
    --dataDir=/var/lib/data \
    --rest \
    --rest.address 0.0.0.0 \
    --rest.port "${BEACON_API_PORT}" \
    --port "${P2P_PORT}" \
    --metrics \
    --metrics.port 8008 \
    --metrics.address 0.0.0.0 \
    --logFile /var/lib/data/beacon.log \
    --logLevel="${DEBUG_LEVEL}" \
    --logFileLevel=debug \
    --logFileDailyRotate 5 \
    "${EXTRA_OPTS}"
