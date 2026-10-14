'use client';

import { useState, useEffect } from 'react';
import {
  DEFAULT_DELIVERY_ZONES,
  DEFAULT_DELIVERY_SETTINGS,
  DeliveryZone,
  DeliverySettings,
} from '@/lib/delivery-zones';
import {
  MapPin,
  Bike,
  Fuel,
  Store,
  Clock,
  CheckCircle2,
  CloudRain,
  Edit2,
  Save,
  RotateCcw,
  Sparkles,
} from 'lucide-react';

const STORAGE_KEY_ZONES = 'quickopia_delivery_zones_config';
const STORAGE_KEY_SETTINGS = 'quickopia_delivery_settings_config';

export default function DeliveryZonesManager() {
  const [zones, setZones] = useState<DeliveryZone[]>(DEFAULT_DELIVERY_ZONES);
  const [settings, setSettings] = useState<DeliverySettings>(DEFAULT_DELIVERY_SETTINGS);
  const [editingZoneId, setEditingZoneId] = useState<string | null>(null);
  const [savedSuccess, setSavedSuccess] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const savedZ = localStorage.getItem(STORAGE_KEY_ZONES);
      const savedS = localStorage.getItem(STORAGE_KEY_SETTINGS);
      if (savedZ) {
        try {
          setZones(JSON.parse(savedZ));
        } catch (_) {}
      }
      if (savedS) {
        try {
          setSettings(JSON.parse(savedS));
        } catch (_) {}
      }
    }
  }, []);

  const saveConfig = (newZones: DeliveryZone[], newSettings: DeliverySettings) => {
    setZones(newZones);
    setSettings(newSettings);
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY_ZONES, JSON.stringify(newZones));
      localStorage.setItem(STORAGE_KEY_SETTINGS, JSON.stringify(newSettings));
    }
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  const handleZoneUpdate = (zoneId: string, field: keyof DeliveryZone, val: any) => {
    const updated = zones.map((z) => {
      if (z.id === zoneId) {
        return { ...z, [field]: val };
      }
      return z;
    });
    saveConfig(updated, settings);
  };

  const toggleRainSurcharge = () => {
    const updatedSettings = {
      ...settings,
      rainPeakTrafficSurchargeActive: !settings.rainPeakTrafficSurchargeActive,
    };
    saveConfig(zones, updatedSettings);
  };

  const handleResetDefaults = () => {
    if (confirm('Reset all delivery zones and fuel surcharges to default Dar es Salaam tariffs?')) {
      saveConfig(DEFAULT_DELIVERY_ZONES, DEFAULT_DELIVERY_SETTINGS);
      setEditingZoneId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-quickopia-navy flex items-center gap-2">
            <Fuel className="w-5 h-5 text-quickopia-amber" />
            <span>Delivery Zones &amp; Fuel Surcharge Tariffs</span>
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Differentiates Store Pickup (TZS 0 Free) from Doorstep Delivery zones across Dar es Salaam, ensuring riders receive fair fuel stipends.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {savedSuccess && (
            <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-3 py-1.5 rounded-xl border border-emerald-200 flex items-center gap-1.5 animate-in fade-in">
              <CheckCircle2 className="w-3.5 h-3.5" />
              Tariffs Updated
            </span>
          )}
          <button
            type="button"
            onClick={handleResetDefaults}
            className="text-xs font-bold text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-3 py-2 rounded-xl transition flex items-center gap-1.5"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            Reset Defaults
          </button>
        </div>
      </div>

      {/* Fulfillment Policy Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Store Pickup Policy */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Store Pickup (Click &amp; Collect)
            </span>
            <Store className="w-4 h-4 text-emerald-600" />
          </div>
          <div className="flex items-baseline gap-2">
            <p className="text-2xl font-black text-emerald-700">FREE</p>
            <span className="text-xs font-bold text-gray-400">TZS 0</span>
          </div>
          <p className="text-[11px] text-gray-500 leading-tight">
            Customer visits supermarket counter. Packaging crew packs groceries in advance (~20 mins prep time).
          </p>
        </div>

        {/* Free Delivery Threshold */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Free Delivery Threshold
            </span>
            <Bike className="w-4 h-4 text-quickopia-navy" />
          </div>
          <div className="flex items-baseline gap-2">
            <p className="text-2xl font-black text-quickopia-navy">
              TZS {settings.freeDeliveryThresholdTzs.toLocaleString()}
            </p>
          </div>
          <p className="text-[11px] text-gray-500 leading-tight">
            Orders above this subtotal qualify for complimentary doorstep delivery (supermarket subsidizes rider fee).
          </p>
        </div>

        {/* Rain / Traffic Surcharge Toggle */}
        <div
          onClick={toggleRainSurcharge}
          className={`p-4 rounded-2xl border transition cursor-pointer space-y-2 select-none ${
            settings.rainPeakTrafficSurchargeActive
              ? 'bg-blue-50/80 border-blue-300 shadow-xs'
              : 'bg-white border-gray-200 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-700 uppercase tracking-wider flex items-center gap-1.5">
              <CloudRain className={`w-4 h-4 ${settings.rainPeakTrafficSurchargeActive ? 'text-blue-600' : 'text-gray-400'}`} />
              Rain / Heavy Traffic Index
            </span>
            <div
              className={`w-10 h-5 rounded-full p-0.5 transition ${
                settings.rainPeakTrafficSurchargeActive
                  ? 'bg-blue-600'
                  : 'bg-gray-300'
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white transition-transform ${
                  settings.rainPeakTrafficSurchargeActive
                    ? 'translate-x-5'
                    : 'translate-x-0'
                }`}
              />
            </div>
          </div>
          <div className="flex items-baseline gap-2">
            <p className="text-xl font-black text-blue-950">
              {settings.rainPeakTrafficSurchargeActive ? '+ TZS 1,000 Active' : 'Off (Standard Rates)'}
            </p>
          </div>
          <p className="text-[11px] text-gray-500 leading-tight">
            Compensates riders for heavy rain showers or severe jam along Bagamoyo / Morogoro Rd.
          </p>
        </div>
      </div>

      {/* Delivery Zones Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden space-y-4 p-5">
        <h3 className="text-sm font-bold text-quickopia-navy uppercase tracking-wider">
          Configured Geographic Delivery Zones (Dar es Salaam)
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {zones.map((zone) => {
            const isEditing = editingZoneId === zone.id;
            const totalFee =
              zone.baseDeliveryFeeTzs +
              zone.fuelSurchargeTzs +
              (settings.rainPeakTrafficSurchargeActive ? settings.rainPeakTrafficSurchargeTzs : 0);
            const supermarketMargin = totalFee - zone.driverPayoutTzs;

            return (
              <div
                key={zone.id}
                className="p-4 rounded-2xl border border-gray-200 bg-gray-50/50 hover:bg-white hover:border-quickopia-amber transition space-y-3"
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h4 className="font-black text-sm text-quickopia-navy">
                      {zone.name}
                    </h4>
                    <p className="text-[11px] text-gray-500 mt-0.5">
                      {zone.description}
                    </p>
                  </div>
                  <span className="text-[10px] font-black px-2 py-0.5 rounded-full bg-quickopia-navy text-white font-mono">
                    {zone.code}
                  </span>
                </div>

                {/* Neighborhoods Tags */}
                <div className="flex flex-wrap gap-1">
                  {zone.popularNeighborhoods.map((nh) => (
                    <span
                      key={nh}
                      className="px-2 py-0.5 rounded-md bg-gray-200/80 text-[10px] font-semibold text-gray-700"
                    >
                      {nh}
                    </span>
                  ))}
                </div>

                {/* Rates Breakdown */}
                <div className="pt-2 border-t border-gray-200/80 space-y-2 text-xs">
                  <div className="grid grid-cols-2 gap-2 bg-white p-2.5 rounded-xl border border-gray-200/70">
                    <div>
                      <span className="text-gray-400 text-[10px] uppercase font-bold block">
                        Base Customer Fee
                      </span>
                      {isEditing ? (
                        <input
                          type="number"
                          value={zone.baseDeliveryFeeTzs}
                          onChange={(e) =>
                            handleZoneUpdate(zone.id, 'baseDeliveryFeeTzs', Number(e.target.value))
                          }
                          className="w-full px-2 py-1 bg-gray-50 border rounded text-xs font-bold"
                        />
                      ) : (
                        <span className="font-bold text-gray-900">
                          TZS {zone.baseDeliveryFeeTzs.toLocaleString()}
                        </span>
                      )}
                    </div>

                    <div>
                      <span className="text-gray-400 text-[10px] uppercase font-bold block">
                        Fuel Surcharge
                      </span>
                      {isEditing ? (
                        <input
                          type="number"
                          value={zone.fuelSurchargeTzs}
                          onChange={(e) =>
                            handleZoneUpdate(zone.id, 'fuelSurchargeTzs', Number(e.target.value))
                          }
                          className="w-full px-2 py-1 bg-gray-50 border rounded text-xs font-bold"
                        />
                      ) : (
                        <span className="font-bold text-amber-700">
                          + TZS {zone.fuelSurchargeTzs.toLocaleString()}
                        </span>
                      )}
                    </div>

                    <div className="pt-1.5 border-t border-gray-100">
                      <span className="text-gray-400 text-[10px] uppercase font-bold block">
                        Rider Payout Split
                      </span>
                      {isEditing ? (
                        <input
                          type="number"
                          value={zone.driverPayoutTzs}
                          onChange={(e) =>
                            handleZoneUpdate(zone.id, 'driverPayoutTzs', Number(e.target.value))
                          }
                          className="w-full px-2 py-1 bg-gray-50 border rounded text-xs font-bold"
                        />
                      ) : (
                        <span className="font-bold text-purple-800">
                          TZS {zone.driverPayoutTzs.toLocaleString()} (Driver)
                        </span>
                      )}
                    </div>

                    <div className="pt-1.5 border-t border-gray-100">
                      <span className="text-gray-400 text-[10px] uppercase font-bold block">
                        Transit Time
                      </span>
                      <span className="font-medium text-gray-600">
                        {zone.estimatedMinutes}
                      </span>
                    </div>
                  </div>

                  {/* Summary Bar */}
                  <div className="flex justify-between items-center bg-slate-100 p-2 rounded-xl text-xs">
                    <span className="text-gray-600 font-semibold">
                      Final Delivery Fee Charged:
                    </span>
                    <span className="font-black text-quickopia-navy text-sm">
                      TZS {totalFee.toLocaleString()}
                    </span>
                  </div>

                  <div className="flex justify-between items-center text-[11px] text-gray-500 px-1">
                    <span>
                      Store Commission: <strong>TZS {supermarketMargin.toLocaleString()}</strong>
                    </span>
                    <button
                      type="button"
                      onClick={() => setEditingZoneId(isEditing ? null : zone.id)}
                      className="text-quickopia-navy hover:text-quickopia-amber font-bold flex items-center gap-1"
                    >
                      {isEditing ? (
                        <>
                          <Save className="w-3 h-3 text-emerald-600" />
                          <span>Done</span>
                        </>
                      ) : (
                        <>
                          <Edit2 className="w-3 h-3" />
                          <span>Edit Rates</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
