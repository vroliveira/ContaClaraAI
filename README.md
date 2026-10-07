# ContaClaraAI v0.11.3 — Mercado Pago Assinaturas

Correção do webhook para o fluxo específico de Assinaturas (`preapproval`) do Mercado Pago.

## O que mudou
- Mantém `notification_url` na criação de cada assinatura.
- Remove a dependência de `MERCADOPAGO_WEBHOOK_SECRET` neste fluxo.
- O payload recebido pelo webhook é tratado somente como aviso.
- O backend obtém `data.id` e consulta `GET /preapproval/{id}` usando `MERCADOPAGO_ACCESS_TOKEN`.
- O plano só é atualizado após confirmar a assinatura diretamente na API do Mercado Pago.
- Confere se `preapproval_plan_id` corresponde ao Plus ou Pro configurado.
- Confere se `external_reference` aponta para uma organização existente.
- Falhas transitórias retornam HTTP 500 para permitir nova tentativa; notificações irrelevantes são reconhecidas sem alterar dados.

## Variáveis Vercel
Server-side:
- `SUPABASE_SERVICE_ROLE_KEY`
- `MERCADOPAGO_ACCESS_TOKEN`
- `MERCADOPAGO_PLUS_PLAN_ID`
- `MERCADOPAGO_PRO_PLAN_ID`

Pública:
- `NEXT_PUBLIC_APP_URL=https://conta-clara-ai-ten.vercel.app`

As variáveis públicas do Supabase usadas pelo frontend continuam necessárias.

> `MERCADOPAGO_WEBHOOK_SECRET` não é mais necessária nesta versão para o fluxo de Assinaturas via `notification_url`.

## Banco
Não há alteração de banco em relação à v0.11.2. Não é necessário executar novamente o `schema.sql` apenas por esta atualização.

## Publicação
```powershell
npm install
npm run build

git add .
git commit -m "Ajusta webhook Mercado Pago assinaturas v0.11.3"
git push origin main
```

## Teste recomendado
1. Faça deploy da v0.11.3.
2. Entre no ContaClaraAI e abra **Assinatura**.
3. Escolha o plano Plus.
4. Conclua uma assinatura de teste/controle.
5. Retorne ao ContaClaraAI e use **Sincronizar** se necessário.
6. Confirme no Supabase que `assinaturas.status`, `assinatura_externa_id`, `plano_externo_id` e `proxima_cobranca` foram atualizados.
7. Só depois valide o ciclo de cancelamento.

## Segurança
Nunca exponha Access Token ou Service Role Key no frontend, Git ou variáveis `NEXT_PUBLIC_*`.
