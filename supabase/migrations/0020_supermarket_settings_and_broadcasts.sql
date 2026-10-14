-- ============================================================================
-- Migration: 0020_supermarket_settings_and_broadcasts.sql
-- Description: Supermarket branding & store profile customization, and admin
--              broadcast notifications with real-time push.
-- ============================================================================

-- 1. Enhance public.settings with supermarket customization fields
ALTER TABLE public.settings 
  ADD COLUMN IF NOT EXISTS supermarket_name text DEFAULT 'Shoppers Supermarket',
  ADD COLUMN IF NOT EXISTS tagline text DEFAULT 'Fresh groceries & daily essentials at your doorstep',
  ADD COLUMN IF NOT EXISTS logo_url text DEFAULT 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300',
  ADD COLUMN IF NOT EXISTS city text DEFAULT 'Dar es Salaam',
  ADD COLUMN IF NOT EXISTS email text DEFAULT 'support@shoppers.co.tz',
  ADD COLUMN IF NOT EXISTS operating_hours text DEFAULT 'Mon - Sun: 07:30 AM - 10:30 PM',
  ADD COLUMN IF NOT EXISTS currency_symbol text DEFAULT 'TZS',
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- Ensure branch_settings row exists and has appropriate defaults
INSERT INTO public.settings (
  id, 
  restaurant_name, 
  supermarket_name, 
  tagline, 
  logo_url, 
  branch_address, 
  city, 
  phone, 
  email, 
  operating_hours, 
  currency_symbol, 
  is_active
)
VALUES (
  'branch_settings',
  'Shoppers Supermarket',
  'Shoppers Supermarket',
  'Fresh groceries & daily essentials at your doorstep',
  'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300',
  'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam',
  'Dar es Salaam',
  '+255 712 345 678',
  'support@shoppers.co.tz',
  'Mon - Sun: 07:30 AM - 10:30 PM',
  'TZS',
  true
)
ON CONFLICT (id) DO UPDATE SET
  supermarket_name = COALESCE(public.settings.supermarket_name, 'Shoppers Supermarket'),
  restaurant_name = 'Shoppers Supermarket',
  tagline = COALESCE(public.settings.tagline, 'Fresh groceries & daily essentials at your doorstep'),
  logo_url = COALESCE(public.settings.logo_url, 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300'),
  branch_address = COALESCE(public.settings.branch_address, 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam'),
  city = COALESCE(public.settings.city, 'Dar es Salaam'),
  phone = COALESCE(public.settings.phone, '+255 712 345 678'),
  email = COALESCE(public.settings.email, 'support@shoppers.co.tz'),
  operating_hours = COALESCE(public.settings.operating_hours, 'Mon - Sun: 07:30 AM - 10:30 PM'),
  currency_symbol = COALESCE(public.settings.currency_symbol, 'TZS'),
  updated_at = now();

-- 2. Create broadcast_notifications table
CREATE TABLE IF NOT EXISTS public.broadcast_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  type text DEFAULT 'offer' CHECK (type IN ('offer', 'reminder', 'alert', 'system')),
  target_audience text DEFAULT 'all' CHECK (target_audience IN ('all', 'customers', 'drivers')),
  image_url text,
  action_route text DEFAULT '/customer/home',
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  is_active boolean DEFAULT true
);

ALTER TABLE public.broadcast_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read active broadcasts" ON public.broadcast_notifications;
CREATE POLICY "Allow public read active broadcasts"
  ON public.broadcast_notifications
  FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Allow admin manage broadcasts" ON public.broadcast_notifications;
CREATE POLICY "Allow admin manage broadcasts"
  ON public.broadcast_notifications
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 3. Add to Realtime
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcast_notifications;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.settings;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;

-- 4. RPC function to broadcast notification safely
CREATE OR REPLACE FUNCTION public.admin_broadcast_notification(
  p_title text,
  p_body text,
  p_type text DEFAULT 'offer',
  p_target text DEFAULT 'all',
  p_image_url text DEFAULT NULL,
  p_action_route text DEFAULT '/customer/home'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only store administrators can send broadcasts';
  END IF;

  INSERT INTO public.broadcast_notifications (
    title, body, type, target_audience, image_url, action_route, created_by
  )
  VALUES (
    p_title, p_body, p_type, p_target, p_image_url, p_action_route, auth.uid()
  )
  RETURNING id INTO v_new_id;

  RETURN jsonb_build_object(
    'success', true,
    'id', v_new_id,
    'message', 'Broadcast notification dispatched successfully'
  );
END;
$$;
