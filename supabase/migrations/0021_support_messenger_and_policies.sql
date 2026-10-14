-- ============================================================================
-- Migration: 0021_support_messenger_and_policies.sql
-- Description: In-App Support Chat (Alibaba-style messenger) and Store Policy Settings
-- ============================================================================

-- 1. Add policy fields to settings
ALTER TABLE public.settings
  ADD COLUMN IF NOT EXISTS return_window_hours integer DEFAULT 2,
  ADD COLUMN IF NOT EXISTS return_policy_notes text DEFAULT 'Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours.';

-- 2. Create support chat tables
CREATE TABLE IF NOT EXISTS public.support_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_name text DEFAULT 'Shopper',
  customer_phone text,
  status text NOT NULL DEFAULT 'open',
  last_message text,
  last_message_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.support_conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  sender_role text NOT NULL DEFAULT 'customer',
  sender_name text NOT NULL DEFAULT 'Shopper',
  content text NOT NULL,
  image_url text,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_support_conversations_customer ON public.support_conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_support_conversations_last_msg ON public.support_conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_messages_conversation ON public.support_messages(conversation_id, created_at ASC);

-- RLS
ALTER TABLE public.support_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view & insert their conversations
DROP POLICY IF EXISTS "support_conv_select_policy" ON public.support_conversations;
CREATE POLICY "support_conv_select_policy" ON public.support_conversations
  FOR SELECT TO authenticated
  USING (customer_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "support_conv_insert_policy" ON public.support_conversations;
CREATE POLICY "support_conv_insert_policy" ON public.support_conversations
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "support_conv_update_policy" ON public.support_conversations;
CREATE POLICY "support_conv_update_policy" ON public.support_conversations
  FOR UPDATE TO authenticated
  USING (customer_id = auth.uid() OR is_admin());

-- Allow authenticated users to view & insert messages
DROP POLICY IF EXISTS "support_msg_select_policy" ON public.support_messages;
CREATE POLICY "support_msg_select_policy" ON public.support_messages
  FOR SELECT TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM public.support_conversations WHERE customer_id = auth.uid()
    ) OR is_admin()
  );

DROP POLICY IF EXISTS "support_msg_insert_policy" ON public.support_messages;
CREATE POLICY "support_msg_insert_policy" ON public.support_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    conversation_id IN (
      SELECT id FROM public.support_conversations WHERE customer_id = auth.uid()
    ) OR is_admin()
  );

-- Enable realtime publications
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.support_conversations;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.support_messages;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;
END $$;
