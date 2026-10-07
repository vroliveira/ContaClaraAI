# ContaClaraAI v0.12.2 — Mercado Pago Hosted Subscription Checkout

Correção do fluxo de assinatura recorrente. Planos associados do Mercado Pago exigem `card_token_id` quando a aplicação cria diretamente `/preapproval`. Esta versão não captura cartão no ContaClaraAI: consulta o `preapproval_plan`, obtém seu `init_point` e redireciona o usuário para o checkout hospedado do Mercado Pago.

## Alterações
- `/api/billing/checkout`: GET `/preapproval_plan/{id}` e retorno do `init_point`; não chama mais POST `/preapproval` sem cartão.
- `billing_checkout_pendentes`: registra o vínculo workspace + usuário + plano + e-mail antes do redirecionamento.
- `/api/billing/webhook`: continua relendo `/preapproval/{id}` no Mercado Pago e, quando não houver `external_reference`, resolve o workspace pelo checkout pendente.
- O cartão permanece fora do ContaClaraAI.

## Banco
Execute `supabase/schema.sql` no SQL Editor. A seção v0.12.2 é idempotente e cria `billing_checkout_pendentes`.

## Variáveis
Mantém as variáveis existentes:
- `NEXT_PUBLIC_APP_URL`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `MERCADOPAGO_ACCESS_TOKEN`
- `MERCADOPAGO_PLUS_PLAN_ID`
- `MERCADOPAGO_PRO_PLAN_ID`

## Publicação
```powershell
npm install
npm run build
git add .
git commit -m "Corrige checkout hospedado Mercado Pago v0.12.2"
git push origin main
```

## Teste esperado
Assinatura > Plus > Assinar com Mercado Pago deve abrir o checkout hospedado do Mercado Pago, em vez de retornar `card_token_id is required`. Após a autorização, o webhook consulta a assinatura na API oficial e atualiza o workspace.
