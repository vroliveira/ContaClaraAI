# ContaClaraAI

MVP responsivo de controle de despesas e comprovantes, pronto para Vercel.

## Executar localmente

```bash
npm install
npm run dev
```

Abra http://localhost:3000

## Build

```bash
npm run build
npm start
```

## Dados

Nesta primeira versão os lançamentos são persistidos no `localStorage` do navegador para permitir deploy imediato sem banco ou variáveis de ambiente. O próximo passo recomendado é conectar Supabase para persistência multiusuário e Storage de comprovantes.
