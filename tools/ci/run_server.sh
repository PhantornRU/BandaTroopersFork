#!/bin/bash
set -euo pipefail

MAP=$1
DEPLOY_DIR=ci_test

cleanup() {
	rm -rf "$DEPLOY_DIR"
}

trap cleanup EXIT

echo Testing $MAP

rm -rf "$DEPLOY_DIR"
tools/deploy.sh "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/data"

#set the map
cp "maps/$MAP.json" "$DEPLOY_DIR/data/next_map.json"
cp maps/templates/space.json "$DEPLOY_DIR/data/next_ship.json"

cd "$DEPLOY_DIR"
set +e
DreamDaemon colonialmarines.dmb -close -trusted -verbose -params "run_tests=1&log-directory=ci"
STATUS=$?
set -e
cd ..
if [ -f "$DEPLOY_DIR/data/logs/ci/clean_run.lk" ]; then
	cat "$DEPLOY_DIR/data/logs/ci/clean_run.lk"
fi

exit $STATUS
