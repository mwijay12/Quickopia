'use client';

import { useState, useEffect } from 'react';
import { SUPERMARKET_ROLES, SupermarketRole } from '@/lib/roles';
import {
  ShieldCheck,
  CreditCard,
  PackageCheck,
  Bike,
  Calculator,
  ChevronDown,
  UserCheck,
} from 'lucide-react';

const ROLE_ICONS: Record<SupermarketRole, any> = {
  store_manager: ShieldCheck,
  cashier: CreditCard,
  packer: PackageCheck,
  fleet_lead: Bike,
  auditor: Calculator,
};

const STORAGE_KEY = 'quickopia_active_role_persona';

export function getActiveRole(): SupermarketRole {
  if (typeof window === 'undefined') return 'store_manager';
  const saved = localStorage.getItem(STORAGE_KEY) as SupermarketRole | null;
  if (saved && SUPERMARKET_ROLES[saved]) {
    return saved;
  }
  return 'store_manager';
}

export function setActiveRole(role: SupermarketRole) {
  if (typeof window !== 'undefined') {
    localStorage.setItem(STORAGE_KEY, role);
    window.dispatchEvent(new CustomEvent('quickopia_role_changed', { detail: role }));
  }
}

export default function RolePersonaSwitcher() {
  const [currentRole, setCurrentRole] = useState<SupermarketRole>('store_manager');
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    setCurrentRole(getActiveRole());

    const handleRoleChanged = (e: Event) => {
      const customEvent = e as CustomEvent<SupermarketRole>;
      if (customEvent.detail) {
        setCurrentRole(customEvent.detail);
      }
    };

    window.addEventListener('quickopia_role_changed', handleRoleChanged);
    return () => {
      window.removeEventListener('quickopia_role_changed', handleRoleChanged);
    };
  }, []);

  const handleSelectRole = (role: SupermarketRole) => {
    setCurrentRole(role);
    setActiveRole(role);
    setIsOpen(false);
  };

  const roleConfig = SUPERMARKET_ROLES[currentRole];
  const IconComponent = ROLE_ICONS[currentRole];

  return (
    <div className="relative inline-block text-left">
      <div className="flex items-center gap-2 bg-slate-100 hover:bg-slate-200/80 p-1.5 rounded-xl border border-slate-200 transition">
        <span className="text-[11px] uppercase tracking-wider font-extrabold text-slate-500 pl-2 hidden sm:inline">
          Live Persona:
        </span>
        <button
          type="button"
          onClick={() => setIsOpen(!isOpen)}
          className="flex items-center gap-2 bg-white px-3 py-1.5 rounded-lg shadow-xs border border-slate-200 hover:border-quickopia-amber transition text-xs font-bold text-quickopia-navy"
        >
          <IconComponent className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>{roleConfig.title}</span>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </button>
      </div>

      {isOpen && (
        <>
          <div
            className="fixed inset-0 z-40"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute right-0 mt-2 w-80 bg-white rounded-2xl shadow-xl border border-slate-200 p-2 z-50 animate-in fade-in zoom-in-95 duration-100">
            <div className="px-3 py-2 border-b border-slate-100 mb-1">
              <p className="text-[11px] uppercase tracking-wider font-extrabold text-slate-400">
                Switch Operational Persona
              </p>
              <p className="text-xs text-slate-500 mt-0.5">
                Demonstrates role-based views for supermarket stakeholders &amp; team leads.
              </p>
            </div>

            <div className="space-y-1">
              {(Object.keys(SUPERMARKET_ROLES) as SupermarketRole[]).map((rKey) => {
                const config = SUPERMARKET_ROLES[rKey];
                const ItemIcon = ROLE_ICONS[rKey];
                const isSelected = currentRole === rKey;

                return (
                  <button
                    key={rKey}
                    type="button"
                    onClick={() => handleSelectRole(rKey)}
                    className={`w-full text-left p-2.5 rounded-xl transition flex items-start gap-3 ${
                      isSelected
                        ? 'bg-quickopia-navy text-white shadow-sm'
                        : 'hover:bg-slate-50 text-slate-800'
                    }`}
                  >
                    <div
                      className={`p-2 rounded-lg shrink-0 mt-0.5 ${
                        isSelected
                          ? 'bg-white/10 text-quickopia-amber'
                          : 'bg-slate-100 text-slate-700'
                      }`}
                    >
                      <ItemIcon className="w-4 h-4" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <p className="text-xs font-bold truncate">{config.title}</p>
                        {isSelected && (
                          <UserCheck className="w-3.5 h-3.5 text-quickopia-amber shrink-0" />
                        )}
                      </div>
                      <p
                        className={`text-[11px] truncate mt-0.5 ${
                          isSelected ? 'text-slate-300' : 'text-slate-500'
                        }`}
                      >
                        {config.department}
                      </p>
                    </div>
                  </button>
                );
              })}
            </div>

            <div className="mt-2 p-2 bg-slate-50 rounded-xl border border-slate-200/60 text-[11px] text-slate-600">
              <span className="font-semibold text-slate-800">Current Scope: </span>
              {roleConfig.description}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
