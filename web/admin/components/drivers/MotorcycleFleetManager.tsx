'use client';

import { useState, useEffect } from 'react';
import {
  Bike,
  Wrench,
  Fuel,
  AlertTriangle,
  CheckCircle2,
  Calendar,
  ShieldCheck,
  Gauge,
  Plus,
  ArrowUpRight,
  Filter,
  Search,
} from 'lucide-react';

export interface MotorcycleAsset {
  id: string;
  plateNumber: string;
  makeModel: string;
  assignedDriver: string;
  driverPhone: string;
  currentOdoKm: number;
  lastOilChangeKm: number;
  nextOilChangeKm: number;
  brakeCondition: 'good' | 'inspect' | 'replace';
  tireCondition: 'good' | 'inspect' | 'replace';
  insuranceExpiry: string;
  latraPermitExpiry: string;
  weeklyFuelTzs: number;
  status: 'active' | 'in_service' | 'standby';
}

const DEFAULT_FLEET: MotorcycleAsset[] = [
  {
    id: 'bike-01',
    plateNumber: 'MC 421 DXB',
    makeModel: 'Bajaj Boxer BM 150',
    assignedDriver: 'Rashid Mohamed',
    driverPhone: '+255 712 111 222',
    currentOdoKm: 14750,
    lastOilChangeKm: 12500,
    nextOilChangeKm: 15000,
    brakeCondition: 'good',
    tireCondition: 'good',
    insuranceExpiry: '2026-11-30',
    latraPermitExpiry: '2026-12-15',
    weeklyFuelTzs: 45000,
    status: 'active',
  },
  {
    id: 'bike-02',
    plateNumber: 'MC 892 BKD',
    makeModel: 'TVS HLX 125 Plus',
    assignedDriver: 'Kelvin Shirima',
    driverPhone: '+255 754 333 444',
    currentOdoKm: 19800,
    lastOilChangeKm: 17000,
    nextOilChangeKm: 19500,
    brakeCondition: 'inspect',
    tireCondition: 'good',
    insuranceExpiry: '2026-10-15',
    latraPermitExpiry: '2026-10-20',
    weeklyFuelTzs: 48000,
    status: 'active',
  },
  {
    id: 'bike-03',
    plateNumber: 'MC 314 CTZ',
    makeModel: 'Honda Ace 125',
    assignedDriver: 'Said Ally',
    driverPhone: '+255 788 555 666',
    currentOdoKm: 22100,
    lastOilChangeKm: 21900,
    nextOilChangeKm: 24500,
    brakeCondition: 'replace',
    tireCondition: 'replace',
    insuranceExpiry: '2026-09-28',
    latraPermitExpiry: '2026-10-05',
    weeklyFuelTzs: 40000,
    status: 'in_service',
  },
  {
    id: 'bike-04',
    plateNumber: 'MC 701 EFG',
    makeModel: 'Bajaj Boxer BM 150 HD',
    assignedDriver: 'Emmanuel Mrema',
    driverPhone: '+255 765 777 888',
    currentOdoKm: 8900,
    lastOilChangeKm: 7500,
    nextOilChangeKm: 10000,
    brakeCondition: 'good',
    tireCondition: 'good',
    insuranceExpiry: '2027-02-28',
    latraPermitExpiry: '2027-03-10',
    weeklyFuelTzs: 42000,
    status: 'active',
  },
  {
    id: 'bike-05',
    plateNumber: 'MC 115 HJK',
    makeModel: 'Haojue Express 125',
    assignedDriver: 'Standby Fleet Pool',
    driverPhone: '+255 759 778 899',
    currentOdoKm: 5200,
    lastOilChangeKm: 5000,
    nextOilChangeKm: 7500,
    brakeCondition: 'good',
    tireCondition: 'good',
    insuranceExpiry: '2027-01-15',
    latraPermitExpiry: '2027-01-20',
    weeklyFuelTzs: 15000,
    status: 'standby',
  },
];

const STORAGE_KEY = 'quickopia_fleet_maintenance_roster';

export default function MotorcycleFleetManager() {
  const [fleet, setFleet] = useState<MotorcycleAsset[]>(DEFAULT_FLEET);
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [selectedBike, setSelectedBike] = useState<MotorcycleAsset | null>(null);
  const [isServiceModalOpen, setIsServiceModalOpen] = useState(false);

  // Modal inputs
  const [serviceOdo, setServiceOdo] = useState<number>(0);
  const [serviceCost, setServiceCost] = useState<number>(35000);
  const [serviceType, setServiceType] = useState<'oil_change' | 'brakes_tires' | 'full_service'>('oil_change');
  const [serviceNotes, setServiceNotes] = useState('');

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        try {
          setFleet(JSON.parse(saved));
        } catch (_) {}
      }
    }
  }, []);

  const saveFleet = (updated: MotorcycleAsset[]) => {
    setFleet(updated);
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    }
  };

  const openServiceModal = (bike: MotorcycleAsset) => {
    setSelectedBike(bike);
    setServiceOdo(bike.currentOdoKm + 50);
    setIsServiceModalOpen(true);
  };

  const handleRecordService = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedBike) return;

    const updated = fleet.map((b) => {
      if (b.id === selectedBike.id) {
        return {
          ...b,
          currentOdoKm: serviceOdo,
          lastOilChangeKm: serviceType === 'oil_change' || serviceType === 'full_service' ? serviceOdo : b.lastOilChangeKm,
          nextOilChangeKm: serviceType === 'oil_change' || serviceType === 'full_service' ? serviceOdo + 2500 : b.nextOilChangeKm,
          brakeCondition: serviceType === 'brakes_tires' || serviceType === 'full_service' ? ('good' as const) : b.brakeCondition,
          tireCondition: serviceType === 'brakes_tires' || serviceType === 'full_service' ? ('good' as const) : b.tireCondition,
          status: 'active' as const,
        };
      }
      return b;
    });

    saveFleet(updated);
    setIsServiceModalOpen(false);
    setSelectedBike(null);
  };

  const filteredFleet = fleet.filter((b) => {
    const matchStatus = filterStatus === 'all' || b.status === filterStatus;
    const matchSearch =
      b.plateNumber.toLowerCase().includes(search.toLowerCase()) ||
      b.assignedDriver.toLowerCase().includes(search.toLowerCase()) ||
      b.makeModel.toLowerCase().includes(search.toLowerCase());
    return matchStatus && matchSearch;
  });

  const totalFuelWeekly = fleet.reduce((acc, b) => acc + b.weeklyFuelTzs, 0);
  const overdueCount = fleet.filter(
    (b) => b.currentOdoKm >= b.nextOilChangeKm || b.brakeCondition === 'replace'
  ).length;

  return (
    <div className="space-y-6">
      {/* KPI Cards for Head of Drivers */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Total Delivery Fleet
            </span>
            <Bike className="w-4 h-4 text-quickopia-navy" />
          </div>
          <p className="text-2xl font-black text-quickopia-navy">{fleet.length} Motorcycles</p>
          <p className="text-[11px] text-gray-500">Express delivery units</p>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Road-Ready &amp; Active
            </span>
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
          </div>
          <p className="text-2xl font-black text-emerald-700">
            {fleet.filter((b) => b.status === 'active').length}
          </p>
          <p className="text-[11px] text-emerald-600 font-medium">Currently on delivery routes</p>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Service / Garage Alerts
            </span>
            <AlertTriangle className="w-4 h-4 text-amber-500" />
          </div>
          <p className="text-2xl font-black text-amber-600">{overdueCount}</p>
          <p className="text-[11px] text-amber-700 font-medium">Oil change or brakes due</p>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Weekly Fuel Allocation
            </span>
            <Fuel className="w-4 h-4 text-blue-600" />
          </div>
          <p className="text-xl font-black text-blue-950">
            TZS {totalFuelWeekly.toLocaleString()}
          </p>
          <p className="text-[11px] text-blue-600 font-medium">Disbursed per weekly shift</p>
        </div>
      </div>

      {/* Filter and Search */}
      <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs flex flex-col sm:flex-row gap-3 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search plate (MC...), driver, or model..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-medium focus:outline-none focus:ring-2 focus:ring-quickopia-amber focus:bg-white transition"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Filter className="w-3.5 h-3.5 text-gray-400 shrink-0" />
          <span className="text-xs font-bold text-gray-500 shrink-0">Status:</span>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-semibold focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
          >
            <option value="all">All Vehicles ({fleet.length})</option>
            <option value="active">Active On Road</option>
            <option value="in_service">In Maintenance Garage</option>
            <option value="standby">Standby Pool</option>
          </select>
        </div>
      </div>

      {/* Fleet Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
              <tr>
                <th className="p-3.5">Motorcycle / Plate</th>
                <th className="p-3.5">Assigned Rider</th>
                <th className="p-3.5">Mileage &amp; Oil Service</th>
                <th className="p-3.5">Brakes &amp; Tires</th>
                <th className="p-3.5">LATRA &amp; Insurance</th>
                <th className="p-3.5">Fuel Budget</th>
                <th className="p-3.5 text-right">Service Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredFleet.map((bike) => {
                const kmUntilOil = bike.nextOilChangeKm - bike.currentOdoKm;
                const isOilOverdue = kmUntilOil <= 0;
                const isOilWarning = kmUntilOil > 0 && kmUntilOil <= 300;

                return (
                  <tr key={bike.id} className="hover:bg-gray-50/60 transition">
                    <td className="p-3.5">
                      <div className="flex items-center gap-2">
                        <div className="p-2 bg-slate-100 rounded-lg text-quickopia-navy shrink-0">
                          <Bike className="w-4 h-4" />
                        </div>
                        <div>
                          <p className="font-black text-gray-900 text-sm font-mono">
                            {bike.plateNumber}
                          </p>
                          <p className="text-[11px] text-gray-500">{bike.makeModel}</p>
                        </div>
                      </div>
                    </td>

                    <td className="p-3.5">
                      <p className="font-bold text-gray-900">{bike.assignedDriver}</p>
                      <p className="text-[11px] text-gray-400">{bike.driverPhone}</p>
                    </td>

                    <td className="p-3.5">
                      <div className="space-y-1">
                        <div className="flex items-center justify-between text-[11px]">
                          <span className="text-gray-500">
                            {bike.currentOdoKm.toLocaleString()} km
                          </span>
                          <span
                            className={`font-bold ${
                              isOilOverdue
                                ? 'text-red-600'
                                : isOilWarning
                                ? 'text-amber-600'
                                : 'text-emerald-700'
                            }`}
                          >
                            {isOilOverdue
                              ? `Overdue by ${Math.abs(kmUntilOil)} km`
                              : `Due in ${kmUntilOil.toLocaleString()} km`}
                          </span>
                        </div>
                        <div className="w-32 bg-gray-200 h-1.5 rounded-full overflow-hidden">
                          <div
                            className={`h-full ${
                              isOilOverdue
                                ? 'bg-red-500 w-full'
                                : isOilWarning
                                ? 'bg-amber-500 w-4/5'
                                : 'bg-emerald-500 w-1/2'
                            }`}
                          />
                        </div>
                      </div>
                    </td>

                    <td className="p-3.5">
                      <div className="space-y-1">
                        <div className="flex items-center gap-1 text-[11px]">
                          <span className="text-gray-400">Brakes:</span>
                          <span
                            className={`font-bold ${
                              bike.brakeCondition === 'replace'
                                ? 'text-red-600'
                                : bike.brakeCondition === 'inspect'
                                ? 'text-amber-600'
                                : 'text-emerald-700'
                            }`}
                          >
                            {bike.brakeCondition.toUpperCase()}
                          </span>
                        </div>
                        <div className="flex items-center gap-1 text-[11px]">
                          <span className="text-gray-400">Tires:</span>
                          <span
                            className={`font-bold ${
                              bike.tireCondition === 'replace'
                                ? 'text-red-600'
                                : bike.tireCondition === 'inspect'
                                ? 'text-amber-600'
                                : 'text-emerald-700'
                            }`}
                          >
                            {bike.tireCondition.toUpperCase()}
                          </span>
                        </div>
                      </div>
                    </td>

                    <td className="p-3.5 text-[11px] text-gray-600">
                      <p>
                        <strong className="text-gray-800">LATRA:</strong>{' '}
                        {bike.latraPermitExpiry}
                      </p>
                      <p>
                        <strong className="text-gray-800">Insurance:</strong>{' '}
                        {bike.insuranceExpiry}
                      </p>
                    </td>

                    <td className="p-3.5 font-bold text-quickopia-navy">
                      TZS {bike.weeklyFuelTzs.toLocaleString()} / wk
                    </td>

                    <td className="p-3.5 text-right">
                      <button
                        type="button"
                        onClick={() => openServiceModal(bike)}
                        className="bg-slate-100 hover:bg-quickopia-navy hover:text-white text-quickopia-navy font-bold px-3 py-1.5 rounded-xl transition text-xs flex items-center gap-1 ml-auto shadow-2xs"
                      >
                        <Wrench className="w-3.5 h-3.5 text-quickopia-amber" />
                        <span>Log Service</span>
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Log Service Modal */}
      {isServiceModalOpen && selectedBike && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4 backdrop-blur-xs">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-2xl border border-gray-200 space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex justify-between items-center pb-2 border-b border-gray-100">
              <h3 className="font-bold text-base text-quickopia-navy flex items-center gap-2">
                <Wrench className="w-5 h-5 text-quickopia-amber" />
                <span>Log Maintenance &bull; {selectedBike.plateNumber}</span>
              </h3>
              <button
                type="button"
                onClick={() => setIsServiceModalOpen(false)}
                className="w-7 h-7 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 font-bold flex items-center justify-center text-xs"
              >
                &times;
              </button>
            </div>

            <form onSubmit={handleRecordService} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-gray-700 mb-1">
                  Service Category
                </label>
                <select
                  value={serviceType}
                  onChange={(e) => setServiceType(e.target.value as any)}
                  className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                >
                  <option value="oil_change">Engine Oil Change (2,500 km Interval)</option>
                  <option value="brakes_tires">Brake Pads &amp; Tires Renewal</option>
                  <option value="full_service">Full Mechanical Overhaul &amp; Inspection</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-gray-700 mb-1">
                    Current Odometer (km)
                  </label>
                  <input
                    type="number"
                    value={serviceOdo}
                    onChange={(e) => setServiceOdo(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl font-mono focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                  />
                </div>
                <div>
                  <label className="block font-bold text-gray-700 mb-1">
                    Garage Cost (TZS)
                  </label>
                  <input
                    type="number"
                    value={serviceCost}
                    onChange={(e) => setServiceCost(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl font-bold focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-gray-700 mb-1">
                  Technician / Workshop Notes
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. Changed 20W-50 oil, tightened chain, adjusted rear drum brakes."
                  value={serviceNotes}
                  onChange={(e) => setServiceNotes(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                />
              </div>

              <div className="p-2.5 bg-blue-50 border border-blue-200 rounded-xl text-[11px] text-blue-900 leading-relaxed">
                <strong>Notice:</strong> Submitting will reset the oil service counter and increment the motorcycle to next service due at{' '}
                <strong>{(serviceOdo + 2500).toLocaleString()} km</strong>.
              </div>

              <div className="pt-2 flex gap-2">
                <button
                  type="button"
                  onClick={() => setIsServiceModalOpen(false)}
                  className="flex-1 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-xl transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-quickopia-navy hover:bg-slate-900 text-white font-bold rounded-xl transition shadow-xs"
                >
                  Confirm &amp; Update Fleet
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
