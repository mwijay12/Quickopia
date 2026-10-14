# 🛒 Quickopia — On-Demand Supermarket, Express Delivery & Click-and-Collect Platform

> **Order groceries in Dar es Salaam. Get them delivered to your door — or walk in, show a 4-digit code, and walk out with your bag already packed.**

![Version](https://img.shields.io/badge/version-1.0.0--pilot-blue)
![Status](https://img.shields.io/badge/status-Production_Ready_Pilot-brightgreen)
![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter)
![Next.js](https://img.shields.io/badge/Next.js-14-black?logo=next.js)
![Supabase](https://img.shields.io/badge/Supabase-Postgres_Auth_Realtime-3ECF8E?logo=supabase)
![Tests](https://img.shields.io/badge/tests-53%2F53_passing-success)
![License](https://img.shields.io/badge/license-Private-orange)

---

## 📑 Table of Contents

1. [🪪 Project Identity](#-section-1-project-identity)
2. [📸 Live System Snapshot](#-section-2-live-system-snapshot)
3. [🏗️ System Architecture](#️-section-3-system-architecture)
4. [📁 Complete File Structure](#-section-4-complete-file-structure)
5. [🔧 Installation & Setup](#-section-5-installation--setup)
6. [🎮 How To Use It](#-section-6-how-to-use-it)
7. [🗄️ Database Schema](#️-section-7-database-schema)
8. [🤖 AI Integration Details](#-section-8-ai-integration-details)
9. [⚠️ Current Limitations & Known Bugs](#️-section-9-current-limitations--known-bugs)
10. [🧩 Modification & Addon Guide](#-section-10-modification--addon-guide)
11. [🚀 Deployment Guide](#-section-11-deployment-guide)
12. [💰 Cost Calculator](#-section-12-cost-calculator)
13. [🗺️ Roadmap](#️-section-13-roadmap)
14. [🎓 Lessons Learned](#-section-14-lessons-learned)
15. [📌 Quick Reference Card](#-section-15-quick-reference-card)

---

# 🪪 SECTION 1: PROJECT IDENTITY

## The Name

**Quickopia** — *Quick* + *Utopia*. Grocery shopping without queues, traffic, or hunting through aisles.

## To a 10-Year-Old 👦

You know how your mom spends two hours in the supermarket and another hour in traffic? Quickopia is an app where she taps on pictures of what she needs, and then either a driver brings everything to the door — or she walks into the shop, shows the cashier a secret 4-digit number, and takes home a bag that was already packed for her.

## To a Developer 👩‍💻

Quickopia is a **production-grade, multi-surface grocery-commerce platform** purpose-built for the Tanzanian urban market. It consists of **four surfaces sharing one Supabase backend**: a Flutter mobile app that serves **both customers and drivers** (dual-role, single binary), a Next.js 14 App Router **web storefront** for browser shoppers, a Next.js 14 **admin & packing portal** with a realtime order Kanban, and a **PostgreSQL backend** with 17 applied migrations — Row Level Security on every table, an atomic `place_order` RPC with `FOR UPDATE` row locks (prevents overselling), a `complete_delivery` RPC guarded by 4-digit pickup codes, an atomic `accept_order_delivery` RPC for driver order claiming, realtime channels for order status and driver GPS, and two serverless AI Edge Functions (bilingual Swahili/English search expansion with a Postgres cache, and an admin-only product-description generator) using a **Groq → Gemini → OpenRouter** provider-fallback chain. Maps are 100% free OpenStreetMap (`flutter_map`) with native Google Maps / Apple Maps hand-off for driver navigation — zero Google Maps API billing.

## The Business Problem It Solves 💼

Supermarket shopping in Dar es Salaam means traffic jams, long queues, and time wasted wandering aisles — while local supermarkets have no practical way to sell online. Existing delivery apps charge heavy commissions and were built for restaurants, not for a supermarket's stock-keeping workflow (packing checklists, shelf stock counts, pickup handoff). Quickopia gives **one supermarket branch** a complete, low-cost digital channel:

| Problem | Quickopia's Answer |
|---|---|
| Customers waste hours shopping | Order in-app or on the web in minutes; track it live |
| "Where should the driver go?" (no street addresses) | Landmark addressing: City → Neighborhood → Landmark → House details, plus an interactive map pin |
| Delivery apps cost too much | Zero-cost stack: Supabase free tier, OpenStreetMap, Vercel Hobby, manual Lipa Namba |
| Cash-based society | Cash on Delivery, Cash at Pickup, and manual **Lipa Namba** (M-Pesa / Tigo Pesa / Airtel Money) |
| Trust ("did they really deliver?") | Customer gets a 4-digit pickup code; the driver **must** enter it to close the order |
| Swahili-speaking shoppers | Bilingual AI search — search *sukari* and find sugar |

## Version & Status

| Field | Value |
|---|---|
| Version | `1.0.0+1` (mobile) / `0.1.0` (web surfaces) |
| Status | 🟢 **Production Ready — Single-Branch Pilot** (Mikocheni, Dar es Salaam) |
| Tests | 53/53 Flutter unit & widget tests · 7/7 storefront routes · 13/13 admin routes compile |
| Database | 17/17 migrations applied cleanly & hardened |
| Platform focus | Android first — iOS **deliberately deferred** (>85% of Tanzanian phones are Android) |

## Who Built It & Why

Built as a 30-prompt, phased solo engineering effort (documented in [`docs/ROADMAP_ONE_PAGE_SUMMARY.md`](docs/ROADMAP_ONE_PAGE_SUMMARY.md)) to prove that one developer can ship a full on-demand retail stack — customer app, driver companion, storefront, admin portal, hardened database, and AI features — with **effectively zero monthly infrastructure cost** during the pilot. The pilot partner is a Dar es Salaam supermarket branch operating on a 10% commission model (`branches.commission_rate = 10.00` in the seed data).

## What Makes It Different 🆚

| Most grocery/delivery products | Quickopia |
|---|---|
| Built for restaurants, retrofitted for groceries | Built around the supermarket workflow: **packing checklists**, stock deltas, Click & Collect handoff |
| Google Maps everywhere → billing traps | **OpenStreetMap pin picker** (free) + native map-app hand-off for navigation (free) |
| Card/wallet payments required | Cash-first: COD, pickup cash, manual Lipa Namba — matches how Tanzania pays today |
| Single app, single role | One Flutter binary, **two roles**: the same APK is the customer app *and* the driver companion |
| English-only search | AI bilingual Swahili ↔ English query expansion with caching so AI is paid once per unique term |
| E-commerce templates with `stock = boolean` | Atomic Postgres RPC with `FOR UPDATE` row locks — **two people can't buy the last packet of sugar** |

---

# 📸 SECTION 2: LIVE SYSTEM SNAPSHOT

*Status as of today — verified against the actual repository, not the plan.*

| Component | Status | What It Does | Tech Used |
|---|---|---|---|
| Flutter Mobile — **Customer** | 🟢 Working | Catalog browsing, category filters, smart search, cart with stock guards, delivery/pickup checkout, OpenStreetMap pin picker, saved addresses, order history, reorder, live order tracking timeline, secure sign-in (admin demo credentials removed) | Flutter 3.5+, Dart, `provider`, `supabase_flutter`, `flutter_map`, `google_fonts` |
| Flutter Mobile — **Driver** (same APK, dual role) | 🟢 Working | 3-tab portal: assigned deliveries with Call/WhatsApp/GPS navigation, available ready order pool with claim/accept action, daily & lifetime earnings reports with settled vs pending payout status, verified driver profile & secure sign out | Same stack + `url_launcher` |
| Web Storefront (`web/storefront`, port 3000) | 🟢 Working | Browser shopping without installing the app, product grid, search, cart drawer, web checkout with map picker, order tracking page, WhatsApp cart share | Next.js 14 App Router, React 18, Tailwind, `@supabase/ssr` |
| Admin & Packing Portal (`web/admin`, port 3001) | 🟢 Working | Role-gated login (middleware), realtime order Kanban (New → Packing → Ready → Dispatched), packing checklist modal, dispatch modal, catalog CRUD with Cloudinary images, stock delta adjustments, driver roster + mid-shift reassignment, analytics dashboard | Next.js 14, Tailwind, `lucide-react`, Supabase SSR |
| Supabase PostgreSQL | 🟢 Working | 7 core tables + support tables, 6 enums, RLS on every table, atomic `place_order`, `complete_delivery`, `accept_order_delivery`, admin status transitions, analytics RPCs, stock-adjustment RPC, cancellation with stock restoration, referral codes, search cache | PostgreSQL (Supabase), 17 migrations |
| Supabase Auth | 🟢 Working | Email/password sign-up; `on_auth_user_created` trigger auto-creates a `profiles` row with role `customer`; roles: `customer` / `driver` / `admin` | Supabase Auth (GoTrue) |
| Supabase Realtime | 🟢 Working | Live order-status timeline for customers; driver assignment appears instantly in the driver queue; order chime on admin Kanban | Supabase Realtime (WebSockets) |
| Edge Function — `generate-product-description` | 🟢 Working | Admin-only AI product descriptions; provider chain Groq → Gemini → OpenRouter; rate limit 10/min; output sanitizing + 15–450 char quality gate | Deno, Groq `llama-3.3-70b`, Gemini 1.5 Flash |
| Edge Function — `expand-search-query` | 🟢 Working | Bilingual Swahili/English query expansion; Postgres cache (`search_query_cache`) checked before any AI call; 1.5s client timeout with silent fallback to direct search | Deno, same provider chain |
| Image hosting | 🟢 Working | Product image upload from Admin Portal via unsigned Cloudinary preset | Cloudinary |
| Error monitoring | 🟢 Working | Sentry across all 4 surfaces (Flutter, storefront, admin, edge functions); non-PII tagging, 10% sampling | `sentry_flutter` ^8.14, `@sentry/nextjs` ^10 |
| Payments — COD / Cash at Pickup / manual Lipa Namba | 🟡 Working (manual) | Customer selects method at checkout; driver records paid status at handoff; **reconciliation is manual** — no gateway API yet | `payment_method` enum + `complete_delivery` RPC |
| Referrals | 🟡 Working (codes live) | Unique `QK-XXXXX` codes with abuse-guarded redemption (migration `0014`) — reward fulfillment not automated yet | Postgres RPC |
| iOS app | 🟡 Deferred | Code is 100% cross-platform; postponed for pilot (see deployment checklist §3B) | — |
| Automated mobile-money gateway (AzamPay / Selcom / Beem USSD push) | 🔴 Not started | `payment_method = mobile_money` enum value already reserved in schema, waiting on gateway integration | — |
| SMS notifications (Beem Africa / Twilio) | 🔴 Not started | Designed in roadmap Prompt 24; no edge function or secret present yet | — |
| Push notifications (FCM) | 🔴 Not started | Not designed yet | — |
| Multi-branch operations UI | 🔴 Not started | Schema supports many branches (`branch_id` everywhere); admin UI assumes one branch | — |
| CI/CD pipeline | 🔴 Not started | Tests/builds run manually; no GitHub Actions | — |

### ✅ Fully working right now
- **End-to-end order lifecycle**: place → pack → ready → dispatch → deliver with pickup code, live across all 4 surfaces
- **Atomic order placement** — race-condition-proof stock decrement (`FOR UPDATE` row locks)
- **Click & Collect** — order ahead, 4-digit code, staff handoff in under a minute
- **Doorstep delivery** — map pin + landmark address, native navigation hand-off, driver call/WhatsApp
- **Admin Kanban** with sound chime, packing checklist, driver dispatch, mid-shift driver reassignment
- **Catalog management** with Cloudinary uploads and concurrency-safe stock adjustments
- **Analytics dashboard** — revenue, order counts, top products, driver performance, low-stock alerts
- **Bilingual smart search** with Postgres cache (AI is paid once per unique term, then free forever)
- **AI product descriptions** for admins — draft-review only; AI never writes directly to the database
- **53/53 Flutter tests passing**; both Next.js production builds compile clean
- Referral codes, reorder basket, WhatsApp cart share, saved addresses, customer cancellation (pre-packing) with automatic stock restoration

### 🟡 Partially working
- **Payments**: COD / Lipa Namba work but reconciliation is a human with a notebook; `payment_status` is only updated by the driver at handoff
- **Referrals**: codes generate and redeem, but there is no automated reward/credit ledger
- **Driver GPS broadcast**: realtime channel + visibility policies exist (migration `0007`); rendering the moving driver on the customer's timeline is basic
- **Analytics**: solid read metrics, but no CSV export, no date-range presets, no customer cohorting
- **Web ↔ mobile parity**: storefront order schema matches mobile 1:1, but visual/UX polish differs slightly between surfaces

### 🔴 Planned but not started
Automated mobile money (AzamPay/Selcom/Beem) · SMS pipeline · FCM push notifications · multi-branch admin UI · CI/CD · iOS release · loyalty/credit wallet · offline mode

### 🗑️ Tried and abandoned — and why
- **The original repo identity**: this folder started life as a static Flutter UI template ("E-commerce-App-UI"). The static-UI approach was **replaced entirely** by the full-stack Quickopia architecture — the folder name is the only survivor. *Suggestion: rename the repo/folder to `quickopia` to stop confusing future-you.*
- **Firebase / Firestore as backend**: early READMEs mention Firestore. **Abandoned in favor of Supabase Postgres** because the #1 correctness requirement — atomic, race-proof stock decrement at checkout — needs `FOR UPDATE` row locks and stored procedures, which Firestore cannot express. Postgres also gave RLS, RPCs, and Realtime in one free-tier service.
- **Vite for the web apps**: the early plan said Vite; **abandoned for Next.js 14 App Router** for server-side session handling (`@supabase/ssr`), route-level code splitting, and one-click Vercel deploys.
- **Google Maps SDK in-app**: abandoned at design time (billing + credit-card wall) → OpenStreetMap + native intent hand-off. This decision preserved the project's "zero-cost" thesis.
- **iOS for pilot**: deferred, not abandoned — a $99/yr fee and slow review cycles add nothing while validating on Android-first Tanzania.

---

# 🏗️ SECTION 3: SYSTEM ARCHITECTURE

## The Full Picture

```
                                ┌─────────────────────────────┐
                                │          HUMANS             │
                                │  Customer │ Driver │ Admin  │
                                └─────┬─────────┬───────┬─────┘
                                      │         │       │
                ┌─────────────────────┘         │       └──────────────────────┐
                ▼                               ▼                              ▼
┌───────────────────────────┐   ┌───────────────────────────┐   ┌───────────────────────────┐
│  FLUTTER MOBILE APP       │   │  WEB STOREFRONT           │   │  ADMIN & PACKING PORTAL   │
│  (customer AND driver,    │   │  web/storefront  :3000    │   │  web/admin      :3001     │
│   role picked at login)   │   │  Next.js 14 App Router    │   │  Next.js 14 + middleware  │
│                           │   │  + CartContext (React)    │   │  role-gate: admin only    │
│  lib/main.dart            │   └────────────┬──────────────┘   └────────────┬──────────────┘
│   └ SentryService.init    │                │                               │
│      └ SupabaseConfig     │                │                               │
│         └ QuickopiaApp    │                │                               │
│            └ AuthGate ──► │                │                               │
│   screens/customer/*      │                │                               │
│   screens/driver/*        │                │                               │
└────────────┬──────────────┘                │                               │
             │                               │                               │
             │      ALL THREE SURFACES SPEAK TO THE SAME BACKEND             │
             ▼                               ▼                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              SUPABASE  (free-tier backend)                              │
│                                                                                         │
│  ┌──────────────┐  ┌───────────────────────┐  ┌──────────────────────────────────────┐  │
│  │ AUTH (GoTrue)│  │ POSTGRES              │  │ REALTIME (WebSockets)                │  │
│  │ email/pass   │  │ branches              │  │ • orders row changes → customer      │  │
│  │ on_auth_user │─►│ profiles              │  │   timeline + driver queue + Kanban   │  │
│  │ _created     │  │ categories            │  │ • driver GPS location broadcast      │  │
│  │ trigger →    │  │ products  addresses   │  └──────────────────────────────────────┘  │
│  │ profiles row │  │ orders    order_items │  ┌──────────────────────────────────────┐  │
│  └──────────────┘  │ search_query_cache    │  │ EDGE FUNCTIONS (Deno, serverless)    │  │
│                    │ + referral tables     │  │ 1. expand-search-query               │  │
│                    │                       │  │     cache→AI→cache (bilingual)       │──┼──► GROQ llama-3.3-70b
│  RLS ON EVERY      │ place_order (RPC)     │  │ 2. generate-product-description      │──┼──► GEMINI 1.5 Flash
│  TABLE             │ complete_delivery     │  │     admin-only, rate-limited         │  │   (fallback: OpenRouter)
│  (customer/driver/ │ admin status RPCs     │  └──────────────────────────────────────┘  │
│  admin enforced    │ analytics RPCs        │  ┌──────────────────────────────────────┐  │
│  in SQL)           │ stock adjust RPC      │  │ STORAGE: none for images — Cloudinary│  │
│                    └───────────────────────┘  │ unsigned preset (admin uploads only) │  │
│                                               └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────┘
             │                               │                        │
             ▼                               ▼                        ▼
   ┌───────────────────┐         ┌───────────────────┐      ┌───────────────────┐
   │ OPENSTREETMAP     │         │ NATIVE MAP APPS   │      │ SENTRY (all 4     │
   │ flutter_map tiles │         │ google.navigation │      │ surfaces, 10%     │
   │ (free pin picker) │         │ intents (free)    │      │ sampling)         │
   └───────────────────┘         └───────────────────┘      └───────────────────┘
             │
             ▼
   ┌───────────────────┐
   │ WHATSAPP / DIALER │  url_launcher: cart share, customer contact
   └───────────────────┘
```

**One sentence version:** every surface talks to one Postgres over RLS-guarded REST; writes that need correctness go through Postgres RPC functions; anything that needs AI goes through a Deno Edge Function that tries Groq, then Gemini, then OpenRouter; realtime changes fan out over WebSockets; everything that crashes lands in Sentry.

## Step-by-Step: What Happens When a Customer Places a Delivery Order (Mobile)

The most common action in the system. Here is the exact execution path, file by file:

1. **`mobile/lib/main.dart`** — `main()` runs: `WidgetsFlutterBinding.ensureInitialized()` → `SentryService.init()` wraps everything → `SupabaseConfig.initialize()` loads `mobile/.env` via `flutter_dotenv` and calls `Supabase.initialize(url, anonKey)` → `runApp(QuickopiaApp())`.
2. **`mobile/lib/app.dart`** — `QuickopiaApp` registers 5 `ChangeNotifierProvider`s (`Auth`, `Catalog`, `Cart`, `OrderHistory`, `DriverOrders`) and sets `home: AuthGate`.
3. **`mobile/lib/screens/auth/auth_gate.dart`** — listens to the Supabase auth stream. No session → `LoginScreen`. Session → reads `profiles.role` and routes: customer → `CustomerShell`, driver → `DriverShell`, admin → portal on web.
4. **`mobile/lib/screens/customer/customer_home_screen.dart`** — `CatalogProvider` fetches `categories` and `products` (RLS: only `is_available = true` rows are visible to non-admins). User taps a product card → `CartProvider.addItem(...)`. `CartProvider` guards quantity against `stock_quantity` and persists the cart to `shared_preferences`.
5. **`mobile/lib/widgets/cart_sticky_bar.dart`** — shows live subtotal via `utils/currency_formatter.dart` (TZS) → tap → `Navigator.push(CartScreen)`.
6. **`mobile/lib/screens/customer/checkout_screen.dart`** — user picks fulfillment (`FulfillmentToggle`: `delivery`/`pickup`), picks/enters landmark address (`AddressFormSheet`, optional `MapPinPicker` with OpenStreetMap), phone (validated by `utils/validators.dart` for Tanzanian 07XX/06XX formats), payment (`PaymentMethodSelector`: `cod` | `lipa_namba`), and taps **Place Order**.
7. The screen builds a `CheckoutData` model and calls **`OrderService.placeOrder(...)`** (`mobile/lib/services/order_service.dart`), which maps cart items to `[{"product_id": "...", "quantity": n}]`.
8. `OrderService` invokes **`_client.rpc('place_order', params: {...})`** — one HTTPS call to PostgREST → the Postgres function `place_order` (`supabase/migrations/0004_order_placement_function.sql`) runs **inside the database**:
   - Opens a transaction and takes **`SELECT ... FOR UPDATE`** locks on every requested product row (concurrent checkouts are serialized here — no overselling, ever)
   - Validates each product: exists → `is_available` → `stock_quantity >= requested`
   - Generates the order number `ORD-YYYY-0001` (sequence) and a random 4-digit `pickup_code`
   - Inserts the `orders` header (`status='placed'`, `payment_status='pending'`)
   - Inserts one `order_items` row per product, **decrements `products.stock_quantity`**
   - Computes `subtotal_tzs` and `total_amount_tzs = subtotal + delivery_fee_tzs` (flat **TZS 3,000** from `mobile/lib/config/app_constants.dart`)
   - Returns the new order `id`. Direct client `INSERT` into `orders` is blocked by RLS (`with check (false)`) — this RPC is the only door in.
9. **Back in Dart** — `fetchOrderById(orderId)` re-selects `orders + order_items(*)` and parses it into the `Order` model. Postgres errors are translated to human sentences by `_parseRpcError()` ("Sorry, one or more items just sold out while you were checking out…").
10. **`Navigator.push(OrderSuccessScreen(order))`** — the customer sees the order number and (for pickup) their 4-digit code, then lands back in `CustomerShell` where **`OrderTrackingProvider`** subscribes to the Supabase Realtime channel for that order row.
11. **Admin side** — the new order row fires a Realtime event → `web/admin/app/dashboard` Kanban plays the chime (`lib/sound.ts`) and the card appears in **New**. Staff: New → Packing (checklist modal) → Ready → **DispatchModal** assigns a driver (sets `orders.driver_id`).
12. **Driver side** — `DriverOrdersProvider` sees the assignment; the order card shows customer phone, landmark, and a **Navigate** button that fires `google.navigation:q=lat,lng` via `utils/navigation_launcher.dart` (free native GPS).
13. **Handoff** — driver opens `MarkDeliveredSheet`, asks the customer for the 4-digit code, enters it → **`complete_delivery` RPC** (migration `0008`) verifies the code against `orders.pickup_code`, confirms the driver is still assigned, sets `status='delivered'` and `payment_status`, and only then does the driver get paid.
14. **Customer side** — the Realtime event flips their timeline to "Delivered". If anything threw along the way, Sentry captured it with non-PII context.

## The Same Order, Storefront Flavor

`web/storefront/app/checkout/page.tsx` does steps 6–9 with React state instead of `provider`: `CartContext` → `lib/orders.ts` → same `place_order` RPC → redirect to `/order/[id]` (`OrderStatusTimeline` component). **Same database door, same guarantees.**

---

# 📁 SECTION 4: COMPLETE FILE STRUCTURE

Every file, with a one-line explanation. (Generated dirs — `build/`, `.dart_tool/`, `node_modules/`, `android/`, `ios/` — are omitted.)

```
E-commerce-App-UI-Flutter-master/      # ⚠️ legacy folder name from the original UI template — suggest renaming to quickopia/
├── README.md                          # THIS document — the living project manual
├── docs/
│   ├── ROADMAP_ONE_PAGE_SUMMARY.md    # The 30-prompt build history, phase by phase, + production status
│   └── PRODUCTION_DEPLOYMENT_CHECKLIST.md  # Ops runbook: Supabase promotion, Vercel deploys, Play Store, rollback, smoke tests
├── assets/
│   ├── icon.png / black icon.png / transparent logo.png  # App icons & logo variants (PNG)
│   ├── logo.png                       # Primary logo
│   ├── quickopia_icon.svg             # Vector app icon
│   └── quickopia_logo_horizontal(_white).svg  # Wordmarks for light/dark surfaces
│
├── mobile/                            # 📱 FLUTTER APP — customer + driver in one binary
│   ├── pubspec.yaml                   # Manifest: name=quickopia, v1.0.0+1, SDK >=3.5.0, deps, .env registered as asset
│   ├── .env                           # Local secrets (NEVER commit): SUPABASE_URL, SUPABASE_ANON_KEY, CLOUDINARY_CLOUD_NAME, SENTRY_DSN
│   ├── .env.example                   # Template for the above
│   ├── analysis_options.yaml          # flutter_lints ^4.0.0 rules
│   ├── android/                       # Standard Flutter Android host (manifest, gradle, key.properties.example)
│   ├── lib/
│   │   ├── main.dart                  # Entry point: Sentry init → Supabase init → runApp(QuickopiaApp)
│   │   ├── app.dart                   # Root widget: MultiProvider (5 providers) + MaterialApp + AuthGate
│   │   ├── config/
│   │   │   ├── supabase_config.dart   # dotenv load, Supabase.initialize, isConfigured guard, placeholder fallback
│   │   │   └── app_constants.dart     # flatDeliveryFeeTzs = 3000 TZS; Dar map center (-6.7924, 39.2083)
│   │   ├── models/                    # Pure data classes with fromMap/toMap
│   │   │   ├── address_model.dart     # Saved customer address (label, landmark, lat/lng, is_default)
│   │   │   ├── branch_model.dart      # Supermarket branch
│   │   │   ├── cart_item_model.dart   # Cart line: product snapshot + quantity
│   │   │   ├── category_model.dart    # Category (name, name_sw, icon, display_order)
│   │   │   ├── checkout_data_model.dart # Immutable bundle for OrderService (fulfillment, address, phone, payment, fee)
│   │   │   ├── driver_profile_model.dart # Driver profile + employment type
│   │   │   ├── order_item_model.dart  # Ordered line item (price frozen at purchase time)
│   │   │   ├── order_model.dart       # Order header incl. status, pickup code, totals
│   │   │   ├── product_model.dart     # Product (title, price_tzs, unit, image, stock, flags)
│   │   │   └── profile_model.dart     # profiles row (role: customer/driver/admin)
│   │   ├── providers/                 # ChangeNotifier state management
│   │   │   ├── auth_provider.dart     # Session state, sign in/out, role lookup
│   │   │   ├── catalog_provider.dart  # Categories + products fetch/search/filter
│   │   │   ├── cart_provider.dart     # Cart add/remove/qty, stock guards, shared_preferences persistence
│   │   │   ├── order_history_provider.dart # Customer past orders + reorder
│   │   │   ├── driver_orders_provider.dart # Driver queue + shift/earnings counters
│   │   │   └── order_tracking_provider.dart # Realtime subscription for one order's status
│   │   ├── screens/
│   │   │   ├── splash_screen.dart     # Cold-start branded splash
│   │   │   ├── auth/
│   │   │   │   ├── auth_gate.dart     # Session listener → route by role (customer/driver)
│   │   │   │   ├── login_screen.dart  # Email/password sign-in
│   │   │   │   └── signup_screen.dart # Sign-up (full name, TZ phone validation, password)
│   │   │   ├── customer/
│   │   │   │   ├── customer_shell.dart # Bottom-nav shell (home/cart/orders/account)
│   │   │   │   ├── customer_home_screen.dart # Catalog grid, category chips, search bar
│   │   │   │   ├── cart_screen.dart   # Cart lines, quantity steppers, subtotal
│   │   │   │   ├── checkout_screen.dart # Fulfillment toggle, address, phone, payment, place order
│   │   │   │   ├── order_success_screen.dart # Confirmation + pickup code display
│   │   │   │   ├── order_history_screen.dart # Past orders, live timeline, reorder
│   │   │   │   ├── account_screen.dart # Profile edit, addresses, referral code, logout
│   │   │   │   └── saved_addresses_screen.dart # Address book CRUD
│   │   │   └── driver/
│   │   │       ├── driver_shell.dart  # Driver multi-tab shell (Deliveries, Reports & Payout, Profile)
│   │   │       ├── driver_available_orders_view.dart # Available order pool + claim/accept delivery
│   │   │       ├── driver_reports_view.dart # Daily & lifetime earnings metrics, settled vs pending payout status
│   │   │       └── driver_profile_view.dart # Driver profile card, active status, branch & sign out
│   │   ├── services/                  # ALL Supabase calls live here (screens never touch the client directly)
│   │   │   ├── auth_service.dart      # signUp / signIn / signOut
│   │   │   ├── profile_service.dart   # profiles reads/updates
│   │   │   ├── catalog_service.dart   # categories + products queries
│   │   │   ├── branch_service.dart    # branch info
│   │   │   ├── order_service.dart     # place_order RPC + fetchOrderById + error translation
│   │   │   ├── order_history_service.dart # Customer order list
│   │   │   ├── order_tracking_service.dart # Realtime channel subscription
│   │   │   ├── driver_order_service.dart # Assigned orders + complete_delivery RPC + error translation
│   │   │   ├── driver_info_service.dart  # Driver profile/earnings
│   │   │   ├── address_service.dart   # Address book CRUD
│   │   │   ├── smart_search_service.dart # 3-tier expansion: memory cache → Postgres cache → Edge Function (1.5s timeout)
│   │   │   └── sentry_service.dart    # Defensive Sentry init (won't crash if DSN missing), 10% sampling
│   │   ├── theme/app_theme.dart       # Design system: colors, typography, component themes
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart # TZS formatting (intl)
│   │   │   ├── navigation_launcher.dart # google.navigation / maps URL intents
│   │   │   └── validators.dart        # Tanzanian phone validation/normalization (07XX/06XX/+255…)
│   │   └── widgets/
│   │       ├── quickopia_logo.dart    # Brand logo widget (SVG, light/dark)
│   │       ├── product_card.dart      # Catalog tile (image, price, stock badge)
│   │       ├── category_chip_list.dart # Horizontal category filter chips
│   │       ├── catalog_search_bar.dart # Search input wired to SmartSearchService
│   │       ├── cart_sticky_bar.dart   # Bottom bar with subtotal → CartScreen
│   │       ├── quantity_stepper.dart  # +/- quantity control
│   │       ├── fulfillment_toggle.dart # Delivery ↔ Pickup segmented control
│   │       ├── address_form_sheet.dart # Bottom-sheet address form (+ map pin)
│   │       ├── map_pin_picker.dart    # flutter_map fullscreen pin picker
│   │       ├── payment_method_selector.dart # cod | lipa_namba radio cards
│   │       ├── order_status_timeline.dart # placed→…→delivered visual
│   │       ├── order_status_badge.dart # Colored status chip
│   │       ├── driver_order_card.dart # Driver queue card (contact + navigate)
│   │       └── mark_delivered_sheet.dart # 4-digit pickup code entry sheet
│   └── test/                          # 53 tests, all passing
│       ├── widget_test.dart           # App smoke test
│       ├── auth_gate_test.dart        # Role routing
│       ├── catalog_models_test.dart   # Category/Product parsing
│       ├── profile_model_test.dart    # Profile role parsing
│       ├── checkout_models_test.dart  # Branch/CheckoutData mapping
│       ├── order_and_timeline_test.dart # Order/OrderItem + timeline logic
│       ├── cart_provider_test.dart    # Cart logic + stock guards
│       ├── cart_screen_test.dart      # Cart UI
│       ├── customer_home_screen_test.dart # Home UI + providers
│       ├── phone_validator_test.dart  # TZ phone formats
│       └── prompt_8_and_9_test.dart   # place_order payload + driver completion flows
│
├── web/                               # 🌐 TWO Next.js apps (deploy separately to Vercel)
│   ├── README.md                      # Web quick start + env vars
│   ├── storefront/                    # PUBLIC — customers without the app
│   │   ├── package.json               # next 14.2.24, react 18, @supabase/ssr, @sentry/nextjs; dev on :3000
│   │   ├── .env.example               # NEXT_PUBLIC_SUPABASE_URL/_ANON_KEY, NEXT_PUBLIC_BRANCH_WHATSAPP_NUMBER
│   │   ├── .env.local                 # Local secrets (never commit)
│   │   ├── next.config.mjs / tailwind.config.ts / postcss.config.js / tsconfig.json
│   │   ├── vercel.json                # Vercel deploy config
│   │   ├── sentry.client/edge/server.config.ts # Sentry wiring for all Next runtimes
│   │   ├── app/
│   │   │   ├── layout.tsx / page.tsx  # Root layout + home (hero + product grid)
│   │   │   ├── login/page.tsx         # Customer sign-in
│   │   │   ├── checkout/page.tsx      # Web checkout (address, map pin, payment)
│   │   │   └── order/[id]/page.tsx    # Order tracking page
│   │   ├── components/
│   │   │   ├── Navbar / Hero / ProductGrid / ProductCard / CategoryFilter / SearchBar
│   │   │   ├── CartDrawer.tsx         # Slide-out cart
│   │   │   ├── OrderStatusTimeline.tsx # Live status steps
│   │   │   └── checkout/              # AddressForm, FulfillmentToggle, MapPinPickerModal, OrderSummary, PaymentMethodSelector
│   │   ├── context/CartContext.tsx    # React cart state
│   │   └── lib/
│   │       ├── supabase/client.ts / server.ts # Browser & server Supabase clients
│   │       └── auth.ts / branch.ts / data.ts / orders.ts / types.ts / whatsapp.ts # Domain logic + WhatsApp share builder
│   │
│   └── admin/                         # PRIVATE — supermarket staff
│       ├── package.json               # Same stack as storefront; dev on :3001
│       ├── middleware.ts              # THE authorization boundary: session refresh + role==='admin' check on every page request
│       ├── .env.example               # + SUPABASE_SERVICE_ROLE_KEY, Cloudinary, GEMINI_API_KEY, OPENROUTER_API_KEY
│       ├── app/
│       │   ├── page.tsx / login/page.tsx / access-denied/page.tsx
│       │   ├── api/ai/generate-description/route.ts # Proxies to the edge function with server-side key
│       │   ├── api/drivers/route.ts + [id]/route.ts # Driver CRUD endpoints
│       │   └── dashboard/
│       │       ├── layout.tsx / page.tsx # Shell + Kanban home
│       │       ├── analytics/page.tsx # Business metrics
│       │       ├── catalog/page.tsx   # Products + categories CRUD
│       │       └── drivers/page.tsx   # Driver roster
│       ├── components/
│       │   ├── DashboardShell.tsx / LogoutButton.tsx / ui/QuickopiaLogo.tsx
│       │   ├── kanban/                # OrderKanbanBoard, OrderColumn, OrderCard, DispatchModal, PackingChecklistModal, CompletePickupModal, CancelOrderDialog
│       │   ├── catalog/               # ProductTable, ProductFormModal, CategoryTable, CategoryFormModal, ImageUploadField
│       │   ├── drivers/               # DriverTable, AddDriverModal, EditDriverModal, ReassignDriverModal, DriverHistoryTable
│       │   └── analytics/             # MetricCard, StatusBreakdownCard, TopProductsTable, DriverPerformanceTable, LowStockAlertCard
│       └── lib/
│           ├── supabase/client.ts / server.ts / admin.ts / middleware.ts # anon clients + service-role admin client (server only!)
│           └── orders.ts / catalog.ts / drivers.ts / analytics.ts / cloudinary.ts / sound.ts / types.ts
│
├── supabase/                          # 🗄️ BACKEND — schema, policies, functions
│   ├── config.toml                    # Supabase CLI project config
│   ├── schema_full.sql                # ALL-IN-ONE schema for the SQL Editor (tables + RPCs + RLS + seed)
│   ├── functions/
│   │   ├── _shared/sentry.ts          # captureEdgeError helper for edge functions
│   │   ├── expand-search-query/index.ts # Bilingual query expansion: cache → AI → cache write, graceful fallback
│   │   └── generate-product-description/index.ts # Admin-only AI copy: provider chain, rate limit, sanitize, quality gate
│   └── migrations/                    # 0001…0017, applied in order (see Section 7 table)
└── .kilo/ .kilocode/ .vscode/         # Editor/agent workspace config (not runtime code)
```

---

# 🔧 SECTION 5: INSTALLATION & SETUP

Written for someone who has never run this project before.

## Prerequisites (download these first)

| Tool | Version | Download | Why you need it |
|---|---|---|---|
| **Flutter SDK** | ≥ 3.5.0 (Dart ≥ 3.5) | https://docs.flutter.dev/get-started/install/windows | Builds the mobile app |
| **Android Studio** (or VS Code + Flutter extension) | latest | https://developer.android.com/studio | Android SDK, emulator, platform tools |
| **Node.js** | 18+ (20 LTS recommended) | https://nodejs.org | Runs both Next.js web apps |
| **npm** | ships with Node | — | Installs web dependencies |
| **Supabase account** | free | https://supabase.com | Database, auth, realtime, edge functions |
| **Supabase CLI** (optional but recommended) | latest | https://supabase.com/docs/guides/cli | Deploying edge functions & migrations |
| **Git** | latest | https://git-scm.com | Cloning the repo |
| **A phone or emulator** | Android 8+ | — | Running the app |

Verify your toolchain before starting:

```bash
flutter doctor        # all checkboxes green except iOS (fine on Windows)
node --version        # v18.x or v20.x
npm --version
```

## Environment Variables (every one, and where to get it)

### `mobile/.env` (copy from `mobile/.env.example`)
| Variable | Where to get it | What it does |
|---|---|---|
| `SUPABASE_URL` | Supabase Dashboard → your project → **Settings → API → Project URL** | Backend endpoint. Falls back to a harmless placeholder if missing (app boots, shows empty catalog) |
| `SUPABASE_ANON_KEY` | Same page → **Project API keys → anon public** | Public client key — safe to ship in the app because RLS guards the data |
| `CLOUDINARY_CLOUD_NAME` *(optional)* | cloudinary.com → Dashboard | Referenced by the app config for future image features |
| `SENTRY_DSN` *(optional)* | sentry.io → Settings → Client Keys | Crash reporting; app runs fine without it (defensive init) |

> ⚠️ **The `.env` file is registered as a Flutter asset in `pubspec.yaml`. After creating or editing it, run `flutter clean` then rebuild, or the file won't be bundled.**

### `web/storefront/.env.local` (copy from `web/storefront/.env.example`)
| Variable | Where to get it | What it does |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase → Settings → API | Backend endpoint |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase → API → anon public | Public client key |
| `NEXT_PUBLIC_BRANCH_WHATSAPP_NUMBER` | Your branch's WhatsApp number, format `255700000000` | Powers "Order via WhatsApp" / cart share |

### `web/admin/.env.local` (copy from `web/admin/.env.example`)
| Variable | Where to get it | What it does |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase → Settings → API | Same as storefront |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → API → **service_role** (secret!) | Server-side only. Bypasses RLS. **Never** expose to the browser, never prefix with `NEXT_PUBLIC_` |
| `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` | Cloudinary dashboard | Product image uploads |
| `NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET` | Cloudinary → Settings → Upload → unsigned preset (e.g. `quickopia_products`) | Allows direct browser upload |
| `GEMINI_API_KEY` | https://aistudio.google.com/apikey | AI descriptions (fallback provider) |
| `OPENROUTER_API_KEY` | https://openrouter.ai/keys | AI fallback chain last resort |

### Supabase Edge Function secrets (set once per project)
```bash
supabase secrets set GROQ_API_KEY="YOUR_GROQ_KEY_HERE"            # from console.groq.com — preferred, fastest
supabase secrets set GEMINI_API_KEY="YOUR_GEMINI_KEY_HERE"          # from aistudio.google.com/apikey
supabase secrets set OPENROUTER_API_KEY="YOUR_OPENROUTER_KEY_HERE"    # from openrouter.ai/keys
supabase secrets set SENTRY_DSN="YOUR_SENTRY_DSN_HERE"
```
The provider chain picks the **first key that exists**: `GROQ_API_KEY` → `GEMINI_API_KEY` → `OPENROUTER_API_KEY`. Having at least one is enough.

## Step-by-Step Setup (in this exact order)

### Step 1 — Database (everything depends on it)
1. Create a project at https://supabase.com (choose a region close to East Africa, e.g. `eu-central-1` / `eu-west-2`).
2. Open **SQL Editor → New query**, paste the entire contents of [`supabase/schema_full.sql`](supabase/schema_full.sql), click **Run**.
   ✅ *Expected output:* `Success. No rows returned` — this creates all tables, RPCs, RLS policies, and the seed branch + 9 categories (products are added via the Admin Portal later).
   *(Alternative: apply the 16 files in `supabase/migrations/` in numeric order — this is what production uses.)*
3. Deploy the two Edge Functions:
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   supabase functions deploy expand-search-query
   supabase functions deploy generate-product-description
   supabase secrets set GROQ_API_KEY="..."   # see table above
   ```
   ✅ *Expected output:* `Deployed Functions ... ok` for each.

### Step 2 — Mobile app
```bash
cd mobile
flutter pub get                 # ✅ "Got dependencies!"
cp .env.example .env            # then paste your SUPABASE_URL + SUPABASE_ANON_KEY
flutter clean                   # only needed first time / after editing .env
flutter run                     # ✅ app boots to splash → login screen
```
✅ *Verify:* the console prints `✅ Quickopia: Supabase initialized with project credentials.` The app shows the login screen. Sign up → you land in the customer shell (empty catalog until an admin adds products).

### Step 3 — Storefront (port 3000)
```bash
cd web/storefront
npm install                     # ✅ adds ~300 packages, ~1–2 min
cp .env.example .env.local      # paste URL, anon key, WhatsApp number
npm run dev                     # ✅ "ready on http://localhost:3000"
```

### Step 4 — Admin portal (port 3001)
```bash
cd web/admin
npm install
cp .env.example .env.local      # paste URL, anon key, service_role, Cloudinary, GEMINI_API_KEY
npm run dev                     # ✅ "ready on http://localhost:3001"
```

### Step 5 — Make yourself the admin (SQL Editor, one line)
```sql
update profiles set role = 'admin' where phone = '+255700000000';
```
Sign in at `localhost:3001` with that account → you're in the Kanban.

### ✅ Full verification checklist
```bash
cd mobile  && flutter test      # ✅ All tests passed! (53 tests)
cd web/storefront && npm run build  # ✅ 7/7 routes compiled
cd web/admin      && npm run build  # ✅ 13/13 routes compiled
```
Then run the 10-step smoke test in [`docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md`](docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md) §6 (admin gate → Kanban → catalog → order → chime → status flow → driver assignment → pickup code → Sentry silence).

## 🔥 The Most Common Setup Errors (and exact fixes)

| Symptom | Cause | Fix |
|---|---|---|
| `Unable to load asset: .env` on app start | `mobile/.env` doesn't exist (it IS a pubspec asset) | Create it from `.env.example`, then `flutter clean && flutter run` |
| App boots but catalog is empty & console shows `Supabase initialized with placeholder credentials` | `.env` values empty or still say `placeholder` | Paste real URL + anon key; ensure no quotes/spaces; `flutter clean` |
| ` flutter run` shows `Failed host lookup` on emulator | Emulator has no internet (esp. Windows DNS) | Cold-boot the emulator, or test on a real device with mobile data |
| App crashes with `LateInitializationError: _client` style errors | Supabase init failed silently | Check console for `❌ Quickopia: Supabase initialization error` — usually a malformed URL |
| `npm run dev` → `Port 3000 is already in use` | Storefront already running | Kill it or run `npx next dev -p 3010` |
| Admin login loops back to `/login` | You created the account **before** promoting role, or middleware session cookie blocked | Log out/in again after the SQL update; check cookie consent/browser blocking |
| Admin shows `/access-denied` | Your `profiles.role` isn't `admin` | Re-run the Step 5 SQL for the correct phone |
| AI description → `500 AI provider is not configured` | No edge secret set | `supabase secrets set GROQ_API_KEY=...` then redeploy not needed — secrets are read at runtime |
| Search never expands (always literal) | Edge function not deployed or 1.5s timeout | It's **by design** to fall back silently; deploy the function and check Supabase → Edge Functions logs |
| `flutter pub get` version solve failure | Flutter SDK < 3.5 | `flutter upgrade` |
| Next.js build error mentioning `@next/swc-wasm-nodejs` | Windows native binary hiccup | `npm install` again (it's in `optionalDependencies`) or `npm i @next/swc-win32-x64-msvc` |

---

# 🎮 SECTION 6: HOW TO USE IT

Real examples with real data. There are no REST endpoints of ours to `curl` directly for orders (writes go through Postgres RPCs), so examples show both the Dart/TS calls **and** the raw Supabase request that actually travels over the wire.

## Feature 1 — Place an order (the core of everything)

**What it does in plain English:** takes the customer's cart, locks the stock, creates the order, decrements inventory — atomically.

**Exact request** (PostgREST RPC — this is what `OrderService.placeOrder` and `web/storefront/lib/orders.ts` both send):

```bash
curl -X POST "https://YOUR-PROJECT.supabase.co/rest/v1/rpc/place_order" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer CUSTOMER_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "p_customer_id": "9d1b...uuid",
    "p_branch_id": "1a2b...uuid",
    "p_fulfillment_type": "delivery",
    "p_delivery_city": "Dar es Salaam",
    "p_delivery_neighborhood": "Mikocheni",
    "p_delivery_landmark": "Near Shoppers Plaza",
    "p_delivery_house_details": "Blue gate, 2nd floor",
    "p_delivery_latitude": -6.7924,
    "p_delivery_longitude": 39.2083,
    "p_customer_phone": "+255712345678",
    "p_payment_method": "cod",
    "p_delivery_fee_tzs": 3000,
    "p_items": [
      {"product_id": "c3d4...uuid", "quantity": 2},
      {"product_id": "e5f6...uuid", "quantity": 1}
    ]
  }'
```

**Exact response:** a single string — the new order UUID:

```json
"f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
```

**Edge cases / errors** (translated to friendly text by `_parseRpcError`):
| Postgres error | HTTP you'd see in-app |
|---|---|
| `Insufficient stock for product Azam Soda 500ml (available: 0, requested: 2)` | "Sorry, one or more items just sold out while you were checking out. Please review your cart and try again." |
| `Product c3d4... not found` | "One of the items in your cart is no longer available." |
| Network/socket failure | "Network error while placing your order…" |

## Feature 2 — Complete a delivery with the pickup code (driver)

**Plain English:** the driver can only close an order if the customer reads out the 4-digit code — no code, no "delivered", no pay.

```bash
curl -X POST "https://YOUR-PROJECT.supabase.co/rest/v1/rpc/complete_delivery" \
  -H "Authorization: Bearer DRIVER_JWT" -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "p_order_id": "f81d...uuid", "p_entered_code": "4821", "p_payment_status": "paid" }'
```

**Response:** `200` empty/ok. **Errors:** `Incorrect confirmation code`, `Order already marked as delivered`, `Order is no longer assigned to you` → surfaced by `DeliveryCompletionException`.

## Feature 3 — Smart search (bilingual)

**Plain English:** customer types Swahili; the system finds English products too.

**Client path (mobile):** `SmartSearchService.expandQuery("sukari")` → checks in-memory cache → checks `search_query_cache` table → calls the Edge Function (1.5s timeout) → else falls back to `["sukari"]`.

**Direct Edge Function call:**
```bash
curl -X POST "https://YOUR-PROJECT.supabase.co/functions/v1/expand-search-query" \
  -H "Authorization: Bearer CUSTOMER_JWT" -H "Content-Type: application/json" \
  -d '{"query": "sukari"}'
```
**Response:**
```json
{ "terms": ["sukari", "sugar", "white sugar", "brown sugar"], "cached": false }
```
**Edge cases:** queries < 3 chars return `[query]` without AI; any timeout/error returns `{"terms": [], "error": "Fallback to direct search"}` with HTTP **200** (search still works — it just doesn't expand).

## Feature 4 — AI product description (admin)

**Plain English:** admin types a product name, AI writes 2–3 factual sentences; admin reviews before saving.

**Via the admin portal's own API route** (`web/admin/app/api/ai/generate-description/route.ts`, which proxies to the edge function):

```bash
curl -X POST "https://YOUR-PROJECT.supabase.co/functions/v1/generate-product-description" \
  -H "Authorization: Bearer ADMIN_JWT" -H "Content-Type: application/json" \
  -d '{ "name": "Azam Vanilla Ice Cream 1L", "category": "Dairy", "keywords": "vanilla, dessert, frozen" }'
```
**Response:**
```json
{ "description": "Azam Vanilla Ice Cream is a 1-litre tub of frozen vanilla dessert. It is stored frozen and should be consumed before the printed expiry date. Suitable for sharing." }
```
**Edge cases:** non-admin → `403 Only admin staff can generate descriptions`; >10 calls/min → `429 Rate limit exceeded…`; output <15 or >450 chars after sanitizing → `422 …failed quality check`; no provider key → `500 AI provider is not configured`.

## Feature 5 — Daily ops on the Admin Kanban

1. New order card appears in **New** with a chime (realtime; no refresh).
2. **Packing** → checklist modal: tick items physically in hand.
3. **Ready** → customer's timeline shows "Ready".
4. Pickup order → customer arrives, shows code → **CompletePickupModal** verifies and closes.
5. Delivery order → **DispatchModal** assigns a driver → card jumps to **Dispatched**; driver's app pings instantly.
6. **CancelOrderDialog** (pre-packing only) → automatic stock restoration via the cancellation RPC.

## Feature 6 — Catalog & stock management

Admin → Dashboard → Catalog: add/edit products (name, bilingual category, price TZS, unit, stock), upload images to Cloudinary via `ImageUploadField`, adjust stock with delta inputs (concurrency-safe RPC — two staff editing never clobber each other), toggle availability. Low-stock cards surface automatically on the analytics page.

---

# 🗄️ SECTION 7: DATABASE SCHEMA

**This is PostgreSQL (Supabase), not Firestore.** Source of truth: [`supabase/schema_full.sql`](supabase/schema_full.sql) + the 17 files in [`supabase/migrations/`](supabase/migrations/).

## Enums (custom types)

| Enum | Values |
|---|---|
| `user_role` | `customer` · `driver` · `admin` |
| `fulfillment_type` | `delivery` · `pickup` |
| `order_status` | `placed` · `packing` · `ready` · `out_for_delivery` · `delivered` · `cancelled` |
| `payment_method` | `cod` · `lipa_namba` · `mobile_money` *(reserved for Phase 2 gateway)* |
| `payment_status` | `pending` · `paid` · `failed` |
| `driver_employment_type` | `in_house` · `partner` |

## Migration ledger (what each file did)

| # | File | Purpose |
|---|---|---|
| 0001 | `enums_and_extensions.sql` | pgcrypto + all enums above |
| 0002 | `core_tables.sql` | branches, profiles, categories, products, addresses, orders, order_items |
| 0003 | `auth_trigger_and_role_functions.sql` | `handle_new_user()` trigger, `current_user_role()`, `is_admin()`, `is_driver()` |
| 0004 | `order_placement_function.sql` | atomic `place_order` RPC with `FOR UPDATE` locks |
| 0005 | `row_level_security_policies.sql` | base RLS on every table |
| 0006 | `seed_data.sql` | pilot branch + 9 bilingual categories |
| 0007 | `realtime_and_driver_visibility.sql` | realtime publications, driver GPS & assigned-order visibility |
| 0008 | `complete_delivery_function.sql` | pickup-code-verified delivery RPC + driver stats |
| 0009 | `admin_order_management_functions.sql` | status transitions, counter pickup handoff |
| 0010 | `profile_active_status.sql` | account active flag |
| 0011 | `admin_stock_adjustment.sql` | concurrency-safe delta stock RPC |
| 0012 | `admin_analytics_function.sql` | revenue/order/top-product/driver-performance RPCs |
| 0013 | `search_query_cache.sql` | bilingual expansion cache + `increment_search_cache_hit` |
| 0014 | `referral_codes.sql` | `QK-XXXXX` codes + abuse-guarded redemption |
| 0015 | `security_hardening.sql` | profile integrity trigger, negative-quantity guard, trigger column protection |
| 0016 | `order_cancellation_enhancement.sql` | customer pre-packing cancellation + atomic stock restoration |
| 0017 | `driver_order_acceptance.sql` | Available ready deliveries query, atomic `accept_order_delivery` RPC & driver order pool policies |

## Core Tables (field by field)

### Table: `branches` — the supermarket stores
```
├── id: uuid, default gen_random_uuid() → PK
├── name: text NOT NULL, e.g. "Quickopia Pilot Branch"
├── city: text NOT NULL, e.g. "Dar es Salaam"
├── neighborhood: text, e.g. "Mikocheni"
├── landmark: text, e.g. "Near Shoppers Plaza, Mwai Kibaki Road"
├── latitude / longitude: double precision → branch location for distance calcs
├── phone: text, e.g. "+255700000000"
├── commission_rate: numeric(5,2) default 0.00 → seed pilot uses 10.00 (%)
└── created_at: timestamptz default now()
```
Public read; only `is_admin()` may write.

### Table: `profiles` — one row per auth user (1:1 with `auth.users`)
```
├── id: uuid PK → references auth.users(id) ON DELETE CASCADE (same UUID as the auth user)
├── full_name: text, e.g. "Amina Juma"
├── phone: text, e.g. "+255712345678"
├── role: user_role NOT NULL default 'customer' → set by admin via SQL/dashboard
├── branch_id: uuid → branches.id (for drivers: which store they work from)
├── employment_type: driver_employment_type (drivers only)
└── created_at: timestamptz
```
Created automatically by the `on_auth_user_created` trigger. Users can update own basic info but **cannot change their own role or branch** (migration 0015 integrity trigger). Drivers may read profiles of orders assigned to them (customer contact needs).

### Table: `categories` — product groupings (bilingual)
```
├── id: uuid PK
├── name: text NOT NULL, e.g. "Fresh Produce"
├── name_sw: text, e.g. "Mboga na Matunda"
├── icon: text → icon identifier for UI
├── display_order: integer default 0 → chip sorting
├── is_active: boolean default true
└── created_at: timestamptz
```
Public read; admin write. Seed: 9 categories.

### Table: `products` — the catalog
```
├── id: uuid PK
├── branch_id: uuid NOT NULL → branches.id
├── category_id: uuid NOT NULL → categories.id
├── title: text NOT NULL, e.g. "Azam Unga Wa Ngano 2KG"
├── description: text → optionally AI-generated (draft-reviewed)
├── price_tzs: numeric(12,2) NOT NULL CHECK (price_tzs >= 0)
├── unit: text, e.g. "1 kg", "500 ml", "piece"
├── image_url: text → Cloudinary URL
├── stock_quantity: integer NOT NULL default 0 CHECK (stock_quantity >= 0)  ← negative stock impossible
├── is_available: boolean default true → RLS hides false rows from customers
├── is_popular: boolean default false → home-page flag
├── created_at / updated_at: timestamptz
```
Indexed: `idx_products_category(category_id)`, `idx_products_branch(branch_id)`.

### Table: `addresses` — saved delivery locations (address book)
```
├── id: uuid PK
├── profile_id: uuid NOT NULL → profiles.id ON DELETE CASCADE
├── label: text, e.g. "Home", "Office"
├── city: text NOT NULL
├── neighborhood: text NOT NULL
├── landmark: text NOT NULL        ← the Tanzania address system
├── house_details: text, e.g. "Blue gate, apartment 4B"
├── latitude / longitude: double precision → from the map pin picker
├── is_default: boolean default false
└── created_at: timestamptz
```
Indexed: `idx_addresses_profile(profile_id)`. RLS: a user manages **only their own** rows.

### Table: `orders` — the transactional heart
```
├── id: uuid PK
├── order_number: text UNIQUE NOT NULL, e.g. "ORD-2025-0042"
├── customer_id: uuid NOT NULL → profiles.id
├── branch_id: uuid NOT NULL → branches.id
├── driver_id: uuid → profiles.id (NULL until dispatched)
├── fulfillment_type: fulfillment_type NOT NULL ('delivery' | 'pickup')
├── status: order_status NOT NULL default 'placed'
├── delivery_city / delivery_neighborhood / delivery_landmark / delivery_house_details: text
├── delivery_latitude / delivery_longitude: double precision
├── customer_phone: text NOT NULL
├── pickup_code: text NOT NULL, e.g. "4821" → the trust mechanism
├── subtotal_tzs: numeric(12,2) NOT NULL
├── delivery_fee_tzs: numeric(12,2) NOT NULL default 0 → flat 3000 (AppConstants)
├── total_amount_tzs: numeric(12,2) NOT NULL
├── payment_method: payment_method NOT NULL
├── payment_status: payment_status NOT NULL default 'pending'
└── created_at / updated_at: timestamptz
```
Indexed: `idx_orders_customer(customer_id)`, `idx_orders_driver(driver_id)`, `idx_orders_status(status)`.
**RLS is special here:** customers read own orders, drivers read assigned orders, admin reads all — and **direct inserts are blocked** (`with check (false)`); `place_order` RPC (security definer) is the only door.

### Table: `order_items` — line items (price snapshot)
```
├── id: uuid PK
├── order_id: uuid NOT NULL → orders.id ON DELETE CASCADE
├── product_id: uuid NOT NULL → products.id
├── title: text NOT NULL            ← copied from product at purchase time (history survives product renames/deletes)
├── unit_price_tzs: numeric(12,2) NOT NULL  ← price frozen at purchase
├── quantity: integer NOT NULL CHECK (quantity > 0)  ← negative qty impossible (0015)
└── total_tzs: numeric(12,2) NOT NULL
```
RLS: readable via parent order access; direct inserts blocked.

### Table: `search_query_cache` — the "pay for AI once" table (0013)
```
├── query_normalized: text PK/unique, e.g. "sukari"
├── expanded_terms: text[] / jsonb, e.g. ["sukari","sugar","white sugar"]
└── hit_count: number → incremented by increment_search_cache_hit RPC
```
First shopper to search a term pays one AI call; everyone after gets a free Postgres read.

### Referral tables (0014)
Unique per-profile codes (`QK-XXXXX`) with abuse-guarded redemption RPC. See [`supabase/migrations/0014_referral_codes.sql`](supabase/migrations/0014_referral_codes.sql) for exact columns.

## How everything relates

```
auth.users ─1:1─ profiles ──┬──1:N── addresses
                            ├──1:N── orders (as customer_id)
                            └──1:N── orders (as driver_id)
branches ──┬──1:N── products ──N:1── categories
           └──1:N── orders
orders ──1:N── order_items ──N:1── products
search_query_cache: standalone key-value (query → synonyms)
```

## Why the indexes exist

| Index | Query it serves |
|---|---|
| `products(category_id)` | Category filter on the home grid |
| `products(branch_id)` | Branch-scoped catalog reads |
| `orders(customer_id)` | "My orders" history screen |
| `orders(driver_id)` + `status` | Driver queue: "assigned & still active" |
| `addresses(profile_id)` | Address book load |

---

# 🤖 SECTION 8: AI INTEGRATION DETAILS

## Which models, and why

| Priority | Provider | Model | Why it's first/second/third |
|---|---|---|---|
| 1st choice | **Groq** | `llama-3.3-70b-versatile` | Generous free tier, extremely fast inference (<1s), OpenAI-compatible API — ideal for a 1.5s-timeout search feature |
| 2nd | **Google Gemini** | `gemini-1.5-flash` | Reliable, free tier (15 RPM / 1500 req-day), good multilingual Swahili handling |
| 3rd | **OpenRouter** | `google/gemini-flash-1.5` | Single key gives access to hundreds of models — the "never dead" fallback |

The chain is selected **by which secret exists**, in that order (see `supabase/functions/*/index.ts`). Both functions are server-side only — AI keys **never** reach any client. Both Edge Functions run with `temperature` low (0.2–0.3) and hard token caps, because this is utility AI, not creative AI.

## The exact prompts (verbatim from the code)

### `generate-product-description` — SYSTEM prompt
```text
You are writing short product descriptions for an online supermarket in Tanzania.
Rules:
- 2 to 3 sentences maximum.
- Plain, informative, factual tone suited to local supermarket shoppers.
- Never invent specifications, health claims, or ingredients not provided in the input.
- Do not use superlatives like "best", "amazing", "ultimate", or "revolutionary".
- Output only the plain description text. No markdown formatting, no bullet points, no quotation marks, no headers.
```
Generation config: `temperature: 0.3`, `maxOutputTokens: 200`.

### `generate-product-description` — USER prompt (constructed dynamically)
```ts
const userPrompt = `Product: ${name.trim()}
Category: ${category?.trim() || 'General Supermarket'}
Keywords: ${keywords?.trim() || 'none provided'}`;
```
Empty fields fall back to safe defaults instead of sending `null`/`undefined` to the model.

### `expand-search-query` — SYSTEM prompt
```text
You expand short shopping search queries for a Tanzanian supermarket app.
Input may be in Swahili, English, or mixed.
Output a JSON array of 3-6 short search terms/synonyms (English and Swahili) that a customer might mean, including the original term.
Do not explain, do not add commentary, output ONLY a valid JSON array of strings.
Example: For "sukari" output: ["sukari", "sugar", "white sugar", "brown sugar"]
Example: For "cooking oil" output: ["cooking oil", "mafuta", "sunflower oil", "vegetable oil"]
```
Generation config: `temperature: 0.2`, `max tokens: 120`, user message: `Query: ${normalized}`.

## How prompts are constructed dynamically
Both functions are **stateless and single-turn** — no chat history is kept (cheaper, safer, faster). Inputs are trimmed and lower-cased (`expand-search-query`) or trimmed with fallbacks (`generate-product-description`). The original query is **always re-inserted first** in the result list (`sanitized.unshift(fallbackTerm)`), so even a hallucination-free response can never drop what the user actually typed.

## Token usage & cost estimates
| Call | Prompt tokens | Output cap | Real-world cost |
|---|---|---|---|
| Description generation | ~120 (system+user) | 200 out | ≈ $0.00024 on Groq paid / $0.00003 on Gemini free-tier quota → **$0 at pilot volume** |
| Query expansion | ~150 | 120 out | ≈ $0.00021, **and each unique term is generated once ever** thanks to the Postgres cache |

At pilot scale (<500 AI calls/day, cache hit rate growing daily), AI cost rounds to **$0.00/month**. Even 100k expansions/month on Groq's paid tier would be ≈ **$21** — and would mostly be cache hits anyway.

---

# ⚠️ SECTION 9: CURRENT LIMITATIONS & KNOWN BUGS

*Brutally honest. The pilot works; here's exactly where the edges are.*

## Known bugs / rough edges
| # | Issue | Repro | Impact | Workaround |
|---|---|---|---|---|
| 1 | **In-memory rate limiter resets** when the edge function cold-starts (each Deno isolate has its own `rateLimitMap`) | Generate descriptions, wait for cold start, generate 10 more immediately | Rate limit is advisory, not guaranteed | Acceptable for admin-only tool; move to Postgres-backed counter if abused |
| 2 | **Pickup code brute-force surface** — `complete_delivery` verifies a 4-digit code; no per-order attempt counter exists | Driver repeatedly calls the RPC with different codes | 1-in-10000 per guess; mitigated by the real customer reading the code aloud, but no lockout | Add `attempt_count` column + lockout after 5 fails (see MOD menu) |
| 3 | **CORS wildcard `*`** on both edge functions | Inspect response headers | Fine for first-party app calls, sloppy for a public surface | Restrict `Access-Control-Allow-Origin` to your domains |
| 4 | **Driver GPS on customer timeline is basic** — realtime channel + visibility policies exist, but no polished "driver moving on map" view | Track an out-for-delivery order | Customer sees status, not live position | Render driver position from the realtime channel on `flutter_map` |
| 5 | **Legacy repo/folder name** (`E-commerce-App-UI-Flutter-master`) and stale references to "FIREBASE"/`PROJECT_PLAN.md` in older docs | `git ls-files` / old docs | Confuses newcomers (and future-you) | Rename repo; this README supersedes old ones |
| 6 | **`mobile/.env` is a Flutter asset** — a wrong key silently yields placeholder mode instead of a hard failure | Boot with a bad key | "Empty catalog" mysteries | Console prints `ℹ️ … placeholder credentials`; consider failing fast in debug builds |

## Performance bottlenecks (what breaks at scale)
- **`ilike` substring search** on `products.title` — full scan per term; fine at hundreds of SKUs, dies at 100k. Fix: `pg_trgm` GIN index or pgvector (Section 8 ideas).
- **No pagination** on catalog/order lists — the home grid fetches all available products. Fine for 40–500 SKUs; painful at 5,000. Add `.range()` + infinite scroll.
- **Realtime on free tier** — Kanban open all day in the shop plus every customer session at 1,000+ users will need Supabase Pro ($25/mo).
- **Analytics RPCs scan orders by date** — "revenue this year" slows as orders accumulate (years, not months). Add a materialized rollup when it hurts.
- **Search cache grows unbounded** — every unique query inserts a row forever.

## Security issues still to fix (prioritized)
1. [ ] **Pickup-code attempt limiting** (bug #2) — highest priority; add `attempt_count` + lockout after 5 failed `complete_delivery` calls.
2. [ ] Tighten edge-function **CORS** to known origins.
3. [ ] Turn on Supabase **email confirmations** for production sign-ups (spam vs. UX trade-off).
4. [ ] Add an expiry/rotation plan for the Cloudinary **unsigned** upload preset (anyone with the cloud name can upload into your account).
5. [ ] Guard `SUPABASE_SERVICE_ROLE_KEY` with a CI grep — it's server-only today (`lib/supabase/admin.ts`), but nothing *enforces* that.
6. [ ] Rate-limit `place_order` per user (stock locks make it safe, but spam is noisy).

## Features that work but work badly
- **Payment reconciliation** — a human compares notebook ↔ orders. Cheap fix: an admin "cash reconciliation" screen listing `payment_status = 'pending'` orders by day.
- **Reorder** — re-adds at *live* prices with no diff preview if prices changed since the original order.
- **Analytics date filter** — works, but no presets (Today/7d/30d) and no export.
- **Signup** — no email verification in the pilot; a typo'd email creates an unreachable account.

## Technical debt (works, but written poorly)
- `AuthProvider` does session + role + profile editing — should split.
- A few customer screens contain Supabase-adjacent logic that belongs in `services/` (pattern drift from the services-only rule).
- The two Next apps duplicate types/logic (`lib/types.ts`) that drift independently — candidate for a shared workspace package.
- Strong Dart test coverage, but **zero tests for edge functions** and no SQL tests for RPC edge cases.
- No CI: "53/53 passing" is only true until someone forgets to run it.

---

# 🧩 SECTION 10: MODIFICATION & ADDON GUIDE

The menu. Pick a mod, follow it top to bottom.

## MOD 1: Swap or Add an AI Model (e.g. Gemini → GPT-4o)

- **Difficulty:** ⭐⭐ · **Time:** 1–2 hours
- **Files to modify:** `supabase/functions/generate-product-description/index.ts`, `supabase/functions/expand-search-query/index.ts`
- **New files:** none · **Dependencies:** none (raw `fetch` is used deliberately)

1. Inside each function, the provider pattern already exists: `interface AIProvider { generate(systemPrompt, userPrompt): Promise<string> }` with `GeminiProvider`, `GroqProvider`, `OpenRouterProvider` classes.
2. Copy `OpenRouterProvider` (OpenAI-compatible) and rename to `OpenAIProvider`; change `url` to `https://api.openai.com/v1/chat/completions` and `model` to `gpt-4o-mini`.
3. In the selection block, insert it anywhere in the chain:
   ```ts
   const openAIKey = Deno.env.get('OPENAI_API_KEY');
   if (openAIKey) provider = new OpenAIProvider(openAIKey); // place before/after others as desired
   ```
4. Deploy: `supabase functions deploy generate-product-description && supabase functions deploy expand-search-query`
5. `supabase secrets set OPENAI_API_KEY="sk-..."`
- **Test:** Admin → Catalog → generate a description; check the response and Supabase edge-function logs show the new provider handled it. Set only `OPENAI_API_KEY` locally to force the chain through it.

## MOD 2: Add a New Payment Method (e.g. "Card on Delivery")

- **Difficulty:** ⭐⭐ · **Time:** 2–4 hours
- **Files to modify:** DB enum (SQL), `mobile/lib/widgets/payment_method_selector.dart`, `web/storefront/components/checkout/PaymentMethodSelector.tsx`, both checkout screens/models if they switch on method strings
- **Dependencies:** none

1. SQL Editor: `alter type payment_method add value 'card_on_delivery';` (one-way enum extension; run before deploying clients).
2. Add a radio card to both selectors (copy the `cod` card, label "Card on Delivery", icon).
3. Check `complete_delivery`'s payment handling accepts the new value for `p_payment_status` — it does (status enum, not method).
4. If the method needs reconciliation labels, update admin `OrderCard` to show a matching badge.
- **Test:** place a delivery order with the new method on mobile AND storefront; verify `orders.payment_method = 'card_on_delivery'`; complete delivery; check Kanban badge.

## MOD 3: Add a Product Category (with Swahili name)

- **Difficulty:** ⭐ (easiest thing in the codebase) · **Time:** 5 minutes, no code
- **Files:** none — the admin portal already does this
- Admin → Dashboard → **Catalog** → Categories → *Add Category* → name + `name_sw` + icon + display order. It appears instantly on mobile (category chips), storefront (filter), and respects `display_order`.
- **Test (if you insist on SQL):** `insert into categories (name, name_sw, display_order) values ('Snacks', 'Vitafunio', 10);` then open the mobile app — the chip is there.

## MOD 4: Phone-Number (OTP) Authentication

- **Difficulty:** ⭐⭐⭐ · **Time:** 1–2 days
- **Files to modify:** `mobile/lib/screens/auth/login_screen.dart`, `signup_screen.dart`, `mobile/lib/services/auth_service.dart`, `mobile/lib/providers/auth_provider.dart`; mirror changes in `web/storefront/lib/auth.ts` + `app/login/page.tsx`
- **Dependencies:** none new (Supabase phone auth); **SMS credit** required — Twilio/MessageBird/Beem via Supabase Auth Providers

1. Supabase Dashboard → Authentication → Providers → **Phone** → enable, attach SMS provider credentials.
2. In `auth_service.dart` add `signInWithOtp(phone: ...)` and keep the existing email flow as fallback (many pilot users already have accounts).
3. Supabase auto-creates `profiles` via the existing trigger — no schema change needed (phone is already a `profiles` column).
4. In `auth_gate.dart`, handle the `onAuthStateChange` OtpVerified event the same as password sign-in.
5. SMS provider choice matters in Tanzania: Beem Africa or Twilio; expect ~$0.01–0.05 per OTP.
- **Test:** sign up with `+2557...`, receive OTP, verify `profiles` row exists with role `customer`; confirm admin middleware still gates the web portal.

## MOD 5: Automated Mobile-Money Payments (AzamPay / Selcom / Beem USSD push)

- **Difficulty:** ⭐⭐⭐⭐ · **Time:** 3–5 days
- **Files to modify:** `supabase/functions/` (new function), `web/storefront/lib/orders.ts`, `mobile/lib/services/order_service.dart`, admin `OrderCard` (payment badge)
- **New files:** `supabase/functions/initiate-payment/index.ts`, `supabase/functions/payment-webhook/index.ts`, `supabase/migrations/0017_payments_ledger.sql`
- **Dependencies:** provider account (Selcom/AzamPay/Beem) + their API keys as secrets

1. Migration 0017: `payments` ledger table (`order_id`, `provider_ref`, `amount_tzs`, `status`, `raw_payload jsonb`) + RLS (admin read, insert via service role only).
2. `initiate-payment` edge function: takes order id, calls provider's USSD-push API (customer's phone gets a M-Pesa prompt), returns provider reference. Trigger it right after `place_order` when `p_payment_method = 'mobile_money'`.
3. `payment-webhook` edge function: provider calls it; verify their signature; update `payments.status` and, on success, `orders.payment_status = 'paid'` **using the service-role client** (webhook has no user JWT).
4. Checkout screens: after placing an order with `mobile_money`, show a "Check your phone for the payment prompt" state and poll order status (already realtime).
- **Test:** sandbox credentials → order → phone prompt → approve → `orders.payment_status` flips to `paid` within seconds; kill the app mid-payment and confirm webhook still reconciles.

## MOD 6: Make It Faster / More Scalable

- **Difficulty:** ⭐⭐⭐ · **Time:** 2–4 days
- **Files to modify:** `mobile/lib/services/catalog_service.dart`, `web/storefront/lib/data.ts`, `supabase/migrations/0018_search_indexes.sql`, edge function CORS
- **New files:** one migration

1. Migration: `create extension if not exists pg_trgm; create index idx_products_title_trgm on products using gin (title gin_trgm_ops);` → `ilike '%sukari%'` stops being a full scan.
2. Add pagination to catalog reads (`.range(0, 19)` + infinite scroll on mobile; `limit/offset` on storefront) — biggest perceived-speed win.
3. Cache storefront product pages with Next.js `revalidate` (catalog changes are admin-driven, 60s staleness is fine).
4. Serve Cloudinary images with auto `f_auto,q_auto` transformations (already a URL change in `ProductCard` components).
5. Restrict edge-function CORS + move rate limiting into a `rate_limits` table (also fixes bug #1).
- **Test:** `flutter test` green; `npm run build` green; `EXPLAIN ANALYZE` the search query before/after to confirm index usage; load-test `place_order` with two parallel carts on the same last item (one wins, one gets the friendly out-of-stock message).

## MOD 7: Publish the iOS App (deferred work)

- **Difficulty:** ⭐⭐⭐ · **Time:** 2–3 days + Apple review
- **Files to modify:** none in `lib/` — it's platform config
- **New files:** `mobile/ios/` (run `flutter create --platforms=ios .`), signing assets

1. Needs a Mac + `$99/yr` Apple Developer account.
2. `flutter create --platforms=ios .` inside `mobile/`; add `assets/quickopia_icon` via `flutter_launcher_icons`.
3. Signing & Capabilities → team + bundle id `com.quickopia.app`; enable Associated Domains if you add universal links.
4. `flutter build ipa --release` → upload via Transporter.
5. Prepare App Store assets: 512×512 icon, screenshots, **Privacy Policy URL** (host it on the storefront).
- **Test:** TestFlight build on a real iPhone; run the full ST-01…ST-10 smoke list on iOS.

## MOD 8: Admin Dashboard Extension — CSV Bulk Product Import

- **Difficulty:** ⭐⭐⭐ · **Time:** 1 day
- **Files to modify:** `web/admin/app/dashboard/catalog/page.tsx`
- **New files:** `web/admin/app/api/catalog/import/route.ts`, `web/admin/components/catalog/ImportCsvModal.tsx`
- **Dependencies:** `papaparse` (`npm i papaparse`)

1. Add an "Import CSV" button on the Catalog page → modal with file picker + template download.
2. API route (server): parse with papaparse, validate rows (title, category exists, price ≥ 0, stock ≥ 0), insert via the service-role client, return a per-row success/error report.
3. Show the report in the modal; offer "download errors as CSV".
- **Test:** import 50-row CSV → 50 products on mobile; import a row with price `-5` → error report line, no partial garbage in DB.

## MOD 9: Analytics & Funnel Tracking (PostHog)

- **Difficulty:** ⭐⭐ · **Time:** 1 day
- **Files to modify:** `web/storefront/app/layout.tsx`, `web/admin/app/layout.tsx`, `mobile/lib/main.dart`
- **New files:** `web/storefront/lib/analytics.ts`, `web/admin/lib/analytics.ts`, `mobile/lib/services/analytics_service.dart`
- **Dependencies:** `posthog-js` (`npm i posthog-js`), `posthog_flutter` (`flutter pub add posthog_flutter`)

1. Create a free PostHog project → get the API key + host.
2. Web: initialize in both root layouts; instrument 5 events: `product_viewed`, `cart_updated`, `checkout_started`, `order_placed`, `order_delivered` (storefront `lib/orders.ts` + Kanban transitions).
3. Mobile: wrap in `main.dart` after Sentry init; track the same events from providers.
4. Dashboard: build a funnel `product_viewed → checkout_started → order_placed` and a retention cohort.
- **Test:** browse on mobile → events appear in PostHog Live; place an order → funnel step 3 increments.

## MOD 10: Scheduled / Automated Jobs (pg_cron)

- **Difficulty:** ⭐⭐⭐ · **Time:** 1 day
- **Files to modify:** none in app code
- **New files:** `supabase/migrations/0019_cron_jobs.sql`
- **Dependencies:** enable the `pg_cron` extension (Supabase Dashboard → Database → Extensions)

1. In one migration:
   ```sql
   select cron.schedule('nightly-backup-notify', '0 3 * * *', $$
     select net.http_post(
       url := 'https://YOUR-PROJECT.supabase.co/functions/v1/nightly-report',
       headers := '{"Authorization":"Bearer ' || current_setting('app.cron_jwt') || '"}'
     ) $$);
   ```
2. Job ideas in priority order: (a) **abandoned-cart report** — carts are client-side, so instead log `cart_updated` events server-side first (small table), then daily digest to the branch WhatsApp; (b) **stale-order sweeper** — orders stuck in `placed` > 2h get flagged on the Kanban; (c) **search-cache cleanup** — delete cache rows with `hit_count = 0` older than 90 days.
- **Test:** `select * from cron.job_run_details order by start_time desc limit 5;` shows successes; force a stale order and see it flagged.

## MOD 11: Email / SMS Notifications at Order Milestones

- **Difficulty:** ⭐⭐⭐ · **Time:** 2 days (email) / +1 day (SMS via Beem)
- **Files to modify:** none existing
- **New files:** `supabase/functions/notify-milestone/index.ts`, `supabase/migrations/0020_notification_log.sql`, a DB webhook (Supabase Dashboard → Database → Webhooks) firing on `orders` UPDATE
- **Dependencies:** Resend (email, free 3k/month) and/or Beem Africa (SMS) keys as secrets

1. Migration 0020: `notification_log` (`order_id`, `channel`, `milestone`, `status`, `created_at`) with RLS admin-read.
2. Edge function `notify-milestone`: DB webhook POSTs the changed row; map `status` → message template:
   - `packing` → "Jambo! Order {order_number} is being packed 🛍️"
   - `ready` (pickup) → "Ready for pickup! Your code: {pickup_code}"
   - `out_for_delivery` → "Your driver is on the way 🛵"
   - `delivered` → "Asante! Rate your experience."
3. Send via Resend (email) and Beem (SMS to `customer_phone`); write every attempt to `notification_log` (idempotency: skip if (order, milestone, channel) already logged — prevents duplicate SMS on realtime replays).
4. Add unsubscribe/STOP handling for marketing later — transactional status messages are exempt.
- **Test:** move an order through the Kanban; customer phone receives exactly one SMS per milestone; `notification_log` has one row each; replay the webhook → no duplicates.

## MOD 12: Waitlist / Landing Page (pre-launch for the next branch)

- **Difficulty:** ⭐ · **Time:** 3–4 hours
- **Files to modify:** none
- **New files:** `web/storefront/app/waitlist/page.tsx` (or a separate `web/landing` project), `supabase/migrations/0021_waitlist.sql`
- **Dependencies:** none

1. Migration: `waitlist_signups (id uuid, phone text unique, neighborhood text, created_at)` + RLS (public insert, admin read).
2. Page: hero, "We're coming to [Neighborhood]", phone input (reuse TZ validation), submit → insert → success state. Add a referral counter ("#42 on the list, share your link").
3. `next.config.mjs`: export `metadata` with OG tags; submit the page URL to WhatsApp status campaigns.
4. Bonus: an admin CSV export button for the list.
- **Test:** submit twice with the same phone → unique constraint catches it, UI shows friendly "You're already on the list".

---

# 🚀 SECTION 11: DEPLOYMENT GUIDE

From local to live, following [`docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md`](docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md) (the ops runbook).

## 11.1 Backend (Supabase) — already production-hardened
The pilot decision: **promote the current Supabase project directly** (single branch; a redundant instance adds migration risk with no benefit). All 16 migrations are applied and locked.
- [ ] Set edge-function secrets: `GROQ_API_KEY` (or `GEMINI_API_KEY`), `OPENROUTER_API_KEY`, `SENTRY_DSN`.
- [ ] **Database security rules:** RLS is already enabled on every table with policies per role (customer/driver/admin), direct inserts into `orders`/`order_items` are blocked, and `security definer` functions own privileged writes. **Do not** disable RLS to "fix" an access problem — add/fix a policy.
- [ ] Verify Auth providers + (optionally) enable email confirmations.
- [ ] Schedule weekly `pg_dump` (free tier has 7-day daily backups but no PITR):
  ```bash
  pg_dump "postgres://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" > backup_$(date +%Y%m%d).sql
  ```

## 11.2 Web apps (Vercel) — two separate projects
Deploy **Storefront** and **Admin** as two projects to isolate builds, domains, and security blast radius.

| Setting | Storefront project | Admin project |
|---|---|---|
| Root Directory | `web/storefront` | `web/admin` |
| Framework | Next.js (auto) | Next.js (auto) |
| Build command | `next build` | `next build` |
| Env vars | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_BRANCH_WHATSAPP_NUMBER` | all admin `.env.example` vars incl. `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY` |

> ⚠️ Add production env vars under **Settings → Environment Variables → Production** (and Preview if you want branch deploys to work). `SUPABASE_SERVICE_ROLE_KEY` must only ever be read in server code.

## 11.3 Mobile (Google Play)
1. [ ] One-time **$25** Google Play developer registration.
2. [ ] Generate the release keystore (keep it safe forever — losing it loses the app identity):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. [ ] Copy `mobile/android/key.properties.example` → `key.properties` with keystore credentials.
4. [ ] `flutter build appbundle --release` → output `build/app/outputs/bundle/release/app-release.aab`.
5. [ ] Store listing assets: 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots (1080×1920), **Privacy Policy URL** (host on the storefront).
6. [ ] Ship to **Internal testing** first, then Staged rollout.

> **iOS:** deliberately deferred for the pilot (>85% Android in TZ, $99/yr, slow review). The Flutter code needs zero architecture changes — see MOD 7.

## 11.4 Custom domains
| Surface | How |
|---|---|
| Storefront | Vercel → Project → Settings → Domains → add `shop.yourdomain.com` → follow DNS instructions (A/CNAME at your registrar). HTTPS is automatic (Let's Encrypt). |
| Admin | Same, `admin.yourdomain.com`. Add `robots.txt` (already present in `web/admin/public`) + optionally Vercel "noindex" header so it never appears in Google. |
| Mobile | Nothing to point — the app already talks to `*.supabase.co`. Update `mobile/.env` values only if you migrate Supabase projects. |

## 11.5 Monitoring after deployment
- **Sentry** — all 4 surfaces report here; environment tag distinguishes `development`/`staging`/`production`. Goal: zero false-alarm crashes (smoke test ST-10).
- **Supabase Dashboard** — Database → Logs (slow queries), Edge Functions → Logs (AI failures), Auth → Users.
- **Vercel Analytics** — page loads, Web Vitals on both web apps.
- **The Kanban itself** — the first "monitor" is the shop staff; if cards stop arriving, they'll call you before Sentry alerts.

## 11.6 Rolling back when something breaks
| Layer | Procedure | Speed |
|---|---|---|
| Storefront/Admin | Vercel → Deployments → previous good deployment → **⋯ → Instant Rollback** (no rebuild) | ~5 seconds |
| Edge Functions | `supabase functions deploy <name> --project-ref <ref>` from a previous git tag/commit | ~1 min |
| Database | `psql "postgres://...@db.[REF].supabase.co:5432/postgres" < pre_migration_backup.sql` (**always** `pg_dump` before any new migration) | minutes |
| Mobile app | Google Play → Production → Halt rollout, or publish a hotfix `.aab` with a version bump | hours |
- [ ] **Rule of thumb:** web rolls back instantly; DB changes are append-only migrations — never edit a shipped migration, always add `0017_...`.

---

# 💰 SECTION 12: COST CALCULATOR

The design goal was "$0/month until the pilot proves itself." Here is the honest math.

| Service | Free Tier | Paid Tier | Cost at 100 users | Cost at 1,000 users |
|---|---|---|---|---|
| **Supabase** (DB, Auth, Realtime, Edge Functions) | 500 MB DB · 50k MAU · 2 GB egress · 5 GB storage · 500k edge invocations | Pro **$25/mo** (8 GB DB, 100k MAU, PITR) | **$0** (pilot fits easily) | **$25/mo** (Realtime + egress likely the first ceiling) |
| **Vercel** (storefront + admin) | Hobby: unlimited static/SSR, 100 GB bandwidth · **⚠️ one project each** | Pro **$20/user/mo** | **$0** (two Hobby projects, well under limits) | **$0–20/mo** (bandwidth growth; images are on Cloudinary, which helps) |
| **Groq** (AI #1) | Free dev tier; paid ≈ $0.59/$0.79 per 1M in/out tokens | — | **$0** (cache + low volume) | **≈ $0–5/mo** (cache hit rate rises with users) |
| **Gemini 1.5 Flash** (AI #2 fallback) | 15 RPM, 1,500 req/day free | Pay-as-you-go ≈ $0.075/$0.30 per 1M tokens | **$0** | **≈ $0–3/mo** |
| **OpenStreetMap / flutter_map** | Free, no key, no billing | — | **$0** | **$0** (self-imposed fair-use; native maps hand-off keeps tile load low) |
| **Cloudinary** (images) | 25 credits/mo (~25 GB mixed storage+bandwidth) | $99/mo tier is overkill; free → next paid **$99** | **$0** (compress uploads) | **$0–99** (only if catalog imagery balloons) |
| **Sentry** | 5k errors/mo, 10% sampling configured | Team $26/mo | **$0** | **$0–26/mo** |
| **Google Play** | — | **$25 one-time** | $25 (sunk) | $25 |
| **Domain** (optional) | — | ~$12/yr | $1/mo avg | $1/mo avg |
| **Beem/Twilio SMS** (MOD 11, optional) | — | ~TZS 20–50 (~$0.01–0.02) per SMS | **$0** (not started) | ≈ $10–30/mo at ~1 msg/order |
| **TOTAL (as built today)** | | | **≈ $1/mo** (just the domain) | **≈ $25–55/mo** (Supabase Pro + maybe Vercel/AI growth) |

**Unit economics sanity check:** at TZS 3,000 flat delivery fee per order, ~130 orders/month cover the entire 1,000-user infrastructure bill. The expensive future line items are **SMS** and **driver incentives**, not software.

---

# 🗺️ SECTION 13: ROADMAP

## Recently Shipped in v1.0.0-pilot (September 2026)
- [x] **Login Screen Security Hardening** — Removed hardcoded demo admin credentials from the mobile login screen to safeguard production administrative accounts.
- [x] **Driver Available Order Pool & Self-Assignment** — Added `get_available_deliveries()` and atomic `accept_order_delivery` RPC (migration `0017`) allowing drivers to browse unassigned ready orders and claim them with one tap.
- [x] **Driver Reports & Payout Status** — Added daily & lifetime earnings metrics, delivery fees earned (TZS 3,000/order), and transparent settled (**PAID**) vs **PENDING** payout tracking.
- [x] **Driver Profile & Operations Card** — Added driver identity screen with verification badge, assigned branch, lifetime trip counts, and sign out with confirmation.
- [x] **Supermarket & Admin Guidance** — Integrated store management guidance in `AccountScreen` explaining web portal synchronization via Supabase Realtime.
- [x] **Verified Release APK Build** — Compiled and verified production release APK (`mobile/build/app/outputs/flutter-apk/app-release.apk`, 62.2 MB).

## Security Remediation Sprint (September 2026)
- [x] **Order-creation attack surface closed** — migration `0022` dropped the client direct-INSERT fallback policies on `orders`/`order_items`; the Flutter direct-insert fallback was removed from `OrderService`. 100% of order creation flows through the atomic `place_order` RPC.
- [x] **`place_order` identity & input guards restored** — strict `p_customer_id = auth.uid()` (anonymous calls rejected, anon execute revoked), positive-quantity check, non-negative delivery-fee guard (regression introduced in `0018` fixed).
- [x] **Customer self-cancellation restored** — `cancel_order` once again allows the owning customer to cancel while `status='placed'` (regression introduced in `0019` fixed); stock is restored atomically.
- [x] **Pickup-code brute-force lockout** — `orders.failed_pickup_attempts` + 5-attempt lock in `complete_delivery`, with admin override on the correct code.
- [x] **Driver order-claim race fixed** — direct `.update()` fallback removed from `DriverOrderService.acceptOrder`; claims go through the atomic `accept_order_delivery` RPC only.
- [x] **Multi-branch scoping** — `get_available_deliveries()` scoped to the driver's branch; admin Kanban got a branch selector with realtime branch guards.
- [x] **Search cache poisoning fixed** — `expand-search-query` sanitizes queries/terms before caching and writes via the service-role key (cache INSERT restricted in `0022`).
- [x] **RPC grant surface tightened** — `place_order`/`cancel_order` execution revoked from `anon`/`public`, granted to `authenticated` + `service_role`.

See `docs/REMEDIATION_LOG.md` for the full verification matrix.

## What is Yet to Fix (Immediate Queue)
1. [x] **Pickup-code attempt lockout** (Section 9, security #1) — ✅ DONE via migration `0022` (`orders.failed_pickup_attempts` column + 5-attempt lock in `complete_delivery`, with admin override on the correct code).
2. [ ] **Cash reconciliation screen** in admin — List `payment_status='pending'` cash deliveries by day for store cashier sign-off (removes physical notebook reliance).
3. [ ] **Driver live-map on customer timeline** (Section 9, bug #4) — Render driver coordinates from the realtime channel onto the customer's `flutter_map` view.
4. [ ] **CI on GitHub Actions** — Automated `flutter test` + both `npm run build` on every pull request.
5. [ ] **Search pagination + `pg_trgm` index** (MOD 6 items 1–2) — GIN index for substring search as catalog scales beyond 500 SKUs.
6. [ ] **Rename repo/folder to `quickopia`** — Remove legacy `E-commerce-App-UI-Flutter-master` naming.

## Medium Term — next 3 months (become a real product)
- [ ] **Automated mobile money** (MOD 5) — the single biggest ops cost today is a human reconciling Lipa Namba by hand.
- [ ] **SMS milestone notifications** (MOD 11) — customers currently must keep the app open to know anything.
- [ ] **Multi-branch operations** — schema is ready (`branch_id` everywhere); needs branch switcher in admin, branch-scoped driver rosters, per-branch analytics.
- [ ] **PostHog funnel analytics** (MOD 9) — you can't improve conversion you can't see.
- [ ] **CSV bulk import** (MOD 8) + refined AI descriptions (Section 8 ideas #1) — real supermarkets have hundreds of SKUs.
- [ ] **pgvector semantic search** — makes Swahili search genuinely great.
- [ ] **Driver live-map on customer timeline** (Section 9, bug #4).
- [ ] **Referral reward ledger** — codes exist; automate the reward (credit on next order).

## Long Term — 6–12 months
**If everything goes perfectly, Quickopia becomes the operating system for neighborhood supermarkets in Dar es Salaam**: the platform a 3-branch chain uses without knowing (or caring) that Supabase exists.
- **Version 2.0 vision:**
  - **Multi-tenant SaaS** — onboard N supermarkets; each gets a subdomain (`shopname.quickopia.com`), isolated data via `branch_id → tenant_id` evolution, self-serve onboarding wizard.
  - **Route optimization** for drivers (open-source OR-Tools or simple nearest-order heuristics) — 2–3 more deliveries per shift.
  - **Customer credit wallet** with weekly repayment cycles (a Tanzanian reality) built on the payments ledger from MOD 5.
  - **Demand forecasting** — "order 40% more sugar on Fridays" using the analytics rollups.
  - **Native Swahili-first UI** — full locale switching, not just search.
  - **iOS launch** (MOD 7) once Android retention proves the economics.
  - **Scale target:** 10 branches, ~50k monthly orders, Supabase Pro + read replicas, ~$200/mo infrastructure, still no per-order platform fee of more than a few cents.

---

# 🎓 SECTION 14: LESSONS LEARNED

## What worked better than expected
- **Putting correctness in the database.** One `place_order` function with `FOR UPDATE` locks eliminated the entire class of overselling bugs with *zero* client-side code. No lock library, no optimistic UI hacks — SQL has been solving this since the 1980s.
- **The "pay for AI once" cache.** A tiny `search_query_cache` table means the 10,000th customer searching *sukari* costs $0.00. This single design choice is why AI features survived the free-tier budget.
- **One APK, two roles.** The dual-role AuthGate meant one build pipeline, one test suite, one release for both customers and drivers. Separate apps would have doubled everything for no benefit at pilot scale.
- **The provider fallback chain.** Groq → Gemini → OpenRouter with "use whichever key exists" selection has never left AI features fully dead, even when a provider had an outage or an expired key.
- **Edge-function-first AI.** Keys live in Deno secrets, never in any client bundle. Rate limiting, sanitizing, and the quality gate all live server-side where they can't be bypassed.
- **Vercel Instant Rollback.** A bad deploy stops being an incident when recovery takes 5 seconds with no rebuild.

## What was harder than expected
- **Realtime + RLS interplay.** Realtime broadcasts respect RLS, so driver visibility of assigned orders required careful `SECURITY DEFINER` helper functions (migration `0007`). Every "simple" realtime feature touches the security model.
- **Windows dev quirks.** `.env` as a Flutter asset requiring `flutter clean`, Next.js SWC native binary hiccups, emulator DNS failures — the error table in Section 5 is basically a diary.
- **Payments are a product, not a checkbox.** "Cash on delivery" sounds trivial until you realize someone must reconcile notes-and-coins against a database every night. The reconciliation screen should have been v1 scope.
- **Migration discipline.** 16 sequential SQL files must stay ordered and append-only. Editing migration 0005 after it shipped in staging would have been a disaster; the ledger discipline (never edit, always add) was learned the hard way.
- **Testing without a live backend.** Widget tests needed mocked providers and `Supabase.initialize` no-ops; writing testable seams around a BaaS took deliberate design (`DriverOrderService({SupabaseClient? client})` exists *because* of tests).

## What I'd do differently if starting over
1. **CI from day one.** The first GitHub Action should exist before the first feature.
2. **Phone auth first.** Tanzania is phone-first; email/password created friction and unreachable accounts. OTP is worth the SMS cost immediately.
3. **`.env.example` on day one** for every surface — the admin key list was reconstructed from memory once.
4. **A shared TypeScript package** for the two web apps from the start, instead of drifting duplicate types.
5. **Rename the repo immediately** when the project pivots — legacy names leak into docs, badges, and muscle memory for months.
6. **Build the reconciliation screen before the analytics dashboard.** Ops truth beats vanity metrics.

## What transfers to every future project
- **The database is the program.** If state correctness matters, put invariants in Postgres (RLS, CHECKs, RPCs) — clients are unreliable narrators.
- **Cache AI aggressively.** Most "AI features" are really cache features with a cold-start API call.
- **Free-tier-first is a design constraint, not a budget hack.** It forced OpenStreetMap, manual payments, and edge functions — all of which are *better* choices at this scale, not just cheaper.
- **Verifiable handoffs beat trust.** The 4-digit pickup code turned "trust the driver" into a protocol. Look for every human handoff that can carry a code.
- **Write the README while you build.** Half of this document's accuracy comes from decisions being captured the week they were made — future-you cannot reconstruct *why* from code alone.
- **One binary with roles beats N apps** until real scale says otherwise.

---

# 📌 SECTION 15: QUICK REFERENCE CARD

*The one-pager. If you only read this, you can run everything.*

## ▶️ Start everything (dev)

```bash
# 1. Mobile (customer + driver app)
cd mobile && flutter pub get && flutter run

# 2. Storefront → http://localhost:3000
cd web/storefront && npm install && npm run dev

# 3. Admin portal → http://localhost:3001
cd web/admin && npm install && npm run dev
```

## ✅ Verify / build / test

```bash
cd mobile && flutter test                      # 53 tests, must be green
cd mobile && flutter build appbundle --release # Play Store .aab
cd web/storefront && npm run build             # 7 routes
cd web/admin && npm run build                  # 13 routes
supabase functions deploy expand-search-query
supabase functions deploy generate-product-description
```

## 🔑 The 5 "endpoints" that matter

| Call | Where | Purpose |
|---|---|---|
| `rpc/place_order` (POST) | PostgREST | Atomic checkout: locks stock, creates order, returns order UUID |
| `rpc/complete_delivery` (POST) | PostgREST | Driver closes order with 4-digit code + payment status |
| `functions/v1/expand-search-query` (POST `{query}`) | Edge Function | Swahili/English search synonyms (`{"terms": [...]}`) |
| `functions/v1/generate-product-description` (POST `{name,category,keywords}`) | Edge Function | Admin-only AI copy (`{"description": "..."}`) |
| Supabase Realtime channel on `orders` | WebSocket | Status timeline, driver queue, Kanban chime |

## 🌍 Environment variables cheat sheet

| File | Required | Optional |
|---|---|---|
| `mobile/.env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `CLOUDINARY_CLOUD_NAME`, `SENTRY_DSN` |
| `web/storefront/.env.local` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `NEXT_PUBLIC_BRANCH_WHATSAPP_NUMBER` |
| `web/admin/.env.local` | both `NEXT_PUBLIC_SUPABASE_*` | `SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_CLOUDINARY_*`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` |
| Supabase secrets | one of `GROQ_API_KEY` / `GEMINI_API_KEY` / `OPENROUTER_API_KEY` | `SENTRY_DSN` |

> Chain order: **Groq → Gemini → OpenRouter** (first key present wins).

## 🔧 Most common fixes

| Problem | Fix |
|---|---|
| `Unable to load asset: .env` | Create `mobile/.env` → `flutter clean && flutter run` |
| Empty catalog, "placeholder credentials" in console | Real keys in `mobile/.env` → `flutter clean` |
| Admin bounces to `/access-denied` | `update profiles set role='admin' where phone='...';` then re-login |
| AI returns "provider not configured" | `supabase secrets set GROQ_API_KEY=...` |
| Port 3000 busy | `npx next dev -p 3010` |
| Search never expands | Deploy the edge function; note the 1.5s timeout fallback is by design |
| SDK/version solve fails | `flutter upgrade` (need ≥3.5.0) |

## 🔢 Numbers to remember

| Constant | Value | Defined in |
|---|---|---|
| Flat delivery fee | **TZS 3,000** | `mobile/lib/config/app_constants.dart` |
| Pickup code | 4 digits (random) | `generate_pickup_code()` SQL |
| Order number | `ORD-YYYY-0001` | `place_order` SQL |
| Order statuses | `placed → packing → ready → out_for_delivery → delivered` (+ `cancelled`) | `order_status` enum |
| Roles | `customer` / `driver` / `admin` | `user_role` enum |
| AI description gate | 15–450 chars, 10 req/min | edge function |
| Search timeout | 1.5 s then literal fallback | `smart_search_service.dart` |
| Sentry sampling | 10% | `sentry_service.dart` |

## 🔗 Where to look when something breaks

| Topic | File |
|---|---|
| App boot / Supabase init | `mobile/lib/main.dart` → `config/supabase_config.dart` |
| Checkout logic | `mobile/lib/screens/customer/checkout_screen.dart` → `services/order_service.dart` |
| The atomic order SQL | `supabase/migrations/0004_order_placement_function.sql` (and `supabase/schema_full.sql`) |
| Delivery completion SQL | `supabase/migrations/0008_complete_delivery_function.sql` |
| AI prompts/providers | `supabase/functions/*/index.ts` |
| Web authorization | `web/admin/middleware.ts` |
| Ops & deployment | `docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md` |
| Build history & phase map | `docs/ROADMAP_ONE_PAGE_SUMMARY.md` |

---

<div align="center">

**Quickopia** · v1.0.0-pilot · Built for Dar es Salaam 🇹🇿
*Every arrow in the architecture diagram, documented. — Last updated: September 2026*

</div>























