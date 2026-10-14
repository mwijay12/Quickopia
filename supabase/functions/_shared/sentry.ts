// supabase/functions/_shared/sentry.ts
// Lightweight, zero-dependency Sentry error reporter for Supabase Edge Functions

export async function captureEdgeError(
  err: unknown,
  context: { functionName: string; extra?: Record<string, unknown> }
): Promise<void> {
  const dsn = Deno.env.get('SENTRY_DSN');
  if (!dsn || dsn.includes('placeholder')) {
    console.error(`[${context.functionName} error]:`, err);
    return;
  }

  try {
    const errorObj = err instanceof Error ? err : new Error(String(err));
    const urlObj = new URL(dsn);
    const key = urlObj.username;
    const projectId = urlObj.pathname.replace('/', '');
    const storeUrl = `https://${urlObj.host}/api/${projectId}/store/`;

    const payload = {
      event_id: crypto.randomUUID().replace(/-/g, ''),
      timestamp: new Date().toISOString(),
      platform: 'javascript',
      level: 'error',
      logger: 'edge_function',
      tags: {
        surface: 'edge_function',
        function_name: context.functionName,
      },
      exception: {
        values: [
          {
            type: errorObj.name,
            value: errorObj.message,
            stacktrace: { frames: [] },
          },
        ],
      },
      extra: context.extra ?? {},
    };

    await fetch(storeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sentry-Auth': `Sentry sentry_version=7, sentry_client=deno-edge/1.0, sentry_key=${key}`,
      },
      body: JSON.stringify(payload),
    });
  } catch (sentryErr) {
    console.error('Failed to report to Sentry:', sentryErr);
  }
}
