#!/usr/bin/env bash
# One command to get the app running in a local kind cluster:
#   ./scripts/kind-up.sh
# Idempotent: safe to re-run after code changes (rebuilds + rolls the images).
set -euo pipefail

CLUSTER="${CLUSTER:-node-react}"
cd "$(dirname "$0")/.."

for bin in docker kind kubectl; do
  command -v "$bin" >/dev/null || { echo "ERROR: '$bin' is required but not installed." >&2; exit 1; }
done

echo "==> Cluster"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "kind cluster '$CLUSTER' already exists"
else
  kind create cluster --name "$CLUSTER" --config scripts/kind-config.yaml
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null

echo "==> Build + load images"
docker build -f Dockerfile.backend  -t node-react-backend:local  .
docker build -f Dockerfile.frontend -t node-react-frontend:local .
kind load docker-image --name "$CLUSTER" node-react-backend:local node-react-frontend:local

echo "==> Deploy to namespace 'dev'"
REDEPLOY=false
kubectl -n dev get deploy backend >/dev/null 2>&1 && REDEPLOY=true
kubectl apply -f k8s/namespace-dev.yaml
kubectl apply -f k8s/
# Same tag (:local) + IfNotPresent means pods keep the old image until restarted.
if [ "$REDEPLOY" = true ]; then
  kubectl -n dev rollout restart deployment/backend deployment/frontend
fi

echo "==> Wait for rollout"
kubectl -n dev rollout status deployment/postgres --timeout=180s
kubectl -n dev rollout status deployment/backend  --timeout=180s
kubectl -n dev rollout status deployment/frontend --timeout=180s

echo
kubectl -n dev get all
echo
echo "App (NodePort): http://localhost:30080"
