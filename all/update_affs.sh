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
GHA2DB_PROJECT=all GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=allprj IDB_DB=allprj GHA2DB_METRICS_YAML=./metrics/all/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/all/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/all/tags_affs.yaml ./gha2db_sync
