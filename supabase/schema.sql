-- ContaClaraAI - Supabase schema v0.2
create extension if not exists pgcrypto;

create table if not exists public.controles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nome text not null default 'Pai - Despesas',
  descricao text,
  created_at timestamptz not null default now()
);

create table if not exists public.despesas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  controle_id uuid references public.controles(id) on delete cascade,
  data date not null,
  descricao text not null,
  categoria text not null,
  valor numeric(12,2) not null check (valor >= 0),
  pagador text,
  fornecedor text,
  status text not null default 'Pago' check (status in ('Pago','Pendente')),
  forma_pagamento text,
  observacoes text,
  comprovante_path text,
  comprovante_nome text,
  created_at timestamptz not null default now()
);

create index if not exists despesas_user_id_idx on public.despesas(user_id);
create index if not exists despesas_data_idx on public.despesas(data desc);

alter table public.controles enable row level security;
alter table public.despesas enable row level security;

drop policy if exists "controles_select_own" on public.controles;
create policy "controles_select_own" on public.controles for select to authenticated
using (auth.uid() is not null and auth.uid() = user_id);
drop policy if exists "controles_insert_own" on public.controles;
create policy "controles_insert_own" on public.controles for insert to authenticated
with check (auth.uid() is not null and auth.uid() = user_id);
drop policy if exists "controles_update_own" on public.controles;
create policy "controles_update_own" on public.controles for update to authenticated
using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "controles_delete_own" on public.controles;
create policy "controles_delete_own" on public.controles for delete to authenticated
using (auth.uid() = user_id);

drop policy if exists "despesas_select_own" on public.despesas;
create policy "despesas_select_own" on public.despesas for select to authenticated
using (auth.uid() is not null and auth.uid() = user_id);
drop policy if exists "despesas_insert_own" on public.despesas;
create policy "despesas_insert_own" on public.despesas for insert to authenticated
with check (auth.uid() is not null and auth.uid() = user_id);
drop policy if exists "despesas_update_own" on public.despesas;
create policy "despesas_update_own" on public.despesas for update to authenticated
using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "despesas_delete_own" on public.despesas;
create policy "despesas_delete_own" on public.despesas for delete to authenticated
using (auth.uid() = user_id);

-- Bucket privado para comprovantes (10 MB, PDF/JPG/PNG)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('comprovantes','comprovantes',false,10485760,array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false, file_size_limit=10485760,
allowed_mime_types=array['application/pdf','image/jpeg','image/png','image/webp'];

-- O primeiro diretório do arquivo deve ser o UUID do usuário autenticado.
drop policy if exists "comprovantes_insert_own" on storage.objects;
create policy "comprovantes_insert_own" on storage.objects for insert to authenticated
with check (bucket_id='comprovantes' and (storage.foldername(name))[1] = (select auth.uid()::text));
drop policy if exists "comprovantes_select_own" on storage.objects;
create policy "comprovantes_select_own" on storage.objects for select to authenticated
using (bucket_id='comprovantes' and owner_id = (select auth.uid()::text));
drop policy if exists "comprovantes_delete_own" on storage.objects;
create policy "comprovantes_delete_own" on storage.objects for delete to authenticated
using (bucket_id='comprovantes' and owner_id = (select auth.uid()::text));

-- v0.4.1 - Categorias configuráveis
create table if not exists public.categorias (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nome text not null,
  descricao text,
  ativo boolean not null default true,
  ordem integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categorias_user_nome_unique unique (user_id, nome)
);
create index if not exists categorias_user_id_idx on public.categorias(user_id);
alter table public.categorias enable row level security;
drop policy if exists "categorias_select_own" on public.categorias;
create policy "categorias_select_own" on public.categorias for select to authenticated using (auth.uid() = user_id);
drop policy if exists "categorias_insert_own" on public.categorias;
create policy "categorias_insert_own" on public.categorias for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "categorias_update_own" on public.categorias;
create policy "categorias_update_own" on public.categorias for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "categorias_delete_own" on public.categorias;
create policy "categorias_delete_own" on public.categorias for delete to authenticated using (auth.uid() = user_id);
