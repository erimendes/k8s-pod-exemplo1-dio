#!/bin/bash

echo "Encerrando qualquer port-forward ativo para MySQL..."
pkill -f "port-forward.*mysql"
echo "Finalizado!"
echo "Port-forward encerrado!"