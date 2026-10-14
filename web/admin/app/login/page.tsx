'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { Zap, Lock } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (signInError) {
      setError(
        signInError.message.toLowerCase().includes('invalid')
          ? 'Incorrect email or password.'
          : 'Something went wrong. Please try again.'
      );
      setLoading(false);
      return;
    }

    // Middleware re-checks role on next request — router.refresh() ensures
    // server re-evaluates before we navigate.
    router.refresh();
    router.push('/dashboard');
  };

  return (
    <main className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <form
        onSubmit={handleSubmit}
        className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 w-full max-w-sm space-y-4"
      >
        <div className="text-center mb-6">
          <h1 className="text-2xl font-black text-quickopia-navy tracking-tight">
            Quick<span className="text-quickopia-amber">opia</span>
          </h1>
          <p className="text-xs font-bold text-gray-500 uppercase tracking-wider mt-1">
            Supermarket Staff Portal
          </p>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Staff Email
          </label>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@quickopia.co.tz"
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber transition"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Password
          </label>
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber transition"
          />
        </div>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 border border-red-200 p-2.5 rounded-lg font-medium">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-2.5 rounded-lg transition disabled:opacity-50 text-sm shadow-sm"
        >
          {loading ? 'Signing in...' : 'Sign In'}
        </button>

        <div className="pt-2">
          <button
            type="button"
            onClick={() => {
              setEmail('admin@quickopia.com');
              setPassword('Password123!');
            }}
            className="w-full bg-amber-50 hover:bg-amber-100 text-amber-900 border border-amber-300 font-bold py-2 rounded-lg transition text-xs flex items-center justify-center gap-2"
          >
            <Zap className="w-3.5 h-3.5 text-amber-600" />
            <span>Fill Demo Admin Credentials</span>
          </button>
        </div>

        <div className="bg-slate-50 border border-slate-200 rounded-xl p-3 text-[11px] text-slate-600 space-y-1">
          <div className="font-bold text-slate-800 flex items-center gap-1.5">
            <Lock className="w-3.5 h-3.5 text-slate-600" />
            <span>Verified Staff Credentials:</span>
          </div>
          <div>• <strong className="text-slate-700">Admin:</strong> <code className="bg-white px-1.5 py-0.5 rounded border border-slate-200 text-slate-900 font-mono">admin@quickopia.com</code> / <code className="bg-white px-1.5 py-0.5 rounded border border-slate-200 text-slate-900 font-mono">Password123!</code></div>
          <div>• <strong className="text-slate-700">Driver:</strong> <code className="bg-white px-1.5 py-0.5 rounded border border-slate-200 text-slate-900 font-mono">driver@quickopia.com</code> / <code className="bg-white px-1.5 py-0.5 rounded border border-slate-200 text-slate-900 font-mono">Password123!</code></div>
        </div>

        <p className="text-[11px] text-gray-400 text-center">
          Accounts are provisioned by supermarket management.
        </p>
      </form>
    </main>
  );
}
