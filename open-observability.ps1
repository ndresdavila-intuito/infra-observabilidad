# =================================================
# Script para levantar SSH túneles y abrir navegadores
# =================================================

# Configuración de VM
$VM_USER = "root"
$VM_IP = "5.189.188.233"

# Lista de servicios y puertos locales
$services = @(
    @{ Name="ArgoCD"; LocalPort=8080; RemotePort=8080; URL="http://localhost:8080" },
    @{ Name="Grafana"; LocalPort=3000; RemotePort=3000; URL="http://localhost:3000" },
    @{ Name="VictoriaMetrics"; LocalPort=8428; RemotePort=8428; URL="http://localhost:8428" },
    @{ Name="ClickHouse HTTP"; LocalPort=8123; RemotePort=8123; URL="http://localhost:8123" },
    @{ Name="ClickHouse TCP"; LocalPort=9000; RemotePort=9000; URL="localhost:9000" },
    @{ Name="Zipkin"; LocalPort=9411; RemotePort=9411; URL="http://localhost:9411" }
)

# Función para crear túneles SSH
function Start-Tunnel {
    param(
        [string]$LocalPort,
        [string]$RemotePort
    )
    # Usa Start-Process para mantener procesos independientes
    Start-Process -NoNewWindow ssh -ArgumentList "-L $LocalPort:localhost:$RemotePort $VM_USER@$VM_IP -N"
}

Write-Host "==============================="
Write-Host "Levantando túneles SSH..."
Write-Host "Mantén esta ventana abierta. Ctrl+C para cerrar todo."
Write-Host "==============================="

# Lanzar los túneles
$tunnelProcesses = @()
foreach ($svc in $services) {
    Write-Host "Levantando $($svc.Name) en localhost:$($svc.LocalPort)..."
    $proc = Start-Process -PassThru -NoNewWindow ssh -ArgumentList "-L $($svc.LocalPort):localhost:$($svc.RemotePort) $VM_USER@$VM_IP -N"
    $tunnelProcesses += $proc
    Start-Sleep -Milliseconds 500
}

# Abrir los navegadores con las URLs
Write-Host "`nAbriendo navegadores..."
foreach ($svc in $services) {
    Start-Process $svc.URL
    Start-Sleep -Milliseconds 300
}

Write-Host "`nTodos los túneles levantados. Mantén esta ventana abierta."
Write-Host "Ctrl+C para cerrar todos los SSH y liberar los puertos."

# Espera indefinida para mantener la ventana abierta
while ($true) {
    Start-Sleep -Seconds 10
}
