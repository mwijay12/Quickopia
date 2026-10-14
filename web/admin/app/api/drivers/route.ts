import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Re-verifies the CALLER is a real logged-in admin, reading their session
 * from cookies server-side. This check is what actually protects this
 * endpoint — knowing the URL alone grants nothing without a valid admin session.
 */
async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  return profile?.role === 'admin' ? user : null;
}

export async function GET() {
  const admin = await requireAdmin();
  if (!admin) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, phone, is_active, created_at')
    .eq('role', 'driver')
    .order('created_at', { ascending: false });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json({ drivers: data });
}

export async function POST(request: NextRequest) {
  const admin = await requireAdmin();
  if (!admin) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
  }

  const { email, password, fullName, phone } = await request.json();

  if (!email || !password || !fullName || !phone) {
    return NextResponse.json(
      { error: 'Email, password, full name, and phone are all required.' },
      { status: 400 }
    );
  }
  if (password.length < 6) {
    return NextResponse.json(
      { error: 'Password must be at least 6 characters.' },
      { status: 400 }
    );
  }

  const adminClient = createAdminClient();

  // Step A: create the auth account via the Admin API.
  // email_confirm: true skips confirmation email since staff provisions this account.
  const { data: created, error: createError } =
    await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName, phone },
    });

  if (createError || !created.user) {
    const message = createError?.message
      ?.toLowerCase()
      .includes('already been registered')
      ? 'An account with this email already exists.'
      : 'Could not create the driver account. Please try again.';
    return NextResponse.json({ error: message }, { status: 400 });
  }

  // Step B: the handle_new_user() trigger created a profile row with role = 'customer'.
  // Promote it to 'driver' and set employment_type = 'in_house'.
  const { error: promoteError } = await adminClient
    .from('profiles')
    .update({ role: 'driver', employment_type: 'in_house' })
    .eq('id', created.user.id);

  if (promoteError) {
    return NextResponse.json(
      {
        error:
          'Account created but could not be set as a driver. Check the profiles table manually.',
      },
      { status: 500 }
    );
  }

  return NextResponse.json({ success: true, driverId: created.user.id });
}
