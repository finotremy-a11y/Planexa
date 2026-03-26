# Supabase Security Fix: RLS & Sensitive Columns

## Issue
Supabase is reporting:
- **rls_disabled_in_public**: 30+ tables missing Row Level Security (RLS)
- **sensitive_columns_exposed**: 3 tables (api_webhooks, reviews, waitlist_entries) exposing `secret`/`token` columns via PostgREST API without RLS

## Root Cause
Rails migrations create tables with RLS disabled by default. Supabase PostgREST API requires RLS to prevent unauthorized access.

## Solution

### Step 1: Execute SQL Hardening Script (5 minutes)

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select project `Agendapro` (iunkhrmfsbyonegybnes)
3. Go to **SQL Editor** (left sidebar)
4. Click **New query**
5. Copy entire content from `db/supabase_security_hardening.sql`
6. Paste into SQL Editor
7. Click **Run**
8. Wait for completion (check console for "Verify RLS is enabled" output)

### Step 2: Verify Fixes (1 minute)

Run this verification query in SQL Editor:

```sql
-- List all public tables with RLS status
select 
  schemaname,
  tablename,
  rowsecurity,
  case when rowsecurity = true then '✓ RLS enabled' else '✗ RLS disabled' end
from pg_tables
where schemaname = 'public'
order by tablename;
```

All tables should show `rowsecurity = true`.

### Step 3: Rotate Database Password (2 minutes)

1. Go to Supabase **Settings** > **Database**
2. Click **Reset password**
3. Copy new password
4. Update `DATABASE_URL` in:
   - Local `.env` file
   - Render/production environment secrets
   - Any other deployment environment

Format:
```
postgresql://postgres.<project-ref>:<NEW-PASSWORD>@aws-1-eu-west-1.pooler.supabase.com:5432/postgres
```

### Step 4: Re-run Supabase Security Check

1. Go to Supabase **Settings** > **Security**
2. Click **Run security checks** (or wait for automatic scan)
3. Errors should disappear within 5 minutes

## What This Script Does

| Step | Action | Impact |
|------|--------|--------|
| 1 | Enables RLS on all public tables | Blocks unauthenticated API access |
| 2 | Forces RLS (prevents bypass) | Even superusers follow policies |
| 3 | Creates default-deny policies | No data leaked through PostgREST |
| 4 | Grants `service_role` full access | Rails app continues to work |

## Why This is Safe

- **Service Role bypass**: Your Rails backend uses `DATABASE_URL` with `service_role` token → full access preserved
- **No data loss**: Only affects PostgREST API access; all queries/reports continue working
- **Reversible**: You can add explicit policies later if you need public API endpoints

## If You Need Public API Endpoints Later

Example (DO NOT RUN unless intentional):

```sql
-- Example: Allow public read on service_types (after RLS is enabled)
create policy "public_can_read_service_types"
  on public.service_types
  for select
  to anon, authenticated
  using (true);  -- or more restrictive conditions
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "must be owner" error | Use Supabase dashboard SQL Editor (it uses service_role key) |
| Rails app connection fails | Restart Rails/Render after updating DATABASE_URL |
| Errors still appearing after 10 min | Manually run verification query to confirm RLS is on all tables |

## References

- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgREST Security](https://postgrest.org/en/latest/references/auth.html)
- [Supabase Security Checks](https://supabase.com/docs/guides/database/database-linter)
