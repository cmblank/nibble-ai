# nibble_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AI Image Generation

Two modes:

1. Direct dev key (simple, not for production):
```
flutter run --dart-define=OPENAI_API_KEY=sk_your_key
```
2. Supabase Edge Function proxy (recommended): deploy the function at `supabase/functions/generate_recipe_image` with env OPENAI_API_KEY, SUPABASE_SERVICE_ROLE_KEY, etc. If no local key is set the app automatically calls the function.

Logging table (optional):
```sql
create table if not exists ai_image_generations(
	id uuid primary key default gen_random_uuid(),
	user_id uuid references auth.users(id) on delete cascade,
	recipe_id text,
	url text,
	created_at timestamptz default now()
);
```

Deploy:
```
supabase functions deploy generate_recipe_image --env-file supabase/.env
```

Environment `.env` example:
```
OPENAI_API_KEY=sk_...
SUPABASE_URL=...your supabase url...
SUPABASE_SERVICE_ROLE_KEY=...service role...
DAILY_USER_LIMIT=10
```

Quota + moderation: extend the edge function to add stricter filtering or per-tier limits.

## AI Recipe Enrichment

Edge Function first strategy (server holds the model key) with client fallback.

Function source: `supabase/functions/enrich-recipe/index.ts`

Deploy:
```
supabase functions deploy enrich-recipe --env-file supabase/.env
```

Required env (`supabase/.env`):
```
OPENAI_API_KEY=sk_...
SUPABASE_URL=...your supabase url...
SUPABASE_SERVICE_ROLE_KEY=...service role...
ENRICH_MODEL=gpt-4o-mini
```

Client integration: The Flutter app calls the Edge Function (name `enrich-recipe`). If it returns non-200 or is unreachable and a local `AiEnrichmentConfig.apiKey` is present, it falls back to direct OpenAI call.

Returned JSON keys (all optional, omit when unknown):
`servings, prep_minutes, cook_minutes, cuisine, meal_type, difficulty, ingredients_structured, instructions_structured, tags, equipment, substitutions, nutrition_estimate, confidence`.

#### Caching & Rate Limiting

Migration step: run `step5_recipe_enrichment_meta.sql` then `step6_enrichment_cache_and_usage.sql`.

New env vars (optional defaults):
```
ENRICH_DAILY_LIMIT=15
ENRICH_CACHE_TTL_MINUTES=1440
```

Behavior:
* Computes SHA-256 hash of (model + truncated prompt). If a fresh cached row exists in `enrichment_cache` within TTL it returns it (adds `_cached: true`) and does NOT count against limit.
* Before model call, checks `enrichment_usage` for today. If `count >= ENRICH_DAILY_LIMIT` returns 429.
* On new result, upserts cache row and increments usage via `increment_enrichment_usage` function (atomic retry loop).
* Table `enrichment_cache` can be periodically pruned (e.g. keep last 7 days) via a scheduled task.

SQL helper function created in step6 migration: `increment_enrichment_usage(p_user_id uuid, p_date date)`.

### RLS Policy Patch

Run `recipes_update_policy_patch.sql` in the Supabase SQL editor so authenticated users can update/delete recipes; needed for persisting AI-enriched fields & images.

### Local Dev Key (fallback)

For quick tests without the Edge Function:
```
flutter run --dart-define=OPENAI_API_KEY=sk_your_key
```
Then at runtime assign `AiEnrichmentConfig.apiKey = const String.fromEnvironment('OPENAI_API_KEY');`

## Household Sharing (Multi-user Households) Deployment Runbook

### Overview
Household sharing introduces normalized tables (`households`, `household_members`, `household_invites`) and scopes pantry, meal plans, and shopping list data by `household_id`.

### Components
Tables & scripts (see repo root SQL files):
- `household_supabase.sql` (core schema & base RLS)
- `household_limits.sql` (member & invite limits)
- `household_invite_status_guard.sql` (status state machine)
- `household_invites_integrity.sql` + `household_invite_expiry_job.sql` (expiry & cleanup)
- `household_audit.sql` + `household_audit_index.sql` (audit trail + index)
- `household_members_userid_guard.sql` (enforce user_id on inserts)
- `household_backfill_userid_expiry.sql` (backfill user_id + expires_at)
- `household_pantry_migration.sql` (adds household_id to pantry)
- `household_mealplan_shopping_migration.sql` (adds household_id to meal_plan_slots & shopping_list)
- `household_null_sanity.sql` (NULL check before constraints)
- `household_enforce_notnull_constraints.sql` (final hardening)

### Ordered Deployment Steps
1. Apply core & guard scripts:
	- Run: `household_supabase.sql`, `household_audit.sql`, `household_invite_expiry_job.sql`, `household_invites_integrity.sql`, `household_invite_status_guard.sql`, `household_limits.sql`, `household_members_userid_guard.sql`.
2. Backfill & transitional data:
	- Run: `household_backfill_userid_expiry.sql`.
3. Migrate feature tables to household scope:
	- Run: `household_pantry_migration.sql`.
	- Run: `household_mealplan_shopping_migration.sql`.
4. Add audit index:
	- Run: `household_audit_index.sql`.
5. Sanity verification (must all be zero):
	- Execute `household_null_sanity.sql`.
6. Enforce constraints:
	- Run: `household_enforce_notnull_constraints.sql` (aborts if any NULL remain).
7. Deploy updated app build (services now require `household_id`).
8. Post-deploy monitoring:
	- Check audit trail size & recent events.
	- Inspect pending invites for unexpected volume.

### Integration Tests (Optional Before Prod)
Provide env vars and run Flutter tests:
```
SUPABASE_URL=... SUPABASE_ANON_KEY=... flutter test test/household_integration_flow_test.dart
```

### Quick Minimal Seed For Tests
If integration test fails with PostgREST table not found (PGRST205) for `household_invites` or related tables, apply the minimal core schema:
1. Open Supabase SQL editor.
2. Paste contents of `sql/household_min_core.sql` and run.
3. Re-run the integration test.

For full production hardening, still execute the complete ordered scripts in the runbook above (limits, expiry job, integrity, audit index, etc.). The minimal file only includes what the test suite requires.

### Rollback Notes
If constraints cause unexpected failures, you can temporarily drop them (NOT NULL) and revert service code to user_id fallback (commit prior to constraint removal). Prefer fixing data inconsistencies instead of removing constraints permanently.

### Realtime Resilience
`HouseholdService` implements exponential backoff (cap 32s) with jitter and resets attempts on successful subscription; failures (timeout/channel error) trigger resubscribe logic.

### Audit Coverage
Logged actions: `invite_created`, `invite_accepted`, `invite_revoked`, `ownership_transferred`, `member_removed`, `leave`. Add more by calling `rpc('household_audit_log', ...)` in service methods.

### Manual Verification Queries
```sql
-- Members per household
select household_id, count(*) members from household_members group by 1 order by members desc limit 10;
-- Active pending invites nearing expiry (next 24h)
select code, household_id, invited_email, expires_at from household_invites where status='pending' and expires_at < now() + interval '24 hours';
-- Recent audit events
select action, details, created_at from household_audit order by created_at desc limit 25;
```
