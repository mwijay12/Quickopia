import { createClient } from './supabase/client';
import type { Branch } from './types';

export async function getPrimaryBranch(): Promise<Branch | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('branches')
    .select('*')
    .limit(1)
    .single();

  if (error) {
    console.error('getPrimaryBranch error:', error.message);
    return null;
  }
  return data as Branch;
}
