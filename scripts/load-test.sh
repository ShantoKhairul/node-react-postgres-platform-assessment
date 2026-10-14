#!/usr/bin/env bash
# Generate load to watch the HPA scale and the dashboards move.
#   ./scripts/load-test.sh [seconds] [parallelism]
# Runs INSIDE the cluster (a throwaway busybox pod hitting backend-service
# directly), so it bypasses the ingress rate limit and really stresses the pods.
# To see rate limiting instead, hit the ingress from the host:
#   for i in $(seq 1 100); do curl -s -o /dev/null -w "%{http_code}\n" http://node-react.local/api/items; done | sort | uniq -c
set -euo pipefail
DURATION="${1:-120}"; PAR="${2:-20}"
kubectl -n dev run load-test --rm -i --restart=Never --image=busybox:1.36 -- sh -c "
  end=\$((\$(date +%s)+${DURATION}))
  for i in \$(seq 1 ${PAR}); do
    ( while [ \$(date +%s) -lt \$end ]; do wget -q -O /dev/null http://backend-service:4000/api/items; done ) &
  done
  wait"
