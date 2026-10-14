#!/usr/bin/env bash
# Delete the local kind cluster (and with it all data in the hostPath volume).
set -euo pipefail
kind delete cluster --name "${CLUSTER:-node-react}"
