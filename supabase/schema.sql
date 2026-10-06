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

-- v0.5 - Configuracoes e identidade visual
create table if not exists public.configuracoes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  nome_empresa text not null default 'ContaClaraAI',
  nome_exibicao text,
  documento text,
  email text,
  telefone text,
  cep text,
  endereco text,
  numero text,
  complemento text,
  bairro text,
  cidade text,
  uf varchar(2),
  cor_primaria text not null default '#0877f9',
  logo_path text,
  logo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.configuracoes enable row level security;
drop policy if exists "configuracoes_select_own" on public.configuracoes;
create policy "configuracoes_select_own" on public.configuracoes for select to authenticated using (auth.uid() = user_id);
drop policy if exists "configuracoes_insert_own" on public.configuracoes;
create policy "configuracoes_insert_own" on public.configuracoes for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "configuracoes_update_own" on public.configuracoes;
create policy "configuracoes_update_own" on public.configuracoes for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Logos não contêm dados financeiros e são públicos para renderização da identidade visual.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('identidade','identidade',true,5242880,array['image/jpeg','image/png','image/webp','image/svg+xml'])
on conflict (id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp','image/svg+xml'];
drop policy if exists "identidade_insert_own" on storage.objects;
create policy "identidade_insert_own" on storage.objects for insert to authenticated
with check (bucket_id='identidade' and (storage.foldername(name))[1]=(select auth.uid()::text));
drop policy if exists "identidade_update_own" on storage.objects;
create policy "identidade_update_own" on storage.objects for update to authenticated
using (bucket_id='identidade' and owner_id=(select auth.uid()::text));
drop policy if exists "identidade_delete_own" on storage.objects;
create policy "identidade_delete_own" on storage.objects for delete to authenticated
using (bucket_id='identidade' and owner_id=(select auth.uid()::text));

-- v0.6 - Multiplos controles e compartilhamento com membros
alter table public.controles add column if not exists ativo boolean not null default true;
alter table public.controles add column if not exists updated_at timestamptz not null default now();

create table if not exists public.controle_membros (
  id uuid primary key default gen_random_uuid(),
  controle_id uuid not null references public.controles(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  email text not null,
  papel text not null default 'visualizador' check (papel in ('administrador','editor','visualizador')),
  status text not null default 'pendente' check (status in ('pendente','ativo')),
  convidado_por uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint controle_membros_controle_email_unique unique(controle_id,email)
);
create index if not exists controle_membros_user_idx on public.controle_membros(user_id);
create index if not exists controle_membros_controle_idx on public.controle_membros(controle_id);

-- Funcoes SECURITY DEFINER evitam recursao nas policies e centralizam autorizacao.
create or replace function public.is_controle_owner(p_controle uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.controles c where c.id=p_controle and c.user_id=auth.uid());
$$;
create or replace function public.can_access_controle(p_controle uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.controles c where c.id=p_controle and c.user_id=auth.uid())
      or exists(select 1 from public.controle_membros m where m.controle_id=p_controle and m.user_id=auth.uid() and m.status='ativo');
$$;
create or replace function public.can_edit_controle(p_controle uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.controles c where c.id=p_controle and c.user_id=auth.uid())
      or exists(select 1 from public.controle_membros m where m.controle_id=p_controle and m.user_id=auth.uid() and m.status='ativo' and m.papel in ('administrador','editor'));
$$;
revoke all on function public.is_controle_owner(uuid) from public;
revoke all on function public.can_access_controle(uuid) from public;
revoke all on function public.can_edit_controle(uuid) from public;
grant execute on function public.is_controle_owner(uuid) to authenticated;
grant execute on function public.can_access_controle(uuid) to authenticated;
grant execute on function public.can_edit_controle(uuid) to authenticated;

alter table public.controle_membros enable row level security;
drop policy if exists "membros_select_access" on public.controle_membros;
create policy "membros_select_access" on public.controle_membros for select to authenticated
using (public.can_access_controle(controle_id) or convidado_por=auth.uid() or user_id=auth.uid());
drop policy if exists "membros_insert_owner" on public.controle_membros;
create policy "membros_insert_owner" on public.controle_membros for insert to authenticated
with check (public.is_controle_owner(controle_id) and convidado_por=auth.uid());
drop policy if exists "membros_update_owner" on public.controle_membros;
create policy "membros_update_owner" on public.controle_membros for update to authenticated
using (public.is_controle_owner(controle_id)) with check (public.is_controle_owner(controle_id));
drop policy if exists "membros_delete_owner" on public.controle_membros;
create policy "membros_delete_owner" on public.controle_membros for delete to authenticated
using (public.is_controle_owner(controle_id));

-- Aceita automaticamente convites pendentes que correspondam ao e-mail autenticado.
create or replace function public.aceitar_meus_convites()
returns integer language plpgsql security definer set search_path=public as $$
declare v_email text; v_count integer;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if auth.uid() is null or v_email='' then return 0; end if;
  update public.controle_membros
     set user_id=auth.uid(), status='ativo', updated_at=now()
   where lower(email)=v_email and status='pendente' and (user_id is null or user_id=auth.uid());
  get diagnostics v_count = row_count;
  return v_count;
end; $$;
revoke all on function public.aceitar_meus_convites() from public;
grant execute on function public.aceitar_meus_convites() to authenticated;

-- Controles: proprietario ou membro ativo pode visualizar; somente proprietario altera/exclui.
drop policy if exists "controles_select_own" on public.controles;
drop policy if exists "controles_insert_own" on public.controles;
drop policy if exists "controles_update_own" on public.controles;
drop policy if exists "controles_delete_own" on public.controles;
create policy "controles_select_access" on public.controles for select to authenticated using (public.can_access_controle(id));
create policy "controles_insert_owner" on public.controles for insert to authenticated with check (auth.uid()=user_id);
create policy "controles_update_owner" on public.controles for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "controles_delete_owner" on public.controles for delete to authenticated using (auth.uid()=user_id);

-- Despesas passam a respeitar o controle selecionado e o papel do membro.
drop policy if exists "despesas_select_own" on public.despesas;
drop policy if exists "despesas_insert_own" on public.despesas;
drop policy if exists "despesas_update_own" on public.despesas;
drop policy if exists "despesas_delete_own" on public.despesas;
create policy "despesas_select_control" on public.despesas for select to authenticated using (public.can_access_controle(controle_id));
create policy "despesas_insert_control" on public.despesas for insert to authenticated with check (auth.uid()=user_id and public.can_edit_controle(controle_id));
create policy "despesas_update_control" on public.despesas for update to authenticated using (public.can_edit_controle(controle_id)) with check (public.can_edit_controle(controle_id));
create policy "despesas_delete_control" on public.despesas for delete to authenticated using (public.can_edit_controle(controle_id));

-- Comprovantes compartilhados seguem a permissao da despesa/controle.
drop policy if exists "comprovantes_select_own" on storage.objects;
create policy "comprovantes_select_control" on storage.objects for select to authenticated
using (bucket_id='comprovantes' and (owner_id=(select auth.uid()::text) or exists(
  select 1 from public.despesas d where d.comprovante_path=name and public.can_access_controle(d.controle_id)
)));
drop policy if exists "comprovantes_delete_own" on storage.objects;
create policy "comprovantes_delete_control" on storage.objects for delete to authenticated
using (bucket_id='comprovantes' and (owner_id=(select auth.uid()::text) or exists(
  select 1 from public.despesas d where d.comprovante_path=name and public.can_edit_controle(d.controle_id)
)));
