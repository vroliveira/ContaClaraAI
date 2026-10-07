-- ContaClaraAI v0.16.0 - Conciliação Bancária 2.0
create table if not exists public.importacoes_bancarias (
  id uuid primary key default gen_random_uuid(),
  organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
  controle_id uuid not null references public.controles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  arquivo text not null,
  formato text not null check (formato in ('OFX','CSV')),
  banco text,
  conta text,
  moeda text default 'BRL',
  periodo_inicial date,
  periodo_final date,
  quantidade_lida integer not null default 0,
  quantidade_importada integer not null default 0,
  quantidade_duplicada integer not null default 0,
  status text not null default 'processando' check (status in ('processando','concluida','erro')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists ix_importacoes_bancarias_controle_created on public.importacoes_bancarias(controle_id,created_at desc);
alter table public.importacoes_bancarias enable row level security;
drop policy if exists "importacoes_bancarias_select" on public.importacoes_bancarias;
create policy "importacoes_bancarias_select" on public.importacoes_bancarias for select to authenticated using (public.can_access_controle(controle_id));
drop policy if exists "importacoes_bancarias_insert" on public.importacoes_bancarias;
create policy "importacoes_bancarias_insert" on public.importacoes_bancarias for insert to authenticated with check (auth.uid()=user_id and public.can_edit_controle(controle_id));
drop policy if exists "importacoes_bancarias_update" on public.importacoes_bancarias;
create policy "importacoes_bancarias_update" on public.importacoes_bancarias for update to authenticated using (public.can_edit_controle(controle_id)) with check (public.can_edit_controle(controle_id));
drop policy if exists "importacoes_bancarias_delete" on public.importacoes_bancarias;
create policy "importacoes_bancarias_delete" on public.importacoes_bancarias for delete to authenticated using (public.can_edit_controle(controle_id));

alter table public.transacoes_bancarias add column if not exists importacao_id uuid references public.importacoes_bancarias(id) on delete set null;
create index if not exists ix_transacoes_bancarias_importacao on public.transacoes_bancarias(importacao_id);
