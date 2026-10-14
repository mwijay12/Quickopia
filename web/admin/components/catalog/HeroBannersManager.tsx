'use client';

import { useEffect, useState } from 'react';
import type { HeroBanner } from '@/lib/catalog';
import {
  fetchHeroBanners,
  updateHeroBanner,
  createHeroBanner,
  deleteHeroBanner,
} from '@/lib/catalog';
import { createClient } from '@/lib/supabase/client';
import ImageUploadField from './ImageUploadField';
import { Modal } from '../kanban/PackingChecklistModal';
import { CardGridSkeleton } from '../ui/Skeleton';
import { Plus, Edit3, Trash2, Image as ImageIcon, Sparkles } from 'lucide-react';

export default function HeroBannersManager() {
  const [banners, setBanners] = useState<HeroBanner[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<HeroBanner | null | 'new'>(null);

  const load = async () => {
    try {
      const data = await fetchHeroBanners();
      setBanners(data);
    } catch (e) {
      console.error('Failed to load hero banners:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();

    const supabase = createClient();
    const channel = supabase
      .channel('admin_banners_live_sync')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'hero_banners' },
        () => {
          load();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleDelete = async (b: HeroBanner) => {
    if (!confirm(`Are you sure you want to delete banner "${b.title}"?`)) return;
    try {
      await deleteHeroBanner(b.id);
      setBanners((prev) => prev.filter((item) => item.id !== b.id));
    } catch (e) {
      alert(`Could not delete banner: ${e}`);
    }
  };

  const toggleActive = async (b: HeroBanner) => {
    const nextState = !b.is_active;
    try {
      await updateHeroBanner(b.id, { is_active: nextState });
      setBanners((prev) =>
        prev.map((item) =>
          item.id === b.id ? { ...item, is_active: nextState } : item
        )
      );
    } catch (e) {
      alert(`Could not update banner status: ${e}`);
    }
  };

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="h-12 bg-white rounded-2xl border border-gray-200 animate-pulse" />
        <CardGridSkeleton count={4} />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div className="flex justify-between items-center bg-white p-4 rounded-2xl border border-gray-200 shadow-xs">
        <div>
          <h3 className="font-extrabold text-sm text-quickopia-navy flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-quickopia-amber" />
            <span>Active Hero Banner Carousel ({banners.length})</span>
          </h3>
          <p className="text-xs text-gray-500 mt-0.5">
            Synchronizes instantly with the mobile app storefront header carousel and parallax slides.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setEditing('new')}
          className="bg-quickopia-navy hover:bg-slate-900 text-white px-4 py-2.5 rounded-xl text-xs font-bold transition shadow-sm flex items-center gap-2"
        >
          <Plus className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>Add New Banner Slide</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {banners.map((b) => (
          <div
            key={b.id}
            className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-xs hover:shadow-md transition flex flex-col"
          >
            {/* Live Banner Preview */}
            <div className="relative h-44 w-full bg-slate-900 overflow-hidden">
              {b.image_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={b.image_url}
                  alt={b.title}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex flex-col items-center justify-center text-gray-500 text-xs">
                  <ImageIcon className="w-8 h-8 text-gray-600 mb-1" />
                  <span>No background image</span>
                </div>
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent flex flex-col justify-end p-4">
                <span className="text-[10px] font-extrabold text-amber-300 tracking-wider uppercase mb-1">
                  {b.tag}
                </span>
                <h4 className="text-white font-black text-base line-clamp-1">
                  {b.title}
                </h4>
                <p className="text-white/80 text-xs line-clamp-1 mt-0.5">
                  {b.subtitle}
                </p>
              </div>
              <div className="absolute top-3 right-3 flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => toggleActive(b)}
                  className={`text-[10px] font-extrabold px-2.5 py-1 rounded-full uppercase tracking-wider transition backdrop-blur-md ${
                    b.is_active
                      ? 'bg-emerald-600/90 text-white shadow-xs'
                      : 'bg-gray-800/80 text-gray-300'
                  }`}
                >
                  {b.is_active ? 'Active' : 'Disabled'}
                </button>
              </div>
            </div>

            {/* Details & Controls */}
            <div className="p-4 flex-1 flex flex-col justify-between space-y-3">
              <div className="space-y-1 text-xs text-gray-600">
                <div className="flex justify-between">
                  <span className="font-semibold text-gray-500">CTA Button:</span>
                  <span className="font-bold text-gray-800">{b.button_text || 'Shop Now'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-semibold text-gray-500">Slide Order:</span>
                  <span className="font-bold text-gray-800">#{b.display_order}</span>
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setEditing(b)}
                  className="inline-flex items-center gap-1.5 bg-gray-100 hover:bg-quickopia-navy hover:text-white text-gray-800 text-xs font-bold px-3 py-1.5 rounded-lg transition"
                >
                  <Edit3 className="w-3 h-3" />
                  <span>Edit Slide</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleDelete(b)}
                  className="inline-flex items-center gap-1.5 bg-red-50 hover:bg-red-600 hover:text-white text-red-700 text-xs font-bold px-3 py-1.5 rounded-lg transition"
                >
                  <Trash2 className="w-3 h-3" />
                  <span>Delete</span>
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {banners.length === 0 && (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-200 text-gray-400">
          <ImageIcon className="w-12 h-12 text-gray-300 mx-auto mb-2" />
          <p className="text-xs font-semibold">No hero banners created yet.</p>
        </div>
      )}

      {editing && (
        <BannerFormModal
          banner={editing === 'new' ? null : editing}
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

function BannerFormModal({
  banner,
  onClose,
  onDone,
}: {
  banner: HeroBanner | null;
  onClose: () => void;
  onDone: () => void;
}) {
  const [title, setTitle] = useState(banner?.title ?? '');
  const [subtitle, setSubtitle] = useState(banner?.subtitle ?? '');
  const [tag, setTag] = useState(banner?.tag ?? 'PROMOTION');
  const [buttonText, setButtonText] = useState(banner?.button_text ?? 'Shop Now');
  const [imageUrl, setImageUrl] = useState<string | null>(banner?.image_url ?? null);
  const [displayOrder, setDisplayOrder] = useState(banner?.display_order ?? 0);
  const [isActive, setIsActive] = useState(banner?.is_active ?? true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !subtitle.trim()) {
      setError('Title and subtitle are required.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const payload = {
        title: title.trim(),
        subtitle: subtitle.trim(),
        tag: tag.trim(),
        button_text: buttonText.trim(),
        image_url: imageUrl,
        display_order: displayOrder,
        is_active: isActive,
      };

      if (banner) {
        await updateHeroBanner(banner.id, payload);
      } else {
        await createHeroBanner(payload);
      }
      onDone();
    } catch (e) {
      setError(`Could not save banner: ${e instanceof Error ? e.message : e}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal title={banner ? 'Edit Hero Banner Slide' : 'New Banner Slide'} onClose={onClose}>
      <form onSubmit={save} className="space-y-4 max-h-[75vh] overflow-y-auto pr-1">
        <ImageUploadField
          value={imageUrl}
          onChange={(url: string) => setImageUrl(url)}
          label="Banner Background Image (Landscape Recommended)"
        />

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Badge Tag (e.g. MEGA SALE, FRESH HARVEST, WEEKEND OFFER)
          </label>
          <input
            type="text"
            required
            value={tag}
            onChange={(e) => setTag(e.target.value)}
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber uppercase tracking-wider font-bold"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Headline Title
          </label>
          <input
            type="text"
            required
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. 50% Off Fresh Farm Groceries"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber font-bold"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Subtitle / Explainer
          </label>
          <input
            type="text"
            required
            value={subtitle}
            onChange={(e) => setSubtitle(e.target.value)}
            placeholder="e.g. Delivered straight to your door across Dar es Salaam in 30 mins"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Call-to-Action Button Label
            </label>
            <input
              type="text"
              value={buttonText}
              onChange={(e) => setButtonText(e.target.value)}
              placeholder="Shop Now"
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber font-semibold"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Slide Sequence Order
            </label>
            <input
              type="number"
              value={displayOrder}
              onChange={(e) => setDisplayOrder(Number(e.target.value))}
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber font-semibold"
            />
          </div>
        </div>

        <label className="flex items-center gap-2 text-xs font-semibold cursor-pointer pt-1">
          <input
            type="checkbox"
            checked={isActive}
            onChange={(e) => setIsActive(e.target.checked)}
            className="h-4 w-4 rounded text-quickopia-navy accent-quickopia-navy"
          />
          <span>Active in live storefront carousel</span>
        </label>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg font-medium">
            {error}
          </p>
        )}

        <div className="pt-2">
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
          >
            {loading ? 'Saving banner slide...' : 'Save Banner Slide'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
