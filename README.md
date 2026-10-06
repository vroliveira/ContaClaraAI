# ContaClaraAI v0.9 — ContaClara AI

Evolução da v0.8 com análise inteligente de comprovantes no fluxo de importação do WhatsApp.

## Novidades
- Análise de PDF/JPG/PNG/WEBP com IA no servidor.
- Extração de valor, data, pagador, recebedor, forma de pagamento e identificador PIX.
- Sugestão de descrição e categoria usando as categorias do workspace.
- Indicador de confiança e revisão humana antes da gravação.
- Persistência dos metadados de IA (`ia_confianca`, `ia_dados`, `origem`).
- Detecção de possível duplicidade pelo `pix_transacao_id` dentro do controle.
- Chave da IA somente no servidor; nunca use `NEXT_PUBLIC_` para ela.

## Configuração
1. Execute `supabase/schema.sql` no SQL Editor (script idempotente).
2. Na Vercel, crie `OPENAI_API_KEY` somente para Production/Preview conforme necessário.
3. Opcional: `OPENAI_MODEL=gpt-5.6-luna` (padrão da aplicação).
4. Faça novo deploy.

## Fluxo
Importar WhatsApp → analisar conversa → em um candidato com comprovante, clicar **Analisar comprovante com IA** → revisar os campos → selecionar → importar.

A IA não grava automaticamente. O usuário sempre revisa e confirma o lançamento.
