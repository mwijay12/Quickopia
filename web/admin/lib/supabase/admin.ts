import { createClient as createSupabaseClient } from '@supabase/supabase-js';

/**
 * DANGER: this client uses the service_role key, which BYPASSES all Row
 * Level Security. It must ONLY ever be imported inside app/api/** route
 * handlers (server-side execution), NEVER inside any component, hook,
 * or file that could end up in client-side JavaScript.
 *
 * Do not import this file from anything under app/dashboard/ directly —
 * always go through the corresponding /api/* route instead.
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!serviceKey) {
    throw new Error(
      'SUPABASE_SERVICE_ROLE_KEY is not set. Check your .env.local file.'
    );
  }

  return createSupabaseClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
