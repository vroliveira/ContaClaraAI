# ContaClaraAI v0.7.1 — Fundação SaaS Multi-tenant (Migration Fix)

Baseada na v0.6.1, preservando o menu mobile.

## Novidades
- Organizações / Workspaces acima dos controles.
- Um usuário pode ser proprietário ou membro de várias organizações.
- Seletor de organização na sidebar desktop/mobile.
- Controles e categorias isolados por `organizacao_id`.
- Membros da organização com papéis Administrador, Editor e Visualizador.
- Convites pendentes são ativados automaticamente quando o e-mail convidado entra no sistema.
- Configuração de identidade passa a pertencer à organização selecionada.
- RLS multi-tenant no Supabase.
- Migração dos controles, categorias, configurações e membros já existentes para um workspace padrão, sem apagar lançamentos.

## Antes de publicar
1. Faça backup do banco Supabase (recomendado para qualquer migração estrutural).
2. No Supabase > SQL Editor, execute `supabase/schema.sql` completo.
3. Confirme que existem as tabelas `organizacoes` e `organizacao_membros` e que `controles`/`categorias` possuem `organizacao_id`.
4. Rode `npm install` e `npm run build` localmente.
5. Faça commit/push para a Vercel.

## Modelo
`Usuário -> Organização -> Controles -> Despesas`

A organização também contém membros, categorias e identidade visual.

## Observação
A v0.7 mantém `controle_membros` por compatibilidade com a v0.6. O novo compartilhamento SaaS deve ser feito preferencialmente em **Organizações**, pois o acesso é herdado pelos controles do workspace.

## Correção v0.7.1
- `schema.sql` idempotente para policies: toda `CREATE POLICY` é precedida por `DROP POLICY IF EXISTS`.
- Corrige o erro PostgreSQL `42710` ao reaplicar o script após uma execução parcial da v0.7.
- Pode ser executado novamente sem remover manualmente as policies já criadas.
