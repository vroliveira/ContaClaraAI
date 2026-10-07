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

