#!/usr/bin/env bash
# Install ingress-nginx (kind flavour) and wait until it is ready.
# The kind node is labelled ingress-ready=true and maps host ports 80/443
# (scripts/kind-config.yaml), so the controller is reachable on localhost.
set -euo pipefail
VERSION="${INGRESS_NGINX_VERSION:-controller-v1.11.2}"

kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${VERSION}/deploy/static/provider/kind/deploy.yaml"
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s
# The validating webhook can lag behind the rollout; wait for the Job to finish.
kubectl -n ingress-nginx wait --for=condition=complete job/ingress-nginx-admission-patch --timeout=120s || true

# Rate-limited requests return 429 Too Many Requests instead of the default 503
# (503 would look like an outage and trip error-rate alerts).
kubectl -n ingress-nginx patch configmap ingress-nginx-controller --type merge \
  -p '{"data":{"limit-req-status-code":"429","limit-conn-status-code":"429"}}'
kubectl -n ingress-nginx rollout restart deployment/ingress-nginx-controller
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=120s

echo
echo "Add this line to your hosts file (Linux/macOS: /etc/hosts, Windows: C:\\Windows\\System32\\drivers\\etc\\hosts):"
echo "    127.0.0.1  node-react.local"
