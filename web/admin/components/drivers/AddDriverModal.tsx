'use client';

import { useState } from 'react';
import { createDriver, DriverManagementError } from '@/lib/drivers';
import { Modal } from '../kanban/PackingChecklistModal';
import { Smartphone } from 'lucide-react';

export default function AddDriverModal({
  onClose,
  onDone,
}: {
  onClose: () => void;
  onDone: () => void;
}) {
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const normalizePhone = (p: string) => {
    const cleaned = p.replace(/\s/g, '');
    return cleaned.startsWith('0') ? `+255${cleaned.slice(1)}` : cleaned;
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !phone.trim() || !email.trim() || !password) {
      setError('All fields are required.');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await createDriver({
        email: email.trim(),
        password,
        fullName: fullName.trim(),
        phone: normalizePhone(phone.trim()),
      });
      onDone();
    } catch (e) {
      setError(
        e instanceof DriverManagementError
          ? e.message
          : 'Could not create driver account.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal title="Add Delivery Driver" onClose={onClose}>
      <form onSubmit={submit} className="space-y-3.5">
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Driver Full Name
          </label>
          <input
            type="text"
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder="e.g. Juma Bakari"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Driver Phone Number
          </label>
          <input
            type="tel"
            required
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="e.g. 0712 345 678"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
          <p className="text-[11px] text-gray-400 mt-1">
            Auto-formatted to Tanzanian +255 country code.
          </p>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Login Email Address
          </label>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="e.g. juma.driver@quickopia.co.tz"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Temporary Login Password
          </label>
          <input
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="At least 6 characters"
            className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          />
        </div>

        <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 text-[11px] text-amber-800 leading-relaxed">
          <p className="font-bold flex items-center gap-1.5">
            <Smartphone className="w-3.5 h-3.5 text-amber-700 inline" /> Driver App Login
          </p>
          <p>
            Share this email and password with the driver. When they log in
            via the Quickopia mobile app, they will automatically land on the
            Driver Delivery Dashboard.
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
          className="w-full mt-2 bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
        >
          {loading ? 'Creating driver account...' : 'Create Driver Account'}
        </button>
      </form>
    </Modal>
  );
}
