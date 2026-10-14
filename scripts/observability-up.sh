#!/usr/bin/env bash
# Install the whole observability + autoscaling stack on the kind cluster:
#   metrics-server (HPA)  ->  Prometheus, kube-state-metrics, Loki, Fluent Bit, Grafana
# Run after ./scripts/kind-up.sh.  Idempotent.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> metrics-server (needed by the HPA and kubectl top)"
kubectl -n kube-system get deploy metrics-server >/dev/null 2>&1 || ./scripts/install-metrics-server.sh

echo "==> monitoring namespace"
kubectl apply -f observability/namespace-monitoring.yaml

echo "==> Grafana admin password (random, kept only in the cluster Secret)"
if ! kubectl -n monitoring get secret grafana-admin >/dev/null 2>&1; then
  kubectl -n monitoring create secret generic grafana-admin \
    --from-literal=admin-password="$(head -c 18 /dev/urandom | base64 | tr -d '/+=')"
fi

echo "==> Dashboards -> ConfigMap"
kubectl -n monitoring create configmap grafana-dashboards \
  --from-file=observability/dashboards/ --dry-run=client -o yaml | kubectl apply -f -

echo "==> Apply observability stack"
kubectl apply -f observability/kube-state-metrics.yaml
kubectl apply -f observability/prometheus.yaml
kubectl apply -f observability/loki.yaml
kubectl apply -f observability/fluentbit-daemonset.yaml
kubectl apply -f observability/grafana.yaml

# Re-read config/dashboards if they changed on a re-run.
kubectl -n monitoring rollout restart deployment/prometheus deployment/grafana >/dev/null

for d in prometheus kube-state-metrics loki grafana; do
  kubectl -n monitoring rollout status "deployment/$d" --timeout=180s
done
kubectl -n monitoring rollout status daemonset/fluent-bit --timeout=120s

echo
echo "Grafana:     http://localhost:30300   user: admin"
echo "Password:    kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d; echo"
echo "Prometheus:  kubectl -n monitoring port-forward svc/prometheus 9090:9090"
