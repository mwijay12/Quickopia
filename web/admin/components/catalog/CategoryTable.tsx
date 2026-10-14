'use client';

import { useEffect, useState } from 'react';
import type { Category } from '@/lib/catalog';
import { fetchAllCategories, archiveCategory } from '@/lib/catalog';
import { createClient } from '@/lib/supabase/client';
import CategoryFormModal from './CategoryFormModal';
import { TableSkeleton } from '../ui/Skeleton';
import { Plus, Edit3, Archive, Layers, Folder } from 'lucide-react';

export default function CategoryTable() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [editing, setEditing] = useState<Category | null | 'new'>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    try {
      const data = await fetchAllCategories();
      setCategories(data);
    } catch (e) {
      console.error('Failed to load categories:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();

    const supabase = createClient();
    const channel = supabase
      .channel('admin_categories_live_sync')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'categories' },
        () => {
          load();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleArchive = async (id: string, name: string) => {
    if (
      !confirm(
        `Archive category "${name}"? It will be hidden from customer catalogs, but existing products in this category will be preserved.`
      )
    ) {
      return;
    }
    try {
      await archiveCategory(id);
      load();
    } catch (e) {
      alert(`Could not archive category: ${e}`);
    }
  };

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="h-8 bg-gray-100 rounded-xl animate-pulse w-48" />
        <TableSkeleton rows={6} />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-2">
          <Layers className="w-4 h-4 text-quickopia-navy" />
          <p className="text-xs font-bold text-gray-700">
            {categories.length} Categories Registered
          </p>
        </div>
        <button
          type="button"
          onClick={() => setEditing('new')}
          className="bg-quickopia-navy hover:bg-slate-900 text-white px-4 py-2.5 rounded-xl text-xs font-bold transition shadow-sm flex items-center gap-2"
        >
          <Plus className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>Add New Category</span>
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden divide-y divide-gray-100">
        {categories.length === 0 ? (
          <div className="text-center py-16 text-gray-400">
            <Folder className="w-10 h-10 text-gray-300 mx-auto mb-2" />
            <p className="text-xs font-semibold">No categories found. Click &quot;Add New Category&quot; to create one.</p>
          </div>
        ) : (
          categories.map((c) => (
            <div
              key={c.id}
              className="flex justify-between items-center px-5 py-4 hover:bg-gray-50/70 transition"
            >
              <div className="flex items-center gap-3.5">
                <span className="text-xs font-black bg-gray-100 text-gray-700 w-7 h-7 rounded-lg flex items-center justify-center border border-gray-200">
                  {c.display_order}
                </span>
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-bold text-sm text-gray-900">{c.name}</p>
                    {!c.is_active && (
                      <span className="text-[10px] font-bold bg-red-100 text-red-700 px-2 py-0.5 rounded-full uppercase">
                        Archived
                      </span>
                    )}
                  </div>
                  {c.name_sw && (
                    <p className="text-xs text-gray-500 italic mt-0.5">
                      Swahili: {c.name_sw}
                    </p>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-2.5 text-xs font-bold">
                <button
                  type="button"
                  onClick={() => setEditing(c)}
                  className="inline-flex items-center gap-1 bg-gray-100 hover:bg-quickopia-navy hover:text-white text-gray-700 px-3 py-1.5 rounded-lg transition"
                >
                  <Edit3 className="w-3 h-3" />
                  <span>Edit</span>
                </button>
                {c.is_active && (
                  <button
                    type="button"
                    onClick={() => handleArchive(c.id, c.name)}
                    className="inline-flex items-center gap-1 bg-red-50 hover:bg-red-600 hover:text-white text-red-600 px-3 py-1.5 rounded-lg transition"
                  >
                    <Archive className="w-3 h-3" />
                    <span>Archive</span>
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      {editing && (
        <CategoryFormModal
          category={editing === 'new' ? null : editing}
          onClose={() => setEditing(null)}
          onDone={() => {
            setEditing(null);
            load();
          }}
        />
      )}
    </div>
  );
}
