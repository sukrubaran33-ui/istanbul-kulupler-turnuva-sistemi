-- Şifresiz kulüp sporcu başvurusu. Mevcut tabloları veya kuraları silmez.
-- DİKKAT: Herkese açık form spam riskine açıktır. Canlı kullanımda CAPTCHA + sunucu tarafı hız sınırı ekleyin.
create extension if not exists pgcrypto;
create table if not exists public.guest_athlete_applications (
 id uuid primary key default gen_random_uuid(),
 club_name text not null check (char_length(btrim(club_name)) between 2 and 150),
 coach_name text not null check (char_length(btrim(coach_name)) between 2 and 150),
 contact_phone text not null check (char_length(btrim(contact_phone)) between 7 and 30),
 athlete_name text not null check (char_length(btrim(athlete_name)) between 2 and 150),
 birth_date date not null check (birth_date between date '1900-01-01' and current_date),
 gender text not null check (gender in ('Erkek','Bayan')),
 age_group text not null check (age_group in ('Alt Minik','Minik','Yıldız','Genç','Ümit','Büyük')),
 weight text not null check (weight ~ '^[+]?[0-9]{1,3}([.][0-9]{1,2})?),
 license text not null default '' check (char_length(license) <= 100),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists guest_athlete_applications_status_idx on public.guest_athlete_applications(status,created_at desc);
alter table public.guest_athlete_applications enable row level security;

drop policy if exists guest_submit on public.guest_athlete_applications;
create policy guest_submit on public.guest_athlete_applications
for insert to anon with check (status='pending');

drop policy if exists guest_admin_read on public.guest_athlete_applications;
create policy guest_admin_read on public.guest_athlete_applications
for select to authenticated using (public.is_tournament_admin());

drop policy if exists guest_admin_update on public.guest_athlete_applications;
create policy guest_admin_update on public.guest_athlete_applications
for update to authenticated using (public.is_tournament_admin())
with check (public.is_tournament_admin());

create or replace function public.protect_guest_athlete_review()
returns trigger language plpgsql set search_path='' as $body$
begin
 if new.id is distinct from old.id
    or new.club_name is distinct from old.club_name
    or new.coach_name is distinct from old.coach_name
    or new.contact_phone is distinct from old.contact_phone
    or new.athlete_name is distinct from old.athlete_name
    or new.birth_date is distinct from old.birth_date
    or new.gender is distinct from old.gender
    or new.age_group is distinct from old.age_group
    or new.weight is distinct from old.weight
    or new.license is distinct from old.license
    or new.created_at is distinct from old.created_at then
   raise exception 'Only status may be reviewed';
 end if;
 if old.status <> 'pending' and new.status is distinct from old.status then
   raise exception 'A reviewed application cannot be changed';
 end if;
 new.updated_at=now();
 return new;
end
$body$;
drop trigger if exists protect_guest_athlete_review on public.guest_athlete_applications;
create trigger protect_guest_athlete_review before update on public.guest_athlete_applications
for each row execute function public.protect_guest_athlete_review();

revoke all on public.guest_athlete_applications from anon, authenticated;
-- Sadece kamu formunun ihtiyaç duyduğu kolonlara INSERT izni verilir.
grant insert (club_name,coach_name,contact_phone,athlete_name,birth_date,gender,age_group,weight,license)
 on public.guest_athlete_applications to anon;
grant select on public.guest_athlete_applications to authenticated;
grant update (status) on public.guest_athlete_applications to authenticated;
revoke all on function public.protect_guest_athlete_review() from public, anon, authenticated;
),
 license text not null default '' check (char_length(license) <= 100),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists guest_athlete_applications_status_idx on public.guest_athlete_applications(status,created_at desc);
alter table public.guest_athlete_applications enable row level security;

drop policy if exists guest_submit on public.guest_athlete_applications;
create policy guest_submit on public.guest_athlete_applications
for insert to anon with check (status='pending');

drop policy if exists guest_admin_read on public.guest_athlete_applications;
create policy guest_admin_read on public.guest_athlete_applications
for select to authenticated using (public.is_tournament_admin());

drop policy if exists guest_admin_update on public.guest_athlete_applications;
create policy guest_admin_update on public.guest_athlete_applications
for update to authenticated using (public.is_tournament_admin())
with check (public.is_tournament_admin());

create or replace function public.protect_guest_athlete_review()
returns trigger language plpgsql set search_path='' as $body$
begin
 if new.id is distinct from old.id
    or new.club_name is distinct from old.club_name
    or new.coach_name is distinct from old.coach_name
    or new.contact_phone is distinct from old.contact_phone
    or new.athlete_name is distinct from old.athlete_name
    or new.birth_date is distinct from old.birth_date
    or new.gender is distinct from old.gender
    or new.age_group is distinct from old.age_group
    or new.weight is distinct from old.weight
    or new.license is distinct from old.license
    or new.created_at is distinct from old.created_at then
   raise exception 'Only status may be reviewed';
 end if;
 if old.status <> 'pending' and new.status is distinct from old.status then
   raise exception 'A reviewed application cannot be changed';
 end if;
 new.updated_at=now();
 return new;
end
$body$;
drop trigger if exists protect_guest_athlete_review on public.guest_athlete_applications;
create trigger protect_guest_athlete_review before update on public.guest_athlete_applications
for each row execute function public.protect_guest_athlete_review();

revoke all on public.guest_athlete_applications from anon, authenticated;
-- Sadece kamu formunun ihtiyaç duyduğu kolonlara INSERT izni verilir.
grant insert (club_name,coach_name,contact_phone,athlete_name,birth_date,gender,age_group,weight,license)
 on public.guest_athlete_applications to anon;
grant select on public.guest_athlete_applications to authenticated;
grant update (status) on public.guest_athlete_applications to authenticated;
revoke all on function public.protect_guest_athlete_review() from public, anon, authenticated;
