#!/bin/sh
set -e

WAHA_API_KEY="${WAHA_API_KEY:-${WAHA_PASS:-}}"
SESSION_NAME="${WAHA_SESSION_NAME:-default}"

BASE_WEBHOOK_URL="${WAHA_WEBHOOK_URL:-}"

# Fallback para N8N_WEBHOOK_URL caso o URL completo do webhook não seja definido
if [ -z "$BASE_WEBHOOK_URL" ] && [ -n "${N8N_WEBHOOK_URL:-}" ]; then
  # Remove barra final, se existir, e acrescenta o path padrão do n8n
  BASE_URL_TRIMMED=${N8N_WEBHOOK_URL%/}
  BASE_WEBHOOK_URL="$BASE_URL_TRIMMED/webhook/webhook"
fi

WEBHOOK_URL="$BASE_WEBHOOK_URL"
WEBHOOK_RETRY_ATTEMPTS="${WAHA_WEBHOOK_RETRY_ATTEMPTS:-10}"
WEBHOOK_RETRY_DELAY_SECONDS="${WAHA_WEBHOOK_RETRY_DELAY_SECONDS:-1}"
WEBHOOK_EVENTS="${WAHA_WEBHOOK_EVENTS:-message}"

if [ -z "$WAHA_API_KEY" ]; then
  echo "[WAHA] Defina WAHA_API_KEY ou WAHA_PASS para autenticar as chamadas" >&2
  exit 1
fi

if [ -z "$WEBHOOK_URL" ]; then
  echo "[WAHA] Defina WAHA_WEBHOOK_URL ou N8N_WEBHOOK_URL para configurar o webhook" >&2
  exit 1
fi

# Inicia o WAHA original em background
/entrypoint.sh &

echo "[WAHA] WAHA rodando, aguardando sessão '${SESSION_NAME}' conectar..."

PAYLOAD=$(cat <<EOF
{
  "config": {
    "webhooks": [{
      "url": "${WEBHOOK_URL}",
      "events": ["${WEBHOOK_EVENTS}"],
      "retries": {
        "attempts": ${WEBHOOK_RETRY_ATTEMPTS},
        "delaySeconds": ${WEBHOOK_RETRY_DELAY_SECONDS}
      }
    }],
    "ignore": {"status": true, "groups": true, "channels": true, "broadcast": true},
    "noweb": {"markOnline": true}
  }
}
EOF
)

# Espera até a sessão ficar WORKING
while true; do
  if curl -s "http://localhost:3000/api/sessions/${SESSION_NAME}" -H "X-Api-Key: ${WAHA_API_KEY}" | grep -q '"status":"WORKING"'; then
    echo "[WAHA] Sessão WORKING → aplicando webhook ${WEBHOOK_URL} com delay ${WEBHOOK_RETRY_DELAY_SECONDS}s (${WEBHOOK_RETRY_ATTEMPTS} tentativas)"
    curl -X PUT "http://localhost:3000/api/sessions/${SESSION_NAME}" \
      -H "X-Api-Key: ${WAHA_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "${PAYLOAD}"
    echo
    echo "[WAHA] WEBHOOK CONFIGURADO"
    echo "[WAHA] SOBREVIVE A TODOS OS RESTARTS!"
    break
  fi
  sleep 3
done

# Mantém o container vivo
wait
