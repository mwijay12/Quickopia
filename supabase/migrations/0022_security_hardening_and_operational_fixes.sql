-- ============================================================================
-- Migration: 0022_security_hardening_and_operational_fixes.sql
-- Description: Critical security hardening, customer self-cancellation restoration,
--              pickup-code brute force mitigation, and multi-branch delivery scoping.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DROP INSECURE FALLBACK RLS POLICIES ON ORDERS & ORDER_ITEMS
-- ----------------------------------------------------------------------------
-- Eliminate client direct INSERT bypasses that allow malicious price/stock tampering
DROP POLICY IF EXISTS "customers can insert own orders fallback" ON public.orders;
DROP POLICY IF EXISTS "insert order items via parent order access" ON public.order_items;

-- Strictly restrict direct table INSERTs to admin/service roles.
-- Normal shoppers MUST place orders via the atomic, validated place_order RPC.
DROP POLICY IF EXISTS "prevent direct client order inserts" ON public.orders;
CREATE POLICY "prevent direct client order inserts" ON public.orders
  FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "prevent direct client order item inserts" ON public.order_items;
CREATE POLICY "prevent direct client order item inserts" ON public.order_items
  FOR INSERT WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 2. RE-HARDEN ATOMIC ORDER PLACEMENT RPC WITH SECURITY GUARDS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.place_order(
  p_customer_id uuid,
  p_branch_id uuid,
  p_fulfillment_type fulfillment_type,
  p_delivery_city text,
  p_delivery_neighborhood text,
  p_delivery_landmark text,
  p_delivery_house_details text,
  p_delivery_latitude double precision,
  p_delivery_longitude double precision,
  p_customer_phone text,
  p_payment_method payment_method,
  p_delivery_fee_tzs numeric,
  p_items jsonb
)
RETURNS uuid AS $$
DECLARE
  v_order_id uuid;
  v_order_number text;
  v_pickup_code text;
  v_item jsonb;
  v_product products%rowtype;
  v_subtotal numeric := 0;
  v_line_total numeric;
  v_qty integer;
  v_effective_branch_id uuid := p_branch_id;
BEGIN
  -- Security Guard 1: Caller must be the customer themselves or an authorized admin.
  -- STRICT identity check: anonymous sessions (auth.uid() IS NULL) are rejected
  -- outright, and a signed-in user can never attribute an order to a different
  -- customer. (The previous "auth.uid() IS NOT NULL AND ..." form allowed
  -- anonymous callers to bypass the check entirely.)
  IF p_customer_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized customer assignment';
  END IF;

  -- Security Guard 2: Order items payload cannot be empty
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Order items list cannot be empty';
  END IF;

  -- Security Guard 2b: Delivery fee is client-supplied; never allow a negative
  -- fee to shrink the payable total.
  IF COALESCE(p_delivery_fee_tzs, 0) < 0 THEN
    RAISE EXCEPTION 'Delivery fee cannot be negative';
  END IF;

  -- Fallback branch resolution if needed
  IF v_effective_branch_id IS NULL OR NOT EXISTS (SELECT 1 FROM branches WHERE id = v_effective_branch_id) THEN
    SELECT id INTO v_effective_branch_id FROM branches LIMIT 1;
  END IF;

  -- Step 1: Pre-lock and validate stock for EVERY item to prevent race conditions & overselling
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_qty := (v_item->>'quantity')::integer;

    -- Security Guard 3: Non-positive or null quantities are strictly forbidden
    IF v_qty IS NULL OR v_qty <= 0 THEN
      RAISE EXCEPTION 'Item quantity must be a positive integer';
    END IF;

    -- Acquire pessimistic row lock
    SELECT * INTO v_product
    FROM products
    WHERE id = (v_item->>'product_id')::uuid
    FOR UPDATE;

    IF v_product.id IS NULL THEN
      RAISE EXCEPTION 'Product % not found', v_item->>'product_id';
    END IF;

    IF NOT v_product.is_available THEN
      RAISE EXCEPTION 'Product % is currently unavailable', v_product.title;
    END IF;

    IF v_product.stock_quantity < v_qty THEN
      RAISE EXCEPTION 'Insufficient stock for product % (available: %, requested: %)',
        v_product.title, v_product.stock_quantity, v_qty;
    END IF;
  END LOOP;

  -- Step 2: Generate order number and 4-digit pickup code
  v_order_number := 'ORD-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('order_number_seq')::text, 4, '0');
  v_pickup_code := public.generate_pickup_code();

  -- Step 3: Insert order header with server-governed status and totals initialized to zero
  INSERT INTO orders (
    order_number, customer_id, branch_id, fulfillment_type, status,
    delivery_city, delivery_neighborhood, delivery_landmark, delivery_house_details,
    delivery_latitude, delivery_longitude, customer_phone, pickup_code,
    subtotal_tzs, delivery_fee_tzs, total_amount_tzs, payment_method, payment_status,
    failed_pickup_attempts
  ) VALUES (
    v_order_number, p_customer_id, v_effective_branch_id, p_fulfillment_type, 'placed',
    p_delivery_city, p_delivery_neighborhood, p_delivery_landmark, p_delivery_house_details,
    p_delivery_latitude, p_delivery_longitude, p_customer_phone, v_pickup_code,
    0, COALESCE(p_delivery_fee_tzs, 0), 0, p_payment_method, 'pending',
    0
  ) RETURNING id INTO v_order_id;

  -- Step 4: Insert order line items with server-enforced product prices and decrement stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_qty := (v_item->>'quantity')::integer;
    SELECT * INTO v_product FROM products WHERE id = (v_item->>'product_id')::uuid;

    v_line_total := v_product.price_tzs * v_qty;
    v_subtotal := v_subtotal + v_line_total;

    INSERT INTO order_items (order_id, product_id, title, unit_price_tzs, quantity, total_tzs)
    VALUES (v_order_id, v_product.id, v_product.title, v_product.price_tzs, v_qty, v_line_total);

    UPDATE products
    SET stock_quantity = stock_quantity - v_qty,
        updated_at = now()
    WHERE id = v_product.id;
  END LOOP;

  -- Step 5: Finalize order totals based strictly on verified catalog prices
  UPDATE orders
  SET subtotal_tzs = v_subtotal,
      total_amount_tzs = v_subtotal + COALESCE(p_delivery_fee_tzs, 0),
      updated_at = now()
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- 3. RESTORE CUSTOMER SELF-CANCELLATION WITH STOCK RESTORATION
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_order(
  p_order_id uuid,
  p_reason text DEFAULT null
)
RETURNS void AS $$
DECLARE
  v_order orders%rowtype;
  v_item record;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  -- Authorization check: must be admin OR the customer who placed the order
  IF v_order.customer_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'You are not authorized to cancel this order';
  END IF;

  -- Customers can cancel only while order is still in 'placed' status (before packing starts)
  IF v_order.customer_id = auth.uid() AND NOT public.is_admin() AND v_order.status != 'placed' THEN
    RAISE EXCEPTION 'Orders can only be cancelled before packing begins. Please contact supermarket support.';
  END IF;

  -- Prevent cancelling already completed or closed orders
  IF v_order.status IN ('delivered', 'cancelled') THEN
    RAISE EXCEPTION 'This order is already closed and cannot be cancelled';
  END IF;

  -- Atomically restore stock for each item in the order
  FOR v_item IN SELECT * FROM order_items WHERE order_id = p_order_id LOOP
    UPDATE products
    SET stock_quantity = stock_quantity + v_item.quantity,
        updated_at = now()
    WHERE id = v_item.product_id;
  END LOOP;

  -- Mark order as cancelled
  UPDATE orders
  SET status = 'cancelled',
      updated_at = now()
  WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- 4. HARDEN PICKUP CODE VERIFICATION AGAINST BRUTE FORCE ATTACKS
-- ----------------------------------------------------------------------------
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS failed_pickup_attempts integer DEFAULT 0;

CREATE OR REPLACE FUNCTION public.complete_delivery(
  p_order_id uuid,
  p_entered_code text,
  p_payment_status payment_status
)
RETURNS void AS $$
DECLARE
  v_order orders%rowtype;
  v_remaining_attempts integer;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  -- Driver or Admin authorization check
  IF v_order.driver_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'You are not authorized to complete this order';
  END IF;

  IF v_order.status = 'delivered' THEN
    RAISE EXCEPTION 'This order is already marked as delivered';
  END IF;

  -- Anti-Brute-Force: Lock confirmation after 5 consecutive failures.
  -- Admin staff retain override: they can still complete the order with the
  -- CORRECT code (the code check below always applies; the counter resets on
  -- success), but non-admin callers are hard-locked.
  IF COALESCE(v_order.failed_pickup_attempts, 0) >= 5 AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Too many failed code attempts (locked). Contact supermarket manager to verify.';
  END IF;

  -- Verification check
  IF v_order.pickup_code IS DISTINCT FROM trim(p_entered_code) THEN
    UPDATE orders
    SET failed_pickup_attempts = COALESCE(failed_pickup_attempts, 0) + 1,
        updated_at = now()
    WHERE id = p_order_id;

    v_remaining_attempts := GREATEST(0, 5 - (COALESCE(v_order.failed_pickup_attempts, 0) + 1));
    RAISE EXCEPTION 'Incorrect confirmation code (% attempt(s) remaining)', v_remaining_attempts;
  END IF;

  -- Code verified successfully: mark delivered and reset failed attempts counter
  UPDATE orders
  SET status = 'delivered',
      payment_status = p_payment_status,
      failed_pickup_attempts = 0,
      updated_at = now()
  WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- 5. MULTI-BRANCH DRIVER DELIVERY POOL SCOPING
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_available_deliveries(p_branch_id uuid DEFAULT NULL)
RETURNS SETOF public.orders AS $$
DECLARE
  v_driver_branch_id uuid;
  v_target_branch_id uuid;
BEGIN
  IF p_branch_id IS NOT NULL THEN
    v_target_branch_id := p_branch_id;
  ELSE
    SELECT branch_id INTO v_driver_branch_id FROM profiles WHERE id = auth.uid();
    v_target_branch_id := v_driver_branch_id;
  END IF;

  IF v_target_branch_id IS NOT NULL THEN
    RETURN QUERY
      SELECT * FROM public.orders
      WHERE driver_id IS NULL
        AND branch_id = v_target_branch_id
        AND status IN ('ready', 'packing', 'placed', 'out_for_delivery')
        AND fulfillment_type = 'delivery'
      ORDER BY created_at ASC;
  ELSE
    RETURN QUERY
      SELECT * FROM public.orders
      WHERE driver_id IS NULL
        AND status IN ('ready', 'packing', 'placed', 'out_for_delivery')
        AND fulfillment_type = 'delivery'
      ORDER BY created_at ASC;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- 6. HARDEN SEARCH_QUERY_CACHE INSERT POLICY
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow insert on search_query_cache" ON public.search_query_cache;
CREATE POLICY "only service role or admin inserts search_query_cache" ON public.search_query_cache
  FOR INSERT WITH CHECK (public.is_admin() OR auth.role() = 'service_role');

-- ----------------------------------------------------------------------------
-- 7. RPC EXECUTION GRANTS — CLOSE THE ANONYMOUS SPOOFING LOOPHOLE
-- ----------------------------------------------------------------------------
-- PostgreSQL grants EXECUTE on functions to PUBLIC by default, and migration
-- 0018 explicitly granted place_order to anon. With Guard 1 now rejecting
-- anonymous sessions, anon execution is pure attack surface (argument
-- enumeration / DoS on the order path). Both customer surfaces (Flutter app
-- and web storefront) require sign-in before checkout, so no anonymous flow
-- is broken. All statements below are idempotent.
REVOKE EXECUTE ON FUNCTION public.place_order(
  uuid, uuid, fulfillment_type, text, text, text, text,
  double precision, double precision, text, payment_method, numeric, jsonb
) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.place_order(
  uuid, uuid, fulfillment_type, text, text, text, text,
  double precision, double precision, text, payment_method, numeric, jsonb
) TO authenticated, service_role;

-- cancel_order: the function body already rejects anonymous callers
-- (customer_id IS DISTINCT FROM NULL), but tighten the grant surface anyway.
REVOKE EXECUTE ON FUNCTION public.cancel_order(uuid, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.cancel_order(uuid, text) TO authenticated, service_role;
