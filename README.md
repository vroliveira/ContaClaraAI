# ContaClaraAI v0.6 — Múltiplos controles e compartilhamento

## Novidades
- Vários controles por usuário (ex.: Pai - Despesas, Casa, Viagem, Empresa).
- Seletor de controle na barra lateral; Dashboard, despesas, comprovantes e relatórios passam a usar somente o controle ativo.
- Tela **Controles** para criar e editar controles.
- Compartilhamento por e-mail com papéis: Administrador, Editor e Visualizador.
- Convites pendentes são ativados automaticamente quando o usuário entra com o mesmo e-mail no ContaClaraAI.
- RLS do Supabase atualizada para acesso por controle.
- Comprovantes de controles compartilhados podem ser visualizados pelos membros autorizados.

## Instalação
1. No Supabase > SQL Editor, execute `supabase/schema.sql` completo.
2. Substitua os arquivos da aplicação pela v0.6.
3. Rode `npm install` e `npm run build`.
4. Faça commit/push para o GitHub; a Vercel fará o deploy.

## Papéis
- **Proprietário**: cria/edita o controle, convida/remove membros e gerencia despesas.
- **Administrador**: consulta e altera despesas do controle.
- **Editor**: consulta e altera despesas do controle.
- **Visualizador**: somente consulta os dados do controle.

> Nesta versão, o convite é interno: o e-mail convidado precisa criar/usar uma conta no ContaClaraAI com o mesmo endereço. O acesso é ativado no próximo login/carregamento. O envio de e-mail transacional de convite pode ser adicionado depois.
