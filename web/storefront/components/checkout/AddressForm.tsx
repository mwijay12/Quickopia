'use client';

import { useState } from 'react';
import type { CheckoutFormData } from '@/lib/types';
import MapPinPickerModal from './MapPinPickerModal';

interface Props {
  form: CheckoutFormData;
  onChange: (patch: Partial<CheckoutFormData>) => void;
  errors: Partial<Record<keyof CheckoutFormData, string>>;
}

export default function AddressForm({ form, onChange, errors }: Props) {
  const [locating, setLocating] = useState(false);
  const [showMapPicker, setShowMapPicker] = useState(false);

  const useMyLocation = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser.');
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        onChange({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        });
        setLocating(false);
      },
      () => {
        setLocating(false);
        alert(
          'Could not get your location. You can still describe your landmark below.'
        );
      }
    );
  };

  return (
    <div className="space-y-3.5 bg-gray-50/70 p-4 rounded-xl border border-gray-200">
      <h3 className="font-semibold text-sm text-quickopia-navy">
        Delivery Landmark &amp; Destination
      </h3>
      <Field
        label="City / Region"
        value={form.city}
        error={errors.city}
        onChange={(v) => onChange({ city: v })}
      />
      <Field
        label="Area / Neighborhood (e.g. Sinza, Mikocheni)"
        value={form.neighborhood}
        error={errors.neighborhood}
        onChange={(v) => onChange({ neighborhood: v })}
      />
      <Field
        label="Nearby Landmark (e.g. Opposite TotalEnergies, Near Big Mast)"
        value={form.landmark}
        error={errors.landmark}
        placeholder="Primary reference for delivery drivers"
        onChange={(v) => onChange({ landmark: v })}
      />
      <Field
        label="House / Gate description (optional)"
        value={form.houseDetails}
        placeholder="e.g. Black gate, 2nd house from the corner"
        onChange={(v) => onChange({ houseDetails: v })}
      />

      <div className="pt-1 flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={useMyLocation}
          disabled={locating}
          className="text-xs font-semibold text-quickopia-navy hover:underline transition flex items-center gap-1"
        >
          <span>🎯</span>
          <span>{locating ? 'Locating...' : 'Use my current location'}</span>
        </button>

        <button
          type="button"
          onClick={() => setShowMapPicker(true)}
          className="text-xs font-semibold text-quickopia-navy hover:underline transition flex items-center gap-1"
        >
          <span>🗺️</span>
          <span>Pick on Map</span>
        </button>
      </div>

      {form.latitude && form.longitude && (
        <p className="text-xs text-green-700 font-medium mt-1">
          📍 Map coordinates attached ({form.latitude.toFixed(4)},{' '}
          {form.longitude.toFixed(4)}) &bull; Ready for driver dispatch
        </p>
      )}

      {showMapPicker && (
        <MapPinPickerModal
          initialLat={form.latitude}
          initialLng={form.longitude}
          onConfirm={(lat, lng) => {
            onChange({ latitude: lat, longitude: lng });
            setShowMapPicker(false);
          }}
          onClose={() => setShowMapPicker(false)}
        />
      )}
    </div>
  );
}

function Field({
  label,
  value,
  error,
  placeholder,
  onChange,
}: {
  label: string;
  value: string;
  error?: string;
  placeholder?: string;
  onChange: (v: string) => void;
}) {
  return (
    <div>
      <label className="block text-xs font-semibold text-gray-700 mb-1">
        {label}
      </label>
      <input
        type="text"
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className={`w-full border rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-quickopia-amber transition ${
          error ? 'border-red-500 ring-1 ring-red-500' : 'border-gray-300'
        }`}
      />
      {error && <p className="text-xs text-red-500 mt-1 font-medium">{error}</p>}
    </div>
  );
}
