export type SupermarketRole =
  | 'store_manager'
  | 'cashier'
  | 'packer'
  | 'fleet_lead'
  | 'auditor';

export interface RoleConfig {
  id: SupermarketRole;
  title: string;
  department: string;
  description: string;
  badgeColor: string;
  allowedRoutes: string[];
}

export const SUPERMARKET_ROLES: Record<SupermarketRole, RoleConfig> = {
  store_manager: {
    id: 'store_manager',
    title: 'Store Manager',
    department: 'Executive Management',
    description: 'Full supervisory authority over store catalog, staff, pricing, logistics, and settings.',
    badgeColor: 'bg-blue-100 text-blue-800 border-blue-200',
    allowedRoutes: [
      '/dashboard',
      '/dashboard/pos',
      '/dashboard/catalog',
      '/dashboard/drivers',
      '/dashboard/staff',
      '/dashboard/support',
      '/dashboard/broadcast',
      '/dashboard/analytics',
      '/dashboard/settings',
    ],
  },
  cashier: {
    id: 'cashier',
    title: 'POS Cashier',
    department: 'Sales & Front Counter',
    description: 'Point of sale counter operator, scanning items, receiving Lipa Namba / cash, and issuing receipts.',
    badgeColor: 'bg-emerald-100 text-emerald-800 border-emerald-200',
    allowedRoutes: [
      '/dashboard/pos',
      '/dashboard',
      '/dashboard/support',
    ],
  },
  packer: {
    id: 'packer',
    title: 'Packaging & Fulfillment Lead',
    department: 'Fulfillment & Warehouse',
    description: 'Gathers shelf goods, checks item freshness, packs grocery bags, and prepares click-and-collect orders.',
    badgeColor: 'bg-amber-100 text-amber-800 border-amber-200',
    allowedRoutes: [
      '/dashboard',
      '/dashboard/catalog',
    ],
  },
  fleet_lead: {
    id: 'fleet_lead',
    title: 'Head of Drivers & Fleet Lead',
    department: 'Logistics & Dispatch',
    description: 'Manages motorcycle maintenance, oil changes, tire wear, fuel allowances, driver rosters, and delivery dispatch.',
    badgeColor: 'bg-purple-100 text-purple-800 border-purple-200',
    allowedRoutes: [
      '/dashboard/drivers',
      '/dashboard',
      '/dashboard/support',
    ],
  },
  auditor: {
    id: 'auditor',
    title: 'Financial Auditor & Accountant',
    department: 'Finance & Compliance',
    description: 'Audits daily register balances, profit margins, delivery fuel vs revenue splits, and tax compliance.',
    badgeColor: 'bg-indigo-100 text-indigo-800 border-indigo-200',
    allowedRoutes: [
      '/dashboard/analytics',
      '/dashboard',
      '/dashboard/settings',
    ],
  },
};

export const STAFF_MEMBERS_SAMPLE = [
  {
    id: 'staff-01',
    full_name: 'Amina Mrope',
    role: 'store_manager' as SupermarketRole,
    phone: '+255 754 112 233',
    email: 'manager@quickopia.tz',
    status: 'on_duty',
    shift: 'Morning Shift (07:00 - 15:30)',
    assignedBranch: 'Dar es Salaam Central #01',
  },
  {
    id: 'staff-02',
    full_name: 'Juma Ramadhani',
    role: 'cashier' as SupermarketRole,
    phone: '+255 713 445 667',
    email: 'pos.counter1@quickopia.tz',
    status: 'on_duty',
    shift: 'Morning Shift (07:00 - 15:30)',
    assignedBranch: 'Register Counter #1',
  },
  {
    id: 'staff-03',
    full_name: 'Fatma Bakari',
    role: 'cashier' as SupermarketRole,
    phone: '+255 768 998 877',
    email: 'pos.counter2@quickopia.tz',
    status: 'on_break',
    shift: 'Evening Shift (14:00 - 22:30)',
    assignedBranch: 'Register Counter #2',
  },
  {
    id: 'staff-04',
    full_name: 'Hamisi Mwambungu',
    role: 'packer' as SupermarketRole,
    phone: '+255 782 334 455',
    email: 'packer.station1@quickopia.tz',
    status: 'on_duty',
    shift: 'Full Shift (08:00 - 17:00)',
    assignedBranch: 'Fulfillment Bay A',
  },
  {
    id: 'staff-05',
    full_name: 'Captain Baraka Temba',
    role: 'fleet_lead' as SupermarketRole,
    phone: '+255 759 778 899',
    email: 'fleet.lead@quickopia.tz',
    status: 'on_duty',
    shift: 'Logistics Supervisor (07:30 - 18:00)',
    assignedBranch: 'Motorcycle Fleet Hub',
  },
  {
    id: 'staff-06',
    full_name: 'Neema Kiwanga (CPA)',
    role: 'auditor' as SupermarketRole,
    phone: '+255 744 556 677',
    email: 'auditor@quickopia.tz',
    status: 'on_duty',
    shift: 'Financial Audit & Tax',
    assignedBranch: 'Finance Department',
  },
];
