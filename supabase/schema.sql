-- ContaClaraAI - Supabase schema v0.7.1 (idempotente / migration fix)
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
drop policy if exists "controles_select_access" on public.controles;
create policy "controles_select_access" on public.controles for select to authenticated using (public.can_access_controle(id));
drop policy if exists "controles_insert_owner" on public.controles;
create policy "controles_insert_owner" on public.controles for insert to authenticated with check (auth.uid()=user_id);
drop policy if exists "controles_update_owner" on public.controles;
create policy "controles_update_owner" on public.controles for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
drop policy if exists "controles_delete_owner" on public.controles;
create policy "controles_delete_owner" on public.controles for delete to authenticated using (auth.uid()=user_id);

-- Despesas passam a respeitar o controle selecionado e o papel do membro.
drop policy if exists "despesas_select_own" on public.despesas;
drop policy if exists "despesas_insert_own" on public.despesas;
drop policy if exists "despesas_update_own" on public.despesas;
drop policy if exists "despesas_delete_own" on public.despesas;
drop policy if exists "despesas_select_control" on public.despesas;
create policy "despesas_select_control" on public.despesas for select to authenticated using (public.can_access_controle(controle_id));
drop policy if exists "despesas_insert_control" on public.despesas;
create policy "despesas_insert_control" on public.despesas for insert to authenticated with check (auth.uid()=user_id and public.can_edit_controle(controle_id));
drop policy if exists "despesas_update_control" on public.despesas;
create policy "despesas_update_control" on public.despesas for update to authenticated using (public.can_edit_controle(controle_id)) with check (public.can_edit_controle(controle_id));
drop policy if exists "despesas_delete_control" on public.despesas;
create policy "despesas_delete_control" on public.despesas for delete to authenticated using (public.can_edit_controle(controle_id));

-- Comprovantes compartilhados seguem a permissao da despesa/controle.
drop policy if exists "comprovantes_select_own" on storage.objects;
drop policy if exists "comprovantes_select_control" on storage.objects;
create policy "comprovantes_select_control" on storage.objects for select to authenticated
using (bucket_id='comprovantes' and (owner_id=(select auth.uid()::text) or exists(
  select 1 from public.despesas d where d.comprovante_path=name and public.can_access_controle(d.controle_id)
)));
drop policy if exists "comprovantes_delete_own" on storage.objects;
drop policy if exists "comprovantes_delete_control" on storage.objects;
create policy "comprovantes_delete_control" on storage.objects for delete to authenticated
using (bucket_id='comprovantes' and (owner_id=(select auth.uid()::text) or exists(
  select 1 from public.despesas d where d.comprovante_path=name and public.can_edit_controle(d.controle_id)
)));

-- v0.7 - Fundação SaaS: Organizações / Workspaces multi-tenant
create table if not exists public.organizacoes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  nome text not null,
  slug text,
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
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists organizacoes_owner_idx on public.organizacoes(owner_id);

create table if not exists public.organizacao_membros (
  id uuid primary key default gen_random_uuid(),
  organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  email text not null,
  papel text not null default 'visualizador' check (papel in ('administrador','editor','visualizador')),
  status text not null default 'pendente' check (status in ('pendente','ativo')),
  convidado_por uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organizacao_membros_org_email_unique unique(organizacao_id,email)
);
create index if not exists organizacao_membros_user_idx on public.organizacao_membros(user_id);
create index if not exists organizacao_membros_org_idx on public.organizacao_membros(organizacao_id);

alter table public.controles add column if not exists organizacao_id uuid references public.organizacoes(id) on delete cascade;
alter table public.categorias add column if not exists organizacao_id uuid references public.organizacoes(id) on delete cascade;

-- Cria um workspace padrão para cada proprietário existente e preserva todos os controles.
insert into public.organizacoes(owner_id,nome,email,cor_primaria,logo_path,logo_url,documento,telefone,cep,endereco,numero,complemento,bairro,cidade,uf)
select distinct c.user_id,
       coalesce(nullif(cfg.nome_exibicao,''),nullif(cfg.nome_empresa,''),'Minha organização'),
       cfg.email,coalesce(cfg.cor_primaria,'#0877f9'),cfg.logo_path,cfg.logo_url,cfg.documento,cfg.telefone,cfg.cep,cfg.endereco,cfg.numero,cfg.complemento,cfg.bairro,cfg.cidade,cfg.uf
from public.controles c
left join public.configuracoes cfg on cfg.user_id=c.user_id
where not exists(select 1 from public.organizacoes o where o.owner_id=c.user_id);

update public.controles c set organizacao_id=(select o.id from public.organizacoes o where o.owner_id=c.user_id order by o.created_at limit 1)
where c.organizacao_id is null;
update public.categorias cat set organizacao_id=(select o.id from public.organizacoes o where o.owner_id=cat.user_id order by o.created_at limit 1)
where cat.organizacao_id is null;

-- Migra convidados dos controles para o workspace, mantendo o maior nível encontrado.
insert into public.organizacao_membros(organizacao_id,user_id,email,papel,status,convidado_por)
select c.organizacao_id, cm.user_id, lower(cm.email),
       case when bool_or(cm.papel='administrador') then 'administrador'
            when bool_or(cm.papel='editor') then 'editor' else 'visualizador' end,
       case when bool_or(cm.status='ativo') then 'ativo' else 'pendente' end,
       min(cm.convidado_por::text)::uuid
from public.controle_membros cm join public.controles c on c.id=cm.controle_id
where c.organizacao_id is not null
group by c.organizacao_id,cm.user_id,lower(cm.email)
on conflict (organizacao_id,email) do nothing;

create or replace function public.is_org_owner(p_org uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.organizacoes o where o.id=p_org and o.owner_id=auth.uid());
$$;
create or replace function public.can_access_org(p_org uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select public.is_org_owner(p_org) or exists(select 1 from public.organizacao_membros m where m.organizacao_id=p_org and m.user_id=auth.uid() and m.status='ativo');
$$;
create or replace function public.can_edit_org(p_org uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select public.is_org_owner(p_org) or exists(select 1 from public.organizacao_membros m where m.organizacao_id=p_org and m.user_id=auth.uid() and m.status='ativo' and m.papel in ('administrador','editor'));
$$;
create or replace function public.can_admin_org(p_org uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select public.is_org_owner(p_org) or exists(select 1 from public.organizacao_membros m where m.organizacao_id=p_org and m.user_id=auth.uid() and m.status='ativo' and m.papel='administrador');
$$;
revoke all on function public.is_org_owner(uuid) from public;
revoke all on function public.can_access_org(uuid) from public;
revoke all on function public.can_edit_org(uuid) from public;
revoke all on function public.can_admin_org(uuid) from public;
grant execute on function public.is_org_owner(uuid), public.can_access_org(uuid), public.can_edit_org(uuid), public.can_admin_org(uuid) to authenticated;

create or replace function public.aceitar_meus_convites_org()
returns integer language plpgsql security definer set search_path=public as $$
declare v_email text; v_count integer;
begin
 v_email:=lower(coalesce(auth.jwt()->>'email',''));
 if auth.uid() is null or v_email='' then return 0; end if;
 update public.organizacao_membros set user_id=auth.uid(),status='ativo',updated_at=now()
 where lower(email)=v_email and status='pendente' and (user_id is null or user_id=auth.uid());
 get diagnostics v_count=row_count; return v_count;
end; $$;
revoke all on function public.aceitar_meus_convites_org() from public;
grant execute on function public.aceitar_meus_convites_org() to authenticated;

-- v0.15.1 - Criação segura/atômica de workspace
-- A organização é criada pelo backend do PostgreSQL usando o auth.uid() da sessão.
-- Isso evita o impasse de RLS durante o primeiro INSERT e impede que o cliente
-- informe outro usuário como proprietário.
create or replace function public.criar_organizacao(p_nome text, p_email text default null)
returns public.organizacoes
language plpgsql
security definer
set search_path=public
as $$
declare
  v_uid uuid := auth.uid();
  v_org public.organizacoes;
begin
  if v_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  if nullif(btrim(p_nome),'') is null then
    raise exception 'Informe o nome da organização';
  end if;

  insert into public.organizacoes(owner_id,nome,email,cor_primaria)
  values(
    v_uid,
    btrim(p_nome),
    coalesce(nullif(btrim(p_email),''), nullif(auth.jwt()->>'email','')),
    '#0877f9'
  )
  returning * into v_org;

  return v_org;
end;
$$;
revoke all on function public.criar_organizacao(text,text) from public;
grant execute on function public.criar_organizacao(text,text) to authenticated;

alter table public.organizacoes enable row level security;
alter table public.organizacao_membros enable row level security;
drop policy if exists "org_select_access" on public.organizacoes;
drop policy if exists "org_insert_owner" on public.organizacoes;
drop policy if exists "org_update_admin" on public.organizacoes;
drop policy if exists "org_delete_owner" on public.organizacoes;
drop policy if exists "org_select_access" on public.organizacoes;
create policy "org_select_access" on public.organizacoes for select to authenticated using (public.can_access_org(id));
drop policy if exists "org_insert_owner" on public.organizacoes;
create policy "org_insert_owner" on public.organizacoes for insert to authenticated with check (owner_id=auth.uid());
drop policy if exists "org_update_admin" on public.organizacoes;
create policy "org_update_admin" on public.organizacoes for update to authenticated using (public.can_admin_org(id)) with check (public.can_admin_org(id));
drop policy if exists "org_delete_owner" on public.organizacoes;
create policy "org_delete_owner" on public.organizacoes for delete to authenticated using (owner_id=auth.uid());

drop policy if exists "org_members_select" on public.organizacao_membros;
drop policy if exists "org_members_insert" on public.organizacao_membros;
drop policy if exists "org_members_update" on public.organizacao_membros;
drop policy if exists "org_members_delete" on public.organizacao_membros;
drop policy if exists "org_members_select" on public.organizacao_membros;
create policy "org_members_select" on public.organizacao_membros for select to authenticated using (public.can_access_org(organizacao_id) or user_id=auth.uid());
drop policy if exists "org_members_insert" on public.organizacao_membros;
create policy "org_members_insert" on public.organizacao_membros for insert to authenticated with check (public.can_admin_org(organizacao_id) and convidado_por=auth.uid());
drop policy if exists "org_members_update" on public.organizacao_membros;
create policy "org_members_update" on public.organizacao_membros for update to authenticated using (public.can_admin_org(organizacao_id)) with check (public.can_admin_org(organizacao_id));
drop policy if exists "org_members_delete" on public.organizacao_membros;
create policy "org_members_delete" on public.organizacao_membros for delete to authenticated using (public.can_admin_org(organizacao_id));

-- Regras dos controles passam a herdar acesso do workspace.
drop policy if exists "controles_select_access" on public.controles;
drop policy if exists "controles_insert_owner" on public.controles;
drop policy if exists "controles_update_owner" on public.controles;
drop policy if exists "controles_delete_owner" on public.controles;
drop policy if exists "controles_select_org" on public.controles;
create policy "controles_select_org" on public.controles for select to authenticated using (public.can_access_org(organizacao_id));
drop policy if exists "controles_insert_org" on public.controles;
create policy "controles_insert_org" on public.controles for insert to authenticated with check (user_id=auth.uid() and public.can_edit_org(organizacao_id));
drop policy if exists "controles_update_org" on public.controles;
create policy "controles_update_org" on public.controles for update to authenticated using (public.can_edit_org(organizacao_id)) with check (public.can_edit_org(organizacao_id));
drop policy if exists "controles_delete_org" on public.controles;
create policy "controles_delete_org" on public.controles for delete to authenticated using (public.can_admin_org(organizacao_id));

-- can_access/edit_controle passam a considerar o tenant.
create or replace function public.can_access_controle(p_controle uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.controles c where c.id=p_controle and public.can_access_org(c.organizacao_id));
$$;
create or replace function public.can_edit_controle(p_controle uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.controles c where c.id=p_controle and public.can_edit_org(c.organizacao_id));
$$;

-- Categorias agora pertencem ao workspace.
alter table public.categorias drop constraint if exists categorias_user_nome_unique;
create unique index if not exists categorias_org_nome_unique on public.categorias(organizacao_id,lower(nome));
drop policy if exists "categorias_select_own" on public.categorias;
drop policy if exists "categorias_insert_own" on public.categorias;
drop policy if exists "categorias_update_own" on public.categorias;
drop policy if exists "categorias_delete_own" on public.categorias;
drop policy if exists "categorias_select_org" on public.categorias;
create policy "categorias_select_org" on public.categorias for select to authenticated using (public.can_access_org(organizacao_id));
drop policy if exists "categorias_insert_org" on public.categorias;
create policy "categorias_insert_org" on public.categorias for insert to authenticated with check (user_id=auth.uid() and public.can_edit_org(organizacao_id));
drop policy if exists "categorias_update_org" on public.categorias;
create policy "categorias_update_org" on public.categorias for update to authenticated using (public.can_edit_org(organizacao_id)) with check (public.can_edit_org(organizacao_id));
drop policy if exists "categorias_delete_org" on public.categorias;
create policy "categorias_delete_org" on public.categorias for delete to authenticated using (public.can_admin_org(organizacao_id));

-- v0.9 - Metadados de IA e identificador PIX para deteccao de duplicidade
alter table public.despesas add column if not exists pix_transacao_id text;
alter table public.despesas add column if not exists origem text not null default 'manual';
alter table public.despesas add column if not exists ia_confianca smallint;
alter table public.despesas add column if not exists ia_dados jsonb;
create index if not exists despesas_controle_pix_idx on public.despesas(controle_id,pix_transacao_id) where pix_transacao_id is not null;

-- v0.10 - Gestão financeira: orçamento, recorrências e rateios
create table if not exists public.orcamentos (
 id uuid primary key default gen_random_uuid(), controle_id uuid not null references public.controles(id) on delete cascade,
 organizacao_id uuid not null references public.organizacoes(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade,
 mes date not null, limite_geral numeric(12,2) not null default 0, categoria text, limite_categoria numeric(12,2), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists orcamentos_controle_mes_categoria_uq on public.orcamentos(controle_id,mes,coalesce(categoria,''));
create table if not exists public.despesas_recorrentes (
 id uuid primary key default gen_random_uuid(), controle_id uuid not null references public.controles(id) on delete cascade,
 organizacao_id uuid not null references public.organizacoes(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade,
 descricao text not null, categoria text not null, valor numeric(12,2) not null check(valor>0), dia_vencimento smallint not null check(dia_vencimento between 1 and 31), pagador text, fornecedor text, forma_pagamento text, ativo boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.rateios (
 id uuid primary key default gen_random_uuid(), controle_id uuid not null references public.controles(id) on delete cascade,
 organizacao_id uuid not null references public.organizacoes(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade,
 descricao text not null, valor_total numeric(12,2) not null check(valor_total>0), pago_por text not null, participantes jsonb not null default '[]'::jsonb, observacoes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.orcamentos enable row level security; alter table public.despesas_recorrentes enable row level security; alter table public.rateios enable row level security;
drop policy if exists "orcamentos_select" on public.orcamentos; create policy "orcamentos_select" on public.orcamentos for select to authenticated using(public.can_access_controle(controle_id));
drop policy if exists "orcamentos_insert" on public.orcamentos; create policy "orcamentos_insert" on public.orcamentos for insert to authenticated with check(user_id=auth.uid() and public.can_edit_controle(controle_id));
drop policy if exists "orcamentos_update" on public.orcamentos; create policy "orcamentos_update" on public.orcamentos for update to authenticated using(public.can_edit_controle(controle_id)) with check(public.can_edit_controle(controle_id));
drop policy if exists "orcamentos_delete" on public.orcamentos; create policy "orcamentos_delete" on public.orcamentos for delete to authenticated using(public.can_edit_controle(controle_id));
drop policy if exists "recorrentes_select" on public.despesas_recorrentes; create policy "recorrentes_select" on public.despesas_recorrentes for select to authenticated using(public.can_access_controle(controle_id));
drop policy if exists "recorrentes_insert" on public.despesas_recorrentes; create policy "recorrentes_insert" on public.despesas_recorrentes for insert to authenticated with check(user_id=auth.uid() and public.can_edit_controle(controle_id));
drop policy if exists "recorrentes_update" on public.despesas_recorrentes; create policy "recorrentes_update" on public.despesas_recorrentes for update to authenticated using(public.can_edit_controle(controle_id)) with check(public.can_edit_controle(controle_id));
drop policy if exists "recorrentes_delete" on public.despesas_recorrentes; create policy "recorrentes_delete" on public.despesas_recorrentes for delete to authenticated using(public.can_edit_controle(controle_id));
drop policy if exists "rateios_select" on public.rateios; create policy "rateios_select" on public.rateios for select to authenticated using(public.can_access_controle(controle_id));
drop policy if exists "rateios_insert" on public.rateios; create policy "rateios_insert" on public.rateios for insert to authenticated with check(user_id=auth.uid() and public.can_edit_controle(controle_id));
drop policy if exists "rateios_update" on public.rateios; create policy "rateios_update" on public.rateios for update to authenticated using(public.can_edit_controle(controle_id)) with check(public.can_edit_controle(controle_id));
drop policy if exists "rateios_delete" on public.rateios; create policy "rateios_delete" on public.rateios for delete to authenticated using(public.can_edit_controle(controle_id));

-- v0.11 - Comercialização SaaS: planos, assinatura, trial e consumo
create table if not exists public.planos_saas (
 id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null,
 preco_mensal numeric(10,2) not null default 0, limite_controles integer, limite_membros integer,
 limite_ia_mes integer, limite_armazenamento_mb integer, ativo boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
insert into public.planos_saas(codigo,nome,preco_mensal,limite_controles,limite_membros,limite_ia_mes,limite_armazenamento_mb)
values ('free','Free',0,1,2,10,100),('plus','Plus',29.90,5,10,150,2048),('pro','Pro',69.90,50,30,600,10240)
on conflict(codigo) do update set nome=excluded.nome,preco_mensal=excluded.preco_mensal,limite_controles=excluded.limite_controles,limite_membros=excluded.limite_membros,limite_ia_mes=excluded.limite_ia_mes,limite_armazenamento_mb=excluded.limite_armazenamento_mb,updated_at=now();

create table if not exists public.assinaturas (
 id uuid primary key default gen_random_uuid(), organizacao_id uuid not null unique references public.organizacoes(id) on delete cascade,
 plano_id uuid not null references public.planos_saas(id), status text not null default 'trial' check(status in ('trial','ativo','inadimplente','cancelado','free')),
 trial_inicio timestamptz, trial_fim timestamptz, periodo_inicio timestamptz, periodo_fim timestamptz,
 provedor text, cliente_externo_id text, assinatura_externa_id text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
-- Workspaces existentes recebem Free. Novos workspaces também serão provisionados por trigger.
insert into public.assinaturas(organizacao_id,plano_id,status)
select o.id,p.id,'free' from public.organizacoes o cross join public.planos_saas p
where p.codigo='free' and not exists(select 1 from public.assinaturas a where a.organizacao_id=o.id);

create or replace function public.criar_assinatura_padrao_org() returns trigger language plpgsql security definer set search_path=public as $$
declare v_plan uuid;
begin
 select id into v_plan from public.planos_saas where codigo='free' limit 1;
 if v_plan is not null then insert into public.assinaturas(organizacao_id,plano_id,status) values(new.id,v_plan,'free') on conflict(organizacao_id) do nothing; end if;
 return new;
end; $$;
drop trigger if exists trg_criar_assinatura_padrao_org on public.organizacoes;
create trigger trg_criar_assinatura_padrao_org after insert on public.organizacoes for each row execute function public.criar_assinatura_padrao_org();

create table if not exists public.consumo_ia (
 id uuid primary key default gen_random_uuid(), organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
 user_id uuid references auth.users(id) on delete set null, competencia date not null, quantidade integer not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(organizacao_id,competencia)
);

alter table public.planos_saas enable row level security;
alter table public.assinaturas enable row level security;
alter table public.consumo_ia enable row level security;
drop policy if exists "planos_read" on public.planos_saas; create policy "planos_read" on public.planos_saas for select to authenticated using(ativo=true);
drop policy if exists "assinaturas_read" on public.assinaturas; create policy "assinaturas_read" on public.assinaturas for select to authenticated using(public.can_access_org(organizacao_id));
drop policy if exists "consumo_ia_read" on public.consumo_ia; create policy "consumo_ia_read" on public.consumo_ia for select to authenticated using(public.can_access_org(organizacao_id));

create or replace function public.meu_consumo_saas(p_organizacao uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare v_controles int; v_membros int; v_ia int; v_storage numeric;
begin
 if not public.can_access_org(p_organizacao) then raise exception 'Acesso negado'; end if;
 select count(*) into v_controles from public.controles where organizacao_id=p_organizacao and ativo=true;
 select count(*) into v_membros from public.organizacao_membros where organizacao_id=p_organizacao and status='ativo';
 select coalesce(sum(quantidade),0) into v_ia from public.consumo_ia where organizacao_id=p_organizacao and competencia=date_trunc('month',current_date)::date;
 -- Storage exato depende do provedor; nesta versão fica 0 até contabilização server-side.
 v_storage:=0;
 return jsonb_build_object('controles',v_controles,'membros',v_membros,'ia_mes',v_ia,'armazenamento_mb',v_storage);
end; $$;
revoke all on function public.meu_consumo_saas(uuid) from public;
grant execute on function public.meu_consumo_saas(uuid) to authenticated;

-- v0.11.1 - Mercado Pago: metadados da assinatura recorrente
alter table public.assinaturas add column if not exists plano_externo_id text;
alter table public.assinaturas add column if not exists pagador_email text;
alter table public.assinaturas add column if not exists valor numeric(10,2);
alter table public.assinaturas add column if not exists proxima_cobranca timestamptz;
alter table public.assinaturas add column if not exists data_cancelamento timestamptz;
create index if not exists ix_assinaturas_externa on public.assinaturas(assinatura_externa_id) where assinatura_externa_id is not null;

-- v0.12.0 - Administração SaaS
create table if not exists public.saas_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.saas_admins enable row level security;
-- Sem policies para authenticated: o painel administrativo consulta esta tabela somente no servidor via service role.

create table if not exists public.consumo_armazenamento (
  organizacao_id uuid primary key references public.organizacoes(id) on delete cascade,
  bytes_utilizados bigint not null default 0 check(bytes_utilizados >= 0),
  arquivos integer not null default 0 check(arquivos >= 0),
  updated_at timestamptz not null default now()
);
alter table public.consumo_armazenamento enable row level security;
drop policy if exists "storage_usage_org_read" on public.consumo_armazenamento;
create policy "storage_usage_org_read" on public.consumo_armazenamento for select to authenticated
using(public.can_access_org(organizacao_id));

insert into public.consumo_armazenamento(organizacao_id)
select id from public.organizacoes
on conflict(organizacao_id) do nothing;

create or replace function public.criar_consumo_armazenamento_org() returns trigger
language plpgsql security definer set search_path=public as $$
begin
 insert into public.consumo_armazenamento(organizacao_id) values(new.id) on conflict do nothing;
 return new;
end; $$;
drop trigger if exists trg_criar_consumo_armazenamento_org on public.organizacoes;
create trigger trg_criar_consumo_armazenamento_org after insert on public.organizacoes
for each row execute function public.criar_consumo_armazenamento_org();

-- v0.12.2 - Checkout hospedado Mercado Pago
-- Mantém o vínculo seguro entre o workspace e a assinatura criada no checkout do plano.
create table if not exists public.billing_checkout_pendentes (
  id uuid primary key default gen_random_uuid(),
  organizacao_id uuid not null unique references public.organizacoes(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  plano_codigo text not null check (plano_codigo in ('plus','pro')),
  plano_externo_id text not null,
  pagador_email text not null,
  status text not null default 'pendente' check (status in ('pendente','concluido','cancelado')),
  assinatura_externa_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists ix_billing_checkout_pendente_lookup
  on public.billing_checkout_pendentes(plano_externo_id,pagador_email,status,updated_at desc);
alter table public.billing_checkout_pendentes enable row level security;
-- Sem policy para authenticated: leitura/escrita somente pelas rotas server-side com secret/service role.

-- v0.15.0 - Conciliacao Bancaria (OFX/CSV + IA)
create table if not exists public.transacoes_bancarias (
  id uuid primary key default gen_random_uuid(),
  organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
  controle_id uuid not null references public.controles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  data date not null,
  valor numeric(14,2) not null,
  descricao text not null,
  memo text,
  tipo text,
  identificador_externo text not null,
  arquivo_origem text,
  status_conciliacao text not null default 'pendente' check (status_conciliacao in ('pendente','conciliado','ignorado')),
  despesa_sugerida_id uuid references public.despesas(id) on delete set null,
  despesa_id uuid references public.despesas(id) on delete set null,
  ia_confianca smallint check (ia_confianca between 0 and 100),
  ia_categoria text,
  ia_justificativa text,
  conciliado_em timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint transacoes_bancarias_controle_externo_uk unique(controle_id,identificador_externo)
);
create index if not exists ix_transacoes_bancarias_controle_data on public.transacoes_bancarias(controle_id,data desc);
create index if not exists ix_transacoes_bancarias_status on public.transacoes_bancarias(controle_id,status_conciliacao);
alter table public.transacoes_bancarias enable row level security;
drop policy if exists "transacoes_bancarias_select" on public.transacoes_bancarias;
create policy "transacoes_bancarias_select" on public.transacoes_bancarias for select to authenticated using (public.can_access_controle(controle_id));
drop policy if exists "transacoes_bancarias_insert" on public.transacoes_bancarias;
create policy "transacoes_bancarias_insert" on public.transacoes_bancarias for insert to authenticated with check (auth.uid()=user_id and public.can_edit_controle(controle_id));
drop policy if exists "transacoes_bancarias_update" on public.transacoes_bancarias;
create policy "transacoes_bancarias_update" on public.transacoes_bancarias for update to authenticated using (public.can_edit_controle(controle_id)) with check (public.can_edit_controle(controle_id));
drop policy if exists "transacoes_bancarias_delete" on public.transacoes_bancarias;
create policy "transacoes_bancarias_delete" on public.transacoes_bancarias for delete to authenticated using (public.can_edit_controle(controle_id));
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
