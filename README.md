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
