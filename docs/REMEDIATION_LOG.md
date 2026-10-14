# 🛡️ Quickopia — Remediation Log & Verification Matrix

> **Scope**: Verification of `QUICKOPIA_SYSTEM_INSPECTION_AND_STRATEGY_REPORT.md` (a.k.a. `docs/QUICKOPIA_INSPECTION_REPORT.md`) against the codebase, and execution of its **Part 6 Remediation Action Plan**.
> **Date**: September 5, 2026

---

## 1. Verification Matrix (Report Claim → Code Evidence → Status)

| # | Report Finding | Evidence (verified in code) | Status | Fix |
|---|----------------|------------------------------|--------|-----|
| 1.1 | **Customer self-cancellation overwritten** — `0016` allowed the owning customer to cancel while `status='placed'`; `0019` redefined `cancel_order` as admin-only. | `0016_order_cancellation_enhancement.sql` L19-27 vs `0019_driver_referral_banners_fix.sql` L235-259 | ✅ Confirmed | `0022` §3 restores combined authorization (admin OR owning customer, customer only while `'placed'`, stock restored atomically). Customer UI already exists: `order_success_screen.dart` "Cancel Order (Pre-Packing)" calls `cancel_order` RPC. |
| 1.2 | **Manual Lipa Namba dispatch-before-payment gap** | Admin Kanban advances Lipa Namba orders with `payment_status='pending'` | ✅ Confirmed (design gap) | Partially mitigated: Kanban shows an "Lipa Namba awaiting verification" alert bar and `updatePaymentStatus()` helper exists in `web/admin/lib/orders.ts`. Full fix = `awaiting_payment_confirmation` state + AzamPay/Selcom webhook (report Part 5, item 1). |
| 1.3 | **Multi-branch schema vs single-branch admin UI** — `fetchActiveOrders()` had no branch filter; `get_available_deliveries()` returned all branches. | `web/admin/lib/orders.ts` (pre-fix), `0017`/`0019` RPC definitions | ✅ Confirmed | Admin: `fetchActiveOrders(branchId)` + branch selector + realtime branch guards in `OrderKanbanBoard.tsx`. Driver: `0022` §5 scopes `get_available_deliveries()` by the driver's `profiles.branch_id` (explicit param override supported). |
| 1.4 | **Search query cache poisoning** — any query >2 chars had AI output cached forever. | `supabase/functions/expand-search-query/index.ts` (pre-fix): unconditional insert when `expandedTerms.length > 1` | ✅ Confirmed | Edge function now validates queries with `isValidSearchTerm()` (length 2-40, charset allowlist, no `aaaa` repeats, must contain a letter), filters AI output terms, and only caches fully sanitized results. DB: `0022` §6 restricts `search_query_cache` INSERT to admin/service_role; the function writes via `SUPABASE_SERVICE_ROLE_KEY`. |
| 2.1 (V1) | **CRITICAL — Direct insert fallback bypasses stock/price guards**: `0018` created "customers can insert own orders fallback" RLS policy; Flutter `_placeOrderDirectFallback()` inserted orders/items client-side (no stock decrement, client-set totals). | `0018` L167-170 + L194-203; `mobile/lib/services/order_service.dart` (pre-fix) | ✅ Confirmed | `0022` §1 drops both fallback policies and enforces `WITH CHECK (public.is_admin())` on `orders`/`order_items` INSERT. Flutter fallback deleted — `OrderService.placeOrder()` is RPC-only. |
| 2.2 (V2) | **HIGH — `place_order` stripped of input validation** by `0018` (identity guard + positive-quantity check from `0015` removed → customer spoofing / qty manipulation). | `0015` L82-99 vs `0018` L57-147 (no guards) | ✅ Confirmed | `0022` §2 restores all guards + hardens further: strict identity (`p_customer_id IS DISTINCT FROM auth.uid()` rejects anonymous sessions entirely), empty-items rejection, quantity > 0, negative delivery-fee rejection, branch auto-resolution retained. |
| 2.3 (V3) | **HIGH — Pickup code brute force**: 4-digit code, `complete_delivery` had no attempt counter or rate limit. | `0008`/`0009`/`0019` `complete_delivery` definitions | ✅ Confirmed | `0022` §4 adds `orders.failed_pickup_attempts` (default 0); 5 wrong codes lock the order for non-admins with per-attempt remaining-count feedback; correct code resets the counter; **admin override** preserved (must still supply the correct code). Driver UI parses remaining attempts + lock state (Swahili messages). |
| 2.4 (V4) | **MEDIUM — Race condition in fallback driver acceptance**: `acceptOrder()` fell back to a direct `.update({'driver_id': ...})` overwriting the atomic RPC's `FOR UPDATE` guarantee. | `mobile/lib/services/driver_order_service.dart` (pre-fix) | ✅ Confirmed | Direct-update fallback removed — acceptance is RPC-only; "already been claimed" errors surface to the driver. |

---

## 2. Hardening Added on Top of the Prior Remediation (this pass)

1. **Anonymous-session loophole closed in `place_order`** — the restored guard originally kept `0015`'s `auth.uid() IS NOT NULL AND …` form, which still let *anonymous* callers bypass the identity check. Now `p_customer_id IS DISTINCT FROM auth.uid()` rejects anon outright. (`0022` §2, Guard 1)
2. **RPC execution grants tightened** — PostgreSQL grants `EXECUTE` to `PUBLIC` by default and `0018` explicitly granted `place_order` to `anon`. `0022` §7 revokes `anon`/`public` and grants only `authenticated` + `service_role` for `place_order` and `cancel_order`. Both customer surfaces require sign-in before checkout, so no flow breaks. (Idempotent statements.)
3. **Negative delivery-fee guard** — `p_delivery_fee_tzs < 0` now rejected (client-supplied fee could otherwise shrink the payable total). (`0022` §2, Guard 2b)
4. **Admin override on pickup-code lock** — the lockout originally blocked admins too, contradicting the report's "require admin override" remediation. Admins can now complete a locked order with the **correct** code (counter resets); non-admins stay hard-locked. (`0022` §4)
5. **`OrderService` documentation** — the RPC-only contract and its security rationale are now documented at the call site.

---

## 3. Deployment Checklist

1. **Apply `0022_security_hardening_and_operational_fixes.sql`** — every statement is idempotent (`DROP POLICY IF EXISTS`, `CREATE OR REPLACE FUNCTION`, `ADD COLUMN IF NOT EXISTS`), so it is safe whether or not an earlier draft was already applied.
2. **Redeploy `expand-search-query`** (`supabase functions deploy expand-search-query`) — `SUPABASE_SERVICE_ROLE_KEY` is injected automatically by Supabase; no extra secrets needed.
3. **Verify** with quick smoke tests:
   - `anon` key `POST /rest/v1/rpc/place_order` → expect `permission denied` (grant revoked).
   - 5 wrong pickup codes on any order → 5th response locks; admin with correct code still completes.
   - Admin Kanban branch selector filters orders and realtime events respect the selection.
   - `expand-search-query` with `query=xyz123badword` → returns terms but must **not** create a `search_query_cache` row.
4. **Manual ops step (report Part 6, item 5)** — rename the repo root folder `E-commerce-App-UI-Flutter-master` → `quickopia` and update any local paths/remotes. This must be done outside the IDE session while the workspace is closed.

## 4. Still Open (tracked in README roadmap / report)

- `awaiting_payment_confirmation` order state + automated mobile-money verification (AzamPay/Selcom webhook) — report Part 1 item 2 / Part 5 item 1.
- Geographical proximity radius for driver pools (currently branch equality) — report Part 1 item 3.
- Search-cache dictionary curation & periodic garbage purge job (e.g. delete rows with `hit_count = 0` older than 30 days).
- Rename repo folder to `quickopia` (manual).
