#!/bin/bash

# Script per gestire il deployment Kubernetes

# Colori per l'output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Menu principale
echo -e "${BLUE}===== KUBERNETES MANAGER =====${NC}"
echo -e "${YELLOW}1) Aggiorna deployment${NC}"
echo -e "${YELLOW}2) Visualizza stato dei pod${NC}"
echo -e "${YELLOW}3) Visualizza stato dei servizi${NC}"
echo -e "${YELLOW}4) Visualizza stato dell'HPA${NC}"
echo -e "${YELLOW}5) Scala manualmente${NC}"
echo -e "${YELLOW}6) Visualizza logs${NC}"
echo -e "${YELLOW}7) Elimina tutto${NC}"
echo -e "${YELLOW}8) Esci${NC}"

read -p "Seleziona un'opzione: " option

case $option in
  1)
    echo -e "${BLUE}Aggiornamento deployment...${NC}"
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/hpa.yaml
    echo -e "${GREEN}Deployment aggiornato!${NC}"
    ;;
    
  2)
    echo -e "${BLUE}Stato dei pod:${NC}"
    kubectl get pods -o wide
    ;;
    
  3)
    echo -e "${BLUE}Stato dei servizi:${NC}"
    kubectl get services
    echo -e "\n${GREEN}L'applicazione è accessibile su: ${YELLOW}http://localhost:30000${NC}"
    ;;
    
  4)
    echo -e "${BLUE}Stato dell'Horizontal Pod Autoscaler:${NC}"
    kubectl get hpa
    kubectl describe hpa swarm-app-hpa
    ;;
    
  5)
    read -p "Inserisci il numero di repliche: " replicas
    kubectl scale deployment swarm-app --replicas=$replicas
    echo -e "${GREEN}Deployment scalato a $replicas repliche${NC}"
    ;;
    
  6)
    echo -e "${BLUE}Logs dell'applicazione:${NC}"
    kubectl logs -l app=swarm-app --tail=50
    ;;
    
  7)
    echo -e "${RED}Attenzione: Questa operazione eliminerà tutte le risorse!${NC}"
    read -p "Sei sicuro di voler procedere? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
      kubectl delete -f k8s/
      echo -e "${GREEN}Risorse eliminate.${NC}"
    else
      echo -e "${YELLOW}Operazione annullata.${NC}"
    fi
    ;;
    
  8)
    echo -e "${GREEN}Arrivederci!${NC}"
    exit 0
    ;;
    
  *)
    echo -e "${RED}Opzione non valida!${NC}"
    ;;
esac

echo -e "\n${BLUE}Operazione completata.${NC}"