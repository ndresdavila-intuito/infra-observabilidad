
Ejecutar script con comandos para ver el estado de general de Kubernetes y ArgoCD
chmod +x estado-k8s.sh
./estado-k8s.sh

Levanta los túneles SSH hacia la VM (ssh -L ...) y abre automáticamente los navegadores apuntando a ArgoCD, ClickHouse y VictoriaMetrics:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\tunnel-windows.ps1
