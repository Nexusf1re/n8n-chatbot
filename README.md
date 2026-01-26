# Stack n8n + WAHA + Whisper

## Visão geral
Hospeda n8n, WAHA (WhatsApp HTTP API), Redis e o serviço Whisper ASR. O script `start-waha-with-config.sh` sobe o WAHA e aplica o webhook automaticamente no n8n.

## Requisitos
- Docker e Docker Compose v2.
- Portas livres: 3000 (WAHA), 5678 (n8n), 9000 (Whisper), opcional 6379 interna para Redis.
- Arquivo `.env` preenchido (baseado em `.env.example`).

## Configuração
1. Duplique `.env.example` para `.env` e ajuste:
   - `WAHA_USER` / `WAHA_PASS`: credenciais do dashboard e API (ou defina `WAHA_API_KEY` separado se quiser uma key distinta).
   - `WAHA_ENGINE`: NOWEB, WEBJS ou GOWS.
   - `WAHA_SESSION_NAME`: nome da sessão criada/iniciada.
   - `WAHA_WEBHOOK_URL`: URL completa do webhook; se vazio, cai para `N8N_WEBHOOK_URL` + `/webhook/webhook`.
   - `WAHA_WEBHOOK_RETRY_ATTEMPTS` / `WAHA_WEBHOOK_RETRY_DELAY_SECONDS`: tentativas e delay do webhook.
   - `N8N_WEBHOOK_URL` e `N8N_HOST`: host público que o n8n usa para gerar webhooks.
   - `ASR_MODEL`: tiny, base ou small (trade-off velocidade vs. precisão).
   - `REDIS_PASSWORD`: senha usada no Redis embutido.
2. (Opcional) Ajuste `WAHA_WEBHOOK_EVENTS` se quiser eventos adicionais (ex.: `message,status`).
3. Mantenha `.env` e credenciais do Cloudflare fora do controle de versão.

## Subir o ambiente
```
docker compose up -d
```

## Endpoints
- WAHA dashboard/API: http://localhost:3000
- n8n: http://localhost:5678
- Whisper ASR: http://localhost:9000 (usado internamente pelo n8n)

O script aguarda a sessão do WAHA ficar `WORKING` e então aplica o webhook com as variáveis acima, sobrevivendo a restart.

## Cloudflare (opcional)
- O serviço `cloudflared` está comentado no `docker-compose.yml`.
- Para usar túnel, forneça `cloudflared/config.yml` e credencial `.json`, e descomente o serviço (ou crie um profile `cloudflared`).
- Nunca commite o arquivo de credenciais; use um `config.example.yml` com IDs fictícios se precisar documentar.

## Parar/atualizar
```
docker compose down    # parar

docker compose pull    # atualizar imagens
```

## Boas práticas
- Troque `REDIS_PASSWORD` e as senhas padrão antes de expor.
- Considere fixar tags de imagem em vez de `latest` para evitar upgrades inesperados.
- Use proxy ou túnel (Cloudflare) se precisar expor os serviços de forma segura.
