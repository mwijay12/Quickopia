'use client';

export default function SearchBar({
  value,
  onChange,
}: {
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="relative w-full">
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Search for anything the store sells (milk, rice, snacks)..."
        className="w-full border border-gray-300 rounded-xl px-4 py-3 pl-11 text-sm md:text-base focus:outline-none focus:ring-2 focus:ring-quickopia-amber focus:border-transparent transition shadow-sm bg-white"
      />
      <svg
        className="w-5 h-5 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
        />
      </svg>
      {value && (
        <button
          type="button"
          onClick={() => onChange('')}
          className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 text-sm font-bold p-1"
        >
          ✕
        </button>
      )}
    </div>
  );
}
