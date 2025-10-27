# ==========================================
# Túneles SSH únicos para todas las herramientas
# ==========================================

$VM_IP = "5.189.188.233"
$VM_USER = "root"

Write-Host "==================================="
Write-Host "Creando un solo túnel SSH con todos los port-forwards..."
Write-Host "Mantén esta ventana abierta para usar los servicios."
Write-Host "Se te pedirá la contraseña solo una vez."
Write-Host "Presiona Ctrl+C para cerrar todo."
Write-Host "==================================="

# Forwarding: local:remote
$forwards = @(
    "8080:localhost:80",    # ArgoCD
    "3000:localhost:3000",  # Grafana
    "8428:localhost:8428",  # VictoriaMetrics
    "8123:localhost:8123",  # ClickHouse HTTP
    "9000:localhost:9000",  # ClickHouse TCP
    "9411:localhost:9411"   # Zipkin
)

# Convertir array a string para pasar a ssh
$forwardArgs = $forwards | ForEach-Object { "-L $_" } | Out-String
$forwardArgs = $forwardArgs -replace "`r`n", " "

# Lanzar ssh en modo no interactivo para mantener túneles
Start-Process "ssh" -ArgumentList "$forwardArgs $VM_USER@$VM_IP -N" -NoNewWindow

# Esperar un par de segundos a que se levanten los túneles
Start-Sleep -Seconds 3

# Abrir navegadores para las UIs HTTP
Write-Host "Abriendo navegadores..."
Start-Process "http://localhost:8080"    # ArgoCD
Start-Process "http://localhost:3000"    # Grafana
Start-Process "http://localhost:8428"    # VictoriaMetrics
Start-Process "http://localhost:8123"    # ClickHouse HTTP
Start-Process "http://localhost:9411"    # Zipkin

Write-Host "`nTúneles activos. Mantén esta ventana abierta."
Write-Host "Presiona Ctrl+C para cerrar todos los túneles."
