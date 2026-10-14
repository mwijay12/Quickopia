'use client';

import { useState } from 'react';
import type { Category } from '@/lib/catalog';
import { createCategory, updateCategory, CatalogError } from '@/lib/catalog';
import { Modal } from '../kanban/PackingChecklistModal';

export default function CategoryFormModal({
  category,
  onClose,
  onDone,
}: {
  category: Category | null;
  onClose: () => void;
  onDone: () => void;
}) {
  const [name, setName] = useState(category?.name ?? '');
  const [nameSw, setNameSw] = useState(category?.name_sw ?? '');
  const [displayOrder, setDisplayOrder] = useState(
    category?.display_order ?? 0
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Category name is required.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      if (category) {
        await updateCategory(category.id, {
          name: name.trim(),
          name_sw: nameSw.trim() || null,
          display_order: displayOrder,
        });
      } else {
        await createCategory({
          name: name.trim(),
          name_sw: nameSw.trim() || null,
          icon: null,
          display_order: displayOrder,
          is_active: true,
        });
      }
      onDone();
    } catch (e) {
      setError(
        e instanceof CatalogError ? e.message : 'Could not save category.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      title={category ? 'Edit Category' : 'New Category'}
      onClose={onClose}
    >
      <form onSubmit={save} className="space-y-4">
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Category Name (English)
          </label>
          <input
            type="text"
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. Dairy & Eggs, Bakery, Fresh Produce"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Category Name (Swahili, optional)
          </label>
          <input
            type="text"
            value={nameSw}
            onChange={(e) => setNameSw(e.target.value)}
            placeholder="e.g. Maziwa na Mayai"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Display Order Priority
          </label>
          <input
            type="number"
            value={displayOrder}
            onChange={(e) => setDisplayOrder(Number(e.target.value))}
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
          <p className="text-[11px] text-gray-400 mt-1">
            Lower numbers appear first in customer app &amp; storefront chips.
          </p>
        </div>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg font-medium">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
        >
          {loading ? 'Saving category...' : 'Save Category'}
        </button>
      </form>
    </Modal>
  );
}
