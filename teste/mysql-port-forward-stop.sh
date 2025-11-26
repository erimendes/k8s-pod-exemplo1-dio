#!/bin/bash

echo "Encerrando port-forward do pod-mysql-db..."

pkill -f "port-forward pod/pod-mysql-db"

echo "Port-forward encerrado!"
