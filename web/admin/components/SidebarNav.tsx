'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { SUPERMARKET_ROLES, SupermarketRole } from '@/lib/roles';
import { getActiveRole } from './RolePersonaSwitcher';
import {
  Package,
  CreditCard,
  ShoppingBag,
  Bike,
  Users,
  MessageSquare,
  Megaphone,
  BarChart3,
  Store,
} from 'lucide-react';

interface NavItem {
  href: string;
  label: string;
  icon: any;
  roleBadge?: string;
}

const ALL_NAV_ITEMS: NavItem[] = [
  { href: '/dashboard', label: 'Orders & Queue', icon: Package },
  { href: '/dashboard/pos', label: 'POS Terminal', icon: CreditCard, roleBadge: 'Counter' },
  { href: '/dashboard/catalog', label: 'Catalog & Shelves', icon: ShoppingBag },
  { href: '/dashboard/drivers', label: 'Drivers & Fleet', icon: Bike, roleBadge: 'Logistics' },
  { href: '/dashboard/staff', label: 'Staff & Roles', icon: Users, roleBadge: 'Ops' },
  { href: '/dashboard/support', label: 'Live Support Chat', icon: MessageSquare },
  { href: '/dashboard/broadcast', label: 'Broadcasts & SMS', icon: Megaphone },
  { href: '/dashboard/analytics', label: 'Audit & Analytics', icon: BarChart3, roleBadge: 'Finance' },
  { href: '/dashboard/settings', label: 'Store & Tariffs', icon: Store },
];

export default function SidebarNav() {
  const pathname = usePathname();
  const [activeRole, setActiveRole] = useState<SupermarketRole>('store_manager');

  useEffect(() => {
    setActiveRole(getActiveRole());

    const handleRoleChanged = (e: Event) => {
      const customEvent = e as CustomEvent<SupermarketRole>;
      if (customEvent.detail) {
        setActiveRole(customEvent.detail);
      }
    };

    window.addEventListener('quickopia_role_changed', handleRoleChanged);
    return () => {
      window.removeEventListener('quickopia_role_changed', handleRoleChanged);
    };
  }, []);

  const allowedRoutes = SUPERMARKET_ROLES[activeRole]?.allowedRoutes || [];
  const visibleNavItems = ALL_NAV_ITEMS.filter((item) =>
    allowedRoutes.includes(item.href)
  );

  return (
    <nav className="flex-1 space-y-1.5">
      {visibleNavItems.map((item) => {
        const IconComponent = item.icon;
        const isActive = pathname === item.href;

        return (
          <Link
            key={item.href}
            href={item.href}
            className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-semibold transition group ${
              isActive
                ? 'bg-white/15 text-white shadow-xs'
                : 'text-white/80 hover:bg-white/10 hover:text-white'
            }`}
          >
            <div className="flex items-center gap-3">
              <IconComponent
                className={`w-5 h-5 transition-transform ${
                  isActive
                    ? 'text-quickopia-amber scale-105'
                    : 'text-quickopia-amber/80 group-hover:scale-110 group-hover:text-quickopia-amber'
                }`}
              />
              <span>{item.label}</span>
            </div>

            {item.roleBadge && (
              <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-white/10 text-white/70">
                {item.roleBadge}
              </span>
            )}
          </Link>
        );
      })}
    </nav>
  );
}
