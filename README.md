# ContaClaraAI v0.11 — Comercialização SaaS

Evolução da v0.10 com fundação comercial por workspace.

## Novidades
- Menu **Assinatura** responsivo.
- Planos Free, Plus e Pro persistidos no Supabase.
- Assinatura por organização/workspace.
- Status de assinatura/trial e período.
- Indicadores de consumo: controles, membros, IA/mês e estrutura para armazenamento.
- Cards de preços e limites comerciais.
- RLS para planos, assinaturas e consumo.
- Provisionamento automático do plano Free para novos workspaces.

## Importante
Execute `supabase/schema.sql` no SQL Editor antes do deploy. O script usa operações idempotentes nas policies e seeds.

## Checkout
A v0.11 prepara banco, UI, planos e limites, mas **não ativa cobrança real**. O provedor de pagamentos deve ser definido antes de armazenar credenciais e implementar checkout/webhooks (Stripe, Mercado Pago, Pagar.me etc.). Isso evita acoplar o produto a um gateway sem decisão comercial.

## Publicação
```powershell
npm install
npm run build
git add .
git commit -m "Implementa comercializacao SaaS v0.11"
git push origin main
```
