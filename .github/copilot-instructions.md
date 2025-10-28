## Repo snapshot

- This repo contains Kubernetes manifests to deploy an observability stack under the `observabilidad` namespace
- Main components (manifests/observabilidad/): VictoriaMetrics, Zipkin, ClickHouse, Grafana, OpenTelemetry Collector
- The repo is managed by ArgoCD using the application defined in `argo/app-observabilidad.yaml`.

## Big picture (what to know first)

- Infrastructure: GitOps via ArgoCD. The Argo Application (`argo/app-observabilidad.yaml`) points to `manifests/observabilidad` and uses automated sync + selfHeal + ServerSideApply. Prefer changing manifests in Git and letting ArgoCD reconcile.
- Namespace: `observabilidad` (see `manifests/observabilidad/namespace.yaml`). Most manifests assume this namespace and the label `app.kubernetes.io/managed-by: argocd`.
- Component layout: each component has its own folder under `manifests/observabilidad/<component>/` and typically contains `deployment|statefulset.yaml`, `service.yaml`, `secret.yaml`, `pvc.yaml`, and `configmap.yaml` when needed. Follow the existing layout for new components.

## Key files and examples to reference

- ArgoCD application: `argo/app-observabilidad.yaml` — shows repoURL, path, syncPolicy, and `ignoreDifferences` for some StatefulSet fields.
- OTEL Collector: `manifests/observabilidad/otel-collector/deployment.yaml` and `service.yaml` — important details:
  - Image: `otel/opentelemetry-collector-contrib:0.138.0`
  - Config is mounted from ConfigMap `otel-collector-config` at `/conf/otel-collector-config.yaml`
  - Env var `CLICKHOUSE_PASSWORD` comes from `clickhouse-secret` (see deployment env section)
  - Service uses NodePort ports: OTLP gRPC 4317 -> nodePort 31317, OTLP HTTP 55681 -> nodePort 31318
- VictoriaMetrics: statefulset and PVC templates live in `manifests/observabilidad/victoriametrics/` and ArgoCD intentionally ignores some StatefulSet JSON pointers (see the Argo app file).

## Project-specific conventions and patterns

- Labeling: resources use `app: <name>` and services select pods using the same `app` label. Keep labels consistent when adding resources.
- Service types: most services are `ClusterIP`; OTEL Collector is exposed as `NodePort` for OTLP ingestion (nodePorts set in `service.yaml`). If you change nodePorts, ensure they don't collide with other services.
- Configs & Secrets: collector config is provided by a ConfigMap named `otel-collector-config`; passwords/secrets are in component-specific secrets (e.g., `clickhouse-secret`, `victoriametrics-auth-basic`). Use existing secret names when wiring new components.
- Resource sizing: Deployments declare modest requests/limits (e.g., otel-collector requests 100m CPU / 128Mi memory). Follow these ranges for lightweight test clusters and bump for production as needed.

## Common developer workflows

- Local quick test (apply directly):
  - kubectl apply -f manifests/observabilidad/<component>/
  - kubectl get pods -n observabilidad -l app=<component>
  - kubectl logs -n observabilidad <pod-name>
- Preferred workflow (GitOps): commit changes to this repo and push — ArgoCD will auto-sync because `argo/app-observabilidad.yaml` sets `automated.selfHeal: true` and `prune: true`.
- Accessing UIs and services from your laptop:
  - The repo provides `tunnel-windows.ps1` and `estado-k8s.sh` to help open tunnels and inspect the cluster. For manual access you can use SSH port forwards or `kubectl port-forward`.

## Debugging tips (concrete commands)

- Check all resources: `kubectl get all -n observabilidad`
- Watch logs for a Deployment: `kubectl logs -n observabilidad -l app=otel-collector --tail=200` (or target a specific pod)
- Inspect collector config: `kubectl get configmap otel-collector-config -n observabilidad -o yaml`
- If Argo reports out-of-sync: inspect the Argo Application in the `argocd` namespace or check the Argo UI; the App manifest is `argo/app-observabilidad.yaml`.

## Integration & cross-component communication

- OTEL Collector receives traces/metrics (OTLP) and forwards them to backend(s) per its ConfigMap. The collector reads `clickhouse-secret` when sending to ClickHouse and mounts `otel-collector-config` for routing rules.
- VictoriaMetrics is exposed on port 8428 (see manifests) and is used for metrics retention; Zipkin receives traces on 9411.

## Do / Don't and pitfalls

- Do: make manifest edits in Git, push, and confirm ArgoCD sync. Use `CreateNamespace=true` Argo option is already set in Argo App.
- Don’t: manually edit Argo-managed resources in-cluster as the Git source is authoritative (ArgoCD will revert changes).
- Be careful when changing NodePort values — they are hard-coded in service manifests (e.g., `manifests/observabilidad/otel-collector/service.yaml`).

## If you need to add components

- Follow the existing directory pattern: `manifests/observabilidad/<component>/` with resource names matching the `app:` label used by services.
- Add a ConfigMap or Secret only when required and reference them by name in the corresponding Deployment/StatefulSet.

---
If anything above is unclear or you want a different level of detail (examples of ConfigMap/Config files, a checklist for adding a new component, or sample otel-collector pipelines), tell me which part to expand and I will iterate.
