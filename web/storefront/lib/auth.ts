import { createClient } from './supabase/client';

export interface UserProfile {
  id: string;
  full_name: string | null;
  phone: string | null;
}

/**
 * Returns the currently signed-in user if an active non-anonymous session exists.
 */
export async function getAuthenticatedUser() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user || user.is_anonymous) {
    return null;
  }
  return user;
}

/**
 * Fetches user profile info (name, phone) for pre-filling checkout.
 */
export async function getUserProfile(userId: string): Promise<UserProfile | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, phone')
    .eq('id', userId)
    .single();

  if (error || !data) return null;
  return data as UserProfile;
}

/**
 * Updates full name and phone number on the current user's profile.
 */
export async function updateProfileBasicInfo(fullName: string, phone: string) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error('No active session');

  const { error } = await supabase
    .from('profiles')
    .update({ full_name: fullName, phone })
    .eq('id', user.id);

  if (error) {
    console.error('updateProfileBasicInfo error:', error.message);
  }
}
