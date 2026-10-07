# ContaClaraAI v0.13.0 — Hotsite Comercial + Onboarding

Baseada na v0.12.2.

## Novidades
- Hotsite público responsivo na raiz para usuários não autenticados.
- Hero comercial, dores, recursos, passo a passo, planos e CTAs.
- Login/cadastro acessíveis pelo hotsite.
- Seleção de Free/Plus/Pro preservada durante o cadastro; após autenticar, planos pagos direcionam para Assinatura.
- Onboarding em 3 passos para nomear workspace, escolher finalidade e nomear o primeiro controle.
- Mantém toda a aplicação, Admin SaaS e checkout hospedado Mercado Pago da v0.12.2.

## Banco de dados
Não há nova migration obrigatória na v0.13.0. O schema da v0.12.2 continua sendo a base.

## Publicação
```bash
npm install
npm run build
git add .
git commit -m "Implementa hotsite comercial e onboarding v0.13.0"
git push origin main
```

## Observação
O onboarding usa um marcador local no navegador (`ccai_onboarding_done`) para não reaparecer após concluído/pulado. Uma evolução futura pode persistir esse estado por usuário no banco e adicionar telemetria de funil/UTM.
