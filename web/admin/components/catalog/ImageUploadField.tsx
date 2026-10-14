'use client';

import { useState } from 'react';
import {
  uploadImageToCloudinary,
  CloudinaryUploadError,
} from '@/lib/cloudinary';
import { Camera } from 'lucide-react';

export default function ImageUploadField({
  value,
  onChange,
  label = 'Product Photo',
}: {
  value: string | null;
  onChange: (url: string) => void;
  label?: string;
}) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFile = async (file: File) => {
    if (file.size > 5 * 1024 * 1024) {
      setError('Image must be smaller than 5MB.');
      return;
    }
    setUploading(true);
    setError(null);
    try {
      const url = await uploadImageToCloudinary(file);
      onChange(url);
    } catch (e) {
      setError(
        e instanceof CloudinaryUploadError ? e.message : 'Image upload failed.'
      );
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      <label className="block text-xs font-semibold text-gray-700 mb-1.5">
        {label}
      </label>
      <div className="flex items-center gap-4">
        <div className="w-20 h-20 rounded-xl border border-gray-200 bg-gray-50 flex items-center justify-center overflow-hidden shadow-2xs shrink-0">
          {value ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={value}
              alt="Product preview"
              className="w-full h-full object-cover"
            />
          ) : (
            <span className="text-xs text-gray-400 font-medium">No photo</span>
          )}
        </div>
        <div>
          <label className="cursor-pointer inline-flex items-center gap-2 bg-gray-100 hover:bg-gray-200 text-gray-800 text-xs font-bold px-3.5 py-2.5 rounded-xl border border-gray-200 transition shadow-2xs">
            {uploading ? (
              <>
                <span className="w-3.5 h-3.5 border-2 border-gray-700 border-t-transparent rounded-full animate-spin" />
                <span>Uploading...</span>
              </>
            ) : (
              <>
                <Camera className="w-3.5 h-3.5" />
                <span>{value ? 'Change Photo' : 'Upload Photo'}</span>
              </>
            )}
            <input
              type="file"
              accept="image/png, image/jpeg, image/webp"
              className="hidden"
              disabled={uploading}
              onChange={(e) =>
                e.target.files?.[0] && handleFile(e.target.files[0])
              }
            />
          </label>
          <p className="text-[11px] text-gray-400 mt-1">
            JPG, PNG or WebP up to 5MB (auto-optimized via Cloudinary)
          </p>
        </div>
      </div>
      {error && (
        <p className="text-xs text-red-600 bg-red-50 p-2 rounded-lg mt-2 font-medium">
          {error}
        </p>
      )}
    </div>
  );
}
