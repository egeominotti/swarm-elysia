#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "Uso: $0 nome-immagine:tag nome-stack nome-servizio"
    echo "Esempio: $0 mia-app-bun:1.2.0 mio-stack app"
    exit 1
fi

NUOVA_IMMAGINE=$1
STACK_NAME=$2
SERVIZIO_NAME="${STACK_NAME}_${3}"

echo "🚀 Avvio aggiornamento a $NUOVA_IMMAGINE"
echo "📦 Stack: $STACK_NAME"
echo "🔧 Servizio: $SERVIZIO_NAME"

if ! docker service ls | grep -q "$SERVIZIO_NAME"; then
    echo "❌ Errore: Il servizio $SERVIZIO_NAME non esiste"
    echo "Servizi disponibili:"
    docker service ls
    exit 1
fi

echo "📋 Stato attuale del servizio:"
docker service inspect --pretty "$SERVIZIO_NAME"

echo "⏳ Aggiornamento in corso..."
docker service update \
    --image "$NUOVA_IMMAGINE" \
    --update-parallelism 2 \
    --update-delay 10s \
    --update-order start-first \
    --update-failure-action rollback \
    --update-monitor 30s \
    "$SERVIZIO_NAME"

echo "🔍 Monitoraggio dell'aggiornamento..."
watch -n 2 "docker service ps $SERVIZIO_NAME"

echo "✅ Aggiornamento completato!"
echo "📊 Stato finale del servizio:"
docker service ps "$SERVIZIO_NAME"

REPLICHE_ATTESE=$(docker service inspect --format='{{.Spec.Mode.Replicated.Replicas}}' "$SERVIZIO_NAME")
REPLICHE_ATTIVE=$(docker service ls --filter "name=$SERVIZIO_NAME" --format "{{.Replicas}}" | cut -d'/' -f1)

if [ "$REPLICHE_ATTIVE" -eq "$REPLICHE_ATTESE" ]; then
    echo "✅ Tutte le $REPLICHE_ATTESE repliche sono attive!"
else
    echo "⚠️ Attenzione: $REPLICHE_ATTIVE/$REPLICHE_ATTESE repliche attive"
fi

echo "📋 Dettagli dell'immagine aggiornata:"
docker service inspect --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}' "$SERVIZIO_NAME"

echo "🎉 Procedura di aggiornamento completata"