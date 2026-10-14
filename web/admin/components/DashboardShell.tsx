import LogoutButton from './LogoutButton';
import { createClient } from '@/lib/supabase/server';
import QuickopiaLogo from './ui/QuickopiaLogo';
import SidebarNav from './SidebarNav';
import RolePersonaSwitcher from './RolePersonaSwitcher';
import { MapPin } from 'lucide-react';

export default async function DashboardShell({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const [{ data: profile }, { data: storeSettings }] = await Promise.all([
    user
      ? supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single()
      : Promise.resolve({ data: null }),
    supabase
      .from('settings')
      .select('supermarket_name, restaurant_name, city, branch_address')
      .eq('id', 'branch_settings')
      .maybeSingle(),
  ]);

  const supermarketName =
    storeSettings?.supermarket_name ||
    storeSettings?.restaurant_name ||
    'Shoppers Supermarket';
  const branchDisplay = storeSettings?.branch_address || 'Dar es Salaam #01';

  return (
    <div className="min-h-screen flex bg-gray-50">
      <aside className="w-64 bg-quickopia-navy text-white flex flex-col p-5 shadow-lg shrink-0">
        <div className="mb-4 px-2">
          <QuickopiaLogo variant="light" size="md" showSubtitle={true} />
        </div>

        {/* Dynamic Supermarket Badge */}
        <div className="mb-6 px-3 py-2 bg-white/10 rounded-xl border border-white/15">
          <div className="text-[10px] uppercase tracking-wider text-quickopia-amber font-extrabold">
            Active Storefront
          </div>
          <div className="text-xs font-bold text-white truncate mt-0.5">
            {supermarketName}
          </div>
        </div>

        <SidebarNav />

        <div className="pt-4 border-t border-white/10 text-xs text-white/50 px-2 flex items-center gap-1.5 truncate" title={branchDisplay}>
          <MapPin className="w-3.5 h-3.5 text-quickopia-amber shrink-0" />
          <span className="truncate">{branchDisplay}</span>
        </div>
      </aside>

      <div className="flex-1 flex flex-col min-w-0">
        <header className="bg-white border-b border-gray-200 px-6 md:px-8 py-3 flex justify-between items-center shadow-xs">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
              <span className="text-xs font-semibold text-gray-700">
                Staff Session:{' '}
                <strong className="text-quickopia-navy font-bold">
                  {profile?.full_name ?? 'Admin Staff'}
                </strong>
              </span>
            </div>
            <RolePersonaSwitcher />
          </div>
          <LogoutButton />
        </header>

        <main className="flex-1 p-6 md:p-8 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}
