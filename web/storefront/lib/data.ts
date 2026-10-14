import { createClient } from './supabase/server';
import type { Category, Product } from './types';

export async function getCategories(): Promise<Category[]> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('display_order');
    if (error) {
      console.error('getCategories error:', error.message);
      return [];
    }
    return (data || []) as Category[];
  } catch (err) {
    console.error('getCategories exception:', err);
    return [];
  }
}

export async function getProducts(): Promise<Product[]> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('is_available', true)
      .order('is_popular', { ascending: false });
    if (error) {
      console.error('getProducts error:', error.message);
      return [];
    }
    return (data || []) as Product[];
  } catch (err) {
    console.error('getProducts exception:', err);
    return [];
  }
}
