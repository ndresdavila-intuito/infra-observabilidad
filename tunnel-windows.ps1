# tunnel-windows.ps1
# ------------------
# Script para levantar port-forwards de ArgoCD, ClickHouse y VictoriaMetrics
# desde Windows hacia la VM, en una sola ventana y con una sola contraseña.

$VM_IP = "5.189.188.233"
$VM_USER = "root"

Write-Host "==============================="
Write-Host " Limpiando puertos antiguos en la VM"
Write-Host "==============================="

# Puertos que queremos liberar
$ports = @(8080, 8123, 8428)
$killCommand = ($ports | ForEach-Object { "sudo fuser -k $_/tcp;" }) -join " "
ssh $VM_USER@$VM_IP $killCommand

Start-Sleep -Seconds 2

Write-Host "==============================="
Write-Host " Levantando túneles SSH para port-forward de Kubernetes"
Write-Host "==============================="

# Comando que ejecuta los port-forwards dentro de la VM
$portForwardCmd = @"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
kubectl port-forward svc/clickhouse -n observabilidad 8123:8123 &
kubectl port-forward svc/victoria-metrics -n observabilidad 8428:8428 &
wait
"@

# Abrimos un SSH interactivo que ejecuta los port-forwards
# La opción -t permite pseudo-terminal para que se mantenga activo
ssh -t $VM_USER@$VM_IP $portForwardCmd

# Espera unos segundos para que los port-forwards se levanten
Start-Sleep -Seconds 5

Write-Host "Abriendo navegadores..."
Start-Process "https://localhost:8080/argo"      # ArgoCD
Start-Process "http://localhost:8123/play"       # ClickHouse
Start-Process "http://localhost:8428/vmui"       # VictoriaMetrics

Write-Host "Túneles activos. Presiona Ctrl+C o cierra la ventana para finalizar."
