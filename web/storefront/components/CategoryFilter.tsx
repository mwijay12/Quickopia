'use client';

import type { Category } from '@/lib/types';

export default function CategoryFilter({
  categories,
  selected,
  onSelect,
}: {
  categories: Category[];
  selected: string | null;
  onSelect: (id: string | null) => void;
}) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 sm:mx-0 sm:px-0">
      <Chip
        label="All Products"
        active={selected === null}
        onClick={() => onSelect(null)}
      />
      {categories.map((c) => (
        <Chip
          key={c.id}
          label={c.name}
          active={selected === c.id}
          onClick={() => onSelect(c.id)}
        />
      ))}
    </div>
  );
}

function Chip({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`whitespace-nowrap px-4 py-2 rounded-full text-sm font-semibold border transition shadow-sm shrink-0 ${
        active
          ? 'bg-quickopia-amber border-quickopia-amber text-black ring-2 ring-quickopia-amber/30'
          : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50 hover:border-gray-400'
      }`}
    >
      {label}
    </button>
  );
}
