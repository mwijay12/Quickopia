import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN;

if (SENTRY_DSN && !SENTRY_DSN.includes('placeholder')) {
  Sentry.init({
    dsn: SENTRY_DSN,
    tracesSampleRate: 0.1,
    environment: process.env.NODE_ENV,
    sendDefaultPii: false,
    initialScope: {
      tags: { surface: 'storefront' },
    },
    beforeSend(event) {
      // Noise filter: ignore client aborted fetches & handled offline network blips
      const message = event.message?.toLowerCase() ?? '';
      if (message.includes('abort') || message.includes('cancelled')) {
        return null;
      }
      return event;
    },
  });
}
