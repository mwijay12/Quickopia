# Supabase Free Tier Keep-Alive Architecture & Operator Guide

## 1. Background: The 7-Day Inactivity Pause
Supabase pauses Free-plan projects after **7 consecutive days without incoming API traffic**. When paused:
- Database, Auth, Realtime, and Storage endpoints become inaccessible.
- The mobile app fails to load the catalog.
- The web admin Kanban board ceases updating.
- A human operator must log into `supabase.com/dashboard` to manually unpause the project (which takes 2–5 minutes).

Quickopia is designed to run reliably at zero monthly hosting cost on the Free Tier. To safeguard pilot supermarkets during quiet weeks or test pauses, this repository includes an observable, multi-layer keep-alive system.

---

## 2. Architecture & Components

```
┌───────────────────────────────┐       ┌──────────────────────────────┐
│  GitHub Actions Workflow      │       │  cron-job.org / External     │
│  (.github/workflows/          │       │  Backup Pinger (Independent) │
│   supabase-keepalive.yml)     │       │                              │
└──────────────┬────────────────┘       └──────────────┬───────────────┘
               │ Every 6h                              │ Every 6h (Offset)
               └───────────────────┬───────────────────┘
                                   │ POST /rest/v1/rpc/heartbeat_ping
                                   ▼
                   ┌───────────────────────────────┐
                   │    Supabase Postgres DB       │
                   │    (Migration 0023)           │
                   │                               │
                   │  - system_heartbeat (1 row)   │
                   │  - heartbeat_ping() RPC       │
                   │  - heartbeat_status() RPC     │
                   └───────────────┬───────────────┘
                                   │ Status & Metrics
               ┌───────────────────┴───────────────────┐
               ▼                                       ▼
┌───────────────────────────────┐       ┌──────────────────────────────┐
│  Web Admin Dashboard          │       │  Mobile Flutter App          │
│  (BackendHealthCard.tsx)      │       │  (backend_health_service.dart│
│  - ALIVE (< 26h)              │       │  - Classifies connectivity   │
│  - PINGER STALLED (26h - 7d)  │       │  - Distinguishes empty store │
│  - PAUSED (>= 7d)             │       │    from paused backend       │
└───────────────────────────────┘       └──────────────────────────────┘
```

### 2.1 One-Row Bounded Liveness Marker
- Table: `public.system_heartbeat` (`id = 1` enforced by primary key check constraint).
- Storage footprint: ~120 bytes forever. Zero unbounded row growth on a 500 MB quota.
- Write throttling: `heartbeat_ping()` limits actual database writes to **≤ 1 write per 60 seconds**. Rapid incoming pings do not thrash disk I/O.

### 2.2 Observable Health States
The `heartbeat_status()` RPC classifies the system into three explicit states:
- **`ALIVE`** (Green): A ping was received within the last 26 hours. Project is actively protected.
- **`PINGER_STALLED`** (Amber): No ping received in 26 hours. You have ~6 days of grace window remaining before Supabase pauses.
- **`PAUSED`** (Red): No ping in 7 days. Backend requires manual restoration.

---

## 3. The 60-Day GitHub Actions Trap & Redundancy

> [!WARNING]
> **The 60-Day Trap**: GitHub automatically disables scheduled workflows (`on: schedule`) on public/private repositories that have had **no commit activity for 60 consecutive days**.
> If Quickopia operates without code commits for two months, GitHub will silently suspend the workflow, causing Supabase to pause a week later.

### 3.1 Primary Pinger: GitHub Actions
- Workflow: `.github/workflows/supabase-keepalive.yml`
- Frequency: Runs every 6 hours (`0 */6 * * *`).
- Retries: 4 attempts with exponential backoff (`5s`, `10s`, `20s`, `40s`).
- Requirements: Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to **GitHub Repo Settings → Secrets and variables → Actions**.

### 3.2 Secondary Pinger: cron-job.org (Free Backup)
To defend against the 60-day GitHub cutoff, configure a free job on [cron-job.org](https://cron-job.org):
1. Create a free account at `https://cron-job.org`.
2. Click **Create Cronjob**.
3. **URL**: `https://<YOUR-PROJECT-REF>.supabase.co/rest/v1/rpc/heartbeat_ping`
4. **Execution Schedule**: Every 6 hours (e.g. at minute 30: `30 */6 * * *`).
5. **Request Method**: `POST`
6. **Headers**:
   - `apikey`: `<YOUR_SUPABASE_ANON_KEY>`
   - `Authorization`: `Bearer <YOUR_SUPABASE_ANON_KEY>`
   - `Content-Type`: `application/json`
7. **Request Body**: `{"p_pinger": "cron-job-org"}`
8. **Failure Notification**: Enable email notifications on consecutive failures.

---

## 4. Admin Health Dashboard Integration
The Web Admin portal features the `BackendHealthCard` on the main dashboard (`/dashboard`):
- Displays live backend status (`ALIVE`, `PINGER STALLED`, `PAUSED`).
- Visual grace-window progress bar (showing remaining days/hours before pause).
- Latency indicator and last ping timestamp.
- Direct link to this operator guide if amber or red.

---

## 5. Emergency Unpause Procedure
If the project ever pauses:
1. Navigate to [Supabase Dashboard](https://supabase.com/dashboard).
2. Select the `quickopia` project.
3. Click **Restore Project** (takes 2–3 minutes).
4. Go to GitHub Actions → **Supabase Free Tier Keep-Alive** → Click **Run workflow** (`workflow_dispatch`).
5. Refresh the Quickopia Admin dashboard to confirm the health badge returns to **ALIVE**.
