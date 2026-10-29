# Kubernetes Monitoring Stack (Prometheus + Node Exporter + Grafana)

Monitoring stack deployed on a k3s cluster with plain Kubernetes manifests (no Helm),
to understand every object that a monitoring setup consists of.

## Architecture

- **Node Exporter** — `DaemonSet`, one pod per node, reads host metrics from `/proc` and `/sys` via `hostPath`
- **Prometheus** — `Deployment`, config from a `ConfigMap`, discovers exporter pods through the Kubernetes API (`kubernetes_sd_configs`, `role: pod`)
- **RBAC** — dedicated `ServiceAccount` + namespace-scoped `Role`/`RoleBinding` with read-only access to pods (`get`, `list`, `watch`)
- **Grafana** — `Deployment` with a `PersistentVolumeClaim` for dashboards and users, Prometheus added as a data source via in-cluster DNS (`prometheus.monitoring.svc:9090`)

## Deploy

```bash
kubectl apply -f manifests/
kubectl get pods -n monitoring
```

Access:
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090 --address 0.0.0.0
# Grafana (NodePort)
kubectl get svc grafana -n monitoring
```

## What I verified

- Scrape pipeline end to end: `up{job="node"} == 1`, failure detection (`up == 0`) after deleting the exporter
- Service discovery: exporter pod recreated with a new IP, Prometheus picked it up without config changes; `node` label stays stable while `instance` changes
- RBAC: without `serviceAccountName` Prometheus logged `pods is forbidden` for `system:serviceaccount:monitoring:default`; verified permissions with `kubectl auth can-i`
- CPU usage query `100 - avg by (node)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100` validated with a load test: one busy core out of 8 → ~12.5% + baseline ≈ 14.4%
- Effect of the `rate()` window: `[5m]` vs `[1m]` (smoothing vs reaction time)

## Known limitations / next steps

- Prometheus uses `emptyDir` — metrics history is lost when the pod restarts (would use a PVC in production)
- No alerting rules / Alertmanager yet
- Next: package as a Helm chart and deploy with ArgoCD (GitOps); provision the cluster on AWS with Terraform

## Screenshots

See [`docs/`](docs/).
