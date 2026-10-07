-- ContaClaraAI v0.17.0 - Onboarding 2.0
create table if not exists public.onboarding_progresso (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  organizacao_id uuid not null references public.organizacoes(id) on delete cascade,
  etapa integer not null default 0,
  dados jsonb not null default '{}'::jsonb,
  concluido boolean not null default false,
  concluido_em timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, organizacao_id)
);
alter table public.onboarding_progresso enable row level security;
drop policy if exists onboarding_select_own on public.onboarding_progresso;
create policy onboarding_select_own on public.onboarding_progresso for select to authenticated using (user_id = auth.uid());
drop policy if exists onboarding_insert_own on public.onboarding_progresso;
create policy onboarding_insert_own on public.onboarding_progresso for insert to authenticated with check (user_id = auth.uid());
drop policy if exists onboarding_update_own on public.onboarding_progresso;
create policy onboarding_update_own on public.onboarding_progresso for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create index if not exists idx_onboarding_progresso_user_org on public.onboarding_progresso(user_id, organizacao_id);
