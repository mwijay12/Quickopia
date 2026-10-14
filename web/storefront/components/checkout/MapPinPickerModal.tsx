'use client';

import { useState } from 'react';

interface Props {
  initialLat: number | null;
  initialLng: number | null;
  onConfirm: (lat: number, lng: number) => void;
  onClose: () => void;
}

// Default center: Dar es Salaam (-6.7924, 39.2083)
const DEFAULT_LAT = -6.7924;
const DEFAULT_LNG = 39.2083;

export default function MapPinPickerModal({
  initialLat,
  initialLng,
  onConfirm,
  onClose,
}: Props) {
  const [lat, setLat] = useState<number>(initialLat ?? DEFAULT_LAT);
  const [lng, setLng] = useState<number>(initialLng ?? DEFAULT_LNG);
  const [locating, setLocating] = useState(false);

  const useBrowserLocation = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser.');
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(pos.coords.latitude);
        setLng(pos.coords.longitude);
        setLocating(false);
      },
      () => {
        setLocating(false);
        alert('Could not detect your location. Please adjust the coordinates manually.');
      }
    );
  };

  const handleNudge = (dLat: number, dLng: number) => {
    setLat((l) => Number((l + dLat).toFixed(6)));
    setLng((l) => Number((l + dLng).toFixed(6)));
  };

  const bbox = `${lng - 0.008},${lat - 0.006},${lng + 0.008},${lat + 0.006}`;
  const embedUrl = `https://www.openstreetmap.org/export/embed.html?bbox=${encodeURIComponent(
    bbox
  )}&layer=mapnik&marker=${lat}%2C${lng}`;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className="bg-white rounded-2xl p-5 w-full max-w-lg shadow-2xl space-y-4 animate-in fade-in zoom-in-95 duration-150 border border-gray-100">
        <div className="flex justify-between items-center pb-2 border-b border-gray-100">
          <div>
            <h3 className="font-bold text-base text-quickopia-navy">
              📍 Pin Delivery Location
            </h3>
            <p className="text-[11px] text-gray-500">
              OpenStreetMap zero-cost delivery location pin
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 font-bold flex items-center justify-center transition"
          >
            ✕
          </button>
        </div>

        <div className="relative rounded-xl overflow-hidden border border-gray-300 h-64 bg-gray-100">
          <iframe
            src={embedUrl}
            title="OpenStreetMap Picker"
            className="w-full h-full border-0 pointer-events-none"
            loading="lazy"
          />
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div className="text-3xl filter drop-shadow-md -mt-6">📍</div>
          </div>
        </div>

        <div className="bg-gray-50 rounded-xl p-3 border border-gray-200 flex flex-wrap items-center justify-between gap-2 text-xs">
          <div>
            <span className="font-semibold text-gray-700">Coordinates: </span>
            <span className="font-mono text-gray-900 font-bold">
              {lat.toFixed(5)}, {lng.toFixed(5)}
            </span>
          </div>
          <button
            type="button"
            onClick={useBrowserLocation}
            disabled={locating}
            className="bg-white hover:bg-gray-100 text-quickopia-navy font-bold px-3 py-1.5 rounded-lg border border-gray-300 transition text-[11px] flex items-center gap-1 shadow-2xs"
          >
            <span>🎯</span>
            <span>{locating ? 'Locating...' : 'My GPS'}</span>
          </button>
        </div>

        <div>
          <p className="text-[11px] text-gray-500 mb-1.5 font-medium text-center">
            Fine-tune pin position:
          </p>
          <div className="grid grid-cols-4 gap-2">
            <button
              type="button"
              onClick={() => handleNudge(0.001, 0)}
              className="py-1.5 text-xs font-bold bg-gray-100 hover:bg-gray-200 rounded-lg text-gray-700 transition"
            >
              ▲ North
            </button>
            <button
              type="button"
              onClick={() => handleNudge(-0.001, 0)}
              className="py-1.5 text-xs font-bold bg-gray-100 hover:bg-gray-200 rounded-lg text-gray-700 transition"
            >
              ▼ South
            </button>
            <button
              type="button"
              onClick={() => handleNudge(0, -0.001)}
              className="py-1.5 text-xs font-bold bg-gray-100 hover:bg-gray-200 rounded-lg text-gray-700 transition"
            >
              ◀ West
            </button>
            <button
              type="button"
              onClick={() => handleNudge(0, 0.001)}
              className="py-1.5 text-xs font-bold bg-gray-100 hover:bg-gray-200 rounded-lg text-gray-700 transition"
            >
              ▶ East
            </button>
          </div>
        </div>

        <div className="flex gap-2 pt-2 border-t border-gray-100">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 py-2.5 text-xs font-bold text-gray-700 hover:bg-gray-100 rounded-xl transition"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={() => onConfirm(lat, lng)}
            className="flex-1 py-2.5 text-xs font-bold bg-quickopia-navy hover:bg-slate-900 text-white rounded-xl transition shadow-sm"
          >
            Confirm Pin
          </button>
        </div>
      </div>
    </div>
  );
}
