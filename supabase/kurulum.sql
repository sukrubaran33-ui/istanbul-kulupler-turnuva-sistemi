-- İstanbul Kulüpler Turnuva Sistemi: Supabase SQL Editor'de BİR KEZ çalıştırılmalıdır.
-- Güvenlik: kullanıcılar yalnızca kendi kulüplerini ve kayıtlarını düzenler.
create extension if not exists pgcrypto;
create table if not exists public.club_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 club_name text not null default '',
 coach_name text not null default '',
 phone text not null default '',
 role text not null default 'club' check (role in ('club','admin')),
 active boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.athlete_applications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 athlete_name text not null,
 birth_date date not null,
 gender text not null check (gender in ('Erkek','Bayan')),
 age_group text not null,
 weight text not null,
 license text not null default '',
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists athlete_applications_user_idx on public.athlete_applications(user_id);
create index if not exists athlete_applications_status_idx on public.athlete_applications(status);
create or replace function public.is_tournament_admin()
returns boolean language sql stable security definer set search_path=public
as $$select exists(select 1 from public.club_profiles where user_id=auth.uid() and role='admin')$$;
revoke all on function public.is_tournament_admin() from public;
grant execute on function public.is_tournament_admin() to authenticated;
alter table public.club_profiles enable row level security;
alter table public.athlete_applications enable row level security;
drop policy if exists "clubs_select" on public.club_profiles;
create policy "clubs_select" on public.club_profiles for select to authenticated
 using (user_id=auth.uid() or public.is_tournament_admin());
drop policy if exists "clubs_insert" on public.club_profiles;
create policy "clubs_insert" on public.club_profiles for insert to authenticated
 with check (user_id=auth.uid() and role='club' and active=false);
drop policy if exists "clubs_update" on public.club_profiles;
-- Yetki yükseltme engeli: profil güncellemesi yönetici SQL üzerinden yapılır.
drop policy if exists "applications_select" on public.athlete_applications;
create policy "applications_select" on public.athlete_applications for select to authenticated
 using (user_id=auth.uid() or public.is_tournament_admin());
drop policy if exists "applications_insert" on public.athlete_applications;
create policy "applications_insert" on public.athlete_applications for insert to authenticated
 with check (
  user_id=auth.uid() and status='pending'
  and exists(select 1 from public.club_profiles p where p.user_id=auth.uid() and p.active)
 );
drop policy if exists "applications_update_admin" on public.athlete_applications;
create policy "applications_update_admin" on public.athlete_applications for update to authenticated
 using (public.is_tournament_admin()) with check (public.is_tournament_admin());
drop policy if exists "applications_delete_owner" on public.athlete_applications;
create policy "applications_delete_owner" on public.athlete_applications for delete to authenticated
 using (user_id=auth.uid() and status='pending');
drop policy if exists "profiles_update_admin" on public.club_profiles;
create policy "profiles_update_admin" on public.club_profiles for update to authenticated
 using (public.is_tournament_admin()) with check (public.is_tournament_admin());
-- İlk yöneticiyi açmak için, kendi hesap e-postanızı yazıp SQL Editor'de çalıştırın:
-- update public.club_profiles set role='admin',active=true
-- where user_id=(select id from auth.users where email='SIZIN_EMAIL_ADRESINIZ' limit 1);