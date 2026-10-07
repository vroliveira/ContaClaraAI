# ContaClaraAI v0.17.2 — Help Mobile Fix

Correção da Central de Ajuda em celulares.

## Alterações
- Central de Ajuda agora fica acima da topbar e do menu mobile (z-index corrigido).
- Painel mobile usa `100dvh`, evitando problemas com a barra dinâmica do navegador.
- Suporte a `safe-area` para iPhone/notch.
- Rolagem interna com comportamento adequado em iOS/Android.
- Cabeçalho e botão de fechar permanecem acessíveis durante a rolagem.
- Alvos de toque maiores e `touch-action` nos controles.
- Botão flutuante respeita a safe-area inferior.

## Banco de dados
Nenhuma migration SQL é necessária nesta versão.
