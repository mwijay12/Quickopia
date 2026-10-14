import BroadcastComposer from '@/components/notifications/BroadcastComposer';

export const metadata = {
  title: 'Broadcasts & Push Alerts | Admin',
};

export default function BroadcastsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black text-gray-900 tracking-tight">
          Broadcast Notifications &amp; Reminders
        </h1>
        <p className="text-xs text-gray-500 mt-1">
          Broadcast live promotional offers, discounts, and useful reminders to your customers and couriers. Messages trigger instant heads-up banners (&quot;ziwe juu&quot;) and lock-screen alerts on mobile devices.
        </p>
      </div>

      <BroadcastComposer />
    </div>
  );
}
