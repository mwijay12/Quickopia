import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

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

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const admin = await requireAdmin();
  if (!admin) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json();

  const updates: Record<string, unknown> = {};
  if (typeof body.isActive === 'boolean') {
    updates.is_active = body.isActive;
  }
  if (typeof body.fullName === 'string') {
    updates.full_name = body.fullName.trim();
  }
  if (typeof body.phone === 'string') {
    updates.phone = body.phone.trim();
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json(
      { error: 'No valid update fields provided' },
      { status: 400 }
    );
  }

  const supabase = await createClient();
  const { error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', id)
    .eq('role', 'driver');

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json({ success: true });
}

