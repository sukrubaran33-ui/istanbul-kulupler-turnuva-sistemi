-- Şifresiz kulüp başvuruları için eksik tablo. Mevcut kayıtları silmez.
create extension if not exists pgcrypto;
create table if not exists public.guest_athlete_applications (
 id uuid primary key default gen_random_uuid(),
 club_name text not null check (char_length(trim(club_name)) between 2 and 150),
 coach_name text not null check (char_length(trim(coach_name)) between 2 and 150),
 contact_phone text not null check (char_length(trim(contact_phone)) between 7 and 30),
 athlete_name text not null check (char_length(trim(athlete_name)) between 2 and 150),
 birth_date date not null,
 gender text not null check (gender in ('Erkek','Bayan')),
 age_group text not null check (age_group in ('Alt Minik','Minik','Yıldız','Genç','Ümit','Büyük')),
 weight text not null check (weight ~ '^\\+?[0-9]+(\\.[0-9]+)?$'),
 license text not null default '',
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create index if not exists guest_athlete_applications_status_idx
 on public.guest_athlete_applications(status);
alter table public.guest_athlete_applications enable row level security;

-- Anonymous users can only submit pending applications; never read other applications.
drop policy if exists guest_submit on public.guest_athlete_applications;
create policy guest_submit on public.guest_athlete_applications
 for insert to anon,authenticated with check (status='pending');

-- Only approved tournament admins may read and review submissions.
drop policy if exists guest_admin_read on public.guest_athlete_applications;
create policy guest_admin_read on public.guest_athlete_applications
 for select to authenticated using (public.is_tournament_admin());
drop policy if exists guest_admin_update on public.guest_athlete_applications;
create policy guest_admin_update on public.guest_athlete_applications
 for update to authenticated using (public.is_tournament_admin())
 with check (public.is_tournament_admin());

-- Admin cannot alter the original submitted details, only pending -> approved/rejected.
create or replace function public.guard_guest_athlete_update()
returns trigger language plpgsql set search_path='' as $$
begin
 if (to_jsonb(new)-'status') is distinct from (to_jsonb(old)-'status') then
   raise exception 'Başvuru ayrıntıları değiştirilemez';
 end if;
 if old.status <> 'pending' and new.status is distinct from old.status then
   raise exception 'Karara bağlanmış başvuru değiştirilemez';
 end if;
 return new;
end $$;
drop trigger if exists guard_guest_athlete_update on public.guest_athlete_applications;
create trigger guard_guest_athlete_update before update on public.guest_athlete_applications
 for each row execute function public.guard_guest_athlete_update();
revoke all on function public.guard_guest_athlete_update() from public,anon,authenticated;
grant usage on schema public to anon,authenticated;
revoke all on public.guest_athlete_applications from anon,authenticated;
grant insert on public.guest_athlete_applications to anon;
grant insert,select,update on public.guest_athlete_applications to authenticated;
-- Public submissions should also be protected with CAPTCHA / rate limiting before broad rollout.
