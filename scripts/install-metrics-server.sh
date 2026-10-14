#!/usr/bin/env bash
# metrics-server feeds `kubectl top` and the HorizontalPodAutoscaler. kind's
# kubelets use self-signed certs, hence --kubelet-insecure-tls (local only!).
set -euo pipefail
VERSION="${METRICS_SERVER_VERSION:-v0.7.2}"
kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${VERSION}/components.yaml"
kubectl -n kube-system patch deployment metrics-server --type json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deployment/metrics-server --timeout=120s
