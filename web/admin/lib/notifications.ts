import { createClient } from './supabase/client';

export type NotificationType = 'offer' | 'reminder' | 'alert' | 'system';
export type TargetAudience = 'all' | 'customers' | 'drivers';

export interface BroadcastNotification {
  id: string;
  title: string;
  body: string;
  type: NotificationType;
  target_audience: TargetAudience;
  image_url: string | null;
  action_route: string;
  created_at: string;
  created_by?: string;
  is_active: boolean;
}

export async function fetchBroadcastNotifications(): Promise<BroadcastNotification[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('broadcast_notifications')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching broadcast notifications:', error);
    throw error;
  }

  return data ?? [];
}

export async function sendBroadcastNotification(payload: {
  title: string;
  body: string;
  type?: NotificationType;
  target_audience?: TargetAudience;
  image_url?: string | null;
  action_route?: string;
}): Promise<BroadcastNotification> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data, error } = await supabase
    .from('broadcast_notifications')
    .insert([
      {
        title: payload.title,
        body: payload.body,
        type: payload.type ?? 'offer',
        target_audience: payload.target_audience ?? 'all',
        image_url: payload.image_url ?? null,
        action_route: payload.action_route ?? '/customer/home',
        created_by: user?.id ?? null,
        is_active: true,
      },
    ])
    .select()
    .single();

  if (error) {
    console.error('Error sending broadcast notification:', error);
    throw error;
  }

  return data;
}

export async function deleteBroadcastNotification(id: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from('broadcast_notifications')
    .delete()
    .eq('id', id);

  if (error) {
    console.error('Error deleting broadcast notification:', error);
    throw error;
  }
}
