# ContaClaraAI v0.17.3 — Ajuda/Tour Mobile Fix 2

Correção estrutural do fluxo de Ajuda + Tour/Onboarding em celular.

- Tour/Onboarding passa a usar fullscreen real com `100dvh` no mobile.
- Removidos limites de `92vh` e centralização vertical que podiam cortar o conteúdo.
- Rolagem ocorre dentro da tela do tour, com suporte a iOS (`-webkit-overflow-scrolling`).
- `safe-area` aplicado no topo e rodapé.
- `viewport-fit=cover` configurado no Next.js.
- Inputs do onboarding usam 16px no mobile para evitar zoom automático do Safari.
- Scroll da página de fundo é bloqueado enquanto Ajuda/Tour estiver aberto.
- Camadas da Ajuda/Tour ficam acima da topbar e menu mobile.

Não há migration SQL nesta versão.
