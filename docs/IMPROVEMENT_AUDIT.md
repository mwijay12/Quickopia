# Quickopia — Improvement Audit & Change Log
Prepared 2026-10-15 against master @ f0484e8. Verified against source code and production runtime targets.

---

## 1. Headline: Free Plan Pause Mitigation
Supabase pauses Free-plan projects after 7 days without incoming API traffic. Quickopia is explicitly designed to run at zero monthly cost on the Free plan. Without an automated keep-alive, any quiet week takes the whole platform offline.

### Fix Implemented:
- Migration `0023_system_heartbeat.sql`: Bounded single-row table with `heartbeat_ping()` and `heartbeat_status()` RPCs. Writes throttled to <=1/min to prevent disk growth.
- `.github/workflows/supabase-keepalive.yml`: Scheduled 6-hour cron workflow with exponential backoff retries.
- `web/admin/app/api/system/health/route.ts` & `web/admin/components/system/BackendHealthCard.tsx`: Realtime observable health status (ALIVE / PINGER STALLED / PAUSED) and grace-window progress bar.
- `mobile/lib/services/backend_health_service.dart` & `mobile/lib/providers/catalog_provider.dart`: Classifies failures so an outage displays helpful guidance instead of an empty shelf.
- `docs/SUPABASE_FREE_TIER_KEEPALIVE.md`: Operator guide covering the 60-day GitHub Actions pause trap and cron-job.org backup redundancy.

---

## 2. Build Reproducibility
- In `mobile/pubspec.yaml`, the SDK floor was updated from `>=3.5.0 <4.0.0` to `>=3.10.0 <4.0.0` to satisfy `flutter_local_notifications: ^22.3.0` which requires Dart `>=3.10.0`.
- Direct dependency on `http: ^1.2.0` declared explicitly in `pubspec.yaml`.

---

## 3. Continuous Integration Pipeline (CI)
- `.github/workflows/ci.yml`: Added 4 automated jobs:
  1. `secrets`: Scans repository files for committed JWTs, service role keys, and provider keys.
  2. `mobile`: Formats check, runs `flutter analyze`, and `flutter test`.
  3. `web`: Type-checks and builds both `admin` and `storefront` Next.js applications.
  4. `migrations`: Validates migration sequence continuity (no missing numbers).

---

## 4. Configuration Failure Diagnostics
- `mobile/lib/config/supabase_config.dart`:
  - Captures exact reason why credentials failed via `configProblem`.
  - Refuses to boot with `service_role` keys in client bundles.
  - Generates clear terminal diagnostic banners.
  - Guarded against duplicate initialization.

---

## 5. Motion & Transition System
- `mobile/lib/theme/app_motion.dart`: Standardized duration and curve tokens.
- `mobile/lib/theme/quickopia_page_transitions.dart`: Custom rise-and-fade transitions for seamless screen shifts.
- `mobile/lib/theme/app_theme.dart`: Wired `pageTransitionsTheme` across all 6 target platforms.
- `mobile/lib/screens/customer/customer_home_screen.dart`: Smooth staggered reveal on top 6 product cards without scroll latency.

---

## 6. Search Cache Security & Pruning
- `supabase/migrations/0024_search_cache_lockdown_and_pruning.sql`:
  - Revokes direct anonymous/authenticated writes to `search_query_cache`.
  - Introduces `last_used_at` and LRU index.
  - Implements bounded LRU pruning `prune_search_cache(p_max_rows)` capped at 5,000 entries.
  - Self-maintains cache via probabilistic trigger in `increment_search_cache_hit`.

---

## 7. Web Security & Dependencies
- Upgraded `next` to `15.3.9` across `web/admin/package.json` and `web/storefront/package.json` (closing CVE-2025-29927 middleware bypass, RSC DoS, and HTTP smuggling vulnerabilities).
- Production builds verified on both Next.js applications:
  - `web/admin`: 22/22 routes & middleware compiled cleanly.
  - `web/storefront`: 6/6 routes compiled cleanly.
- Scoped `web/storefront/next.config.mjs` image `remotePatterns` to trusted hosts (`res.cloudinary.com`, `**.supabase.co`, `images.unsplash.com`) closing open SSRF image proxy vulnerabilities.
- Added server-side auth verification in `web/admin/app/dashboard/layout.tsx` for defence-in-depth.

---

## 8. Client-Side AI Provider Keys Architecture (RESOLVED)
- **Supabase Edge Functions created**:
  - `supabase/functions/ai-assistant/index.ts`: Server-side conversational assistant with Groq (`llama-3.3-70b-versatile`), Gemini (`gemini-1.5-flash`), and OpenRouter failover pools.
  - `supabase/functions/ai-tts/index.ts`: Server-side ElevenLabs multilingual TTS proxy.
- **Mobile app integration (`ai_assistant_service.dart`)**:
  - Proxies AI queries and audio synthesis through `SupabaseConfig.client.functions.invoke()`.
  - Sensitive provider keys (Groq, Gemini, OpenRouter, ElevenLabs) now reside exclusively in Supabase Secrets (`supabase secrets set ...`).
  - Production APK/IPA releases contain **zero** third-party AI provider secrets.
  - Retains local environment variable fallback exclusively for offline development / unit testing.
- Updated `mobile/.env.example` with clear documentation separating client-side public keys from server-side secret management.
