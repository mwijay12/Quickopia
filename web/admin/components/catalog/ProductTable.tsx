'use client';

import { useEffect, useState } from 'react';
import type { Product, Category } from '@/lib/catalog';
import {
  fetchAllProducts,
  fetchAllCategories,
  adjustStockDelta,
  updateProduct,
  deleteProduct,
} from '@/lib/catalog';
import { createClient } from '@/lib/supabase/client';
import ProductFormModal from './ProductFormModal';
import { TableSkeleton } from '../ui/Skeleton';
import {
  Plus,
  Minus,
  Search,
  Edit3,
  Trash2,
  CheckCircle2,
  AlertCircle,
  Package,
  Layers,
  Sparkles,
} from 'lucide-react';

export default function ProductTable() {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [stockFilter, setStockFilter] = useState<'all' | 'in_stock' | 'out_of_stock'>('all');
  const [editing, setEditing] = useState<Product | null | 'new'>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const load = async () => {
    try {
      const [p, c] = await Promise.all([
        fetchAllProducts(),
        fetchAllCategories(),
      ]);
      setProducts(p);
      setCategories(c);
    } catch (e) {
      console.error('Failed to load catalog:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();

    // Realtime Postgres changes on products
    const supabase = createClient();
    const channel = supabase
      .channel('admin_products_live_sync')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'products' },
        () => {
          load();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  useEffect(() => {
    if (toast) {
      const t = setTimeout(() => setToast(null), 3500);
      return () => clearTimeout(t);
    }
  }, [toast]);

  const categoryName = (id: string) =>
    categories.find((c) => c.id === id)?.name ?? '—';

  const filtered = products.filter((p) => {
    const matchesSearch = search.trim()
      ? p.title.toLowerCase().includes(search.trim().toLowerCase())
      : true;
    const matchesCategory = categoryFilter
      ? p.category_id === categoryFilter
      : true;
    const matchesStock =
      stockFilter === 'all'
        ? true
        : stockFilter === 'in_stock'
        ? p.stock_quantity > 0
        : p.stock_quantity === 0;

    return matchesSearch && matchesCategory && matchesStock;
  });

  const quickStockDelta = async (p: Product, delta: number) => {
    try {
      const newStock = await adjustStockDelta(p.id, delta);
      setProducts((prev) =>
        prev.map((item) =>
          item.id === p.id ? { ...item, stock_quantity: newStock } : item
        )
      );
      setToast({
        type: 'success',
        text: `Stock for "${p.title}" adjusted to ${newStock} units.`,
      });
    } catch (e) {
      setToast({
        type: 'error',
        text: `Could not adjust stock: ${e instanceof Error ? e.message : e}`,
      });
    }
  };

  const toggleAvailability = async (p: Product) => {
    const nextState = !p.is_available;
    try {
      await updateProduct(p.id, { is_available: nextState });
      setProducts((prev) =>
        prev.map((item) =>
          item.id === p.id ? { ...item, is_available: nextState } : item
        )
      );
      setToast({
        type: 'success',
        text: `"${p.title}" is now ${nextState ? 'Active in catalog' : 'Hidden from storefront'}.`,
      });
    } catch (e) {
      setToast({
        type: 'error',
        text: `Could not update visibility: ${e instanceof Error ? e.message : e}`,
      });
    }
  };

  const handleDelete = async (p: Product) => {
    if (!confirm(`Are you sure you want to permanently delete "${p.title}"?`)) {
      return;
    }
    try {
      await deleteProduct(p.id);
      setProducts((prev) => prev.filter((item) => item.id !== p.id));
      setToast({
        type: 'success',
        text: `"${p.title}" has been deleted.`,
      });
    } catch (e) {
      setToast({
        type: 'error',
        text: `Could not delete product: ${e instanceof Error ? e.message : e}`,
      });
    }
  };

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="h-10 bg-gray-100 rounded-xl animate-pulse w-72" />
        <TableSkeleton rows={8} />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {toast && (
        <div
          className={`flex items-center gap-2 p-3.5 rounded-xl text-xs font-bold border transition-all ${
            toast.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
              : 'bg-red-50 text-red-800 border-red-200'
          }`}
        >
          {toast.type === 'success' ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
          ) : (
            <AlertCircle className="w-4 h-4 text-red-600 shrink-0" />
          )}
          <span>{toast.text}</span>
        </div>
      )}

      {/* Control Bar: Search, Filters, Add Button */}
      <div className="flex flex-wrap gap-3 items-center justify-between">
        <div className="flex flex-wrap gap-2.5 flex-1 max-w-2xl">
          <div className="relative flex-1 min-w-[180px]">
            <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              placeholder="Search products by title..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="border border-gray-300 rounded-xl pl-9 pr-3.5 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber w-full bg-white transition"
            />
          </div>
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
          >
            <option value="">All Categories ({categories.length})</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} {!c.is_active ? '(archived)' : ''}
              </option>
            ))}
          </select>
          <select
            value={stockFilter}
            onChange={(e) => setStockFilter(e.target.value as typeof stockFilter)}
            className="border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
          >
            <option value="all">All Inventory</option>
            <option value="in_stock">In Stock (&gt;0)</option>
            <option value="out_of_stock">Out of Stock (0)</option>
          </select>
        </div>

        <button
          type="button"
          onClick={() => setEditing('new')}
          className="bg-quickopia-navy hover:bg-slate-900 text-white px-4 py-2.5 rounded-xl text-xs font-bold transition shadow-sm flex items-center gap-2"
        >
          <Plus className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>Add New Product</span>
        </button>
      </div>

      {/* Category Navigation Pills */}
      <div className="flex gap-2 overflow-x-auto pb-1 text-xs no-scrollbar">
        <button
          type="button"
          onClick={() => setCategoryFilter('')}
          className={`px-3 py-1.5 rounded-full font-bold transition whitespace-nowrap flex items-center gap-1.5 ${
            categoryFilter === ''
              ? 'bg-quickopia-navy text-white shadow-xs'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          <Layers className="w-3 h-3" />
          <span>All ({products.length})</span>
        </button>
        {categories.map((c) => {
          const count = products.filter((p) => p.category_id === c.id).length;
          return (
            <button
              key={c.id}
              type="button"
              onClick={() => setCategoryFilter(c.id === categoryFilter ? '' : c.id)}
              className={`px-3 py-1.5 rounded-full font-bold transition whitespace-nowrap ${
                categoryFilter === c.id
                  ? 'bg-quickopia-navy text-white shadow-xs'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              <span>{c.name}</span>
              <span className="text-[10px] opacity-70 ml-1">({count})</span>
            </button>
          );
        })}
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead className="bg-gray-50/80 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
            <tr>
              <th className="p-3.5">Product</th>
              <th className="p-3.5">Category</th>
              <th className="p-3.5">Price</th>
              <th className="p-3.5 text-center">Stock Adjustment</th>
              <th className="p-3.5">Visibility</th>
              <th className="p-3.5 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map((p) => (
              <tr key={p.id} className="hover:bg-gray-50/60 transition group">
                <td className="p-3.5">
                  <div className="flex items-center gap-3">
                    <div className="w-11 h-11 rounded-xl bg-gray-100 border border-gray-200 overflow-hidden flex items-center justify-center shrink-0">
                      {p.image_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={p.image_url}
                          alt={p.title}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <Package className="w-5 h-5 text-gray-300" />
                      )}
                    </div>
                    <div>
                      <div className="font-bold text-gray-900 text-sm">{p.title}</div>
                      <div className="flex items-center gap-2 mt-0.5">
                        {p.unit && (
                          <span className="text-[11px] text-gray-500">{p.unit}</span>
                        )}
                        {p.is_popular && (
                          <span className="inline-flex items-center gap-1 text-[9px] font-extrabold bg-amber-100 text-amber-900 px-1.5 py-0.5 rounded">
                            <Sparkles className="w-2.5 h-2.5 text-amber-600" />
                            <span>POPULAR</span>
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="p-3.5 text-gray-600 font-medium">
                  {categoryName(p.category_id)}
                </td>
                <td className="p-3.5 font-extrabold text-quickopia-navy text-sm">
                  TZS {p.price_tzs.toLocaleString('en-US')}
                </td>
                <td className="p-3.5">
                  <div className="flex items-center justify-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => quickStockDelta(p, -1)}
                      className="w-7 h-7 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-lg font-bold flex items-center justify-center transition"
                      title="Reduce stock by 1"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <span
                      className={`min-w-[36px] text-center font-bold px-2 py-0.5 rounded text-xs ${
                        p.stock_quantity === 0
                          ? 'bg-red-50 text-red-600 font-black'
                          : 'text-gray-900 bg-gray-50'
                      }`}
                    >
                      {p.stock_quantity}
                    </span>
                    <button
                      type="button"
                      onClick={() => quickStockDelta(p, 1)}
                      className="w-7 h-7 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-lg font-bold flex items-center justify-center transition"
                      title="Increase stock by 1"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                    <button
                      type="button"
                      onClick={() => quickStockDelta(p, 10)}
                      className="px-2 py-1 bg-gray-100 hover:bg-gray-200 text-[10px] text-gray-700 font-bold rounded-md transition"
                      title="Quick restock +10"
                    >
                      +10
                    </button>
                  </div>
                </td>
                <td className="p-3.5">
                  <button
                    type="button"
                    onClick={() => toggleAvailability(p)}
                    className={`text-[10px] font-extrabold px-2.5 py-1 rounded-full uppercase tracking-wider transition ${
                      p.is_available
                        ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                        : 'bg-gray-200 text-gray-600 hover:bg-gray-300'
                    }`}
                  >
                    {p.is_available ? 'Active' : 'Hidden'}
                  </button>
                </td>
                <td className="p-3.5 text-right font-bold">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      type="button"
                      onClick={() => setEditing(p)}
                      className="inline-flex items-center gap-1 bg-gray-100 hover:bg-quickopia-navy hover:text-white text-gray-700 text-xs px-2.5 py-1.5 rounded-lg transition"
                      title="Edit details"
                    >
                      <Edit3 className="w-3 h-3" />
                      <span>Edit</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDelete(p)}
                      className="inline-flex items-center gap-1 bg-red-50 hover:bg-red-600 hover:text-white text-red-600 text-xs px-2.5 py-1.5 rounded-lg transition"
                      title="Delete product"
                    >
                      <Trash2 className="w-3 h-3" />
                      <span>Delete</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filtered.length === 0 && (
          <div className="text-center py-16 text-gray-400">
            <Search className="w-10 h-10 text-gray-300 mx-auto mb-2" />
            <p className="text-xs font-semibold">No products match your search or filter criteria.</p>
          </div>
        )}
      </div>

      {editing && (
        <ProductFormModal
          product={editing === 'new' ? null : editing}
          categories={categories}
          onClose={() => setEditing(null)}
          onDone={() => {
            setEditing(null);
            load();
            setToast({
              type: 'success',
              text: 'Product saved and synchronized successfully!',
            });
          }}
        />
      )}
    </div>
  );
}
