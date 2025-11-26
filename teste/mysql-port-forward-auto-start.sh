#!/bin/bash

POD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep mysql)
LOCAL_PORT=3306
REMOTE_PORT=3306

if [ -z "$POD" ]; then
  echo "Nenhum pod de MySQL encontrado!"
  exit 1
fi

echo "Iniciando port-forward no pod: $POD"
kubectl port-forward pod/$POD $LOCAL_PORT:$REMOTE_PORT >/dev/null 2>&1 &
echo "MySQL acessível em localhost:$LOCAL_PORT"
echo "Port-forward iniciado!"