# ContaClaraAI v0.13.2 — Logo oficial na área autenticada

Baseada na v0.13.1.

## Alterações
- Mantém o logotipo oficial no hotsite público.
- Aplica o mesmo logotipo oficial na sidebar após o login.
- Aplica o logotipo oficial no cabeçalho mobile autenticado.
- Preserva a possibilidade de uma organização usar um logotipo próprio em Configurações.
- Nenhuma alteração de banco de dados, Supabase ou Mercado Pago.

## Publicação
```bash
npm install
npm run build
git add .
git commit -m "Aplica logo oficial na area autenticada v0.13.2"
git push origin main
```


## v0.13.3 — Logo na autenticação
- Logo oficial ContaClaraAI aplicado na tela de login.
- O mesmo componente de autenticação cobre criação de conta.
- Ajuste responsivo para mobile.

## v0.15.0 — Conciliação Bancária

Nova área **Conciliação Bancária** para importar extratos OFX/CSV e reconciliar movimentações com despesas do controle.

### Entregas
- Importação de arquivos `.ofx` com leitura de `DTPOSTED`, `TRNAMT`, `FITID`, `NAME`, `MEMO` e `TRNTYPE`.
- Importação CSV com detecção de separador `;`/`,` e colunas de data, valor, descrição/histórico, tipo e identificador.
- Deduplicação por `controle_id + identificador_externo` (FITID no OFX).
- Central de conciliação com filtros Pendentes, Conciliadas, Ignoradas e Todas.
- Sugestão por IA comparando valor, data, favorecido e descrição com despesas existentes.
- Fallback local de sugestão quando o provedor de IA estiver indisponível.
- Confirmação humana antes de conciliar.
- Criação de despesa a partir de uma movimentação sem correspondência.
- RLS por controle e permissões existentes do SaaS multi-tenant.

### Implantação
1. Execute novamente `supabase/schema.sql` no SQL Editor do Supabase. O bloco v0.15.0 cria `transacoes_bancarias` e suas policies.
2. Mantenha `OPENAI_API_KEY` configurada na Vercel para usar **Analisar com IA**.
3. Faça deploy da aplicação.
4. Acesse **Conciliação Bancária**, importe um OFX/CSV e revise as sugestões antes de confirmar.

### CSV mínimo
O CSV deve possuir ao menos colunas equivalentes a `Data` e `Valor`. São reconhecidos também nomes como `date`, `amount`, `descricao`, `historico`, `memo`, `tipo`, `id` e `fitid`.

### Observação
Esta versão não conecta diretamente a bancos/Open Finance. A integração automática por API fica reservada para uma evolução posterior; a v0.15.0 trabalha com arquivos exportados pelo banco.
