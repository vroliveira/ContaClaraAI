# ContaClaraAI v0.10 — Gestão Financeira

Evolução sobre a v0.9 com Central de Pendências, orçamento mensal, despesas recorrentes e rateio/reembolso.

## Migração
Execute `supabase/schema.sql` no SQL Editor do Supabase. O script mantém o padrão idempotente das versões anteriores.

## Publicação
```powershell
npm install
npm run build
git add .
git commit -m "Implementa gestao financeira v0.10"
git push origin main
```

## Funcionalidades
- Menu Financeiro responsivo.
- Central de Pendências: sem comprovante, pagamentos pendentes, itens em Outros/sem categoria e PIX repetido.
- Orçamento mensal geral e opcional por categoria.
- Despesas recorrentes com ativação/pausa.
- Rateios com pagador, participantes e cálculo da cota individual.
- RLS por organização/controle.
