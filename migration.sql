-- ============================================================
--  MIGRACJA do wersji multi-project
--  Wklej w Supabase SQL Editor i kliknij Run
-- ============================================================

-- 1. NOWA TABELA: projekty
create table if not exists projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  owner_email text not null,
  created_at  timestamptz default now()
);

-- 2. NOWA TABELA: dostęp per-projekt (zastępuje allowed_users)
create table if not exists project_access (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references projects(id) on delete cascade,
  user_email  text not null,
  user_name   text,
  can_edit    boolean default true,
  added_at    timestamptz default now(),
  unique(project_id, user_email)
);

-- 3. Dodaj project_id do crew_members
alter table crew_members add column if not exists project_id uuid references projects(id) on delete cascade;

-- 4. Utwórz domyślny projekt dla istniejącej ekipy
insert into projects (id, name, owner_email)
values ('00000000-0000-0000-0000-000000000001', 'Produkcja 2026', 'sztukjakub@gmail.com')
on conflict do nothing;

-- 5. Przypisz istniejącą ekipę do domyślnego projektu
update crew_members
set project_id = '00000000-0000-0000-0000-000000000001'
where project_id is null;

-- 6. Dodaj Jakuba do project_access domyślnego projektu
insert into project_access (project_id, user_email, user_name, can_edit) values
  ('00000000-0000-0000-0000-000000000001', 'sztukjakub@gmail.com',    'Jakub Sztuk', true),
  ('00000000-0000-0000-0000-000000000001', 'sztukjakubdop@gmail.com', 'Jakub Sztuk', true)
on conflict (project_id, user_email) do nothing;

-- 7. RLS dla nowych tabel
alter table projects       enable row level security;
alter table project_access enable row level security;

-- Usuń stare polityki
drop policy if exists "crew_select"  on crew_members;
drop policy if exists "crew_modify"  on crew_members;
drop policy if exists "log_select"   on audit_log;
drop policy if exists "log_insert"   on audit_log;
drop policy if exists "users_select" on allowed_users;
drop policy if exists "users_modify" on allowed_users;

-- Polityki: projects
drop policy if exists "projects_select" on projects;
drop policy if exists "projects_insert" on projects;
drop policy if exists "projects_modify" on projects;

create policy "projects_select" on projects for select to authenticated
  using (
    owner_email = (auth.jwt() ->> 'email')
    or exists (
      select 1 from project_access pa
      where pa.project_id = projects.id
      and pa.user_email = (auth.jwt() ->> 'email')
    )
  );

create policy "projects_insert" on projects for insert to authenticated
  with check (owner_email = (auth.jwt() ->> 'email'));

create policy "projects_modify" on projects for update to authenticated
  using (owner_email = (auth.jwt() ->> 'email'));

create policy "projects_delete" on projects for delete to authenticated
  using (owner_email = (auth.jwt() ->> 'email'));

-- Polityki: crew_members (scoped do projektu)
drop policy if exists "crew_select2" on crew_members;
drop policy if exists "crew_all2"    on crew_members;

create policy "crew_select2" on crew_members for select to authenticated
  using (
    exists (
      select 1 from projects p
      left join project_access pa on pa.project_id = p.id and pa.user_email = (auth.jwt() ->> 'email')
      where p.id = crew_members.project_id
      and (p.owner_email = (auth.jwt() ->> 'email') or pa.user_email is not null)
    )
  );

create policy "crew_all2" on crew_members for all to authenticated
  using (
    exists (
      select 1 from projects p
      left join project_access pa on pa.project_id = p.id and pa.user_email = (auth.jwt() ->> 'email') and pa.can_edit = true
      where p.id = crew_members.project_id
      and (p.owner_email = (auth.jwt() ->> 'email') or pa.user_email is not null)
    )
  );

-- Polityki: project_access
drop policy if exists "pa_select" on project_access;
drop policy if exists "pa_modify" on project_access;

create policy "pa_select" on project_access for select to authenticated
  using (
    exists (
      select 1 from projects p
      where p.id = project_access.project_id
      and (
        p.owner_email = (auth.jwt() ->> 'email')
        or project_access.user_email = (auth.jwt() ->> 'email')
      )
    )
  );

create policy "pa_modify" on project_access for all to authenticated
  using (
    exists (
      select 1 from projects p
      where p.id = project_access.project_id
      and p.owner_email = (auth.jwt() ->> 'email')
    )
  );

-- Polityki: audit_log (bez zmian, scoped przez crew_member)
create policy "log_select2" on audit_log for select to authenticated using (true);
create policy "log_insert2" on audit_log for insert to authenticated with check (true);
