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
echo -e "${YELLOW}8) Build e aggiorna immagine Docker${NC}"
echo -e "${YELLOW}9) Esci${NC}"

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
    echo -e "${BLUE}Build e aggiornamento immagine Docker...${NC}"
    
    # Impostazioni per l'immagine
    read -p "Inserisci il nome dell'immagine (default: egeominotti/swarm-app): " image_name
    image_name=${image_name:-egeominotti/swarm-app}
    
    read -p "Inserisci il tag dell'immagine (default: latest): " image_tag
    image_tag=${image_tag:-latest}
    
    # Percorso del Dockerfile
    read -p "Inserisci il percorso del Dockerfile (default: .): " dockerfile_path
    dockerfile_path=${dockerfile_path:-.}
    
    # Build dell'immagine
    echo -e "${YELLOW}Costruzione dell'immagine Docker...${NC}"
    docker build -t $image_name:$image_tag $dockerfile_path
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Errore durante la build dell'immagine!${NC}"
        exit 1
    fi
    
    # Push dell'immagine
    echo -e "${YELLOW}Vuoi eseguire il push dell'immagine su Docker Hub? (y/n): ${NC}"
    read push_confirm
    
    if [ "$push_confirm" = "y" ]; then
        echo -e "${YELLOW}Esecuzione del push su Docker Hub...${NC}"
        docker push $image_name:$image_tag
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Errore durante il push dell'immagine!${NC}"
            echo -e "${YELLOW}Assicurati di aver eseguito 'docker login' prima.${NC}"
            exit 1
        fi
    fi
    
    # Aggiornamento del deployment
    echo -e "${YELLOW}Seleziona metodo di aggiornamento:${NC}"
    echo "1) Imposta nuova immagine (set image)"
    echo "2) Riavvia deployment (rollout restart)"
    read -p "Scelta: " update_method
    
    if [ "$update_method" = "1" ]; then
        kubectl set image deployment/swarm-app swarm-app=$image_name:$image_tag
        echo -e "${GREEN}Immagine aggiornata a $image_name:$image_tag${NC}"
    elif [ "$update_method" = "2" ]; then
        kubectl rollout restart deployment swarm-app
        echo -e "${GREEN}Deployment riavviato, scaricherà la nuova immagine $image_name:$image_tag${NC}"
    else
        echo -e "${RED}Opzione non valida!${NC}"
    fi
    
    echo -e "${BLUE}Monitoraggio aggiornamento...${NC}"
    kubectl rollout status deployment/swarm-app
    ;;
    
  9)
    echo -e "${GREEN}Arrivederci!${NC}"
    exit 0
    ;;
    
  *)
    echo -e "${RED}Opzione non valida!${NC}"
    ;;
esac

echo -e "\n${BLUE}Operazione completata.${NC}"