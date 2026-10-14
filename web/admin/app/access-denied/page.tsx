import LogoutButton from '@/components/LogoutButton';
import { ShieldAlert } from 'lucide-react';

export default function AccessDeniedPage() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="text-center max-w-sm bg-white p-8 rounded-2xl border border-gray-200 shadow-sm">
        <ShieldAlert className="w-14 h-14 text-rose-500 mx-auto mb-4" />
        <h1 className="text-xl font-extrabold text-quickopia-navy mb-2">
          Access Denied
        </h1>
        <p className="text-gray-600 text-sm mb-6 leading-relaxed">
          This account does not have administrator privileges to access the
          Quickopia staff portal. Customers and drivers should use the mobile
          app or public storefront.
        </p>
        <div className="pt-2 border-t border-gray-100">
          <LogoutButton />
        </div>
      </div>
    </main>
  );
}
