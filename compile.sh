#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

IMAGE_NAME="egeominotti/swarm-app"
IMAGE_TAG="latest"

PROJECT_DIR="$(pwd)"

echo -e "${BLUE}===== AGGIORNAMENTO DOCKER E KUBERNETES =====${NC}"

echo -e "${YELLOW}Eliminazione dell'immagine locale corrente...${NC}"
docker rmi $IMAGE_NAME:$IMAGE_TAG > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Immagine locale eliminata con successo.${NC}"
else
  echo -e "${YELLOW}Nessuna immagine locale da eliminare o errore nella rimozione.${NC}"
fi

echo -e "${YELLOW}Costruzione della nuova immagine Docker...${NC}"
docker build -t $IMAGE_NAME:$IMAGE_TAG .
if [ $? -ne 0 ]; then
  echo -e "${RED}Errore durante la costruzione dell'immagine!${NC}"
  exit 1
fi
echo -e "${GREEN}Immagine Docker costruita con successo.${NC}"

echo -e "${YELLOW}Effettuo il push dell'immagine su Docker Hub...${NC}"
docker push $IMAGE_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
  echo -e "${RED}Errore durante il push dell'immagine!${NC}"
  echo -e "${YELLOW}Prova ad eseguire 'docker login' e riprova.${NC}"
  exit 1
fi
echo -e "${GREEN}Immagine caricata con successo su Docker Hub.${NC}"

echo -e "${YELLOW}Verifica dello stato del cluster Kubernetes...${NC}"
kubectl get nodes > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "${RED}Il cluster Kubernetes non è raggiungibile!${NC}"
  echo -e "${YELLOW}Provo ad avviare kind...${NC}"
  
  if ! command -v kind &> /dev/null; then
    echo -e "${RED}kind non è installato. Installalo o avvia manualmente il cluster Kubernetes.${NC}"
    exit 1
  fi
  
  if kind get clusters | grep -q kind; then
    echo -e "${YELLOW}Cluster kind esiste. Provo a riavviarlo...${NC}"
    kind delete cluster
    kind create cluster
  else
    echo -e "${YELLOW}Creazione di un nuovo cluster kind...${NC}"
    kind create cluster
  fi
  
  kubectl get nodes > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${RED}Impossibile avviare il cluster Kubernetes. Verifica la configurazione.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Cluster Kubernetes avviato con successo.${NC}"
else
  echo -e "${GREEN}Cluster Kubernetes è attivo e raggiungibile.${NC}"
fi

echo -e "${YELLOW}Applicazione della configurazione Kubernetes...${NC}"
if [ -d "k8s" ]; then
  echo -e "${YELLOW}Imposto imagePullPolicy: Always nel deployment...${NC}"
  if grep -q "imagePullPolicy: Always" k8s/deployment.yaml; then
    echo -e "${GREEN}imagePullPolicy già impostato su Always.${NC}"
  else
    echo -e "${YELLOW}imagePullPolicy non trovato, considera di aggiungerlo manualmente.${NC}"
  fi
  
  kubectl apply -f k8s/
  if [ $? -ne 0 ]; then
    echo -e "${RED}Errore durante l'applicazione della configurazione Kubernetes!${NC}"
    exit 1
  fi
else
  echo -e "${RED}Directory k8s non trovata. Assicurati di essere nella directory corretta.${NC}"
  exit 1
fi

echo -e "${YELLOW}Forzo il riavvio del deployment per usare la nuova immagine...${NC}"
kubectl rollout restart deployment swarm-app
if [ $? -ne 0 ]; then
  echo -e "${RED}Errore durante il riavvio del deployment!${NC}"
  exit 1
fi

echo -e "${YELLOW}Monitoraggio dello stato dell'aggiornamento...${NC}"
kubectl rollout status deployment swarm-app --timeout=120s
if [ $? -ne 0 ]; then
  echo -e "${RED}Timeout durante l'aggiornamento del deployment.${NC}"
  echo -e "${YELLOW}Verificare manualmente con 'kubectl get pods' e 'kubectl describe pods'.${NC}"
else
  echo -e "${GREEN}Deployment aggiornato con successo!${NC}"
fi

echo -e "${BLUE}Stato attuale dei pod:${NC}"
kubectl get pods -o wide

echo -e "${BLUE}Informazioni sul servizio:${NC}"
kubectl get services
if kubectl get service swarm-app &> /dev/null; then
  SERVICE_PORT=$(kubectl get service swarm-app -o jsonpath='{.spec.ports[0].nodePort}')
  if [ ! -z "$SERVICE_PORT" ]; then
    echo -e "\n${GREEN}L'applicazione è disponibile su: ${YELLOW}http://localhost:$SERVICE_PORT${NC}"
  else
    echo -e "\n${YELLOW}Il servizio non è di tipo NodePort. Usa 'kubectl port-forward' per accedere:${NC}"
    echo -e "${YELLOW}kubectl port-forward service/swarm-app 8080:3000${NC}"
  fi
else
  echo -e "\n${YELLOW}Servizio swarm-app non trovato.${NC}"
fi

echo -e "\n${BLUE}Processo completato.${NC}"