Kubernetes no Linux com Minikube

Este guia mostra como instalar Kubernetes localmente usando Minikube e rodar uma aplicação PHP (myapp-php) com Docker.

1️⃣ Pré-requisitos

Um Linux moderno (Ubuntu, Debian, Fedora, CentOS, etc.)

Docker instalado

kubectl (linha de comando do Kubernetes)

Instalar Docker no Ubuntu:
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker

Instalar kubectl:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

2️⃣ Instalar Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version

3️⃣ Criar e iniciar o cluster
minikube start
kubectl get nodes


Saída esperada:

NAME       STATUS   ROLES            AGE   VERSION
minikube   Ready    control-plane    1m    v1.xx.x

4️⃣ Usando imagens Docker locais no Minikube

Configure o terminal para usar o Docker do Minikube:

eval $(minikube docker-env)


Construa a imagem local dentro do Minikube:

docker build -t erimendes/myapp-php:1.0 .


Agora aplique o Pod:

kubectl apply -f pod.yml
kubectl get pods


O Minikube agora consegue usar a imagem local sem precisar baixar do Docker Hub.

5️⃣ Enviar imagem para Docker Hub (opcional)

Se você quiser que a imagem fique disponível para qualquer cluster:

Faça login no Docker Hub:

docker login


Envie a imagem:

docker tag erimendes/myapp-php:1.0 SEU_USUARIO/erimendes-myapp-php:1.0
docker push SEU_USUARIO/erimendes-myapp-php:1.0


Atualize o pod.yml para usar a imagem no Docker Hub:

image: SEU_USUARIO/erimendes-myapp-php:1.0


Aplique novamente:

kubectl delete pod myapp-php
kubectl apply -f pod.yml
kubectl get pods

6️⃣ Comandos úteis

Abrir dashboard Kubernetes:

minikube dashboard


Parar o cluster:

minikube stop


Reiniciar o cluster:

minikube start


Acessar o serviço do Pod (quando exposto):

minikube service myapp-php --url


⭐ Então, a estrutura correta é:
✔ MySQL
Pod (ou Deployment):

pod-mysql-db

Service:

mysql-service (tipo ClusterIP)

✔ PHP
Deployment:

myapp-php-deployment

Service:

myapp-php-service (tipo NodePort)

📌 2. Estrutura mínima correta
🟦 MySQL Pod
apiVersion: v1
kind: Pod
metadata:
  name: pod-mysql-db
  labels:
    app: pod-mysql-db
spec:
  containers:
  - name: mysql
    image: mysql:latest
    env:
      - name: MYSQL_DATABASE
        value: "meubanco"
      - name: MYSQL_ROOT_PASSWORD
        value: "s3cr3ta"
    ports:
      - containerPort: 3306

🟩 MySQL Service
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  type: ClusterIP
  selector:
    app: pod-mysql-db
  ports:
    - port: 3306
      targetPort: 3306

🟦 PHP Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-php-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp-php
  template:
    metadata:
      labels:
        app: myapp-php
    spec:
      containers:
      - name: myapp-php
        image: erimendes/myapp-php:1.0
        ports:
          - containerPort: 80

🟩 PHP Service
apiVersion: v1
kind: Service
metadata:
  name: myapp-php-service
spec:
  type: NodePort
  selector:
    app: myapp-php
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30007

🎯 3. Importante: PHP deve acessar MySQL assim:
host = mysql-service
user = root
password = s3cr3ta
database = meubanco

Exportar para conectar com DBeaver:
```
kubectl port-forward pod/mysql-db-58d8bcdc4f-wj9n9 3306:3306
```
