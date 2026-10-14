import { createClient } from './supabase/client';

export interface SupportConversation {
  id: string;
  customer_id: string;
  customer_name: string;
  customer_phone?: string;
  status: 'open' | 'closed';
  last_message: string | null;
  last_message_at: string;
  created_at: string;
}

export interface SupportMessage {
  id: string;
  conversation_id: string;
  sender_id: string | null;
  sender_role: 'customer' | 'admin' | 'driver';
  sender_name: string;
  content: string;
  image_url?: string | null;
  is_read: boolean;
  created_at: string;
}

export async function fetchSupportConversations(): Promise<SupportConversation[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('support_conversations')
    .select('*')
    .order('last_message_at', { ascending: false });

  if (error) {
    console.error('Error fetching support conversations:', error);
    return [];
  }
  return data || [];
}

export async function fetchConversationMessages(conversationId: string): Promise<SupportMessage[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('support_messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('Error fetching conversation messages:', error);
    return [];
  }
  return data || [];
}

export async function sendAdminSupportMessage(
  conversationId: string,
  content: string,
  adminName: string = 'Store Support'
): Promise<SupportMessage | null> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data, error } = await supabase
    .from('support_messages')
    .insert({
      conversation_id: conversationId,
      sender_id: user?.id || null,
      sender_role: 'admin',
      sender_name: adminName,
      content: content.trim(),
    })
    .select()
    .single();

  if (error) {
    console.error('Error sending support message:', error);
    throw error;
  }

  // Update last message
  await supabase
    .from('support_conversations')
    .update({
      last_message: content.trim(),
      last_message_at: new Date().toISOString(),
    })
    .eq('id', conversationId);

  return data;
}

export async function updateConversationStatus(
  conversationId: string,
  status: 'open' | 'closed'
): Promise<void> {
  const supabase = createClient();
  await supabase
    .from('support_conversations')
    .update({ status })
    .eq('id', conversationId);
}
