# ContaClaraAI v0.15.4 — Autocomplete de Pessoas

## Novidades
- Campo **Quem pagou?** com autocomplete usando pessoas cadastradas e pagadores já existentes nas despesas.
- Permite continuar digitando um nome que ainda não exista.
- Ao salvar uma despesa nova ou editar uma existente, o pagador inexistente é cadastrado automaticamente em **Pessoas**.
- Normalização de espaços e comparação sem diferenciar maiúsculas/minúsculas para reduzir duplicidades.
- Reutiliza a restrição única de pessoas da v0.15.3 para proteção adicional contra duplicidade.

## Banco de dados
Não há nova estrutura obrigatória. A migration `supabase/v0.15.4-autocomplete-pagador.sql` é apenas informativa. É necessário que a migration da v0.15.3 já tenha sido executada.

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


## v0.15.1 — Correção de criação de organizações

Corrige o erro `new row violates row-level security policy for table "organizacoes"` ao criar um novo workspace.

Antes de publicar esta versão, execute no Supabase SQL Editor o arquivo:

`supabase/v0.15.1-fix-organizacao.sql`

A criação passa a usar a RPC `criar_organizacao`, que obtém o proprietário diretamente de `auth.uid()` no PostgreSQL. O cliente não pode escolher outro `owner_id`, preservando o isolamento multi-tenant e as políticas RLS existentes.

## v0.15.2 — Categorização Inteligente do Extrato
- CSV: reconhece coluna `Categoria/Category` quando fornecida pelo banco.
- OFX/CSV: botão **Sugerir categorias com IA** classifica até 30 movimentações pendentes por lote.
- A IA prioriza categorias existentes e, quando nenhuma se encaixa, propõe uma nova categoria reutilizável.
- Novas categorias só são cadastradas após confirmação em **Criar categoria**.
- Ao confirmar uma nova categoria, o ContaClaraAI grava uma regra de aprendizado por descrição para reaplicar a classificação em importações futuras.
- Antes do deploy, execute `supabase/v0.15.2-categorizacao-inteligente.sql` no SQL Editor.


## v0.15.3 — Gestão de Pessoas
- CRUD de pessoas por controle (criar, editar e excluir).
- Campos: nome, e-mail, telefone e observações.
- Total pago calculado a partir das despesas pelo nome do pagador.
- Pagadores históricos ainda não cadastrados aparecem com ação “Cadastrar”.
- Renomear uma pessoa atualiza o pagador das despesas vinculadas pelo nome anterior.
- Exclusão é bloqueada quando existem despesas vinculadas, evitando perda de referência.
- Execute `supabase/v0.15.3-gestao-pessoas.sql` antes do deploy.


## v0.15.5 — Correção Dashboard / Quem mais pagou
- Removeu valores fixos de Thais/Outros do placar.
- Ranking calculado dinamicamente pelas despesas com status Pago do controle atual.
- Agrupamento do pagador ignora diferenças de maiúsculas/minúsculas e espaços extras.
- Exibe até os 5 maiores pagadores e barras proporcionais ao maior valor.
- Despesas sem pagador não são atribuídas artificialmente a 'Outros'.
- Não requer migration de banco.

## v0.15.6 — Dashboard por Organização
- O quadro **Quem mais pagou** agora consolida despesas pagas de todos os controles da organização selecionada.
- A troca do controle atual não altera esse ranking; a troca da organização recalcula os dados.
- O quadro identifica visualmente que o resultado é consolidado por organização.
- Os demais indicadores do Dashboard continuam no escopo do controle atual nesta versão, evitando mudança silenciosa de semântica.
- Não requer migration SQL.
