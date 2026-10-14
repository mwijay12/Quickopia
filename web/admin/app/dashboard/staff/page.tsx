'use client';

import { useState, useEffect } from 'react';
import {
  SUPERMARKET_ROLES,
  SupermarketRole,
  STAFF_MEMBERS_SAMPLE,
} from '@/lib/roles';
import {
  Users,
  UserPlus,
  ShieldCheck,
  CreditCard,
  PackageCheck,
  Bike,
  Calculator,
  Phone,
  Mail,
  Clock,
  CheckCircle2,
  AlertCircle,
  Building2,
  Search,
  Filter,
} from 'lucide-react';

const ROLE_ICONS: Record<SupermarketRole, any> = {
  store_manager: ShieldCheck,
  cashier: CreditCard,
  packer: PackageCheck,
  fleet_lead: Bike,
  auditor: Calculator,
};

const STORAGE_KEY = 'quickopia_staff_members_roster';

export default function StaffManagementPage() {
  const [staffList, setStaffList] = useState(STAFF_MEMBERS_SAMPLE);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // Form State for new staff
  const [newFullName, setNewFullName] = useState('');
  const [newRole, setNewRole] = useState<SupermarketRole>('cashier');
  const [newPhone, setNewPhone] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [newShift, setNewShift] = useState('Morning Shift (07:00 - 15:30)');
  const [newStation, setNewStation] = useState('Register Counter #3');

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        try {
          setStaffList(JSON.parse(saved));
        } catch (_) {}
      }
    }
  }, []);

  const saveStaffList = (updated: typeof staffList) => {
    setStaffList(updated);
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    }
  };

  const handleAddStaff = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFullName.trim() || !newPhone.trim()) {
      alert('Please provide staff name and phone number.');
      return;
    }

    const newMember = {
      id: `staff-${Date.now().toString().slice(-4)}`,
      full_name: newFullName.trim(),
      role: newRole,
      phone: newPhone.trim(),
      email: newEmail.trim() || `${newFullName.toLowerCase().replace(/\s+/g, '.')}@quickopia.tz`,
      status: 'on_duty',
      shift: newShift,
      assignedBranch: newStation,
    };

    const updated = [newMember, ...staffList];
    saveStaffList(updated);
    setIsAddModalOpen(false);

    // Reset Form
    setNewFullName('');
    setNewPhone('');
    setNewEmail('');
  };

  const handleToggleStatus = (id: string) => {
    const updated = staffList.map((m) => {
      if (m.id === id) {
        const nextStatus =
          m.status === 'on_duty'
            ? 'on_break'
            : m.status === 'on_break'
            ? 'off_duty'
            : 'on_duty';
        return { ...m, status: nextStatus };
      }
      return m;
    });
    saveStaffList(updated);
  };

  // Filtered List
  const filteredStaff = staffList.filter((s) => {
    const matchRole = roleFilter === 'all' || s.role === roleFilter;
    const matchQuery =
      s.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.phone.includes(searchQuery) ||
      s.assignedBranch.toLowerCase().includes(searchQuery.toLowerCase());
    return matchRole && matchQuery;
  });

  const onDutyCount = staffList.filter((s) => s.status === 'on_duty').length;
  const onBreakCount = staffList.filter((s) => s.status === 'on_break').length;

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-black text-quickopia-navy flex items-center gap-2">
            Supermarket Staff &amp; Role Hierarchy
          </h1>
          <p className="text-xs text-gray-500 mt-1">
            Enterprise division of responsibilities: Cashiers, Packaging Crew, Fleet Lead &amp; Financial Auditor
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsAddModalOpen(true)}
          className="bg-quickopia-navy hover:bg-slate-900 text-white font-bold px-4 py-2.5 rounded-xl transition text-xs flex items-center gap-2 shadow-xs"
        >
          <UserPlus className="w-4 h-4 text-quickopia-amber" />
          <span>Register Staff Member</span>
        </button>
      </div>

      {/* KPI Overview Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Total Roster
            </span>
            <Users className="w-4 h-4 text-quickopia-navy" />
          </div>
          <p className="text-2xl font-black text-quickopia-navy">{staffList.length}</p>
          <p className="text-[11px] text-gray-500">Across 5 departments</p>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Active On Shift
            </span>
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          </div>
          <p className="text-2xl font-black text-emerald-700">{onDutyCount}</p>
          <p className="text-[11px] text-emerald-600 font-medium">Currently on supermarket floor</p>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              On Scheduled Break
            </span>
            <Clock className="w-4 h-4 text-amber-500" />
          </div>
          <p className="text-2xl font-black text-amber-700">{onBreakCount}</p>
          <p className="text-[11px] text-amber-600 font-medium">Rotating meal / rest interval</p>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Head of Logistics
            </span>
            <Bike className="w-4 h-4 text-purple-600" />
          </div>
          <p className="text-sm font-black text-purple-900 mt-1 truncate">
            Capt. Baraka Temba
          </p>
          <p className="text-[11px] text-purple-700 font-medium">Fleet Lead on Duty</p>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs flex flex-col sm:flex-row gap-3 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search by name, phone, or station..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-medium focus:outline-none focus:ring-2 focus:ring-quickopia-amber focus:bg-white transition"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto">
          <Filter className="w-3.5 h-3.5 text-gray-400 shrink-0" />
          <span className="text-xs font-bold text-gray-500 shrink-0">Role:</span>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-semibold focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
          >
            <option value="all">All Roles ({staffList.length})</option>
            <option value="store_manager">Store Manager</option>
            <option value="cashier">POS Cashier</option>
            <option value="packer">Packaging Crew</option>
            <option value="fleet_lead">Fleet Lead</option>
            <option value="auditor">Financial Auditor</option>
          </select>
        </div>
      </div>

      {/* Staff Roster Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
              <tr>
                <th className="p-3.5">Staff Member</th>
                <th className="p-3.5">Role &amp; Department</th>
                <th className="p-3.5">Assigned Station</th>
                <th className="p-3.5">Shift Hours</th>
                <th className="p-3.5">Shift Status</th>
                <th className="p-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredStaff.map((staff) => {
                const roleConfig = SUPERMARKET_ROLES[staff.role];
                const RoleIcon = ROLE_ICONS[staff.role];

                return (
                  <tr key={staff.id} className="hover:bg-gray-50/60 transition">
                    <td className="p-3.5">
                      <div className="font-bold text-gray-900 text-sm">
                        {staff.full_name}
                      </div>
                      <div className="flex items-center gap-3 text-gray-500 text-[11px] mt-0.5">
                        <span className="flex items-center gap-1">
                          <Phone className="w-3 h-3 text-gray-400" />
                          {staff.phone}
                        </span>
                        <span className="flex items-center gap-1">
                          <Mail className="w-3 h-3 text-gray-400" />
                          {staff.email}
                        </span>
                      </div>
                    </td>

                    <td className="p-3.5">
                      <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border text-xs font-bold bg-gray-50 border-gray-200 text-quickopia-navy">
                        <RoleIcon className="w-3.5 h-3.5 text-quickopia-amber" />
                        <span>{roleConfig?.title ?? staff.role}</span>
                      </div>
                      <p className="text-[11px] text-gray-400 mt-0.5">
                        {roleConfig?.department}
                      </p>
                    </td>

                    <td className="p-3.5">
                      <div className="flex items-center gap-1.5 font-semibold text-gray-800">
                        <Building2 className="w-3.5 h-3.5 text-gray-400" />
                        <span>{staff.assignedBranch}</span>
                      </div>
                    </td>

                    <td className="p-3.5 text-gray-600 font-medium">
                      {staff.shift}
                    </td>

                    <td className="p-3.5">
                      <button
                        type="button"
                        onClick={() => handleToggleStatus(staff.id)}
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold transition ${
                          staff.status === 'on_duty'
                            ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                            : staff.status === 'on_break'
                            ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                        }`}
                        title="Click to toggle shift status"
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            staff.status === 'on_duty'
                              ? 'bg-emerald-600'
                              : staff.status === 'on_break'
                              ? 'bg-amber-600'
                              : 'bg-gray-400'
                          }`}
                        />
                        <span className="capitalize">{staff.status.replace('_', ' ')}</span>
                      </button>
                    </td>

                    <td className="p-3.5 text-right">
                      <button
                        type="button"
                        onClick={() => handleToggleStatus(staff.id)}
                        className="text-quickopia-navy hover:text-quickopia-amber font-bold text-xs transition"
                      >
                        Cycle Status
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          {filteredStaff.length === 0 && (
            <div className="py-12 text-center text-gray-400 text-xs">
              No staff members found matching your search or filter.
            </div>
          )}
        </div>
      </div>

      {/* Add Staff Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4 backdrop-blur-xs">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-2xl border border-gray-200 space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex justify-between items-center pb-2 border-b border-gray-100">
              <h3 className="font-bold text-base text-quickopia-navy flex items-center gap-2">
                <UserPlus className="w-5 h-5 text-quickopia-amber" />
                <span>Register Supermarket Staff</span>
              </h3>
              <button
                type="button"
                onClick={() => setIsAddModalOpen(false)}
                className="w-7 h-7 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 font-bold flex items-center justify-center text-xs"
              >
                &times;
              </button>
            </div>

            <form onSubmit={handleAddStaff} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-gray-700 mb-1">
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Grace Mwalimu"
                  value={newFullName}
                  onChange={(e) => setNewFullName(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-gray-700 mb-1">
                    Phone Number
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="+255 7XX XXX XXX"
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                  />
                </div>
                <div>
                  <label className="block font-bold text-gray-700 mb-1">
                    Role &amp; Responsibilities
                  </label>
                  <select
                    value={newRole}
                    onChange={(e) => setNewRole(e.target.value as SupermarketRole)}
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                  >
                    <option value="cashier">POS Cashier</option>
                    <option value="packer">Packaging Crew</option>
                    <option value="fleet_lead">Fleet Lead (Head of Drivers)</option>
                    <option value="auditor">Financial Auditor</option>
                    <option value="store_manager">Store Manager</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block font-bold text-gray-700 mb-1">
                  Assigned Station / Bay / Counter
                </label>
                <input
                  type="text"
                  placeholder="e.g. Register Counter #2 or Fulfillment Bay B"
                  value={newStation}
                  onChange={(e) => setNewStation(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                />
              </div>

              <div>
                <label className="block font-bold text-gray-700 mb-1">
                  Shift Schedule
                </label>
                <select
                  value={newShift}
                  onChange={(e) => setNewShift(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                >
                  <option value="Morning Shift (07:00 - 15:30)">
                    Morning Shift (07:00 - 15:30)
                  </option>
                  <option value="Evening Shift (14:00 - 22:30)">
                    Evening Shift (14:00 - 22:30)
                  </option>
                  <option value="Full Day Shift (08:00 - 18:00)">
                    Full Day Shift (08:00 - 18:00)
                  </option>
                  <option value="Night Restock Shift (22:00 - 06:00)">
                    Night Restock Shift (22:00 - 06:00)
                  </option>
                </select>
              </div>

              <div className="pt-2 flex gap-2">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="flex-1 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-xl transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-quickopia-navy hover:bg-slate-900 text-white font-bold rounded-xl transition shadow-xs"
                >
                  Save &amp; Activate
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
