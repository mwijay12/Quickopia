'use client';

import { useState } from 'react';
import type { Product, Category } from '@/lib/catalog';
import {
  createProduct,
  updateProduct,
  deleteProduct,
  getPrimaryBranchId,
  CatalogError,
} from '@/lib/catalog';
import { Modal } from '../kanban/PackingChecklistModal';
import ImageUploadField from './ImageUploadField';
import { Sparkles, Trash2, Loader2 } from 'lucide-react';

export default function ProductFormModal({
  product,
  categories,
  onClose,
  onDone,
}: {
  product: Product | null;
  categories: Category[];
  onClose: () => void;
  onDone: () => void;
}) {
  const [title, setTitle] = useState(product?.title ?? '');
  const [description, setDescription] = useState(product?.description ?? '');
  const [categoryId, setCategoryId] = useState(
    product?.category_id ?? categories.find((c) => c.is_active)?.id ?? ''
  );
  const [price, setPrice] = useState(product?.price_tzs ?? 0);
  const [unit, setUnit] = useState(product?.unit ?? '');
  const [stock, setStock] = useState(product?.stock_quantity ?? 0);
  const [imageUrl, setImageUrl] = useState<string | null>(
    product?.image_url ?? null
  );
  const [isAvailable, setIsAvailable] = useState(
    product?.is_available ?? true
  );
  const [isPopular, setIsPopular] = useState(product?.is_popular ?? false);
  const [keywords, setKeywords] = useState('');
  const [generatingAi, setGeneratingAi] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const generateAiDescription = async () => {
    if (!title.trim()) {
      setError('Please enter a product title before generating an AI description.');
      return;
    }
    setGeneratingAi(true);
    setError(null);
    try {
      const catName = categories.find((c) => c.id === categoryId)?.name;
      const res = await fetch('/api/ai/generate-description', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: title.trim(),
          category: catName,
          keywords: keywords.trim(),
        }),
      });
      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error ?? 'Could not generate description.');
      }
      if (json.description) {
        setDescription(json.description);
      }
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'AI generation encountered an error.'
      );
    } finally {
      setGeneratingAi(false);
    }
  };


  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      setError('Product title is required.');
      return;
    }
    if (!categoryId) {
      setError('Please select a supermarket category.');
      return;
    }
    if (price < 0 || stock < 0) {
      setError('Price and stock quantity cannot be negative.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const payload = {
        title: title.trim(),
        description: description.trim() || null,
        category_id: categoryId,
        price_tzs: price,
        unit: unit.trim() || null,
        image_url: imageUrl,
        stock_quantity: stock,
        is_available: isAvailable,
        is_popular: isPopular,
      };

      if (product) {
        await updateProduct(product.id, payload);
      } else {
        const branchId = await getPrimaryBranchId();
        await createProduct({ ...payload, branch_id: branchId });
      }
      onDone();
    } catch (e) {
      setError(
        e instanceof CatalogError ? e.message : 'Could not save product.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal title={product ? 'Edit Product' : 'New Product'} onClose={onClose}>
      <form onSubmit={save} className="space-y-3.5 max-h-[72vh] overflow-y-auto pr-1">
        <ImageUploadField value={imageUrl} onChange={setImageUrl} />

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Product Title
          </label>
          <input
            type="text"
            required
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Asas Fresh Milk 500ml, Azam Wheat Flour 1kg"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div className="space-y-2 bg-gray-50/70 p-3.5 rounded-xl border border-gray-200">
          <div className="flex justify-between items-center">
            <label className="block text-xs font-semibold text-gray-700">
              Description (Draft to Review)
            </label>
            <button
              type="button"
              disabled={generatingAi}
              onClick={generateAiDescription}
              className="bg-quickopia-navy hover:bg-slate-900 text-white text-[11px] font-bold px-2.5 py-1 rounded-lg transition disabled:opacity-50 flex items-center gap-1.5 shadow-2xs"
            >
              {generatingAi ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Sparkles className="w-3.5 h-3.5 text-quickopia-amber" />
              )}
              <span>{generatingAi ? 'Generating draft...' : 'Generate with AI'}</span>
            </button>
          </div>

          <div>
            <input
              type="text"
              value={keywords}
              onChange={(e) => setKeywords(e.target.value)}
              placeholder="Keywords / Key highlights (e.g. chilled, pasteurized, 100% natural)"
              className="w-full border border-gray-300 rounded-lg px-3 py-1.5 text-xs bg-white focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
            />
          </div>

          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={3}
            placeholder="Key product details, brand, ingredients or packaging notes"
            className="w-full border border-gray-300 rounded-xl p-3 text-xs bg-white focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
          <p className="text-[10px] text-gray-400">
            Generated descriptions follow a concise 2–3 sentence factual format. Edit as needed before saving.
          </p>
        </div>


        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Supermarket Category
          </label>
          <select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
          >
            {categories
              .filter((c) => c.is_active || c.id === categoryId)
              .map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} {!c.is_active ? '(archived)' : ''}
                </option>
              ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Price (TZS)
            </label>
            <input
              type="number"
              min={0}
              required
              value={price}
              onChange={(e) => setPrice(Number(e.target.value))}
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Unit Specification
            </label>
            <input
              type="text"
              value={unit}
              placeholder="e.g. 1kg, 500ml, packet"
              onChange={(e) => setUnit(e.target.value)}
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Current Stock Quantity
          </label>
          <input
            type="number"
            min={0}
            required
            value={stock}
            onChange={(e) => setStock(Number(e.target.value))}
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
          <p className="text-[11px] text-gray-400 mt-1">
            Orders decrement stock automatically. When stock reaches 0, it shows as Out of Stock.
          </p>
        </div>

        <div className="pt-2 flex flex-col sm:flex-row gap-4 border-t border-gray-100">
          <label className="flex items-center gap-2 text-xs font-semibold cursor-pointer">
            <input
              type="checkbox"
              checked={isAvailable}
              onChange={(e) => setIsAvailable(e.target.checked)}
              className="h-4 w-4 rounded text-quickopia-navy accent-quickopia-navy"
            />
            <span>Available for purchase in catalog</span>
          </label>
          <label className="flex items-center gap-2 text-xs font-semibold cursor-pointer">
            <input
              type="checkbox"
              checked={isPopular}
              onChange={(e) => setIsPopular(e.target.checked)}
              className="h-4 w-4 rounded text-quickopia-navy accent-quickopia-navy"
            />
            <span>Mark as Popular (Homepage badge)</span>
          </label>
        </div>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg font-medium">
            {error}
          </p>
        )}

        <div className="pt-2 space-y-2">
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm flex items-center justify-center gap-2"
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Saving product...</span>
              </>
            ) : (
              <span>{product ? 'Save Product Changes' : 'Create Product'}</span>
            )}
          </button>

          {product && (
            <button
              type="button"
              disabled={loading}
              onClick={async () => {
                if (
                  confirm(
                    `Are you sure you want to permanently delete "${product.title}"?`
                  )
                ) {
                  setLoading(true);
                  try {
                    await deleteProduct(product.id);
                    onDone();
                  } catch (e) {
                    setError(`Could not delete: ${e instanceof Error ? e.message : e}`);
                    setLoading(false);
                  }
                }
              }}
              className="w-full border border-red-200 bg-red-50 hover:bg-red-100 text-red-700 font-bold py-2.5 rounded-xl disabled:opacity-40 transition text-xs flex items-center justify-center gap-2"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Delete this Product</span>
            </button>
          )}
        </div>
      </form>
    </Modal>
  );
}
