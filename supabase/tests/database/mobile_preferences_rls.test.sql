-- pgTAP contract test for mobile_preferences grants and RLS.
-- Run only against an isolated local/dev Supabase database after applying all
-- migrations. The transaction is always rolled back.

begin;

create extension if not exists pgtap with schema extensions;

select plan(28);

select has_table(
  'public',
  'mobile_preferences',
  'mobile_preferences table exists'
);

select ok(
  (
    select relrowsecurity and relforcerowsecurity
    from pg_class
    where oid = 'public.mobile_preferences'::regclass
  ),
  'mobile_preferences enables and forces RLS'
);

select policies_are(
  'public',
  'mobile_preferences',
  array[
    'mobile_preferences_insert_own',
    'mobile_preferences_select_own',
    'mobile_preferences_update_own'
  ],
  'only the reviewed preference policies exist'
);

select policy_roles_are(
  'public',
  'mobile_preferences',
  'mobile_preferences_select_own',
  array['authenticated'],
  'select policy targets authenticated only'
);

select policy_cmd_is(
  'public',
  'mobile_preferences',
  'mobile_preferences_select_own',
  'SELECT',
  'select policy has SELECT command'
);

select policy_roles_are(
  'public',
  'mobile_preferences',
  'mobile_preferences_insert_own',
  array['authenticated'],
  'insert policy targets authenticated only'
);

select policy_cmd_is(
  'public',
  'mobile_preferences',
  'mobile_preferences_insert_own',
  'INSERT',
  'insert policy has INSERT command'
);

select policy_roles_are(
  'public',
  'mobile_preferences',
  'mobile_preferences_update_own',
  array['authenticated'],
  'update policy targets authenticated only'
);

select policy_cmd_is(
  'public',
  'mobile_preferences',
  'mobile_preferences_update_own',
  'UPDATE',
  'update policy has UPDATE command'
);

select has_function(
  'public',
  'save_mobile_theme_preference',
  array['text'],
  'fixed-purpose theme save function exists'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.save_mobile_theme_preference(text)',
    'EXECUTE'
  ),
  'authenticated can execute the theme save function'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.save_mobile_theme_preference(text)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.save_mobile_theme_preference(text)',
    'EXECUTE'
  ),
  'anon and service_role cannot execute the theme save function'
);

select ok(
  has_table_privilege(
    'authenticated',
    'public.mobile_preferences',
    'SELECT'
  ),
  'authenticated has SELECT access'
);

select ok(
  has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'owner_id',
    'INSERT'
  )
  and has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'theme_mode',
    'INSERT'
  )
  and not has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'created_at',
    'INSERT'
  )
  and not has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'updated_at',
    'INSERT'
  ),
  'authenticated INSERT is limited to owner_id and theme_mode'
);

select ok(
  has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'theme_mode',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'owner_id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'created_at',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.mobile_preferences',
    'updated_at',
    'UPDATE'
  ),
  'authenticated UPDATE is limited to theme_mode'
);

select ok(
  not has_table_privilege(
    'authenticated',
    'public.mobile_preferences',
    'DELETE'
  ),
  'authenticated has no DELETE access'
);

select ok(
  not has_table_privilege('anon', 'public.mobile_preferences', 'SELECT')
  and not has_any_column_privilege(
    'anon',
    'public.mobile_preferences',
    'INSERT,UPDATE'
  ),
  'anon has no preference access'
);

select ok(
  not has_table_privilege(
    'service_role',
    'public.mobile_preferences',
    'SELECT,DELETE'
  )
  and not has_any_column_privilege(
    'service_role',
    'public.mobile_preferences',
    'INSERT,UPDATE'
  ),
  'service_role has no app-table grant in this baseline'
);

insert into public.mobile_preferences (owner_id, theme_mode)
values ('11111111-1111-4111-8111-111111111111', 'system');

set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","is_anonymous":false}',
  true
);

select results_eq(
  $$
    select owner_id
    from public.mobile_preferences
  $$,
  $$
    values ('11111111-1111-4111-8111-111111111111'::uuid)
  $$,
  'owner sees exactly their preference row'
);

select lives_ok(
  $$
    select public.save_mobile_theme_preference('dark')
  $$,
  'owner can atomically save theme_mode'
);

select results_eq(
  $$
    select theme_mode
    from public.mobile_preferences
  $$,
  array['dark'::text],
  'owner update is persisted'
);

set local request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","is_anonymous":false}',
  true
);

select results_eq(
  'select count(*) from public.mobile_preferences',
  array[0::bigint],
  'another user cannot see the owner row'
);

select results_eq(
  $$
    update public.mobile_preferences
    set theme_mode = 'light'
    returning owner_id
  $$,
  $$
    select null::uuid where false
  $$,
  'another user cannot update the owner row'
);

select throws_ok(
  $$
    insert into public.mobile_preferences (owner_id, theme_mode)
    values ('33333333-3333-4333-8333-333333333333', 'light')
  $$,
  '42501',
  'new row violates row-level security policy for table "mobile_preferences"',
  'authenticated user cannot insert a row for another owner'
);

select lives_ok(
  $$
    select public.save_mobile_theme_preference('light')
  $$,
  'authenticated user can atomically create their own row'
);

set local request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","is_anonymous":true}',
  true
);

select results_eq(
  'select count(*) from public.mobile_preferences',
  array[0::bigint],
  'anonymous authenticated session sees no rows'
);

select throws_ok(
  $$
    select public.save_mobile_theme_preference('dark')
  $$,
  '42501',
  'new row violates row-level security policy for table "mobile_preferences"',
  'anonymous authenticated session cannot insert'
);

reset role;
set local role anon;

select throws_ok(
  'select count(*) from public.mobile_preferences',
  '42501',
  'permission denied for table mobile_preferences',
  'anon cannot select the table'
);

select * from finish();
rollback;
