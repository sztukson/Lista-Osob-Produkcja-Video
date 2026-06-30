-- ============================================================
--  LISTA EKIPY — Supabase Schema
--  1. Wklej to w SQL Editor w Supabase (Project > SQL Editor)
--  2. Uzupełnij swój email w allowed_users na dole
-- ============================================================

-- TABELA GŁÓWNA
create table if not exists crew_members (
  id              uuid primary key default gen_random_uuid(),
  lp              integer,
  name            text not null,
  position        text not null,
  phone           text,
  email           text,
  meals           text,
  allergies       text,
  city            text,
  transport       text,
  language        text,
  contract_type   text,
  day_rate        numeric,
  equipment_rate  numeric,
  car_rate        numeric,
  travel_reimbursement numeric,
  arrival_date    date,
  departure_date  date,
  notes           text,
  sort_order      integer default 0,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- LOG ZMIAN
create table if not exists audit_log (
  id               uuid primary key default gen_random_uuid(),
  crew_member_id   uuid references crew_members(id) on delete set null,
  crew_member_name text,
  user_email       text not null,
  user_name        text,
  field_name       text,
  old_value        text,
  new_value        text,
  changed_at       timestamptz default now()
);

-- DOSTĘP (whitelist)
create table if not exists allowed_users (
  email    text primary key,
  name     text,
  can_edit boolean default true,
  added_at timestamptz default now()
);

-- RLS
alter table crew_members    enable row level security;
alter table audit_log       enable row level security;
alter table allowed_users   enable row level security;

-- Polityki — crew_members
drop policy if exists "crew_select" on crew_members;
drop policy if exists "crew_modify" on crew_members;

create policy "crew_select" on crew_members
  for select to authenticated using (true);

create policy "crew_modify" on crew_members
  for all to authenticated
  using (true)
  with check (true);

-- Polityki — audit_log
drop policy if exists "log_select" on audit_log;
drop policy if exists "log_insert" on audit_log;

create policy "log_select" on audit_log
  for select to authenticated using (true);

create policy "log_insert" on audit_log
  for insert to authenticated with check (true);

-- Polityki — allowed_users
drop policy if exists "users_select" on allowed_users;
drop policy if exists "users_modify" on allowed_users;

create policy "users_select" on allowed_users
  for select to authenticated using (true);

create policy "users_modify" on allowed_users
  for all to authenticated using (true) with check (true);

-- Trigger: updated_at
create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists crew_updated_at on crew_members;
create trigger crew_updated_at
  before update on crew_members
  for each row execute function touch_updated_at();

-- ============================================================
--  DANE WSTĘPNE — 26 osób
-- ============================================================
insert into crew_members
  (lp, sort_order, name, position, phone, email, meals, allergies, city, transport, contract_type, notes)
values
  (1,  10,  'Jakub Sztuk',           'DoP / Producent',                     '666 602 359',  'sztukjakubdop@gmail.com',  'Mięso',    'Orzechy włoskie', null, 'Własny',    'UOD',                       null),
  (2,  20,  'Jarosław Burger',       'Focus Puller',                        '531 553 412',  'jarek.burger@gmail.com',   'Dopytać',  null,              null, 'Własny',    'Faktura VAT',               null),
  (3,  30,  'Kajetan Zieliński',     'Asystent Kamery',                     '500 185 110',  'kajozet@gmail.com',        'Mięso',    null,              null, 'Własny',    'Dopytać',                   null),
  (null,35, 'Maciej Malec',          'Podglądy / Cinetake',                 '502 942 245',  'maciejmalec03@gmail.com',  'Mięso',    null,              null, 'Własny',    'Umowa Zlecenie do 26 lat',  null),
  (4,  40,  'Paweł Sadowski',        'Reżyser',                             '502 656 003',  null,                       null,       null,              null, null,        null,                        null),
  (5,  50,  'Karol Szczepanik',      '2 Reżyser',                           null,           null,                       null,       null,              null, null,        null,                        null),
  (6,  60,  'Mateusz Kot',           '2 Operator / 2 AC',                   null,           null,                       null,       null,              null, null,        null,                        null),
  (7,  70,  'Krzysztof Kawula',      'Mistrz Oświetlenia / Gaffer',         '512 805 951',  null,                       null,       null,              null, null,        null,                        null),
  (8,  80,  'Adam Gier',             'Best Boy',                            null,           null,                       null,       null,              null, null,        null,                        null),
  (9,  90,  'TBD',                   'Oświetlacz I',                        null,           null,                       null,       null,              null, null,        null,                        null),
  (10, 100, 'TBD (od Kawuli)',       'Oświetlacz II',                       null,           null,                       null,       null,              null, null,        null,                        'Ew. od Krzyska Kawuli za darmo, ale spanie'),
  (11, 110, 'Dagmara Matoń',         'Scenograf',                           null,           null,                       null,       null,              null, null,        null,                        null),
  (12, 120, 'Adam Lubański',         'Pomoc Scenograficzna',                null,           null,                       null,       null,              null, null,        null,                        null),
  (13, 130, 'Justyna Szczepkowska',  'Kostiumograf',                        null,           null,                       null,       null,              null, null,        null,                        null),
  (null,135,'Kasia',                 'Pomoc Kostiumu',                      null,           null,                       null,       null,              null, null,        null,                        'Od Justyny'),
  (14, 140, 'Katarzyna Berć',        'Make-up / Charakteryzacja',           '537 650 020',  null,                       null,       null,              null, null,        null,                        null),
  (15, 150, 'TBD',                   'Make-up / Charakteryzacja Pomoc',     null,           null,                       null,       null,              null, null,        null,                        'DO USTALENIA — czy od Carli czy Dobek'),
  (16, 160, 'Dora Konarska',         'Kierownik Produkcji',                 '517 238 404',  null,                       null,       null,              null, null,        null,                        null),
  (17, 170, 'Carla',                 'Asystent Kierownika Produkcji',       '728 986 703',  null,                       null,       null,              null, null,        null,                        null),
  (18, 180, 'TBD (Łuki Chlebek?)',   'Dyżur + Auto',                        null,           null,                       null,       null,              null, null,        null,                        'Czekam na odpowiedź od Łuki Chlebka'),
  (19, 190, 'Bartek Grzybkowski',    'Dźwiękowiec + Sprzęt',                '607 084 604',  null,                       null,       null,              null, null,        null,                        null),
  (20, 200, 'TBD (od Bartka)',       'Boom Op',                             null,           null,                       null,       null,              null, null,        null,                        'Od Bartek Grzybkowski'),
  (21, 210, 'Norbi',                 'Key Grip',                            null,           null,                       null,       null,              null, null,        null,                        null),
  (22, 220, 'TBD (od Norbiego)',     'Grip',                                null,           null,                       null,       null,              null, null,        null,                        'Od Norbiego'),
  (23, 230, 'Pavel Krauchanka',      'Making Of',                           null,           null,                       null,       null,              null, null,        null,                        null),
  (24, 240, 'Tomasz Dedek',          'Aktor 1',                             null,           null,                       null,       null,              null, null,        null,                        null),
  (25, 250, 'Aleksandra',            'Aktor 2',                             null,           null,                       'Wege, Bezglutenowe, Bez mleka', null, null, null, null,                    null),
  (26, 260, 'Karolina Bruchnicka',   'Aktor 3',                             null,           null,                       null,       null,              null, null,        null,                        null)
;

-- TWÓJ DOSTĘP (dodaj swój Gmail)
insert into allowed_users (email, name, can_edit) values
  ('sztukjakub@gmail.com',    'Jakub Sztuk',  true),
  ('sztukjakubdop@gmail.com', 'Jakub Sztuk',  true)
on conflict (email) do nothing;

-- Dodaj Dorę i Carlę po tym jak podadzą swoje emaile Gmail:
-- insert into allowed_users (email, name, can_edit) values ('dora@gmail.com', 'Dora Konarska', true);
-- insert into allowed_users (email, name, can_edit) values ('carla@gmail.com', 'Carla', true);
