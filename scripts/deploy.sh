#!/usr/bin/env bash
# Render the dev-shaped manifests in k8s/ for one environment and apply them.
# Used by CI (.github/workflows/ci-cd.yml) and runnable by hand:
#
#   NAMESPACE=preprod TAG=pre-release-v1.2.0-ab12cd3 \
#   BACKEND_IMAGE=ghcr.io/me/repo-backend FRONTEND_IMAGE=ghcr.io/me/repo-frontend \
#   DB_USER=... DB_PASSWORD=... ./scripts/deploy.sh
#
# Why a script instead of sed in YAML: one tested code path for every
# environment, and the manifests in git stay valid, runnable "dev" manifests.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${NAMESPACE:?NAMESPACE is required (dev|preprod|release)}"
: "${TAG:?TAG is required}"
: "${BACKEND_IMAGE:?BACKEND_IMAGE is required}"
: "${FRONTEND_IMAGE:?FRONTEND_IMAGE is required}"

OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
cp k8s/*.yaml "$OUT/"

# Credentials: non-dev environments MUST bring their own (from GitHub
# Environment secrets); the placeholder app-secrets.yaml is dev-only.
if [ -n "${DB_PASSWORD:-}" ]; then
  rm "$OUT/app-secrets.yaml"
elif [ "$NAMESPACE" != "dev" ]; then
  echo "ERROR: DB_USER/DB_PASSWORD must be provided for namespace '$NAMESPACE'" >&2
  exit 1
fi

# Images, namespace, cluster-scoped PV name/path and the Ingress host.
sed -i \
  -e "s#image: node-react-backend:local#image: ${BACKEND_IMAGE}:${TAG}#" \
  -e "s#image: node-react-frontend:local#image: ${FRONTEND_IMAGE}:${TAG}#" \
  -e "s#namespace: dev\$#namespace: ${NAMESPACE}#" \
  -e "s#postgres-pv-dev#postgres-pv-${NAMESPACE}#" \
  -e "s#/data/postgres-dev#/data/postgres-${NAMESPACE}#" \
  "$OUT"/*.yaml
if [ "$NAMESPACE" != "dev" ]; then
  sed -i "s#host: node-react.local#host: node-react-${NAMESPACE}.local#" "$OUT/ingress-dev.yaml"
  # The dev NodePort would collide across namespaces on one cluster.
  sed -i "/nodePort: 30080/d; s#type: NodePort#type: ClusterIP#" "$OUT/frontend-service.yaml"
fi
# Registry images are pulled; only the local dev flow uses IfNotPresent+load.
sed -i "s#imagePullPolicy: IfNotPresent#imagePullPolicy: Always#" "$OUT/backend-deployment.yaml" "$OUT/frontend-deployment.yaml"
[ -f "$OUT/bullmq-worker-deployment.yaml" ] && sed -i "s#imagePullPolicy: IfNotPresent#imagePullPolicy: Always#" "$OUT/bullmq-worker-deployment.yaml"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
if [ -n "${DB_PASSWORD:-}" ]; then
  kubectl -n "$NAMESPACE" create secret generic app-secrets \
    --from-literal=DB_USER="${DB_USER:-appuser}" \
    --from-literal=DB_PASSWORD="$DB_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -
fi
kubectl apply -n "$NAMESPACE" -f "$OUT/"

for d in postgres backend frontend; do
  kubectl -n "$NAMESPACE" rollout status "deployment/$d" --timeout=180s
done
