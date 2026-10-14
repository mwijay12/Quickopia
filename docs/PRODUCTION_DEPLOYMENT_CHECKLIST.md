# Quickopia — Production Deployment Checklist & Environment Runbook

This document serves as the operational guide for deploying Quickopia across Supabase, Vercel, and the Google Play Store.

---

## 1. Supabase Production Readiness

### A. Environment Promotion Strategy (Pilot Phase)
- **Decision:** Promote the current Supabase instance directly for the single-branch pilot launch.
- **Rationale:** All 16 database migrations (`0001` through `0016`) have been verified, hardened, and locked with RLS policies, concurrency locks (`FOR UPDATE`), atomic stock triggers, and cancellation functions. Standing up a redundant instance for a single pilot store adds migration risk without operational benefit.
- **Migration Sequence Verified:**
  1. `0001_enums_and_extensions.sql` — Core types (`user_role`, `order_status`, `fulfillment_type`)
  2. `0002_base_schema.sql` — Branches, categories, products, profiles, addresses, orders
  3. `0003_order_number_sequence.sql` — Unique sequential order generator
  4. `0004_order_placement_function.sql` — Atomic `place_order` RPC with row locking
  5. `0005_row_level_security_policies.sql` — Base RLS policies
  6. `0006_delivery_coordinates_and_distance.sql` — Haversine distance calculator
  7. `0007_realtime_and_driver_visibility.sql` — Driver location and assigned order publication
  8. `0008_driver_stats_and_pickup_code.sql` — Driver metrics and 4-digit pickup code
  9. `0009_admin_order_management_functions.sql` — Status transitions & counter pickup handoff
  10. `0010_admin_category_management.sql` — Dynamic category CRUD
  11. `0011_admin_stock_adjustment.sql` — Concurrency-safe delta stock adjustment
  12. `0012_admin_analytics_functions.sql` — Business metrics & top products RPCs
  13. `0013_search_query_cache.sql` — Bilingual query expansion cache
  14. `0014_referral_codes.sql` — Unique referral codes & abuse-guarded redemption
  15. `0015_security_hardening.sql` — Profile integrity trigger & quantity guard
  16. `0016_order_cancellation_enhancement.sql` — Customer pre-packing cancellation & stock restoration

### B. Production Edge Function Secrets
Set these secrets in Supabase CLI or Supabase Dashboard (`Project Settings -> Edge Functions -> Secrets`):
```bash
supabase secrets set GEMINI_API_KEY="your_production_gemini_key"
supabase secrets set OPENROUTER_API_KEY="your_openrouter_fallback_key"
supabase secrets set SENTRY_DSN="your_sentry_edge_dsn"
```

### C. Database Backup Awareness & Risk Assessment
- **Free Tier Backup Policy:** Supabase provides 7-day daily automated backups on the free tier.
- **Limitation:** Point-in-time recovery (PITR) is only available on Supabase Pro ($25/month).
- **Free Tier Mitigation:** Schedule an automated weekly backup script using `pg_dump`:
  ```bash
  pg_dump "postgres://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" > backup_$(date +%Y%m%d).sql
  ```

---

## 2. Vercel Production Deployment (Storefront & Admin Portal)

Deploy Storefront and Admin as **two separate projects** in the Vercel dashboard to isolate build bundles, domain routing, and security blast radiuses.

### A. Project 1: Public Storefront (`web/storefront`)
- **Root Directory:** `web/storefront`
- **Framework Preset:** Next.js
- **Build Command:** `next build`
- **Output Directory:** `.next`
- **Production Environment Variables:**
  | Variable | Value / Description | Exposure |
  | :--- | :--- | :--- |
  | `NEXT_PUBLIC_SUPABASE_URL` | Production Supabase URL | Public |
  | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production Supabase Anon Key | Public |
  | `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` | Cloudinary Cloud Name | Public |
  | `NEXT_PUBLIC_SENTRY_DSN` | Sentry Storefront DSN | Public |

### B. Project 2: Admin Portal (`web/admin`)
- **Root Directory:** `web/admin`
- **Framework Preset:** Next.js
- **Build Command:** `next build`
- **Output Directory:** `.next`
- **Production Environment Variables:**
  | Variable | Value / Description | Exposure |
  | :--- | :--- | :--- |
  | `NEXT_PUBLIC_SUPABASE_URL` | Production Supabase URL | Public |
  | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production Supabase Anon Key | Public |
  | `SUPABASE_SERVICE_ROLE_KEY` | Supabase Service Role Key | **SERVER-ONLY (Never NEXT_PUBLIC)** |
  | `GEMINI_API_KEY` | Gemini API Key | **SERVER-ONLY** |
  | `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` | Cloudinary Cloud Name | Public |
  | `NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET` | Cloudinary Preset Name | Public |
  | `NEXT_PUBLIC_SENTRY_DSN` | Sentry Admin DSN | Public |

### C. Search Engine Crawl Protection (Admin Portal)
- **Robots Tag:** Configured `robots: { index: false, follow: false }` in `web/admin/app/layout.tsx`.
- **Robots File:** Created `web/admin/public/robots.txt` containing:
  ```txt
  User-agent: *
  Disallow: /
  ```

---

## 3. Flutter App Store Submission Prep

### A. Android (Google Play Store)
1. **Google Play Console:** One-time $25 registration fee (the single non-negotiable cost of the project).
2. **Release Keystore Setup:**
   Generate the release upload key if not already done:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Copy `mobile/android/key.properties.example` to `mobile/android/key.properties` with the keystore credentials.
3. **Build Release App Bundle:**
   ```bash
   cd mobile
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`.
4. **Required Store Assets:**
   - App Icon: 512 x 512 PNG
   - Feature Graphic: 1024 x 500 PNG
   - Minimum 2 phone screenshots (1080 x 1920 or 1080 x 2340)
   - Privacy Policy URL (hosted on Storefront: `https://[storefront-domain]/privacy`)

### B. iOS (Apple App Store) — Explicit Decision
- **Status: DEFERRED FOR PILOT PHASE.**
- **Rationale:**
  1. Tanzania's smartphone market is >85% Android.
  2. Apple requires an ongoing $99/year Apple Developer Program membership.
  3. iOS app review times and test builds slow down early pilot iteration.
  4. The code is already 100% cross-platform Flutter and can be deployed to iOS post-pilot without architecture changes.

---

## 4. Environment Separation Map

| Dimension | Development (Local) | Staging / Preview | Production (Live Pilot) |
| :--- | :--- | :--- | :--- |
| **Supabase DB** | Local or Sandbox DB | Branch Database | Live Pilot Supabase Project |
| **Storefront** | `localhost:3000` | `[branch].vercel.app` | `shop.quickopia.com` (or Vercel prod) |
| **Admin Portal** | `localhost:3001` | `[branch-admin].vercel.app` | `admin.quickopia.com` (noindex) |
| **Flutter App** | `flutter run --debug` | Internal App Distribution | Google Play Store (`com.quickopia.app`) |
| **Sentry Surface** | `environment: development` | `environment: staging` | `environment: production` |

---

## 5. Rollback Readiness Protocols

### Vercel Instant Rollback (Zero-Downtime)
1. Navigate to **Vercel Dashboard &rarr; Project &rarr; Deployments**.
2. Locate the previous working production deployment.
3. Click **... (three dots) &rarr; Instant Rollback**.
4. Traffic is redirected to the previous build within 5 seconds without triggering a rebuild.

### Database State Protection
- Prior to deploying any post-pilot migration, execute a backup using `pg_dump`.
- In case of critical schema failure, restore via:
  ```bash
  psql "postgres://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" < pre_migration_backup.sql
  ```

---

## 6. Post-Deploy Smoke Test Checklist

Execute these 10 tests immediately upon deploying to production:

- [ ] **ST-01:** Admin login gate: Verify non-admin accounts are redirected to `/access-denied`.
- [ ] **ST-02:** Admin Kanban loads active orders via live Supabase connection.
- [ ] **ST-03:** Storefront loads published categories and active products.
- [ ] **ST-04:** Doorstep delivery checkout on storefront places order into Supabase.
- [ ] **ST-05:** Mobile app boots, connects to Supabase, and displays catalog items.
- [ ] **ST-06:** Customer places mobile order; verify order chime fires on Admin Kanban.
- [ ] **ST-07:** Move order from `New` &rarr; `Packing` &rarr; `Ready` on Kanban; verify mobile tracking updates in realtime.
- [ ] **ST-08:** Assign driver on Kanban; verify driver's mobile queue displays the order.
- [ ] **ST-09:** Complete delivery using 4-digit pickup code; verify order marked `delivered`.
- [ ] **ST-10:** Verify Sentry dashboard captures 0 false-alarm crash reports.
