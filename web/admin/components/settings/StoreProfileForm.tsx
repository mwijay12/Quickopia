'use client';

import { useEffect, useState } from 'react';
import {
  fetchSupermarketSettings,
  updateSupermarketSettings,
  type SupermarketSettings,
} from '@/lib/settings';
import { uploadImageToCloudinary, CloudinaryUploadError } from '@/lib/cloudinary';
import { CardGridSkeleton } from '@/components/ui/Skeleton';
import {
  Store,
  MapPin,
  Phone,
  Clock,
  Tag,
  Upload,
  CreditCard,
  FileText,
  Scale,
  Save,
} from 'lucide-react';

export default function StoreProfileForm() {
  const [settings, setSettings] = useState<SupermarketSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingLogo, setUploadingLogo] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Form fields
  const [supermarketName, setSupermarketName] = useState('');
  const [tagline, setTagline] = useState('');
  const [logoUrl, setLogoUrl] = useState('');
  const [branchAddress, setBranchAddress] = useState('');
  const [city, setCity] = useState('Dar es Salaam');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [operatingHours, setOperatingHours] = useState('');
  const [currencySymbol, setCurrencySymbol] = useState('TZS');
  const [mpesaTill, setMpesaTill] = useState('');
  const [tigoTill, setTigoTill] = useState('');
  const [airtelTill, setAirtelTill] = useState('');
  const [haloTill, setHaloTill] = useState('');
  const [nmbAccount, setNmbAccount] = useState('');
  const [crdbAccount, setCrdbAccount] = useState('');
  const [returnWindowHours, setReturnWindowHours] = useState(2);
  const [returnPolicyNotes, setReturnPolicyNotes] = useState('');

  useEffect(() => {
    async function load() {
      try {
        const data = await fetchSupermarketSettings();
        setSettings(data);
        setSupermarketName(data.supermarket_name || 'Shoppers Supermarket');
        setTagline(data.tagline || '');
        setLogoUrl(data.logo_url || '');
        setBranchAddress(data.branch_address || '');
        setCity(data.city || 'Dar es Salaam');
        setPhone(data.phone || '');
        setEmail(data.email || '');
        setOperatingHours(data.operating_hours || 'Mon - Sun: 07:30 AM - 10:30 PM');
        setCurrencySymbol(data.currency_symbol || 'TZS');
        setMpesaTill(data.mpesa_till || '');
        setTigoTill(data.tigo_till || '');
        setAirtelTill(data.airtel_till || '');
        setHaloTill(data.halo_till || '');
        setNmbAccount(data.nmb_account || '');
        setCrdbAccount(data.crdb_account || '');
        setReturnWindowHours(data.return_window_hours ?? 2);
        setReturnPolicyNotes(
          data.return_policy_notes ||
            'Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours.'
        );
      } catch (e) {
        setMessage({ type: 'error', text: `Failed to load settings: ${e}` });
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  const handleLogoUpload = async (file: File) => {
    if (file.size > 5 * 1024 * 1024) {
      alert('Logo file must be smaller than 5MB.');
      return;
    }
    setUploadingLogo(true);
    setMessage(null);
    try {
      const url = await uploadImageToCloudinary(file);
      setLogoUrl(url);
      setMessage({ type: 'success', text: 'Logo uploaded successfully! Click "Save Store Profile" to persist.' });
    } catch (e) {
      setMessage({
        type: 'error',
        text: e instanceof CloudinaryUploadError ? e.message : 'Logo upload failed.',
      });
    } finally {
      setUploadingLogo(false);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      const updated = await updateSupermarketSettings({
        supermarket_name: supermarketName.trim(),
        tagline: tagline.trim(),
        logo_url: logoUrl.trim(),
        branch_address: branchAddress.trim(),
        city: city.trim(),
        phone: phone.trim(),
        email: email.trim(),
        operating_hours: operatingHours.trim(),
        currency_symbol: currencySymbol.trim(),
        mpesa_till: mpesaTill.trim() || undefined,
        tigo_till: tigoTill.trim() || undefined,
        airtel_till: airtelTill.trim() || undefined,
        halo_till: haloTill.trim() || undefined,
        nmb_account: nmbAccount.trim() || undefined,
        crdb_account: crdbAccount.trim() || undefined,
        return_window_hours: returnWindowHours,
        return_policy_notes: returnPolicyNotes.trim(),
      });
      setSettings(updated);
      setMessage({
        type: 'success',
        text: 'Supermarket details saved successfully! All mobile devices & storefront will synchronize immediately.',
      });
    } catch (e) {
      setMessage({ type: 'error', text: `Failed to save changes: ${e}` });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="max-w-4xl space-y-6">
        <div className="h-40 bg-gray-100 rounded-2xl animate-pulse" />
        <CardGridSkeleton count={2} />
      </div>
    );
  }

  return (
    <div className="max-w-4xl space-y-8">
      {message && (
        <div
          className={`p-4 rounded-xl text-sm font-semibold flex items-center justify-between shadow-xs ${
            message.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}
        >
          <span>{message.text}</span>
          <button
            type="button"
            onClick={() => setMessage(null)}
            className="text-xs opacity-70 hover:opacity-100 ml-4 font-bold"
          >
            &times;
          </button>
        </div>
      )}

      {/* Live Supermarket Identity Preview Card */}
      <div className="bg-gradient-to-r from-quickopia-navy to-slate-900 rounded-2xl p-6 text-white shadow-md">
        <div className="text-xs uppercase tracking-widest text-amber-400 font-extrabold mb-2">
          Live Storefront Identity Preview
        </div>
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-5">
          <div className="w-20 h-20 rounded-2xl bg-white/10 backdrop-blur-sm border-2 border-white/20 p-1 flex items-center justify-center overflow-hidden shrink-0">
            {logoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={logoUrl}
                alt="Supermarket Logo"
                className="w-full h-full object-contain rounded-xl"
              />
            ) : (
              <Store className="w-8 h-8 text-quickopia-amber" />
            )}
          </div>
          <div className="text-center sm:text-left flex-1">
            <h2 className="text-2xl font-black tracking-tight text-white">
              {supermarketName || 'Quickopia Supermarket'}
            </h2>
            <p className="text-sm text-gray-300 mt-0.5">
              {tagline || 'Fresh groceries & daily essentials at your doorstep'}
            </p>
            <div className="flex flex-wrap gap-4 mt-3 text-xs text-white/80">
              <span className="flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-quickopia-amber inline" /> {branchAddress || 'Dar es Salaam, Tanzania'}
              </span>
              <span className="flex items-center gap-1.5">
                <Phone className="w-3.5 h-3.5 text-quickopia-amber inline" /> {phone || '+255 712 345 678'}
              </span>
              <span className="flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-quickopia-amber inline" /> {operatingHours || '07:30 AM - 10:30 PM'}
              </span>
            </div>
          </div>
        </div>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* Section 1: Supermarket Branding */}
        <div className="bg-white rounded-2xl p-6 border border-gray-200 shadow-xs space-y-5">
          <h3 className="text-base font-bold text-gray-900 border-b border-gray-100 pb-3 flex items-center gap-2">
            <Tag className="w-4 h-4 text-quickopia-amber" /> Supermarket Name &amp; Branding
          </h3>
          <p className="text-xs text-gray-500">
            Replace the system name &quot;Quickopia&quot; with your physical or commercial supermarket name. Shoppers on mobile and web will see this name immediately.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Supermarket Name *
              </label>
              <input
                type="text"
                required
                value={supermarketName}
                onChange={(e) => setSupermarketName(e.target.value)}
                placeholder="e.g. Shoppers Supermarket, Village Supermarket"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Tagline / Slogan
              </label>
              <input
                type="text"
                value={tagline}
                onChange={(e) => setTagline(e.target.value)}
                placeholder="e.g. Fresh groceries &amp; daily essentials"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>
          </div>

          {/* Logo Uploader */}
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1.5">
              Supermarket Logo (Upload from Device or paste Image URL)
            </label>
            <div className="flex flex-col sm:flex-row items-center gap-4">
              <div className="w-20 h-20 rounded-xl border border-gray-200 bg-gray-50 flex items-center justify-center overflow-hidden shrink-0">
                {logoUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={logoUrl}
                    alt="Logo"
                    className="w-full h-full object-contain p-1"
                  />
                ) : (
                  <span className="text-xs text-gray-400 font-medium">No logo</span>
                )}
              </div>
              <div className="flex-1 space-y-2 w-full">
                <div className="flex items-center gap-3">
                  <label className="cursor-pointer inline-flex items-center gap-2 bg-gray-100 hover:bg-gray-200 text-gray-800 text-xs font-bold px-3.5 py-2.5 rounded-xl border border-gray-200 transition shadow-2xs">
                    {uploadingLogo ? (
                      <>
                        <span className="w-3.5 h-3.5 border-2 border-gray-700 border-t-transparent rounded-full animate-spin" />
                        <span>Uploading...</span>
                      </>
                    ) : (
                      <>
                        <Upload className="w-3.5 h-3.5 text-gray-700" />
                        <span>Upload Logo from Device</span>
                      </>
                    )}
                    <input
                      type="file"
                      accept="image/png, image/jpeg, image/webp, image/svg+xml"
                      className="hidden"
                      disabled={uploadingLogo}
                      onChange={(e) =>
                        e.target.files?.[0] && handleLogoUpload(e.target.files[0])
                      }
                    />
                  </label>
                  <span className="text-xs text-gray-400 font-medium">or</span>
                  <input
                    type="url"
                    value={logoUrl}
                    onChange={(e) => setLogoUrl(e.target.value)}
                    placeholder="https://.../logo.png"
                    className="flex-1 border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
                  />
                </div>
                <p className="text-[11px] text-gray-400">
                  Direct upload automatically optimizes your image on Cloudinary and synchronizes everywhere.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Section 2: Physical Location & Contact */}
        <div className="bg-white rounded-2xl p-6 border border-gray-200 shadow-xs space-y-5">
          <h3 className="text-base font-bold text-gray-900 border-b border-gray-100 pb-3 flex items-center gap-2">
            <MapPin className="w-4 h-4 text-quickopia-amber" /> Physical Location &amp; Contact Information
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2">
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Branch Address &amp; Mall / Street Location *
              </label>
              <input
                type="text"
                required
                value={branchAddress}
                onChange={(e) => setBranchAddress(e.target.value)}
                placeholder="e.g. Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                City / Region *
              </label>
              <input
                type="text"
                required
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder="Dar es Salaam"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Customer Support Phone *
              </label>
              <input
                type="tel"
                required
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+255 712 345 678"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Customer Support Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="support@shoppers.co.tz"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Store Operating Hours
              </label>
              <input
                type="text"
                value={operatingHours}
                onChange={(e) => setOperatingHours(e.target.value)}
                placeholder="Mon - Sun: 07:30 AM - 10:30 PM"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1.5">
                Currency Symbol
              </label>
              <input
                type="text"
                value={currencySymbol}
                onChange={(e) => setCurrencySymbol(e.target.value)}
                placeholder="TZS"
                className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-medium"
              />
            </div>
          </div>
        </div>

        {/* Section 3: Payment Till & Account Numbers */}
        <div className="bg-white rounded-2xl p-6 border border-gray-200 shadow-xs space-y-5">
          <h3 className="text-base font-bold text-gray-900 border-b border-gray-100 pb-3 flex items-center gap-2">
            <CreditCard className="w-4 h-4 text-quickopia-amber" /> Payment Tills &amp; Accounts (Tanzania Mobile Money)
          </h3>
          <p className="text-xs text-gray-500">
            These till and bank account numbers are presented to shoppers choosing Mobile Money or Bank Transfer at checkout.
          </p>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                M-Pesa Till #
              </label>
              <input
                type="text"
                value={mpesaTill}
                onChange={(e) => setMpesaTill(e.target.value)}
                placeholder="556677"
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Tigo Pesa Till #
              </label>
              <input
                type="text"
                value={tigoTill}
                onChange={(e) => setTigoTill(e.target.value)}
                placeholder="223344"
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Airtel Money Till #
              </label>
              <input
                type="text"
                value={airtelTill}
                onChange={(e) => setAirtelTill(e.target.value)}
                placeholder="889900"
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                HaloPesa Till #
              </label>
              <input
                type="text"
                value={haloTill}
                onChange={(e) => setHaloTill(e.target.value)}
                placeholder="112233"
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
            </div>

            <div className="col-span-2">
              <label className="block text-xs font-bold text-gray-700 mb-1">
                NMB Bank Account #
              </label>
              <input
                type="text"
                value={nmbAccount}
                onChange={(e) => setNmbAccount(e.target.value)}
                placeholder="9900112233"
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
            </div>

            <div className="col-span-2">
              <label className="block text-xs font-bold text-gray-700 mb-1">
                CRDB Bank Account #
              </label>
              <input
                type="text"
                value={crdbAccount}
                onChange={(e) => setCrdbAccount(e.target.value)}
                placeholder="8877665544"
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
            </div>
          </div>
        </div>

        {/* Store Policies & Terms */}
        <div className="bg-white border border-gray-200 rounded-2xl p-6 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-bold text-gray-900 flex items-center gap-2">
              <FileText className="w-4 h-4 text-quickopia-amber" /> Store Policies & Customer Terms (Vigezo na Masharti ya Duka)
            </h2>
            <span className="text-[11px] font-bold bg-amber-100 text-amber-900 px-2.5 py-1 rounded-full">
              Synchronized to Mobile App
            </span>
          </div>
          <p className="text-xs text-gray-500">
            These terms govern delivery handoffs, fresh item returns, and 6-digit OTP verification displayed to customers during checkout and in their profile.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Return Claim Window (Hours)
              </label>
              <input
                type="number"
                min={1}
                max={72}
                value={returnWindowHours}
                onChange={(e) => setReturnWindowHours(parseInt(e.target.value) || 2)}
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white font-bold"
              />
              <span className="text-[10px] text-gray-400 mt-1 block">
                Standard: 2 hours for fresh food, 24 hours for pantry.
              </span>
            </div>

            <div className="md:col-span-2">
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Perishable Goods & Returns Policy Notice
              </label>
              <textarea
                rows={3}
                value={returnPolicyNotes}
                onChange={(e) => setReturnPolicyNotes(e.target.value)}
                placeholder="Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours."
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white leading-relaxed"
              />
            </div>
          </div>

          <div className="bg-slate-50 border border-slate-200 rounded-xl p-3.5 flex items-start gap-3">
            <Scale className="w-5 h-5 text-slate-600 shrink-0 mt-0.5" />
            <div className="text-xs text-slate-700 space-y-1">
              <span className="font-bold block text-slate-900">
                Customer Mobile App Notice:
              </span>
              <p>
                &ldquo;By browsing, creating an account, or placing orders at{' '}
                <strong className="text-quickopia-navy">{supermarketName || 'Shoppers Supermarket'}</strong>, 
                customers agree to express delivery terms across Dar es Salaam, 6-digit courier OTP handoff, and return claims within{' '}
                <strong>{returnWindowHours} hours</strong> of delivery.&rdquo;
              </p>
            </div>
          </div>
        </div>

        {/* Save button bar */}
        <div className="flex justify-end items-center gap-4 pt-4">
          <button
            type="submit"
            disabled={saving}
            className="bg-quickopia-navy hover:bg-slate-900 text-white text-sm font-bold px-8 py-3 rounded-xl transition shadow-md flex items-center gap-2"
          >
            {saving ? (
              <>
                <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                <span>Saving Store Profile...</span>
              </>
            ) : (
              <>
                <Save className="w-4 h-4 text-quickopia-amber" />
                <span>Save Store Profile</span>
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
