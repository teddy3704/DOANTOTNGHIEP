-- DLU LMS Mobile app-owned data only.
-- Moodle remains the source of truth for LMS users, courses, assignments,
-- grades, submissions, and authorization.

create table public.mobile_preferences (
  owner_id uuid primary key,
  theme_mode text not null default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mobile_preferences_theme_mode_check
    check (theme_mode in ('system', 'light', 'dark'))
);

comment on table public.mobile_preferences is
  'User-owned mobile UI preferences; never Moodle academic data or credentials.';

comment on column public.mobile_preferences.owner_id is
  'Stable UUID from the verified Supabase JWT sub claim. No auth.users FK until DLU identity mapping is approved.';

create function public.set_mobile_preferences_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  new.updated_at = statement_timestamp();
  return new;
end;
$function$;

revoke all on function public.set_mobile_preferences_updated_at()
  from public, anon, authenticated, service_role;

create trigger set_mobile_preferences_updated_at
before update on public.mobile_preferences
for each row
execute function public.set_mobile_preferences_updated_at();

alter table public.mobile_preferences enable row level security;
alter table public.mobile_preferences force row level security;

-- Remove inherited/legacy Data API grants before opting in to the exact client
-- operations. Column grants keep identity and audit columns immutable to clients.
revoke all privileges on table public.mobile_preferences
  from public, anon, authenticated, service_role;

grant select on table public.mobile_preferences to authenticated;
grant insert (owner_id, theme_mode)
  on table public.mobile_preferences to authenticated;
grant update (theme_mode)
  on table public.mobile_preferences to authenticated;

create policy mobile_preferences_select_own
on public.mobile_preferences
for select
to authenticated
using (
  (select auth.uid()) = owner_id
  and coalesce(
    (select (auth.jwt() ->> 'is_anonymous')::boolean),
    false
  ) is false
);

create policy mobile_preferences_insert_own
on public.mobile_preferences
for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and coalesce(
    (select (auth.jwt() ->> 'is_anonymous')::boolean),
    false
  ) is false
);

create policy mobile_preferences_update_own
on public.mobile_preferences
for update
to authenticated
using (
  (select auth.uid()) = owner_id
  and coalesce(
    (select (auth.jwt() ->> 'is_anonymous')::boolean),
    false
  ) is false
)
with check (
  (select auth.uid()) = owner_id
  and coalesce(
    (select (auth.jwt() ->> 'is_anonymous')::boolean),
    false
  ) is false
);

-- Atomic, fixed-purpose write boundary. The caller cannot choose owner_id;
-- Postgres derives it from the verified JWT and RLS still evaluates the row.
create function public.save_mobile_theme_preference(p_theme_mode text)
returns public.mobile_preferences
language sql
security invoker
set search_path = ''
as $function$
  insert into public.mobile_preferences as preferences (owner_id, theme_mode)
  values ((select auth.uid()), p_theme_mode)
  on conflict (owner_id) do update
    set theme_mode = excluded.theme_mode
  returning preferences.*;
$function$;

comment on function public.save_mobile_theme_preference(text) is
  'Atomically saves the authenticated user mobile theme preference.';

revoke all on function public.save_mobile_theme_preference(text)
  from public, anon, authenticated, service_role;
grant execute on function public.save_mobile_theme_preference(text)
  to authenticated;
