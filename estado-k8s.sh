#!/bin/bash
# ==========================================================
# Script: estado-k8s.sh
# Autor: Andrés Dávila
# Descripción: Muestra un resumen del estado del clúster Kubernetes y Argo CD
# ==========================================================

echo "ESTADO GENERAL DEL CLUSTER"
kubectl cluster-info
echo "--------------------------------------------"

echo "NAMESPACES DISPONIBLES"
kubectl get ns
echo "--------------------------------------------"

echo "PODS EN TODOS LOS NAMESPACES"
kubectl get pods -A -o wide
echo "--------------------------------------------"

echo "DEPLOYMENTS Y STATEFULSETS"
kubectl get deployments -A
kubectl get statefulsets -A
echo "--------------------------------------------"

echo "VOLUMENES Y RECLAMOS"
kubectl get pv
kubectl get pvc -A
echo "--------------------------------------------"

echo "NODOS DEL CLUSTER"
kubectl get nodes -o wide
echo "--------------------------------------------"

echo "SERVICIOS POR NAMESPACE"
kubectl get svc -A
echo "--------------------------------------------"

echo "ESTADO DE ARGO CD"
kubectl get pods -n argocd
kubectl get applications -n argocd
echo "--------------------------------------------"

echo "OBSERVABILIDAD"
kubectl get all -n observabilidad
echo "--------------------------------------------"

echo "REPORTE COMPLETO FINALIZADO"
