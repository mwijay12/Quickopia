import { createClient } from './supabase/client';

export interface Category {
  id: string;
  name: string;
  name_sw: string | null;
  icon: string | null;
  display_order: number;
  is_active: boolean;
}

export interface Product {
  id: string;
  category_id: string;
  title: string;
  description: string | null;
  price_tzs: number;
  unit: string | null;
  image_url: string | null;
  stock_quantity: number;
  is_available: boolean;
  is_popular: boolean;
}

export class CatalogError extends Error {}

// --- Categories ---

export async function fetchAllCategories(): Promise<Category[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .order('display_order', { ascending: true });
  if (error) throw new CatalogError(error.message);
  return (data || []) as Category[];
}

export async function createCategory(input: Omit<Category, 'id'>) {
  const supabase = createClient();
  const { error } = await supabase.from('categories').insert(input);
  if (error) throw new CatalogError(error.message);
}

export async function updateCategory(
  id: string,
  input: Partial<Omit<Category, 'id'>>
) {
  const supabase = createClient();
  const { error } = await supabase
    .from('categories')
    .update(input)
    .eq('id', id);
  if (error) throw new CatalogError(error.message);
}

export async function archiveCategory(id: string) {
  // Soft-delete only — never hard-delete a category that products may reference.
  const supabase = createClient();
  const { error } = await supabase
    .from('categories')
    .update({ is_active: false })
    .eq('id', id);
  if (error) throw new CatalogError(error.message);
}

// --- Products ---

export async function fetchAllProducts(): Promise<Product[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .order('title', { ascending: true });
  if (error) throw new CatalogError(error.message);
  return (data || []) as Product[];
}

export async function createProduct(
  input: Omit<Product, 'id'> & { branch_id: string }
) {
  try {
    const res = await fetch('/api/catalog/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(input),
    });
    if (res.ok) return;
    const json = await res.json();
    throw new Error(json.error || 'Failed to create product via API');
  } catch (apiErr) {
    const supabase = createClient();
    const { error } = await supabase.from('products').insert(input);
    if (error) throw new CatalogError(error.message || String(apiErr));
  }
}

export async function updateProduct(
  id: string,
  input: Partial<Omit<Product, 'id'>>
) {
  try {
    const res = await fetch('/api/catalog/products', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, ...input }),
    });
    if (res.ok) return;
    const json = await res.json();
    throw new Error(json.error || 'Failed to update product via API');
  } catch (apiErr) {
    const supabase = createClient();
    const { error } = await supabase
      .from('products')
      .update(input)
      .eq('id', id);
    if (error) throw new CatalogError(error.message || String(apiErr));
  }
}

export async function adjustStockDelta(
  id: string,
  delta: number
): Promise<number> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc('admin_adjust_stock', {
    p_product_id: id,
    p_delta: delta,
  });

  if (error) {
    // Fallback if migration not yet applied
    const { data: prod } = await supabase
      .from('products')
      .select('stock_quantity')
      .eq('id', id)
      .single();
    const current = prod?.stock_quantity ?? 0;
    const next = Math.max(0, current + delta);
    await updateProduct(id, { stock_quantity: next });
    return next;
  }

  return data as number;
}

export async function adjustStock(id: string, newQuantity: number) {
  if (newQuantity < 0) throw new CatalogError('Stock cannot be negative.');
  await updateProduct(id, { stock_quantity: newQuantity });
}

export async function deleteProduct(id: string) {
  try {
    const res = await fetch(`/api/catalog/products?id=${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
    if (res.ok) return;
    const json = await res.json();
    throw new Error(json.error || 'Failed to delete product via API');
  } catch (apiErr) {
    const supabase = createClient();
    const { error } = await supabase.from('products').delete().eq('id', id);
    if (error) throw new CatalogError(error.message || String(apiErr));
  }
}

export async function getPrimaryBranchId(): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('branches')
    .select('id')
    .limit(1)
    .single();
  if (error || !data) {
    throw new CatalogError(
      'No primary branch found. Please verify the branches table in Supabase.'
    );
  }
  return data.id as string;
}

// --- Hero Banners ---

export interface HeroBanner {
  id: string;
  title: string;
  subtitle: string;
  tag: string;
  image_url: string | null;
  button_text: string;
  display_order: number;
  is_active: boolean;
}

export async function fetchHeroBanners(): Promise<HeroBanner[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('hero_banners')
    .select('*')
    .order('display_order', { ascending: true });
  if (error) throw new CatalogError(error.message);
  return (data || []) as HeroBanner[];
}

export async function updateHeroBanner(
  id: string,
  input: Partial<Omit<HeroBanner, 'id'>>
) {
  const supabase = createClient();
  const { error } = await supabase
    .from('hero_banners')
    .update(input)
    .eq('id', id);
  if (error) throw new CatalogError(error.message);
}

export async function createHeroBanner(
  input: Omit<HeroBanner, 'id'> & { id?: string }
) {
  const supabase = createClient();
  const payload = {
    ...input,
    id: input.id || Date.now().toString(),
  };
  const { error } = await supabase.from('hero_banners').insert(payload);
  if (error) throw new CatalogError(error.message);
}

export async function deleteHeroBanner(id: string) {
  const supabase = createClient();
  const { error } = await supabase.from('hero_banners').delete().eq('id', id);
  if (error) throw new CatalogError(error.message);
}

