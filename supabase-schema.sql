-- Jefferson County Pool League: Supabase setup
-- Run this entire script in Supabase Dashboard > SQL Editor.
-- The browser app uses only the publishable/anon key; never expose service_role keys.

create table if not exists public.league_state (
  id integer primary key check (id = 1),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.league_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.league_state enable row level security;
alter table public.league_admins enable row level security;

-- Enable live standings/results refresh in connected browser sessions.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'league_state'
  ) then
    alter publication supabase_realtime add table public.league_state;
  end if;
end $$;

grant select on public.league_state to anon, authenticated;
grant insert, update on public.league_state to authenticated;
grant select on public.league_admins to authenticated;

create or replace function public.is_league_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.league_admins a
    where a.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_league_admin() from public;
grant execute on function public.is_league_admin() to anon, authenticated;

drop policy if exists "League state is publicly readable" on public.league_state;
create policy "League state is publicly readable"
on public.league_state for select to anon, authenticated
using (true);

drop policy if exists "Only league admins can insert state" on public.league_state;
create policy "Only league admins can insert state"
on public.league_state for insert to authenticated
with check (public.is_league_admin());

drop policy if exists "Only league admins can update state" on public.league_state;
create policy "Only league admins can update state"
on public.league_state for update to authenticated
using (public.is_league_admin())
with check (public.is_league_admin());

drop policy if exists "Admins can see their own admin grant" on public.league_admins;
create policy "Admins can see their own admin grant"
on public.league_admins for select to authenticated
using (user_id = (select auth.uid()));

-- Public rules PDFs; uploads and deletes require an authenticated league admin.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('league-rules', 'league-rules', true, 20971520, array['application/pdf'])
on conflict (id) do update set public = true, file_size_limit = 20971520, allowed_mime_types = array['application/pdf'];

drop policy if exists "League rules PDFs are publicly readable" on storage.objects;
create policy "League rules PDFs are publicly readable"
on storage.objects for select to anon, authenticated
using (bucket_id = 'league-rules');

drop policy if exists "League admins can upload rules PDFs" on storage.objects;
create policy "League admins can upload rules PDFs"
on storage.objects for insert to authenticated
with check (bucket_id = 'league-rules' and public.is_league_admin());

drop policy if exists "League admins can update rules PDFs" on storage.objects;
create policy "League admins can update rules PDFs"
on storage.objects for update to authenticated
using (bucket_id = 'league-rules' and public.is_league_admin())
with check (bucket_id = 'league-rules' and public.is_league_admin());

drop policy if exists "League admins can delete rules PDFs" on storage.objects;
create policy "League admins can delete rules PDFs"
on storage.objects for delete to authenticated
using (bucket_id = 'league-rules' and public.is_league_admin());

-- After creating the admin user in Supabase Authentication > Users, run this separately
-- in SQL Editor, replacing the email with the exact admin email:
-- insert into public.league_admins (user_id)
-- select id from auth.users where lower(email) = lower('your-admin-email@example.com')
-- on conflict (user_id) do nothing;
