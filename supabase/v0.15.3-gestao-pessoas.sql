-- ContaClaraAI v0.15.3 - Gestão de Pessoas
create table if not exists public.pessoas (
  id uuid primary key default gen_random_uuid(),
  controle_id uuid not null references public.controles(id) on delete cascade,
  organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  nome text not null,
  email text,
  telefone text,
  observacoes text,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pessoas_nome_check check (length(trim(nome)) > 0)
);
create unique index if not exists pessoas_controle_nome_uidx on public.pessoas(controle_id, lower(trim(nome)));
create index if not exists pessoas_controle_idx on public.pessoas(controle_id);
alter table public.pessoas enable row level security;
drop policy if exists "pessoas_select" on public.pessoas;
create policy "pessoas_select" on public.pessoas for select to authenticated using(public.can_access_controle(controle_id));
drop policy if exists "pessoas_insert" on public.pessoas;
create policy "pessoas_insert" on public.pessoas for insert to authenticated with check(user_id=auth.uid() and public.can_edit_controle(controle_id));
drop policy if exists "pessoas_update" on public.pessoas;
create policy "pessoas_update" on public.pessoas for update to authenticated using(public.can_edit_controle(controle_id)) with check(public.can_edit_controle(controle_id));
drop policy if exists "pessoas_delete" on public.pessoas;
create policy "pessoas_delete" on public.pessoas for delete to authenticated using(public.can_edit_controle(controle_id));
