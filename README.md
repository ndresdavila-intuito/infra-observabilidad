# Manual de Despliegue del Stack de Observabilidad

Este manual explica cómo desplegar los servicios de observabilidad —VictoriaMetrics, Zipkin, ClickHouse, Grafana y OpenTelemetry Collector— en Kubernetes usando los manifiestos YAML proporcionados.

---

### Ver estado general de Kubernetes y ArgoCD

```bash
chmod +x estado-k8s.sh
./estado-k8s.sh
```

### Levantar túneles SSH y abrir dashboards automáticamente (Windows)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.	unnel-windows.ps1
```

## 1. Estructura del Proyecto

```
manifests/
└── observabilidad/
    ├── namespace.yaml
    ├── clickhouse/
    ├── grafana/
    ├── otel-collector/
    ├── victoriametrics/
    │   ├── secret.yaml
    │   ├── service.yaml
    │   └── statefulset.yaml
    └── zipkin/
        ├── deployment.yaml
        └── service.yaml
```

---

## 2. Namespace

Archivo: `namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: observabilidad
  labels:
    app.kubernetes.io/managed-by: argocd
```

Crea el namespace base:

```bash
kubectl apply -f manifests/observabilidad/namespace.yaml
```

---

## 3. VictoriaMetrics

VictoriaMetrics es una base de datos para métricas de series temporales, ideal para Prometheus, Grafana y OpenTelemetry.

### Archivos

#### `secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: victoriametrics-auth-basic
  namespace: observabilidad
type: Opaque
stringData:
  auth-basic: "Basic YWRtaW46Y2FtcGJhci1wb3ItcGFzc3dvcmQ="
```

#### `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: victoriametrics
  namespace: observabilidad
spec:
  selector:
    app: victoriametrics
  type: ClusterIP
  ports:
    - name: http
      port: 8428
      targetPort: 8428
```

#### `statefulset.yaml`

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: victoriametrics
  namespace: observabilidad
spec:
  serviceName: "victoriametrics"
  replicas: 1
  selector:
    matchLabels:
      app: victoriametrics
  template:
    metadata:
      labels:
        app: victoriametrics
    spec:
      containers:
        - name: victoriametrics
          image: victoriametrics/victoria-metrics:latest
          args:
            - "-retentionPeriod=3"
            - "-storageDataPath=/victoria-metrics-data"
            - "-httpAuth.username=admin"
            - "-httpAuth.password=campbar-por-password"
          ports:
            - containerPort: 8428
              name: http
          volumeMounts:
            - name: vm-storage
              mountPath: /victoria-metrics-data
  volumeClaimTemplates:
    - metadata:
        name: vm-storage
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
        storageClassName: local-path
```

### Despliegue

```bash
kubectl apply -f manifests/observabilidad/victoriametrics/
```

Verifica que el pod esté corriendo:

```bash
kubectl get pods -n observabilidad -l app=victoriametrics
```

Accede localmente (túnel SSH):

```bash
ssh -L 8428:localhost:8428 root@<ip-del-servidor>
```

Luego abre [http://localhost:8428](http://localhost:8428).

---

## 4. Zipkin

Zipkin recolecta y visualiza trazas distribuidas de tus microservicios.

### Archivos

#### `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: observabilidad
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
        - name: zipkin
          image: openzipkin/zipkin:2.23.2
          ports:
            - containerPort: 9411
```

#### `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: zipkin
  namespace: observabilidad
spec:
  selector:
    app: zipkin
  type: ClusterIP
  ports:
    - port: 9411
      targetPort: 9411
      name: http
```

### Despliegue

```bash
kubectl apply -f manifests/observabilidad/zipkin/
```

Verifica que esté corriendo:

```bash
kubectl get pods -n observabilidad -l app=zipkin
```

Accede a la interfaz:

```bash
ssh -L 9411:localhost:9411 root@<ip-del-servidor>
```

Luego abre [http://localhost:9411](http://localhost:9411).

---

## 5. Verificación General

```bash
kubectl get all -n observabilidad
```

Si todos los pods están en estado `Running`, el stack de observabilidad está desplegado correctamente.

---

## 6. Limpieza

Para eliminar todos los recursos:

```bash
kubectl delete ns observabilidad
```

---

## 7. Resumen de Puertos

| Servicio        | Puerto | URL local             |
| --------------- | ------ | --------------------- |
| VictoriaMetrics | 8428   | http://localhost:8428 |
| Zipkin          | 9411   | http://localhost:9411 |
| Grafana         | 3000   | http://localhost:3000 |
| ClickHouse      | 8123   | http://localhost:8123 |
| OTEL Collector  | 4317   | grpc://localhost:4317 |
