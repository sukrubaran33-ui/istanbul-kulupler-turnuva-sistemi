-- İstanbul Kulüpler Turnuva Sistemi / Supabase online kayıt
-- Supabase SQL Editor'da yalnızca bir kez çalıştırın.
create table if not exists public.bt_members (
 user_id uuid primary key references auth.users(id) on delete cascade,
 club_name text not null check (length(trim(club_name)) between 2 and 150),
 coach_name text not null default '',
 role text not null default 'club' check (role in ('club','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.bt_applications (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 athlete_name text not null check(length(trim(athlete_name)) between 2 and 150),
 birth_date date not null,
 gender text not null check(gender in ('Erkek','Bayan')),
 age_group text not null,
 weight text not null,
 license_no text not null default '',
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 created_at timestamptz not null default now(),
 reviewed_at timestamptz
);
create index if not exists bt_applications_owner_idx on public.bt_applications(owner_id);
create index if not exists bt_applications_status_idx on public.bt_applications(status);
alter table public.bt_members enable row level security;
alter table public.bt_applications enable row level security;
create or replace function public.bt_is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.bt_members where user_id=auth.uid() and role='admin')
$$;
revoke all on function public.bt_is_admin() from public;
grant execute on function public.bt_is_admin() to authenticated;
drop policy if exists bt_member_read on public.bt_members;
create policy bt_member_read on public.bt_members for select to authenticated
using(user_id=auth.uid() or public.bt_is_admin());
drop policy if exists bt_member_create on public.bt_members;
create policy bt_member_create on public.bt_members for insert to authenticated
with check(user_id=auth.uid() and role='club');
drop policy if exists bt_member_admin_update on public.bt_members;
create policy bt_member_admin_update on public.bt_members for update to authenticated
using(public.bt_is_admin()) with check(public.bt_is_admin());
drop policy if exists bt_app_read on public.bt_applications;
create policy bt_app_read on public.bt_applications for select to authenticated
using(owner_id=auth.uid() or public.bt_is_admin());
drop policy if exists bt_app_create on public.bt_applications;
create policy bt_app_create on public.bt_applications for insert to authenticated
with check(owner_id=auth.uid() and status='pending' and exists(select 1 from public.bt_members m where m.user_id=auth.uid()));
drop policy if exists bt_app_owner_delete on public.bt_applications;
create policy bt_app_owner_delete on public.bt_applications for delete to authenticated
using(owner_id=auth.uid() and status='pending');
drop policy if exists bt_app_admin_update on public.bt_applications;
create policy bt_app_admin_update on public.bt_applications for update to authenticated
using(public.bt_is_admin()) with check(public.bt_is_admin());

-- İLK YÖNETİCİ YETKİSİ:
-- Siteye kendi e-posta adresinizle kayıt olduktan sonra
-- Supabase Authentication > Users ekranından kullanıcı UUID'nizi bulun.
-- Aşağıdaki satırdaki UUID'yi kendinizinkiyle değiştirip TEK BAŞINA çalıştırın:
-- update public.bt_members set role='admin' where user_id='BURAYA_KENDI_KULLANICI_UUID';
-- Önemli: service_role veya secret anahtarını siteye eklemeyin.
