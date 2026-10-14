# 🚀 Quickopia — 30-Prompt Architecture & Launch Roadmap (Executive Summary)

A complete, production-ready on-demand supermarket platform built for Tanzania across Flutter Mobile, Next.js Storefront, Next.js Admin Portal, and Supabase Backend.

---

## 🗺️ Phase-by-Phase Roadmap Summary

### Phase 1: Foundation & Base Schema (Prompts 0 – 3)
- **Prompt 0:** Technical stack alignment (Flutter, Next.js, Supabase, Tailwind, zero-cost OpenStreetMap).
- **Prompt 1:** Postgres schemas & migrations (`branches`, `categories`, `products`, `profiles`, `addresses`, `orders`, `order_items`).
- **Prompt 2:** Row Level Security (RLS) policies and role-based permissions (`customer`, `driver`, `admin`).
- **Prompt 3:** Seed data for Dar es Salaam supermarket pilot (Mlimani City branch, 8 grocery categories, 40+ products in TZS).

### Phase 2: Mobile Customer Shopping (Prompts 4 – 8)
- **Prompt 4:** Dual-role AuthGate (`mobile/lib/gates/auth_gate.dart`) & customer catalog browsing with search and category filtering.
- **Prompt 5:** Cart state management (`CartProvider`) with persistent storage and stock availability guards.
- **Prompt 6:** Dual-fulfillment checkout (Doorstep Delivery with OpenStreetMap interactive pin & landmark vs. Click & Collect).
- **Prompt 7:** Realtime order tracking timeline via WebSocket channel with audio/visual progress updates.
- **Prompt 8:** Atomic `place_order` database RPC function with `FOR UPDATE` row locks, preventing race conditions and overselling.

### Phase 3: Driver Experience (Prompts 9 – 13)
- **Prompt 9:** Driver queue and assignment overview with live shift toggle and daily earnings counters.
- **Prompt 10:** Active delivery card with customer contact (WhatsApp/call) and native Google Maps / Apple Maps GPS routing.
- **Prompt 11:** Secure 4-digit pickup code verification flow (`complete_delivery` RPC) preventing false delivery claims.
- **Prompt 12:** Realtime driver GPS location broadcasts over Supabase Realtime for live customer tracking.
- **Prompt 13:** Order history and earnings breakdown for supermarket-employed drivers.

### Phase 4: Web Storefront (Prompts 14 – 16)
- **Prompt 14:** Customer-facing Next.js 14 App Router storefront (`web/storefront`) with static generation and dynamic search.
- **Prompt 15:** Interactive shopping cart drawer, instant category filters, and live stock indicator badges.
- **Prompt 16:** Web checkout with OpenStreetMap delivery coordinate picker, matching mobile order schema 1:1.

### Phase 5: Admin Portal (Prompts 17 – 21)
- **Prompt 17:** Dedicated Next.js 14 Admin Portal (`web/admin`) with role-gated middleware blocking non-admin accounts.
- **Prompt 18:** Realtime operational Order Kanban board (`New` &rarr; `Packing` &rarr; `Ready` &rarr; `Dispatched`) with packing checklist modals.
- **Prompt 19:** Catalog & stock management with Cloudinary image upload and instant stock delta adjustments.
- **Prompt 20:** Driver roster management, live driver picker, and mid-shift driver reassignment with realtime app updates.
- **Prompt 21:** Business analytics dashboard with date filtering, total revenue, order counts, and top-selling product metrics.

### Phase 6: AI Features (Prompts 22 – 23)
- **Prompt 22:** AI Product Description Generator via Supabase Edge Function (`generate-product-description`) using Gemini 1.5 Flash (temperature 0.3) with draft-review safety.
- **Prompt 23:** AI-Assisted Bilingual Query Expansion (`expand-search-query`) handling Swahili/English queries (*sukari*, *unga*, *mafuta*) with Postgres caching and graceful direct-search fallback.

### Phase 7: Notifications & Stickiness (Prompts 24 – 25)
- **Prompt 24:** SMS notification pipeline (Beem Africa / Twilio) sending transactional updates at milestone order transitions.
- **Prompt 25:** Customer retention features: unique referral codes (`QK-XXXXX`), 1-tap "Reorder Basket" with live catalog pricing, and WhatsApp Cart Share.

### Phase 8: Hardening & Launch (Prompts 26 – 30)
- **Prompt 26:** Systematic Security Audit (RLS policy tightening, PostgREST trigger column guards, negative quantity protection, service-role key containment).
- **Prompt 27:** Error tracking & monitoring via Sentry across all 4 surfaces with non-PII tagging, 10% sampling, and defensive initialization.
- **Prompt 28:** End-to-end Manual QA Pass across 6 user journeys, concurrency stress-testing, and customer pre-packing order cancellation with atomic stock restoration.
- **Prompt 29:** Production deployment checklist, Android release signing configuration, and search crawler blocking (`robots.txt`).
- **Prompt 30:** Final branding and polish pass: SVG logo & wordmark, Android cold-start splash screen, Next.js favicons, and cross-surface visual harmonization.

---

## 🎯 Production Status
- **Mobile Unit & Widget Tests:** 53 / 53 Passing (Exit Code 0)
- **Storefront Build:** 7 / 7 Routes Compiled (Exit Code 0)
- **Admin Portal Build:** 13 / 13 Routes Compiled (Exit Code 0)
- **Database Migrations:** 16 / 16 Applied Cleanly & Hardened
