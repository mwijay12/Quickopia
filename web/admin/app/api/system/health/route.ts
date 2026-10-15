import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET() {
  const startTime = Date.now();
  try {
    const supabase = await createClient();

    // Check user session
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized: Admin authentication required' },
        { status: 401 }
      );
    }

    // Call heartbeat_status RPC in database
    const { data: heartbeat, error: rpcError } = await supabase.rpc(
      'heartbeat_status'
    );

    const latencyMs = Date.now() - startTime;

    if (rpcError) {
      return NextResponse.json(
        {
          status: 'ERROR',
          error: rpcError.message,
          latencyMs,
          timestamp: new Date().toISOString(),
        },
        { status: 500 }
      );
    }

    return NextResponse.json({
      status: 'OK',
      heartbeat,
      latencyMs,
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    const latencyMs = Date.now() - startTime;
    return NextResponse.json(
      {
        status: 'DOWN',
        error: err?.message || 'Failed to reach Supabase backend',
        latencyMs,
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    );
  }
}
