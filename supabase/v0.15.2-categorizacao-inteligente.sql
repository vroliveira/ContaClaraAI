-- ContaClaraAI v0.15.2 - Categorização Inteligente do Extrato
-- Executar no Supabase SQL Editor antes do deploy.

alter table public.transacoes_bancarias
  add column if not exists categoria_sugerida_nova text;

create table if not exists public.regras_categorizacao_bancaria (
  id uuid primary key default gen_random_uuid(),
  organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
  controle_id uuid not null references public.controles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  termo text not null,
  categoria text not null,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists regras_cat_bancaria_controle_termo_uk
  on public.regras_categorizacao_bancaria(controle_id, termo);
create index if not exists regras_cat_bancaria_controle_idx
  on public.regras_categorizacao_bancaria(controle_id, ativo);

alter table public.regras_categorizacao_bancaria enable row level security;
drop policy if exists "regras_cat_bancaria_select" on public.regras_categorizacao_bancaria;
create policy "regras_cat_bancaria_select" on public.regras_categorizacao_bancaria for select to authenticated
  using (public.can_access_controle(controle_id));
drop policy if exists "regras_cat_bancaria_insert" on public.regras_categorizacao_bancaria;
create policy "regras_cat_bancaria_insert" on public.regras_categorizacao_bancaria for insert to authenticated
  with check (auth.uid()=user_id and public.can_edit_controle(controle_id));
drop policy if exists "regras_cat_bancaria_update" on public.regras_categorizacao_bancaria;
create policy "regras_cat_bancaria_update" on public.regras_categorizacao_bancaria for update to authenticated
  using (public.can_edit_controle(controle_id)) with check (public.can_edit_controle(controle_id));
drop policy if exists "regras_cat_bancaria_delete" on public.regras_categorizacao_bancaria;
create policy "regras_cat_bancaria_delete" on public.regras_categorizacao_bancaria for delete to authenticated
  using (public.can_edit_controle(controle_id));
