# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Security (Supabase)

If Supabase reports `rls_disabled_in_public` or `sensitive_columns_exposed`, run:

1. Open Supabase SQL Editor.
2. Execute `db/supabase_security_hardening.sql`.
3. In Supabase project settings, rotate the database password.
4. Update `DATABASE_URL` in local and deployment secrets.

Notes:

- This app uses server-side DB access via Rails. It does not require direct `anon` or `authenticated` table access for core flows.
- If you later expose data through Supabase API, create explicit per-table RLS policies first.
