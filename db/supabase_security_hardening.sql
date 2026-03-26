
begin;


do $$
declare
  t record;
begin
  for t in
    select tablename
    from pg_tables
    where schemaname = 'public'
  loop
    -- Enable RLS
    execute format('alter table public.%I enable row level security', t.tablename);
    
    -- Force RLS (prevents bypassing via bypassrls)
    execute format('alter table public.%I force row level security', t.tablename);
    
    -- Revoke public access
    execute format('revoke all on table public.%I from anon, authenticated', t.tablename);
    
    raise notice 'RLS enabled on table: %', t.tablename;
  end loop;
end $$;

-- Step 2: Create default-deny policies on all tables (strict security posture)
-- This prevents any data leak through PostgREST while keeping service_role (Rails app) functional
do $$
declare
  t record;
  policy_name text;
begin
  for t in
    select tablename
    from pg_tables
    where schemaname = 'public'
  loop
    policy_name := 'deny_all_' || t.tablename;
    
    -- Drop existing policies if any
    execute format('drop policy if exists %I on public.%I', policy_name, t.tablename);
    
    -- Create strict deny-all policy (only service_role bypasses this)
    execute format(
      'create policy %I on public.%I as permissive for all using (false)',
      policy_name,
      t.tablename
    );
    
    raise notice 'Default-deny policy created: %', policy_name;
  end loop;
end $$;

-- Step 3: Grant full access to service_role (used by Rails app)
-- This is safe because service_role is controlled and only used server-side
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

commit;

-- Verify RLS is enabled
select tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
order by tablename;
