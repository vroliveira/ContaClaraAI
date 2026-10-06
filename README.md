# ContaClaraAI v0.2 — Vercel + Supabase

## 1. Criar projeto no Supabase
Crie um projeto em https://supabase.com e aguarde o banco ficar disponível.

## 2. Criar banco e Storage
No Supabase, abra **SQL Editor > New query**, cole todo o conteúdo de `supabase/schema.sql` e execute.
Isso cria `controles`, `despesas`, RLS e o bucket privado `comprovantes`.

## 3. Configurar autenticação
Em **Authentication > Providers > Email**, mantenha Email habilitado.
Para testes, você pode manter confirmação de e-mail ativa (recomendado) ou desativá-la temporariamente.
Em **Authentication > URL Configuration**, configure:
- Site URL: `https://SEU-PROJETO.vercel.app`
- Redirect URLs: `http://localhost:3000/**` e `https://SEU-PROJETO.vercel.app/**`

## 4. Variáveis locais
Copie `.env.example` para `.env.local` e informe os valores do painel **Connect** do Supabase:
```
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
```
Não use `service_role` no navegador.

## 5. Instalar e testar
```
npm install
npm run dev
```
Depois:
```
npm run build
```

## 6. Publicar
```
git add .
git commit -m "Integra Supabase ao ContaClaraAI"
git push origin main
```

Na Vercel, abra **Project > Settings > Environment Variables** e cadastre as mesmas duas variáveis. Marque Production, Preview e Development. Depois faça Redeploy.

## Segurança
- Todas as tabelas usam RLS por `auth.uid()`.
- O bucket `comprovantes` é privado.
- Cada upload fica em uma pasta cujo primeiro segmento é o UUID do usuário.
- A visualização usa URL assinada temporária (60 s).

## v0.3 — Importador WhatsApp real
A tela **Importar WhatsApp** agora:
- lê o `chat.txt` exportado pelo WhatsApp no navegador;
- interpreta mensagens multilinha, data/hora e autor;
- detecta candidatos de despesas por contexto, valor, categoria e referência a PDF;
- permite revisar, editar, selecionar ou ignorar cada candidato;
- aceita selecionar junto PDFs/imagens e associa o comprovante pelo nome citado no chat;
- só grava no PostgreSQL depois da confirmação do usuário;
- envia comprovantes encontrados para o bucket privado `comprovantes`.

### Como testar com o caso Pai - Despesas
1. Entre em **Importar WhatsApp**.
2. Selecione `chat.txt` (e, se disponíveis, os PDFs citados no chat).
3. Clique em **Analisar conversa**.
4. Revise os candidatos. Itens sem valor ficam desmarcados até que o valor seja informado.
5. Marque os lançamentos desejados e clique em **Importar selecionados**.

> O parser não inventa valores ausentes no `.txt`. Se o WhatsApp exportou apenas `<imagem ocultada>` ou uma referência de PDF sem valor textual, o lançamento fica para conferência manual. Leitura automática do conteúdo de PDF/imagem por IA/OCR é a próxima camada.


## v0.4 — Importação direta do ZIP do WhatsApp
- Aceita o `.zip` gerado por **Exportar conversa > Incluir mídia**.
- Extrai o ZIP no próprio navegador com JSZip; o ZIP bruto não é enviado ao servidor.
- Localiza automaticamente o `.txt` da conversa e disponibiliza PDFs/imagens extraídos para associação.
- Ignora diretórios internos e metadados comuns (`__MACOSX`, arquivos ocultos).
- Mantém compatibilidade com seleção manual de `.txt`, PDF e imagens.
- Quando o nome de um PDF citado no chat coincide com um arquivo dentro do ZIP, o comprovante é enviado ao Storage privado no momento da confirmação.

### Atualização
Execute `npm install` para instalar `jszip`, depois `npm run build`.
