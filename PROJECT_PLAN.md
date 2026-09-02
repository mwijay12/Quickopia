# 🛒 Quickopia — Master Engineering Blueprint & 30-Prompt Implementation Plan
## On-Demand Supermarket & Multi-Category Delivery Platform (Tanzania Edition)

---

## 🏷️ Brand Identity & Locked Scope

- **Platform Name**: **Quickopia**
- **Core Concept**: Single-supermarket on-demand multi-category shopping platform (groceries, household goods, personal care, electronics, etc.) with dual fulfillment:
  1. **Express Doorstep Delivery** (supermarket-employed drivers, landmark addressing, zero-cost map navigation).
  2. **Click & Collect (Store Pickup)** (order packed ahead of time, customer collects with 4-digit pickup code in under 60 seconds).
- **Market**: Tanzania (Dar es Salaam pilot, multi-branch ready).
- **Visual Branding Palette**:
  - **Primary Base**: Deep Navy / Blue (`#0F172A` / `#1E293B`) — establishes trust, technical authority, and premium polish.
  - **Accent**: Warm Amber / Orange (`#F59E0B` / `#EA580C`) — reserved strictly for high-converting CTAs (*Add to Cart*, *Place Order*, *Start Navigation*).
  - **Neutrals**: Clean grays/whites (`#F8FAFC`, `#FFFFFF`, `#64748B`) — optimized for WCAG contrast and readability on mobile, tablet, and driver devices.

---

## 🏛️ System Architecture

```
                  ┌────────────────────────────────────────────────────────┐
                  │                 SUPABASE CLOUD BACKEND                 │
                  │  (Postgres DB + RLS, Auth, Realtime Engine, Storage)  │
                  └──────────┬──────────────┬──────────────┬───────────────┘
                             │              │              │               │
               ┌─────────────┴──┐    ┌──────┴──────┐    ┌──┴──────────┐   ┌┴────────────────┐
               ▼                ▼    ▼             ▼    ▼             ▼   ▼                 ▼
     ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
     │ CUSTOMER FLUTTER │ │  DRIVER FLUTTER  │ │ NEXT.JS STOREWEB │ │ NEXT.JS ADMIN &  │
     │    MOBILE VIEW   │ │   COMPANION VIEW │ │ (Vercel Deploy)  │ │ PACKING PORTAL   │
     │ (Same app, RLS)  │ │ (Role-switched)  │ │ (WhatsApp orders)│ │ (Tablet/Desktop) │
     └──────────────────┘ └──────────────────┘ └──────────────────┘ └──────────────────┘
```

### Technology Stack Summary
| Layer | Technology | Key Advantage |
|---|---|---|
| **Mobile App** | Flutter (single unified app, role-based customer ↔ driver) | 60fps native performance, single codebase for iOS/Android |
| **Web Storefront & Admin** | Next.js (App Router) on Vercel | Instant global edge CDN, SEO-friendly, zero-config deployment |
| **Backend & Realtime** | Supabase (PostgreSQL with Row Level Security) | Built-in Auth, Realtime DB subscriptions, generous free tier |
| **Mapping & Navigation** | OpenStreetMap (`flutter_map`) + Native Intent | Zero Google Cloud billing fees; native voice turn-by-turn navigation |
| **Images & Media** | Cloudinary Free Tier (Supabase Storage fallback) | Automatic responsive optimization and free storage |
| **AI Features** | Gemini API via Supabase Edge Functions | AI description generation and bilingual smart search |
| **Payments** | Cash on Delivery/Pickup, Manual Lipa Namba (Phase 1) → AzamPay/Selcom (Phase 2) | Instant adoption without waiting for commercial merchant accounts |

---

## 🗺️ FULL 30-PROMPT ROADMAP

### Phase 0 — Foundation
- **Prompt 0: Environment + Project Foundation** *(Current)*: Supabase setup, Flutter cleanup & rename, Next.js web scaffold, branding tokens, env vars.

### Phase 1 — Backend & Security
- **Prompt 1: Database Schema**: `categories`, `products`, `branches`, `orders`, `order_items`, `profiles`, `drivers` tables + stock race-condition constraints.
- **Prompt 2: Row Level Security & Role Model**: Strict RLS policies enforcing isolation between customer, driver, and admin roles.
- **Prompt 3: Supabase Auth Integration in Flutter**: Phone/email login, profile onboarding, and role-based initial route guard.

### Phase 2 — Core Shopping (Flutter)
- **Prompt 4: Dynamic Product Catalog**: Fetch Supabase categories and products with category pills and search filter.
- **Prompt 5: Cart State Management**: Reactive cart provider with TZS currency formatting and persistent storage.
- **Prompt 6: Product Detail Screen**: Image gallery, unit price, stock badge, and quantity controls.
- **Prompt 7: Dual Fulfillment Checkout**: Pickup vs Delivery toggle, landmark form, and OpenStreetMap pin selector.
- **Prompt 8: Order Placement & Confirmation**: Generate unique order ID, 4-digit pickup code, and order success view.
- **Prompt 9: Live Order Tracking**: Realtime WebSocket subscription to order status updates with visual timeline.
- **Prompt 10: Customer Profile & Order History**: Past orders, re-order basket, and saved addresses.

### Phase 3 — Driver Experience (Same App, Role-Switched)
- **Prompt 11: Driver Dashboard Shell**: Role check routes drivers to dedicated delivery queue.
- **Prompt 12: Driver Order List & Navigation**: View assigned orders, one-tap phone/WhatsApp dial, and launch native Google/Apple Maps navigation.
- **Prompt 13: Delivery Confirmation Flow**: Cash/Lipa Namba collection verification and mark-as-delivered.

### Phase 4 — Web Presence (Next.js on Vercel)
- **Prompt 14: Next.js Storefront Foundation**: Vercel-ready landing page connected to Supabase.
- **Prompt 15: Web Catalog, Cart & WhatsApp Fallback**: Full product catalog with direct "Order via WhatsApp" button.
- **Prompt 16: Web Checkout Flow**: Web-based dual fulfillment checkout.

### Phase 5 — Admin Portal (Next.js)
- **Prompt 17: Admin Portal Foundation & Auth**: Role-gated dashboard layout.
- **Prompt 18: Order Kanban & Packing Checklist**: Live incoming orders (New → Packing → Ready → Dispatched) with audio chime and packer item checklist.
- **Prompt 19: Catalog & Stock Management**: Add/edit items, stock toggle, and Cloudinary image uploader.
- **Prompt 20: Driver Dispatch**: Manual driver assignment from active driver roster.
- **Prompt 21: Admin Analytics**: Daily revenue, order counts, top-selling items.

### Phase 6 — AI Features
- **Prompt 22: AI Product Description Generator**: Supabase Edge Function calling Gemini API to draft rich supermarket product descriptions.
- **Prompt 23: Bilingual Smart Search**: Swahili ↔ English query expansion (e.g. "maziwa" → "fresh milk").

### Phase 7 — Notifications & Stickiness
- **Prompt 24: SMS Status Notifications**: Twilio / Beem Africa SMS alerts on order status changes.
- **Prompt 25: Stickiness & Growth**: Referral codes, one-tap reorder basket, WhatsApp cart sharing.

### Phase 8 — Hardening & Launch
- **Prompt 26: Security Audit**: RLS penetration review, input sanitization, and policy tests.
- **Prompt 27: Error Tracking**: Sentry SDK integration across Flutter and Web.
- **Prompt 28: Concurrency & QA Pass**: Stock race condition tests and edge cases.
- **Prompt 29: Production Deployment Checklist**: Vercel production domains, Supabase production instance, Android release build.
- **Prompt 30: Final Branding Polish**: App launcher icons, splash screen, and final aesthetic pass.
