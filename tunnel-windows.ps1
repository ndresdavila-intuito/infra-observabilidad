# tunnel-windows-auto.ps1
# -----------------------
# Script para abrir túneles SSH que sirven para navegador y CLI de ArgoCD

# IP pública de tu VM
$VM_IP = "5.189.188.233"
# Usuario SSH
$VM_USER = "root"

Write-Host "==============================="
Write-Host " Iniciando túneles SSH hacia $VM_IP"
Write-Host "==============================="

# Comando SSH con túneles:
#  - 8080: ArgoCD UI y CLI
#  - 8123: ClickHouse UI
#  - 8428: VictoriaMetrics UI
$sshCommand = "ssh -N -L 8080:localhost:443 -L 8123:localhost:8123 -L 8428:localhost:8428 $VM_USER@$VM_IP"

Write-Host "Ejecutando túneles SSH..."
Write-Host $sshCommand

# Ejecuta SSH en segundo plano y mantiene la ventana abierta
$sshProcess = Start-Process powershell -ArgumentList "-NoExit", "-Command", $sshCommand -PassThru

# Espera unos segundos para que se establezcan los túneles
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Abriendo navegadores..."

# URLs locales a través de los túneles
$urls = @(
    "http://localhost:8080",       # ArgoCD UI
    "http://localhost:8123/play",  # ClickHouse UI
    "http://localhost:8428/vmui"   # VictoriaMetrics UI
)

# Abrir cada URL en el navegador predeterminado
foreach ($url in $urls) {
    Start-Process $url
}

Write-Host ""
Write-Host "Túneles activos."
Write-Host "Puedes usar la CLI de ArgoCD desde Windows:"
Write-Host "  argocd login localhost:8080 --insecure --username admin --password <tu-password>"
Write-Host ""
Write-Host "Cierra esta ventana para terminar los túneles SSH."
