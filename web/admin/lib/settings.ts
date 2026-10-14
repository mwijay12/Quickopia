import { createClient } from './supabase/client';

export interface SupermarketSettings {
  id: string;
  supermarket_name: string;
  tagline: string;
  logo_url: string;
  branch_address: string;
  city: string;
  phone: string;
  email: string;
  operating_hours: string;
  currency_symbol: string;
  mpesa_till?: string;
  tigo_till?: string;
  airtel_till?: string;
  halo_till?: string;
  nmb_account?: string;
  crdb_account?: string;
  return_window_hours?: number;
  return_policy_notes?: string;
  is_active: boolean;
  updated_at?: string;
}

export async function fetchSupermarketSettings(): Promise<SupermarketSettings> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('settings')
    .select('*')
    .eq('id', 'branch_settings')
    .maybeSingle();

  if (error) {
    console.error('Error fetching supermarket settings:', error);
    throw error;
  }

  if (!data) {
    // Return fallback defaults
    return {
      id: 'branch_settings',
      supermarket_name: 'Shoppers Supermarket',
      tagline: 'Fresh groceries & daily essentials at your doorstep',
      logo_url: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300',
      branch_address: 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam',
      city: 'Dar es Salaam',
      phone: '+255 712 345 678',
      email: 'support@shoppers.co.tz',
      operating_hours: 'Mon - Sun: 07:30 AM - 10:30 PM',
      currency_symbol: 'TZS',
      return_window_hours: 2,
      return_policy_notes: 'Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours.',
      is_active: true,
    };
  }

  return {
    ...data,
    supermarket_name: data.supermarket_name || data.restaurant_name || 'Shoppers Supermarket',
    tagline: data.tagline || 'Fresh groceries & daily essentials at your doorstep',
    logo_url: data.logo_url || data.logo || 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300',
    branch_address: data.branch_address || 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam',
    city: data.city || 'Dar es Salaam',
    phone: data.phone || '+255 712 345 678',
    email: data.email || 'support@shoppers.co.tz',
    operating_hours: data.operating_hours || 'Mon - Sun: 07:30 AM - 10:30 PM',
    currency_symbol: data.currency_symbol || 'TZS',
    return_window_hours: data.return_window_hours ?? 2,
    return_policy_notes: data.return_policy_notes || 'Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours.',
    is_active: data.is_active ?? true,
  };
}

export async function updateSupermarketSettings(
  updates: Partial<SupermarketSettings>
): Promise<SupermarketSettings> {
  const supabase = createClient();
  const payload = {
    ...updates,
    restaurant_name: updates.supermarket_name ?? undefined,
    updated_at: new Date().toISOString(),
  };

  const { data, error } = await supabase
    .from('settings')
    .update(payload)
    .eq('id', 'branch_settings')
    .select()
    .single();

  if (error) {
    console.error('Error updating supermarket settings:', error);
    throw error;
  }

  return data;
}
