# ContaClaraAI v0.11.2 — Mercado Pago Webhook

Integração de assinaturas recorrentes Plus/Pro com Mercado Pago.

## Recursos
- Checkout de assinatura Plus e Pro
- `notification_url` enviada automaticamente na criação de cada assinatura, derivada de `NEXT_PUBLIC_APP_URL`
- Persistência do ID da assinatura e do plano Mercado Pago
- Sincronização manual do status
- Webhook com validação HMAC (`x-signature`)
- Ativação do plano somente após confirmação do status pelo Mercado Pago
- Cancelamento server-side
- Mantém Free sem cobrança

## 1. Banco
Execute `supabase/schema.sql` no SQL Editor. O script adiciona metadados do Mercado Pago à tabela `assinaturas` e é reaplicável.

## 2. Variáveis Vercel (server-side)
Configure sem prefixo `NEXT_PUBLIC_`:
- `SUPABASE_SERVICE_ROLE_KEY`
- `MERCADOPAGO_ACCESS_TOKEN`
- `MERCADOPAGO_WEBHOOK_SECRET`
- `MERCADOPAGO_PLUS_PLAN_ID`
- `MERCADOPAGO_PRO_PLAN_ID`

Também configure:
- `NEXT_PUBLIC_APP_URL=https://conta-clara-ai-ten.vercel.app`

As variáveis Supabase públicas já utilizadas pelo frontend continuam necessárias.

## 3. Mercado Pago
Crie dois planos recorrentes mensais no Mercado Pago (Plus e Pro) e coloque os IDs nas variáveis acima. O backend usa `/preapproval` para iniciar a assinatura e o `init_point` retornado para redirecionar ao checkout.

Webhook de produção:
`https://conta-clara-ai-ten.vercel.app/api/billing/webhook`

Na v0.11.2 essa URL é enviada automaticamente no campo `notification_url` ao criar o `/preapproval`. Portanto, para esse fluxo de Assinaturas, não é necessário informar manualmente a URL em cada contratação. O endpoint continua validando `x-signature` usando `MERCADOPAGO_WEBHOOK_SECRET`.

## 4. Publicação
```powershell
npm install
npm run build
git add .
git commit -m "Corrige notification_url Mercado Pago v0.11.2"
git push origin main
```

## Segurança
Nunca exponha Access Token, Webhook Secret ou Service Role Key no frontend/Git. Nenhuma dessas variáveis deve usar `NEXT_PUBLIC_`.
