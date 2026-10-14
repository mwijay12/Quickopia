'use client';

import { useEffect, useState } from 'react';
import {
  fetchBroadcastNotifications,
  sendBroadcastNotification,
  deleteBroadcastNotification,
  type BroadcastNotification,
  type NotificationType,
  type TargetAudience,
} from '@/lib/notifications';
import { uploadImageToCloudinary, CloudinaryUploadError } from '@/lib/cloudinary';
import { TableSkeleton } from '@/components/ui/Skeleton';
import {
  Tag,
  Clock,
  AlertTriangle,
  Megaphone,
  Users,
  ShoppingCart,
  Bike,
  Send,
  Smartphone,
  History,
  RefreshCw,
  Camera,
  Image as ImageIcon,
  PenTool,
  Trash2,
} from 'lucide-react';

const NOTIFICATION_TYPES = [
  { type: 'offer' as NotificationType, label: 'Promo Offer / Discount', icon: Tag, color: 'bg-amber-100 text-amber-800 border-amber-200' },
  { type: 'reminder' as NotificationType, label: 'Useful Reminder', icon: Clock, color: 'bg-blue-100 text-blue-800 border-blue-200' },
  { type: 'alert' as NotificationType, label: 'Store Alert / Urgent', icon: AlertTriangle, color: 'bg-rose-100 text-rose-800 border-rose-200' },
  { type: 'system' as NotificationType, label: 'General Announcement', icon: Megaphone, color: 'bg-purple-100 text-purple-800 border-purple-200' },
];

const TARGET_AUDIENCES = [
  { target: 'all' as TargetAudience, label: 'All App Users (Shoppers & Drivers)', icon: Users },
  { target: 'customers' as TargetAudience, label: 'Customers / Shoppers Only', icon: ShoppingCart },
  { target: 'drivers' as TargetAudience, label: 'Delivery Couriers Only', icon: Bike },
];

export default function BroadcastComposer() {
  const [history, setHistory] = useState<BroadcastNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Form State
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [type, setType] = useState<NotificationType>('offer');
  const [targetAudience, setTargetAudience] = useState<TargetAudience>('all');
  const [imageUrl, setImageUrl] = useState('');

  const loadHistory = async () => {
    try {
      const list = await fetchBroadcastNotifications();
      setHistory(list);
    } catch (e) {
      console.error('Failed to load broadcast history:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHistory();
  }, []);

  const handleImageUpload = async (file: File) => {
    if (file.size > 5 * 1024 * 1024) {
      alert('Notification banner must be smaller than 5MB.');
      return;
    }
    setUploadingImage(true);
    setFeedback(null);
    try {
      const url = await uploadImageToCloudinary(file);
      setImageUrl(url);
      setFeedback({ type: 'success', text: 'Banner graphic uploaded successfully!' });
    } catch (e) {
      setFeedback({
        type: 'error',
        text: e instanceof CloudinaryUploadError ? e.message : 'Banner upload failed.',
      });
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      alert('Please fill out both the title and message body.');
      return;
    }

    setSending(true);
    setFeedback(null);
    try {
      const newNotif = await sendBroadcastNotification({
        title: title.trim(),
        body: body.trim(),
        type,
        target_audience: targetAudience,
        image_url: imageUrl.trim() || null,
      });

      setHistory((prev) => [newNotif, ...prev]);
      setTitle('');
      setBody('');
      setImageUrl('');
      setFeedback({
        type: 'success',
        text: 'Broadcast notification dispatched! Mobile users will receive an in-app banner and lock screen alert in real time.',
      });
    } catch (e) {
      setFeedback({ type: 'error', text: `Failed to broadcast notification: ${e}` });
    } finally {
      setSending(false);
    }
  };

  const handleDelete = async (id: string, notifTitle: string) => {
    if (!confirm(`Are you sure you want to delete broadcast "${notifTitle}"?`)) return;
    try {
      await deleteBroadcastNotification(id);
      setHistory((prev) => prev.filter((item) => item.id !== id));
    } catch (e) {
      alert(`Could not delete notification: ${e}`);
    }
  };

  const currentTypeMeta = NOTIFICATION_TYPES.find((t) => t.type === type)!;

  return (
    <div className="space-y-10">
      {feedback && (
        <div
          className={`p-4 rounded-xl text-sm font-semibold flex items-center justify-between shadow-xs ${
            feedback.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}
        >
          <span>{feedback.text}</span>
          <button
            type="button"
            onClick={() => setFeedback(null)}
            className="text-xs opacity-70 hover:opacity-100 ml-4 font-bold"
          >
            &times;
          </button>
        </div>
      )}

      {/* Grid: Composer on Left, Live Mobile Preview on Right */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* COMPOSER FORM (7 cols) */}
        <div className="lg:col-span-7 bg-white rounded-2xl p-6 border border-gray-200 shadow-xs space-y-6">
          <div className="border-b border-gray-100 pb-3">
            <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <PenTool className="w-4 h-4 text-quickopia-amber" /> Compose Broadcast Notification
            </h2>
            <p className="text-xs text-gray-500 mt-0.5">
              Send real-time alerts, promotional discounts, and reminders directly to users&apos; smartphones.
            </p>
          </div>

          <form onSubmit={handleSend} className="space-y-5">
            {/* Notification Type Selector */}
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-2">
                Notification Category / Purpose
              </label>
              <div className="grid grid-cols-2 gap-2">
                {NOTIFICATION_TYPES.map((t) => {
                  const Icon = t.icon;
                  return (
                    <button
                      key={t.type}
                      type="button"
                      onClick={() => setType(t.type)}
                      className={`p-2.5 rounded-xl border text-left text-xs font-bold transition flex items-center gap-2 ${
                        type === t.type
                          ? 'border-quickopia-navy bg-slate-900 text-white shadow-xs'
                          : 'border-gray-200 bg-gray-50 text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      <Icon className={`w-4 h-4 shrink-0 ${type === t.type ? 'text-quickopia-amber' : 'text-gray-500'}`} />
                      <span>{t.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Title */}
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Headline / Title *
              </label>
              <input
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Flash 20% Discount on Fresh Fruits!"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            {/* Body */}
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Message Body *
              </label>
              <textarea
                required
                rows={3}
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Describe your special offer, discount voucher code, or important supermarket update..."
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            {/* Target Audience */}
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Target Audience
              </label>
              <select
                value={targetAudience}
                onChange={(e) => setTargetAudience(e.target.value as TargetAudience)}
                className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              >
                {TARGET_AUDIENCES.map((a) => (
                  <option key={a.target} value={a.target}>
                    {a.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Image / Graphic Banner Uploader */}
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Optional Banner Graphic / Promo Image
              </label>
              <div className="flex flex-col sm:flex-row items-center gap-3">
                <div className="w-16 h-16 rounded-xl border border-gray-200 bg-gray-50 flex items-center justify-center overflow-hidden shrink-0">
                  {imageUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={imageUrl}
                      alt="Banner Preview"
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <ImageIcon className="w-6 h-6 text-gray-400" />
                  )}
                </div>
                <div className="flex-1 w-full space-y-1.5">
                  <div className="flex items-center gap-2">
                    <label className="cursor-pointer inline-flex items-center gap-2 bg-gray-100 hover:bg-gray-200 text-gray-800 text-xs font-bold px-3 py-2 rounded-xl border border-gray-200 transition shadow-2xs">
                      {uploadingImage ? (
                        <>
                          <span className="w-3 h-3 border-2 border-gray-700 border-t-transparent rounded-full animate-spin" />
                          <span>Uploading...</span>
                        </>
                      ) : (
                        <>
                          <Camera className="w-3.5 h-3.5 text-gray-600" />
                          <span>Upload Banner</span>
                        </>
                      )}
                      <input
                        type="file"
                        accept="image/png, image/jpeg, image/webp"
                        className="hidden"
                        disabled={uploadingImage}
                        onChange={(e) =>
                          e.target.files?.[0] && handleImageUpload(e.target.files[0])
                        }
                      />
                    </label>
                    <span className="text-xs text-gray-400">or</span>
                    <input
                      type="url"
                      value={imageUrl}
                      onChange={(e) => setImageUrl(e.target.value)}
                      placeholder="Paste image URL..."
                      className="flex-1 border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Submit Button */}
            <div className="pt-2">
              <button
                type="submit"
                disabled={sending || !title.trim() || !body.trim()}
                className="w-full bg-gradient-to-r from-quickopia-navy to-slate-900 hover:from-slate-900 hover:to-black text-white font-bold py-3 px-6 rounded-xl transition shadow-md flex items-center justify-center gap-2 text-sm disabled:opacity-50"
              >
                {sending ? (
                  <>
                    <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Broadcasting to Users...</span>
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4 text-quickopia-amber" />
                    <span>Send Broadcast Notification</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>

        {/* LIVE MOBILE PREVIEW DEVICE MOCKUP (5 cols) */}
        <div className="lg:col-span-5 space-y-4">
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500 flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <Smartphone className="w-4 h-4 text-quickopia-amber inline" /> Real-Time Device Mockup
            </span>
            <span className="text-emerald-600 font-semibold flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Live Preview
            </span>
          </div>

          {/* Smartphone Bezel */}
          <div className="mx-auto max-w-[340px] bg-slate-900 p-3 rounded-[38px] shadow-2xl border-4 border-slate-700">
            {/* Screen Area */}
            <div className="bg-slate-950 rounded-[28px] overflow-hidden min-h-[480px] flex flex-col relative text-white">
              {/* Dynamic Island / Speaker Notch */}
              <div className="w-24 h-4 bg-black rounded-full mx-auto mt-2 mb-3 shrink-0" />

              {/* Status bar */}
              <div className="flex justify-between px-6 text-[10px] text-gray-400 font-medium mb-3 shrink-0">
                <span>09:41</span>
                <span className="flex items-center gap-1.5">
                  <span>5G</span>
                  <span>100%</span>
                </span>
              </div>

              {/* Top Heads-Up Dropdown Notification Banner ("ziwe juu") */}
              <div className="px-3 mb-4 shrink-0">
                <div className="bg-slate-900/95 backdrop-blur-md border border-amber-500/40 rounded-2xl p-3.5 shadow-xl">
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-xl bg-quickopia-navy border border-amber-400/30 flex items-center justify-center shrink-0">
                      {(() => {
                        const IconComp = currentTypeMeta.icon;
                        return <IconComp className="w-4 h-4 text-quickopia-amber" />;
                      })()}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] uppercase tracking-wider text-amber-400 font-extrabold">
                          Shoppers Supermarket
                        </span>
                        <span className="text-[9px] text-gray-400">now</span>
                      </div>
                      <div className="text-xs font-bold text-white mt-0.5 truncate">
                        {title.trim() || 'Weekend Discount Alert!'}
                      </div>
                      <div className="text-[11px] text-gray-300 line-clamp-2 mt-0.5">
                        {body.trim() || 'Get up to 25% OFF fresh produce and bakery items this weekend across Dar es Salaam.'}
                      </div>
                    </div>
                  </div>
                  {imageUrl && (
                    <div className="mt-2.5 rounded-lg overflow-hidden h-24 bg-gray-800">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={imageUrl}
                        alt="Preview Banner"
                        className="w-full h-full object-cover"
                      />
                    </div>
                  )}
                </div>
              </div>

              {/* Mock Mobile Home Screen Background */}
              <div className="flex-1 px-4 flex flex-col justify-end pb-8 opacity-40">
                <div className="space-y-3">
                  <div className="h-10 bg-white/10 rounded-xl" />
                  <div className="h-28 bg-white/10 rounded-2xl" />
                  <div className="grid grid-cols-2 gap-2">
                    <div className="h-20 bg-white/10 rounded-xl" />
                    <div className="h-20 bg-white/10 rounded-xl" />
                  </div>
                </div>
              </div>

              {/* Home indicator bar */}
              <div className="w-32 h-1 bg-white/40 rounded-full mx-auto mb-2 shrink-0" />
            </div>
          </div>
        </div>
      </div>

      {/* Broadcast History Table */}
      <div className="bg-white rounded-2xl p-6 border border-gray-200 shadow-xs space-y-4">
        <div className="flex items-center justify-between border-b border-gray-100 pb-3">
          <div>
            <h3 className="text-base font-bold text-gray-900 flex items-center gap-2">
              <History className="w-4 h-4 text-quickopia-navy" /> Sent Broadcast History ({history.length})
            </h3>
            <p className="text-xs text-gray-500">
              Review active push announcements and offer notifications visible to mobile users.
            </p>
          </div>
          <button
            type="button"
            onClick={loadHistory}
            className="text-xs font-bold text-quickopia-navy hover:underline flex items-center gap-1"
          >
            <RefreshCw className="w-3.5 h-3.5" /> Refresh
          </button>
        </div>

        {loading ? (
          <TableSkeleton rows={4} />
        ) : history.length === 0 ? (
          <div className="py-12 text-center text-gray-400">
            <Megaphone className="w-8 h-8 text-gray-300 mx-auto mb-2" />
            <p className="text-xs font-semibold">No broadcast notifications sent yet.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
                <tr>
                  <th className="p-3.5">Category</th>
                  <th className="p-3.5">Headline &amp; Body</th>
                  <th className="p-3.5">Audience</th>
                  <th className="p-3.5">Banner</th>
                  <th className="p-3.5">Dispatched</th>
                  <th className="p-3.5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {history.map((h) => {
                  const typeMeta =
                    NOTIFICATION_TYPES.find((t) => t.type === h.type) ||
                    NOTIFICATION_TYPES[0];
                  const TypeIcon = typeMeta.icon;
                  return (
                    <tr key={h.id} className="hover:bg-gray-50/60 transition">
                      <td className="p-3.5">
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-extrabold border ${typeMeta.color}`}
                        >
                          <TypeIcon className="w-3 h-3" />
                          <span>{h.type.toUpperCase()}</span>
                        </span>
                      </td>
                      <td className="p-3.5 max-w-sm">
                        <div className="font-bold text-gray-900 text-sm">{h.title}</div>
                        <div className="text-gray-500 text-xs mt-0.5 line-clamp-2">
                          {h.body}
                        </div>
                      </td>
                      <td className="p-3.5 text-gray-600 font-medium">
                        {h.target_audience === 'all' ? (
                          <span className="flex items-center gap-1.5">
                            <Users className="w-3.5 h-3.5 text-gray-500" /> All Users
                          </span>
                        ) : h.target_audience === 'customers' ? (
                          <span className="flex items-center gap-1.5">
                            <ShoppingCart className="w-3.5 h-3.5 text-blue-500" /> Shoppers
                          </span>
                        ) : (
                          <span className="flex items-center gap-1.5">
                            <Bike className="w-3.5 h-3.5 text-amber-500" /> Couriers
                          </span>
                        )}
                      </td>
                      <td className="p-3.5">
                        {h.image_url ? (
                          <div className="w-12 h-12 rounded-lg overflow-hidden bg-gray-100 border border-gray-200">
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                              src={h.image_url}
                              alt=""
                              className="w-full h-full object-cover"
                            />
                          </div>
                        ) : (
                          <span className="text-gray-400 text-[10px]">None</span>
                        )}
                      </td>
                      <td className="p-3.5 text-gray-500">
                        {new Date(h.created_at).toLocaleDateString()}{' '}
                        <span className="text-[10px] text-gray-400">
                          {new Date(h.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </td>
                      <td className="p-3.5 text-right">
                        <button
                          type="button"
                          onClick={() => handleDelete(h.id, h.title)}
                          className="text-red-600 hover:text-red-800 font-bold hover:underline inline-flex items-center gap-1"
                        >
                          <Trash2 className="w-3.5 h-3.5" /> Delete
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
