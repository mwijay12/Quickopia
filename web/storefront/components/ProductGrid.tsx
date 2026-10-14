'use client';

import { useMemo, useState } from 'react';
import type { Category, Product } from '@/lib/types';
import SearchBar from './SearchBar';
import CategoryFilter from './CategoryFilter';
import ProductCard from './ProductCard';

export default function ProductGrid({
  categories,
  products,
}: {
  categories: Category[];
  products: Product[];
}) {
  const [search, setSearch] = useState('');
  const [categoryId, setCategoryId] = useState<string | null>(null);

  const filtered = useMemo(() => {
    return products.filter((p) => {
      const matchesCategory = categoryId ? p.category_id === categoryId : true;
      const matchesSearch = search.trim()
        ? p.title.toLowerCase().includes(search.trim().toLowerCase())
        : true;
      return matchesCategory && matchesSearch;
    });
  }, [products, search, categoryId]);

  return (
    <section className="max-w-6xl mx-auto px-4 py-8">
      <div className="mb-4">
        <SearchBar value={search} onChange={setSearch} />
      </div>
      <div className="mb-6">
        <CategoryFilter
          categories={categories}
          selected={categoryId}
          onSelect={setCategoryId}
        />
      </div>
      {filtered.length === 0 ? (
        <div className="text-center py-16 px-4 bg-white rounded-2xl border border-gray-200 shadow-sm max-w-lg mx-auto">
          <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-500">
            <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
          <h3 className="text-lg font-bold text-quickopia-navy mb-1">
            No matching products found
          </h3>
          <p className="text-gray-500 text-sm mb-5">
            We couldn't find anything matching your search or category filter. Try searching in Swahili or English.
          </p>
          {(search || categoryId) && (
            <button
              type="button"
              onClick={() => {
                setSearch('');
                setCategoryId(null);
              }}
              className="inline-flex items-center gap-2 bg-quickopia-navy hover:bg-slate-800 text-white font-semibold text-sm px-5 py-2.5 rounded-xl transition shadow-sm"
            >
              Clear All Filters
            </button>
          )}
        </div>
      ) : (
        <div>
          <div className="flex justify-between items-center mb-4">
            <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
              Showing {filtered.length} products
            </span>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {filtered.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </div>
      )}
    </section>
  );
}
