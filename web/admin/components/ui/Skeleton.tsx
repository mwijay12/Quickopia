'use client';

export function TableSkeleton({ rows = 6 }: { rows?: number }) {
  return (
    <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden animate-pulse">
      <div className="bg-gray-50/80 px-4 py-3.5 border-b border-gray-100 flex items-center justify-between">
        <div className="h-4 bg-gray-200 rounded-md w-32" />
        <div className="h-4 bg-gray-200 rounded-md w-24" />
      </div>
      <div className="divide-y divide-gray-100">
        {Array.from({ length: rows }).map((_, i) => (
          <div key={i} className="p-4 flex items-center justify-between gap-4">
            <div className="flex items-center gap-3 flex-1">
              <div className="w-11 h-11 rounded-xl bg-gray-200 shrink-0" />
              <div className="space-y-2 flex-1 max-w-sm">
                <div className="h-4 bg-gray-200 rounded-md w-3/4" />
                <div className="h-3 bg-gray-100 rounded-md w-1/2" />
              </div>
            </div>
            <div className="h-6 bg-gray-100 rounded-full w-24 hidden sm:block" />
            <div className="h-5 bg-gray-200 rounded-md w-20" />
            <div className="h-8 bg-gray-100 rounded-lg w-28 hidden md:block" />
            <div className="flex gap-2 shrink-0">
              <div className="w-8 h-8 rounded-lg bg-gray-100" />
              <div className="w-8 h-8 rounded-lg bg-gray-100" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export function CardGridSkeleton({ count = 4 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 animate-pulse">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-xs">
          <div className="h-40 bg-gray-200 w-full" />
          <div className="p-4 space-y-3">
            <div className="h-4 bg-gray-200 rounded-md w-2/3" />
            <div className="h-3 bg-gray-100 rounded-md w-1/2" />
            <div className="pt-2 border-t border-gray-100 flex justify-end gap-2">
              <div className="h-7 w-20 bg-gray-100 rounded-lg" />
              <div className="h-7 w-16 bg-gray-100 rounded-lg" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export function FullPageLoader({ message = 'Loading Dashboard...' }: { message?: string }) {
  return (
    <div className="min-h-[50vh] flex flex-col items-center justify-center p-8">
      <div className="relative mb-4">
        <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-quickopia-orange via-quickopia-amber to-quickopia-navy flex items-center justify-center shadow-lg shadow-quickopia-orange/20 animate-bounce">
          <div className="w-8 h-8 rounded-xl bg-white flex items-center justify-center">
            <div className="w-3 h-3 rounded-full bg-quickopia-orange animate-ping" />
          </div>
        </div>
      </div>
      <h3 className="text-sm font-black text-quickopia-navy tracking-tight mt-2">{message}</h3>
      <p className="text-xs text-gray-400 mt-1 font-medium">Synchronizing live store data...</p>
    </div>
  );
}
