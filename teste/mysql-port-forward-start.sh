#!/bin/bash

POD_NAME="pod-mysql-db"
LOCAL_PORT=3306
REMOTE_PORT=3306

echo "Iniciando port-forward do pod '$POD_NAME'..."
kubectl port-forward pod/$POD_NAME $LOCAL_PORT:$REMOTE_PORT >/dev/null 2>&1 &

sleep 1

echo "Port-forward iniciado!"
echo "MySQL acessível em: localhost:$LOCAL_PORT"
echo "Use Ctrl+C para parar o port-forward."