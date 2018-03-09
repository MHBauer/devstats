#!/bin/bash
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
GHA2DB_PROJECT=fluentd GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=fluentd IDB_DB=fluentd GHA2DB_METRICS_YAML=./metrics/fluentd/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/fluentd/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/fluentd/tags_affs.yaml ./gha2db_sync
