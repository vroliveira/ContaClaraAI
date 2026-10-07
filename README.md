# ContaClaraAI v0.11.5 — Billing / resolução da organização

Correção incremental da v0.11.4 para diagnosticar e tratar corretamente a organização usada no checkout do Mercado Pago.

## O que mudou

- `assertOrgAdmin` não transforma mais qualquer erro do Supabase em "Organização não encontrada".
- Diferencia: workspace não informado, erro de consulta, organização inexistente e falta de permissão.
- A consulta usa `maybeSingle()` e preserva a mensagem segura retornada pelo PostgREST.
- Valida proprietário ou membro `administrador` ativo antes de criar/sincronizar/cancelar assinatura.
- O checkout usa o ID da organização já validada no `external_reference` do Mercado Pago.
- Erros ao atualizar `assinaturas` deixam de ser ignorados.
- Mantém JWT do Supabase no `Authorization: Bearer` introduzido na v0.11.4.
- Não há migração de banco nesta versão.

## Variáveis Vercel

As variáveis abaixo devem continuar configuradas. `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` e `SUPABASE_SERVICE_ROLE_KEY` precisam ser do MESMO projeto Supabase.

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_APP_URL=https://conta-clara-ai-ten.vercel.app
MERCADOPAGO_ACCESS_TOKEN=
MERCADOPAGO_PLUS_PLAN_ID=
MERCADOPAGO_PRO_PLAN_ID=
```

Nunca exponha `SUPABASE_SERVICE_ROLE_KEY` ou `MERCADOPAGO_ACCESS_TOKEN` no navegador, Git ou screenshots.

## Publicação

```bash
npm install
npm run build
git add .
git commit -m "Corrige resolucao da organizacao no billing v0.11.5"
git push origin main
```

Após o deploy, saia e entre novamente no ContaClaraAI e teste Assinatura > Plus. Se houver falha, a mensagem agora identifica a etapa real (Supabase, organização, permissão ou Mercado Pago).
