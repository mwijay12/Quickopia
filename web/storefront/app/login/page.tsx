'use client';

import { Suspense, useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';
import { getAuthenticatedUser } from '@/lib/auth';

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get('redirectTo') || '/checkout';

  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);

  useEffect(() => {
    getAuthenticatedUser().then((user) => {
      if (user) {
        router.replace(redirectTo);
      } else {
        setCheckingAuth(false);
      }
    });
  }, [redirectTo, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const supabase = createClient();

    try {
      if (mode === 'signin') {
        const { error: signInError } =
          await supabase.auth.signInWithPassword({
            email: email.trim(),
            password,
          });

        if (signInError) {
          throw new Error('Invalid email or password. Please try again.');
        }
      } else {
        if (!fullName.trim()) throw new Error('Full name is required.');
        if (password.length < 6) {
          throw new Error('Password must be at least 6 characters.');
        }

        const { data: signUpData, error: signUpError } =
          await supabase.auth.signUp({
            email: email.trim(),
            password,
            options: {
              data: {
                full_name: fullName.trim(),
                phone: phone.trim() || null,
              },
            },
          });

        if (signUpError) {
          throw new Error(signUpError.message);
        }

        if (signUpData.user) {
          // If session is created, update profile explicitly
          await supabase
            .from('profiles')
            .update({
              full_name: fullName.trim(),
              phone: phone.trim() || null,
            })
            .eq('id', signUpData.user.id);
        }
      }

      router.replace(redirectTo);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred.');
      setLoading(false);
    }
  };

  if (checkingAuth) {
    return (
      <main className="max-w-md mx-auto p-8 text-center py-28">
        <div className="inline-block w-8 h-8 border-4 border-quickopia-navy border-t-transparent rounded-full animate-spin mb-3" />
        <p className="text-xs text-gray-500 font-medium">
          Checking your session...
        </p>
      </main>
    );
  }

  return (
    <main className="max-w-md mx-auto px-4 py-12">
      <div className="text-center mb-8">
        <Link
          href="/"
          className="inline-block text-2xl font-black text-quickopia-navy tracking-tight"
        >
          Quick<span className="text-quickopia-amber">opia</span>
        </Link>
        <h1 className="text-xl font-bold text-gray-900 mt-3">
          {mode === 'signin' ? 'Sign in to your account' : 'Create an account'}
        </h1>
        <p className="text-xs text-gray-500 mt-1">
          {mode === 'signin'
            ? 'Sign in to complete your checkout and track orders'
            : 'Register to save your address and track orders'}
        </p>
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-5">
        <div className="flex bg-gray-100 p-1 rounded-xl">
          <button
            type="button"
            onClick={() => {
              setMode('signin');
              setError(null);
            }}
            className={`flex-1 py-2 text-xs font-bold rounded-lg transition ${
              mode === 'signin'
                ? 'bg-white text-quickopia-navy shadow-xs'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => {
              setMode('signup');
              setError(null);
            }}
            className={`flex-1 py-2 text-xs font-bold rounded-lg transition ${
              mode === 'signup'
                ? 'bg-white text-quickopia-navy shadow-xs'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Create Account
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === 'signup' && (
            <>
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="e.g. Maria Joseph"
                  className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Phone Number
                </label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="0712 345 678"
                  className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
                />
              </div>
            </>
          )}

          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Email Address
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Password
            </label>
            <input
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
            />
          </div>

          {error && (
            <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-xl font-medium border border-red-200">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-50 transition shadow-sm text-sm"
          >
            {loading
              ? 'Please wait...'
              : mode === 'signin'
              ? 'Sign In & Continue'
              : 'Create Account & Continue'}
          </button>
        </form>
      </div>

      <div className="text-center mt-6">
        <Link
          href="/"
          className="text-xs font-medium text-gray-500 hover:text-quickopia-navy transition"
        >
          &larr; Back to shopping
        </Link>
      </div>
    </main>
  );
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="py-24 text-center text-xs text-gray-500">
          Loading sign in...
        </div>
      }
    >
      <LoginForm />
    </Suspense>
  );
}
