'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useCart } from '@/context/CartContext';
import { getAuthenticatedUser, getUserProfile, updateProfileBasicInfo } from '@/lib/auth';
import { getPrimaryBranch } from '@/lib/branch';
import {
  placeOrder,
  revalidateCartItems,
  OrderPlacementError,
} from '@/lib/orders';
import type { Branch, CheckoutFormData } from '@/lib/types';
import FulfillmentToggle from '@/components/checkout/FulfillmentToggle';
import AddressForm from '@/components/checkout/AddressForm';
import PaymentMethodSelector from '@/components/checkout/PaymentMethodSelector';
import OrderSummary from '@/components/checkout/OrderSummary';

const DELIVERY_FEE_TZS = 3000;
const TZ_PHONE_REGEX = /^(\+255|0)[67]\d{8}$/;

export default function CheckoutPage() {
  const router = useRouter();
  const { items, subtotalTzs, clearCart } = useCart();
  const [branch, setBranch] = useState<Branch | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [apiError, setApiError] = useState<string | null>(null);
  const [errors, setErrors] = useState<
    Partial<Record<keyof CheckoutFormData, string>>
  >({});

  const [form, setForm] = useState<CheckoutFormData>({
    fulfillmentType: 'delivery',
    city: 'Dar es Salaam',
    neighborhood: '',
    landmark: '',
    houseDetails: '',
    latitude: null,
    longitude: null,
    phone: '',
    fullName: '',
    paymentMethod: 'cod',
  });

  // Auth Gate: ensure customer is logged in before proceeding
  useEffect(() => {
    getAuthenticatedUser().then(async (user) => {
      if (!user) {
        router.replace('/login?redirectTo=/checkout');
      } else {
        setUserId(user.id);
        const profile = await getUserProfile(user.id);
        if (profile) {
          setForm((f) => ({
            ...f,
            fullName: f.fullName || profile.full_name || '',
            phone: f.phone || profile.phone || '',
          }));
        }
        setCheckingAuth(false);
      }
    });
  }, [router]);

  useEffect(() => {
    getPrimaryBranch().then(setBranch);
  }, []);

  const patch = (p: Partial<CheckoutFormData>) =>
    setForm((f) => ({ ...f, ...p }));
  const deliveryFee =
    form.fulfillmentType === 'delivery' ? DELIVERY_FEE_TZS : 0;

  const validate = (): boolean => {
    const e: typeof errors = {};
    if (!form.fullName.trim()) e.fullName = 'Full name is required';
    if (!TZ_PHONE_REGEX.test(form.phone.replace(/\s/g, ''))) {
      e.phone = 'Enter a valid Tanzanian phone number (e.g. 0712 345 678)';
    }
    if (form.fulfillmentType === 'delivery') {
      if (!form.city.trim()) e.city = 'City is required';
      if (!form.neighborhood.trim())
        e.neighborhood = 'Neighborhood is required';
      if (!form.landmark.trim())
        e.landmark = 'Nearby landmark is required for delivery';
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const normalizePhone = (p: string) => {
    const cleaned = p.replace(/\s/g, '');
    return cleaned.startsWith('0') ? `+255${cleaned.slice(1)}` : cleaned;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) {
      router.push('/');
      return;
    }
    if (!validate()) return;
    if (!branch) {
      setApiError(
        'Supermarket branch details not loaded yet. Please try again.'
      );
      return;
    }
    if (!userId) {
      router.replace('/login?redirectTo=/checkout');
      return;
    }

    setSubmitting(true);
    setApiError(null);

    try {
      // 1. Re-validate stock and pricing before submitting
      const check = await revalidateCartItems(items);
      if (!check.valid) {
        setApiError(check.message || 'Cart validation failed.');
        setSubmitting(false);
        return;
      }

      // 2. Persist customer profile name and phone
      const normalizedPhone = normalizePhone(form.phone);
      await updateProfileBasicInfo(form.fullName.trim(), normalizedPhone);

      // 3. Submit order via the shared atomic Postgres RPC
      const order = await placeOrder(
        userId,
        branch.id,
        { ...form, phone: normalizedPhone },
        items,
        deliveryFee
      );

      // 4. Clear cart and proceed to live confirmation
      clearCart();
      router.push(`/order/${order.id}`);
    } catch (err) {
      setApiError(
        err instanceof OrderPlacementError
          ? err.message
          : err instanceof Error
          ? err.message
          : 'Something went wrong while placing your order. Please try again.'
      );
      setSubmitting(false);
    }
  };

  if (checkingAuth) {
    return (
      <main className="max-w-lg mx-auto p-8 text-center py-28">
        <div className="inline-block w-8 h-8 border-4 border-quickopia-navy border-t-transparent rounded-full animate-spin mb-3" />
        <p className="text-xs text-gray-500 font-medium">
          Verifying account session...
        </p>
      </main>
    );
  }

  if (items.length === 0) {
    return (
      <main className="max-w-lg mx-auto p-8 text-center py-20">
        <span className="text-5xl">🛒</span>
        <h1 className="text-xl font-bold mt-4 text-quickopia-navy">
          Your cart is empty
        </h1>
        <p className="text-gray-500 text-sm mt-2 mb-6">
          Add items from our catalog to start checkout.
        </p>
        <Link
          href="/"
          className="inline-block bg-quickopia-navy text-white px-6 py-3 rounded-xl font-bold hover:bg-slate-900 transition"
        >
          Browse Products
        </Link>
      </main>
    );
  }

  return (
    <main className="max-w-xl mx-auto px-4 py-8 space-y-6 pb-28">
      <div>
        <Link
          href="/"
          className="text-xs font-semibold text-quickopia-navy hover:underline flex items-center gap-1 mb-2"
        >
          &larr; Return to Shopping
        </Link>
        <h1 className="text-2xl font-extrabold text-quickopia-navy">
          Secure Checkout
        </h1>
        <p className="text-gray-600 text-xs mt-1">
          Complete your order with live fulfillment tracking
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 uppercase tracking-wider">
            1. Fulfillment Method
          </label>
          <FulfillmentToggle
            value={form.fulfillmentType}
            onChange={(v) => patch({ fulfillmentType: v })}
          />
        </div>

        {form.fulfillmentType === 'pickup' && branch && (
          <div className="bg-amber-50/70 border border-amber-200/80 rounded-xl p-4 text-sm text-gray-800 space-y-1">
            <p className="font-bold text-quickopia-navy">{branch.name}</p>
            <p className="text-xs text-gray-700">
              {branch.neighborhood ? `${branch.neighborhood}, ` : ''}
              {branch.city}
            </p>
            {branch.landmark && (
              <p className="text-xs text-gray-600">
                Landmark: {branch.landmark}
              </p>
            )}
            <p className="text-xs font-semibold text-green-700 pt-1">
              &bull; Estimated packing time: ~20 minutes from placement
            </p>
          </div>
        )}

        <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-3.5 shadow-sm">
          <h3 className="font-semibold text-sm text-quickopia-navy">
            2. Contact Information
          </h3>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Full Name
            </label>
            <input
              type="text"
              value={form.fullName}
              placeholder="e.g. Zuwena Said"
              onChange={(e) => patch({ fullName: e.target.value })}
              className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber transition ${
                errors.fullName
                  ? 'border-red-500 ring-1 ring-red-500'
                  : 'border-gray-300'
              }`}
            />
            {errors.fullName && (
              <p className="text-xs text-red-500 mt-1 font-medium">
                {errors.fullName}
              </p>
            )}
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Phone Number
            </label>
            <input
              type="tel"
              value={form.phone}
              onChange={(e) => patch({ phone: e.target.value })}
              placeholder="0712 345 678 or +255712345678"
              className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber transition ${
                errors.phone
                  ? 'border-red-500 ring-1 ring-red-500'
                  : 'border-gray-300'
              }`}
            />
            {errors.phone && (
              <p className="text-xs text-red-500 mt-1 font-medium">
                {errors.phone}
              </p>
            )}
            <p className="text-[11px] text-gray-500 mt-1">
              Used for driver delivery calls or store pickup readiness notification.
            </p>
          </div>
        </div>

        {form.fulfillmentType === 'delivery' && (
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5 uppercase tracking-wider">
              3. Delivery Address
            </label>
            <AddressForm form={form} onChange={patch} errors={errors} />
          </div>
        )}

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 uppercase tracking-wider">
            {form.fulfillmentType === 'delivery'
              ? '4. Payment Method'
              : '3. Payment Method'}
          </label>
          <PaymentMethodSelector
            value={form.paymentMethod}
            onChange={(v) => patch({ paymentMethod: v })}
            branch={branch}
          />
        </div>

        <OrderSummary subtotal={subtotalTzs} deliveryFee={deliveryFee} />

        {apiError && (
          <div className="text-red-700 bg-red-50 border border-red-200 text-sm p-3.5 rounded-xl font-medium">
            {apiError}
          </div>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="w-full bg-quickopia-amber hover:bg-amber-400 text-black font-extrabold py-4 px-4 rounded-xl shadow transition text-base disabled:opacity-50 flex items-center justify-center gap-2"
        >
          {submitting ? (
            <>
              <span className="inline-block w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
              <span>Validating &amp; Placing Order...</span>
            </>
          ) : (
            <span>
              Place Order &bull; TZS{' '}
              {(subtotalTzs + deliveryFee).toLocaleString('en-US')}
            </span>
          )}
        </button>
      </form>
    </main>
  );
}
