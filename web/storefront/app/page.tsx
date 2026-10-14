import Hero from '@/components/Hero';
import ProductGrid from '@/components/ProductGrid';
import { getCategories, getProducts } from '@/lib/data';

export const dynamic = 'force-dynamic';
export const revalidate = 60; // Refresh dynamic Supabase catalog every 60 seconds

export default async function HomePage() {
  const [categories, products] = await Promise.all([
    getCategories(),
    getProducts(),
  ]);

  return (
    <main>
      <Hero />
      <ProductGrid categories={categories} products={products} />
    </main>
  );
}
