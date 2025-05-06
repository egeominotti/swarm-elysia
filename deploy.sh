#!/bin/bash

set -e 

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

APP_NAME="swarm-app"
STACK_NAME="swarm"

echo -e "${GREEN}=== DOCKER SWARM REDEPLOYMENT SCRIPT ===${NC}"
echo "Questo script ricostruisce e ridistribuisce l'applicazione Bun su Docker Swarm"
echo ""

# Verifica che Docker Swarm sia inizializzato
if ! docker info | grep -q "Swarm: active"; then
    echo -e "${YELLOW}Swarm non è attivo su questa macchina. Inizializzazione...${NC}"
    docker swarm init || {
        echo -e "${RED}Errore durante l'inizializzazione di Swarm${NC}"
        exit 1
    }
    echo -e "${GREEN}Swarm inizializzato con successo!${NC}"
else
    echo -e "${GREEN}Swarm è già attivo su questa macchina.${NC}"
fi

echo -e "${YELLOW}Costruendo l'immagine Docker...${NC}"
docker build -t ${APP_NAME}:latest . || {
    echo -e "${RED}Errore durante la build dell'immagine Docker${NC}"
    exit 1
}
echo -e "${GREEN}Immagine Docker costruita con successo!${NC}"

echo -e "${YELLOW}Generando il file docker-compose.yml...${NC}"
cat > docker-compose.yml << EOF
services:
  app:
    image: ${APP_NAME}:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 10
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
      endpoint_mode: vip
EOF
echo -e "${GREEN}File docker-compose.yml generato con successo!${NC}"

echo -e "${YELLOW}Rimuovendo stack precedente se esistente...${NC}"
docker stack rm ${STACK_NAME} 2>/dev/null || true

echo -e "${YELLOW}Attendere mentre lo stack viene rimosso completamente...${NC}"
while docker stack ls | grep -q ${STACK_NAME}; do
    echo -e "${YELLOW}.${NC}"
    sleep 1
done

while docker network ls | grep -q "${STACK_NAME}_"; do
    echo -e "${YELLOW}Attendere pulizia reti...${NC}"
    sleep 3
done

echo -e "${YELLOW}Deploying stack su Swarm...${NC}"
docker stack deploy -c docker-compose.yml ${STACK_NAME} || {
    echo -e "${RED}Errore durante il deployment dello stack${NC}"
    exit 1
}

echo -e "${GREEN}Stack deployato con successo!${NC}"

echo -e "${YELLOW}Verifica dello stato del servizio...${NC}"
echo "Attendere mentre i servizi vengono avviati..."
sleep 10

docker service ls | grep ${STACK_NAME}
echo ""
echo -e "${YELLOW}Visualizzazione dei container in esecuzione:${NC}"
docker stack ps ${STACK_NAME}

echo ""
echo -e "${GREEN}=== DEPLOYMENT COMPLETATO ===${NC}"
echo "L'applicazione è ora disponibile su http://localhost:3000"
echo ""
echo "Comandi utili:"
echo "  - docker service ls                        # Mostra lo stato dei servizi"
echo "  - docker stack ps ${STACK_NAME}            # Mostra lo stato dei container"
echo "  - docker service logs ${STACK_NAME}_app    # Mostra i log dell'applicazione"
echo "  - docker service scale ${STACK_NAME}_app=15 # Scala a 15 repliche"