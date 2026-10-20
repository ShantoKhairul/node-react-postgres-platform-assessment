# Evidence

Every screenshot here was taken from this repository running on a local kind cluster.
The top-level [README](../README.md) embeds the key ones next to the task they prove.

| Task | Evidence | File |
|---|---|---|
| 1. Compose | App running through Docker Compose | [compose-app.png](compose-app.png) |
| 1. Compose | Containers and health (`docker compose ps`) | [compose-ps.png](compose-ps.png) |
| 2. Kubernetes | `kubectl get all -n dev` | [kubectl-get-all-dev.png](kubectl-get-all-dev.png) |
| 2. Kubernetes | Frontend via NodePort 30080 | [k8s-app-nodeport.png](k8s-app-nodeport.png) |
| 3. Ingress | App at http://node-react.local | [app-node-react-local.png](app-node-react-local.png) |
| 3. Ingress | `kubectl -n dev get ingress` | [ingress.png](ingress.png) |
| 4. CI/CD | First run: tests and image build | [github-actions-run.png](github-actions-run.png) |
| 4. CI/CD | Full run including deploy | [github-actions-deploy.png](github-actions-deploy.png) |
| 4. CI/CD | Deploy and smoke-test log | [github-actions-deploy-log.png](github-actions-deploy-log.png) |
| 4. CI/CD | Images in GHCR | [ghcr-packages.png](ghcr-packages.png) |
| 4. CI/CD | Environment secrets (values hidden) | [github-environment.png](github-environment.png) |
| 4. CI/CD | Self-hosted runner online | [github-runner.png](github-runner.png) |
| 4. CI/CD | Runner finishing deploy jobs | [github-runner-terminal.png](github-runner-terminal.png) |
| 4. CI/CD | Pods running the GHCR images | [deployed-ghcr-images.png](deployed-ghcr-images.png) |
| 4. CI/CD | App served by the deployed images | [deployed-app.png](deployed-app.png) |
| 5. Platform services | Redis, worker and search running | [task5-platform-services.png](task5-platform-services.png) |
| 5. Platform services | NetworkPolicy isolation test | [task5-network-isolation.png](task5-network-isolation.png) |
| 6. Observability | Grafana backend dashboard | [grafana-backend-overview.png](grafana-backend-overview.png) |
| 6. Scaling | HPA scaling under load | [hpa-scaling.png](hpa-scaling.png) |
| 6. Rate limiting | 100 requests: 68 x 200, 32 x 429 | [rate-limit.png](rate-limit.png) |
| 6. Logging | Loki query `{app="backend"}` | [loki-query.png](loki-query.png) |

Architecture and sequence diagrams are embedded in the top-level README as Mermaid (rendered by GitHub).
