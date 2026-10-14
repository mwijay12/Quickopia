-- 0019_driver_referral_banners_fix.sql
-- 1. Profile is_active column
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

-- 2. is_driver helper
CREATE OR REPLACE FUNCTION public.is_driver()
RETURNS boolean AS $$
  SELECT COALESCE(
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'driver' AND COALESCE(p.is_active, true) = true
    ),
    false
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 3. Hero Banners Table with RLS & Realtime
CREATE TABLE IF NOT EXISTS public.hero_banners (
  id text PRIMARY KEY,
  title text NOT NULL,
  subtitle text NOT NULL,
  tag text NOT NULL,
  image_url text,
  button_text text DEFAULT 'Shop Now',
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.hero_banners ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "public read hero banners" ON public.hero_banners FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "admin manage hero banners" ON public.hero_banners FOR ALL USING (public.is_admin());
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE hero_banners;

-- 4. Referral Code System
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS referral_code text UNIQUE,
  ADD COLUMN IF NOT EXISTS referred_by text,
  ADD COLUMN IF NOT EXISTS referral_count integer DEFAULT 0;

CREATE OR REPLACE FUNCTION public.generate_referral_code()
RETURNS text AS $$
DECLARE
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := 'QK-';
  i integer;
BEGIN
  FOR i IN 1..5 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION public.set_profile_referral_code()
RETURNS trigger AS $$
DECLARE
  v_new_code text;
BEGIN
  IF NEW.referral_code IS NULL THEN
    LOOP
      v_new_code := public.generate_referral_code();
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = v_new_code) THEN
        NEW.referral_code := v_new_code;
        EXIT;
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_set_profile_referral_code ON public.profiles;
CREATE TRIGGER tr_set_profile_referral_code
  BEFORE INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_profile_referral_code();

CREATE OR REPLACE FUNCTION public.apply_referral_code(p_code text)
RETURNS json AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_referrer_id uuid;
  v_clean_code text := upper(trim(p_code));
  v_own_code text;
  v_already_referred text;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'You must be signed in to apply a code');
  END IF;

  SELECT referral_code, referred_by INTO v_own_code, v_already_referred
  FROM public.profiles
  WHERE id = v_user_id;

  IF v_already_referred IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'You have already applied a referral code');
  END IF;

  IF v_own_code = v_clean_code THEN
    RETURN json_build_object('success', false, 'error', 'You cannot use your own referral code');
  END IF;

  SELECT id INTO v_referrer_id
  FROM public.profiles
  WHERE referral_code = v_clean_code;

  IF v_referrer_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Invalid referral code. Please check and try again');
  END IF;

  UPDATE public.profiles
  SET referred_by = v_clean_code
  WHERE id = v_user_id;

  UPDATE public.profiles
  SET referral_count = COALESCE(referral_count, 0) + 1
  WHERE id = v_referrer_id;

  RETURN json_build_object('success', true, 'message', 'Referral code applied successfully!');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC Functions for Orders
CREATE OR REPLACE FUNCTION public.admin_update_order_status(
  p_order_id uuid,
  p_new_status order_status,
  p_driver_id uuid DEFAULT null
)
RETURNS void AS $$
DECLARE
  v_order orders%rowtype;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admin staff can update orders this way';
  END IF;

  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF v_order.status IN ('delivered', 'cancelled') THEN
    RAISE EXCEPTION 'This order is already closed and cannot be changed';
  END IF;

  UPDATE orders
  SET status = p_new_status,
      driver_id = COALESCE(p_driver_id, driver_id),
      updated_at = now()
  WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_available_deliveries()
RETURNS SETOF public.orders AS $$
  SELECT * FROM public.orders
  WHERE driver_id IS NULL
    AND status IN ('ready', 'packing', 'placed', 'out_for_delivery')
    AND fulfillment_type = 'delivery'
  ORDER BY created_at ASC;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.accept_order_delivery(p_order_id uuid)
RETURNS void AS $$
DECLARE
  v_order public.orders%rowtype;
BEGIN
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF v_order.driver_id IS NOT NULL AND v_order.driver_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'This order has already been claimed by another driver';
  END IF;

  IF v_order.status IN ('delivered', 'cancelled') THEN
    RAISE EXCEPTION 'This order is already closed and cannot be accepted';
  END IF;

  UPDATE public.orders
  SET driver_id = auth.uid(),
      status = 'out_for_delivery',
      updated_at = now()
  WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.complete_delivery(
  p_order_id uuid,
  p_entered_code text,
  p_payment_status payment_status
)
RETURNS void AS $$
DECLARE
  v_order orders%rowtype;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF v_order.driver_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'You are not authorized to complete this order';
  END IF;

  IF v_order.status = 'delivered' THEN
    RAISE EXCEPTION 'This order is already marked as delivered';
  END IF;

  IF v_order.pickup_code IS DISTINCT FROM p_entered_code THEN
    RAISE EXCEPTION 'Incorrect confirmation code';
  END IF;

  UPDATE orders
  SET status = 'delivered',
      payment_status = p_payment_status,
      updated_at = now()
  WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.cancel_order(p_order_id uuid, p_reason text DEFAULT null)
RETURNS void AS $$
DECLARE
  v_order orders%rowtype;
  v_item record;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admin staff can cancel orders';
  END IF;

  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;
  IF v_order.status IN ('delivered', 'cancelled') THEN
    RAISE EXCEPTION 'This order cannot be cancelled anymore';
  END IF;

  FOR v_item IN SELECT * FROM order_items WHERE order_id = p_order_id LOOP
    UPDATE products SET stock_quantity = stock_quantity + v_item.quantity WHERE id = v_item.product_id;
  END LOOP;

  UPDATE orders SET status = 'cancelled', updated_at = now() WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Driver RLS Policies
DROP POLICY IF EXISTS "drivers view assigned orders" ON public.orders;
CREATE POLICY "drivers view assigned orders" ON public.orders
  FOR SELECT USING (auth.uid() = driver_id);

DROP POLICY IF EXISTS "drivers view unassigned ready orders" ON public.orders;
CREATE POLICY "drivers view unassigned ready orders" ON public.orders
  FOR SELECT USING (
    public.is_driver()
    AND driver_id IS NULL
    AND fulfillment_type = 'delivery'
    AND status IN ('ready', 'packing', 'placed', 'out_for_delivery')
  );

DROP POLICY IF EXISTS "view order items via parent order access" ON public.order_items;
CREATE POLICY "view order items via parent order access" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
        AND (
          orders.customer_id = auth.uid()
          OR orders.driver_id = auth.uid()
          OR is_admin()
          OR (is_driver() AND orders.driver_id IS NULL)
        )
    )
  );
