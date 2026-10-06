# ContaClaraAI v0.8 — Prestação de Contas

Baseada na v0.7.1 multi-tenant.

## Novidades
- Relatório por período no controle atual.
- Cabeçalho com identidade e dados da organização.
- Resumo: total, pago, pendente e quantidade de lançamentos.
- Consolidação por categoria.
- Conferência de comprovantes e cobertura documental.
- Detalhamento com pagador, recebedor, forma, status e comprovante.
- Exportação compatível com Excel via CSV UTF-8.
- Geração de PDF usando a impressão nativa do navegador, com CSS específico para impressão.
- Layout responsivo preservado.

## Banco de dados
Esta versão não exige alteração de schema. Não é necessário executar `supabase/schema.sql` novamente se a v0.7.1 já está aplicada.

## Publicação
```powershell
npm install
npm run build
git add .
git commit -m "Implementa prestacao de contas v0.8"
git push origin main
```

## Teste
Abra Relatórios, escolha o período, confira os totais, teste Exportar Excel (CSV) e Gerar PDF / Imprimir.
