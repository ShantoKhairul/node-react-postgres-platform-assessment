# Evidence

Screenshots and diagrams are **not yet captured**: the environment this repository was authored
in had no Docker daemon / Kubernetes cluster, so nothing here has been run end to end. On a machine
with Docker + kind, produce each item below and save it in this folder with the suggested name.

| Evidence | How | File |
|---|---|---|
| `kubectl get all -n dev` | `./scripts/kind-up.sh && kubectl get all -n dev` | `kubectl-get-all-dev.png` |
| App at http://node-react.local | add hosts entry, open in browser, add an item | `app-node-react-local.png` |
| Ingress | `kubectl -n dev get ingress` | `ingress.png` |
| Grafana dashboard | `./scripts/observability-up.sh`, then `./scripts/load-test.sh 180 20`, open http://localhost:30300 → Backend overview | `grafana-backend-overview.png` |
| HPA scaling | `kubectl -n dev get hpa backend-hpa -w` during the load test | `hpa-scaling.png` |
| Loki log query | Grafana → Explore → `{namespace_name="dev", app="backend"} \| json \| status >= 500` | `loki-query.png` |
| Rate limiting | the `curl … \| sort \| uniq -c` loop in the README showing 200s and 429s | `rate-limit.png` |
| Passing GitHub Actions run | push to `master` on your fork; screenshot the green run | `github-actions-run.png` |

Architecture and sequence diagrams are embedded in the top-level README as Mermaid (rendered by GitHub).
