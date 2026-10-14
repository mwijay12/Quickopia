import SettingsTabs from '@/components/settings/SettingsTabs';

export const metadata = {
  title: 'Store Profile & Supermarket Settings | Admin',
};

export default function StoreSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black text-gray-900 tracking-tight">
          Supermarket Configuration &amp; Logistics
        </h1>
        <p className="text-xs text-gray-500 mt-1">
          Manage your supermarket branding, branch contact information, pickup policies, and Dar es Salaam delivery zone fuel tariffs.
        </p>
      </div>

      <SettingsTabs />
    </div>
  );
}
