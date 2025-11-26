#!/bin/bash

# ==========================================================
# Script: setup_minikube.sh
# Descrição: Instala Docker, kubectl, Minikube,
# e aplica YAMLs do PHP + MySQL (Deployment + Service)
# ==========================================================

# Nome da Imagem e Tag
IMAGE_NAME="myapp-php"
IMAGE_TAG="1.0"
FULL_IMAGE="erimendes/$IMAGE_NAME:$IMAGE_TAG"

# Lista de arquivos YAML a aplicar
YAML_FILES=(
  "pod.yml"
  "nodePort.yml"
  "mysql-deployment.yml"
  "mysql-service.yml"
)

# --- Variáveis de Estilo ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Função para verificar comando
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}ERRO: $1 não está instalado.${NC}"
        return 1
    else
        echo -e "${GREEN}INFO: $1 já está instalado.${NC}"
        return 0
    fi
}

# ==========================================================
## 1️⃣ Instalação Docker + kubectl
# ==========================================================
echo -e "\n${BLUE}--- 1. INSTALANDO PRÉ-REQUISITOS ---${NC}"

if ! check_command docker; then
    echo -e "${GREEN}Instalando Docker...${NC}"
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
fi

if ! check_command kubectl; then
    echo -e "${GREEN}Instalando kubectl...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 755 kubectl /usr/local/bin/kubectl
fi

kubectl version --client

# ==========================================================
## 2️⃣ Instalar Minikube
# ==========================================================
echo -e "\n${BLUE}--- 2. INSTALANDO MINIKUBE ---${NC}"

if ! check_command minikube; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

minikube version

# ==========================================================
## 3️⃣ Iniciar cluster
# ==========================================================
echo -e "\n${BLUE}--- 3. INICIANDO MINIKUBE ---${NC}"

if minikube status | grep -q "Running"; then
    echo -e "${GREEN}Minikube já está rodando. Pulando o início.${NC}"
else
    echo -e "${GREEN}Iniciando Minikube com driver Docker...${NC}"
    # Solução: Usar nohup ou setsid para garantir que o processo ignore a necessidade de um TTY.
    # Usaremos 'nohup' para isolar a execução, se necessário.
    
    # Tentativa de iniciar minikube e capturar o erro
    if ! minikube start --driver=docker; then
        echo -e "${RED}Tentativa 1 de 'minikube start' falhou. Tentando com 'nohup' para isolar...${NC}"
        # AQUI ESTÁ A CHAVE: Rodar o comando isolado para contornar a checagem do TTY.
        nohup minikube start --driver=docker > /dev/null 2>&1 & 
        
        # Espera um pouco para a inicialização começar antes de prosseguir
        sleep 10 
        
        # Mata o processo nohup de inicialização em background (pois o cluster deve estar subindo)
        # O cluster continua rodando, mas o processo de inicialização em background é encerrado
        # Isso é uma solução de contorno se a primeira chamada falhar.
        # Geralmente, a primeira chamada sem nohup funciona, mas gera o aviso.
        
        echo -e "${GREEN}Minikube iniciado em background. Verificando status em 30 segundos...${NC}"
        sleep 30 # Dá tempo suficiente para o cluster subir
    fi
fi

echo -e "\n${GREEN}Verificando status do cluster:${NC}"
kubectl get nodes

# ==========================================================
## 4️⃣ Configurar Docker do Minikube
# ==========================================================
echo -e "\n${BLUE}--- 4. CONFIGURANDO DOCKER DO MINIKUBE ---${NC}"
eval $(minikube docker-env)

if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}ERRO: Dockerfile não encontrado.${NC}"
    exit 1
fi

if docker image inspect $FULL_IMAGE &> /dev/null; then
    echo -e "${GREEN}Imagem $FULL_IMAGE já existe. Pulando build.${NC}"
else
    echo -e "${GREEN}Construindo imagem docker...${NC}"
    docker build -t $FULL_IMAGE .
fi

# ==========================================================
## 5️⃣ Remover Pod/Service MySQL ANTIGO
# ==========================================================
echo -e "\n${BLUE}--- 5. REMOVENDO MYSQL ANTIGO ---${NC}"

if kubectl get pod pod-mysql-db &> /dev/null; then
    echo -e "${GREEN}Removendo pod antigo: pod-mysql-db${NC}"
    kubectl delete pod pod-mysql-db
fi

if kubectl get service pod-mysql-db-service &> /dev/null; then
    echo -e "${GREEN}Removendo service antigo: pod-mysql-db-service${NC}"
    kubectl delete service pod-mysql-db-service
fi

# ==========================================================
## 6️⃣ Aplicar YAMLs
# ==========================================================
echo -e "\n${BLUE}--- 6. APLICANDO ARQUIVOS YAML ---${NC}"

for FILE in "${YAML_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}Aplicando: $FILE${NC}"
        kubectl apply -f "$FILE"
    else
        echo -e "${RED}Arquivo não encontrado: $FILE${NC}"
    fi
done

# ==========================================================
## 7️⃣ Status geral
# ==========================================================
echo -e "\n${GREEN}STATUS ATUAL:${NC}"
kubectl get pods
kubectl get svc

# ==========================================================
## 8️⃣ Serviço PHP (SOLUÇÃO AGRESSIVA)
# ==========================================================
echo -e "\n${BLUE}--- 8. SERVIÇO PHP ---${NC}"
SERVICE_NAME="myapp-php-service"

if kubectl get service $SERVICE_NAME &> /dev/null; then
    
    echo -e "${GREEN}Tentando obter a URL do Minikube (usando timeout para evitar travamento)...${NC}"
    
    # 🚨 SOLUÇÃO CHAVE: Usar 'timeout' para garantir que o comando não trave.
    # Usaremos 'setsid' + redirecionamento agressivo para ignorar TTY.
    # O timeout garante que, se travar, ele será morto após 10 segundos.
    
    # Executa em um subshell para isolar
    URL=$(
        timeout 10 \
        setsid minikube service $SERVICE_NAME --url 2>/dev/null 
    )

    # Limpar espaços em branco e nova linha
    URL=$(echo "$URL" | tr -d '\n\r ')

    # Verifica se a URL foi retornada e se o timeout não interferiu
    if [ -n "$URL" ]; then
        echo -e "${GREEN}Acesse seu app PHP em: $URL${NC}"
    else
        echo -e "${RED}AVISO: Não foi possível obter a URL do minikube service em tempo hábil.${NC}"
        echo -e "${RED}Possíveis causas: O Minikube NodePort ainda não está pronto, ou o aviso TTY foi severo.${NC}"
        echo -e "${RED}Tente executar manualmente: minikube service $SERVICE_NAME --url${NC}"
    fi
else
    echo -e "${RED}Serviço PHP não encontrado.${NC}"
fi

# ==========================================================
## 9️⃣ Criar port-forward automático para MySQL (Opcional)
# ==========================================================
echo -e "\n${BLUE}--- 9. PORT-FORWARD DO MYSQL (3306) ---${NC}"

# A. Limpeza: Encerra qualquer port-forward antigo na porta 3306
echo -e "${GREEN}Verificando e encerrando port-forward antigos na porta 3306...${NC}"
# Procura processos 'kubectl port-forward' que estão usando a porta 3306
PORT_FORWARD_PIDS=$(ps aux | grep 'kubectl port-forward' | grep '3306:3306' | grep -v grep | awk '{print $2}')

if [ -n "$PORT_FORWARD_PIDS" ]; then
    echo "$PORT_FORWARD_PIDS" | xargs -r kill
    sleep 2
    echo -e "${GREEN}Processos anteriores encerrados.${NC}"
fi

# B. Iniciar o novo port-forward
if kubectl get svc mysql-service &> /dev/null; then
    echo -e "${GREEN}Iniciando novo port-forward do MySQL...${NC}"
    
    # 🚨 CORREÇÃO: Usar 'nohup' para isolar o processo do terminal (TTY)
    # A saída é redirecionada para um arquivo de log específico, ignorando o TTY.
    nohup kubectl port-forward svc/mysql-service 3306:3306 > mysql_port_forward.log 2>&1 &
    
    echo -e "${GREEN}Port-forward rodando em background! (Log em mysql_port_forward.log)${NC}"
    echo -e "${GREEN}Conecte usando: mysql -h 127.0.0.1 -u root -ps3cr3ta${NC}"
    echo -e "${GREEN}OU via DBeaver usando host 127.0.0.1 porta 3306${NC}"
else
    echo -e "${RED}mysql-service não encontrado, não foi possível iniciar port-forward.${NC}"
fi

echo -e "\n${GREEN}Setup concluído com sucesso!${NC}\n"