import { LayoutDashboard, PackageCheck, Truck, BarChart3, ShieldCheck } from "lucide-react";

export default function AdminHome() {
  return (
    <main className="min-h-screen bg-slate-900 text-slate-100 flex flex-col justify-between">
      {/* Admin Header */}
      <header className="border-b border-slate-800 bg-slate-950/60 backdrop-blur sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-9 h-9 rounded-lg bg-quickopia-amber flex items-center justify-center font-black text-slate-900">
              Q
            </div>
            <div>
              <span className="text-xl font-bold text-white tracking-tight">Quickopia</span>
              <span className="ml-2 text-xs font-semibold px-2 py-0.5 rounded bg-slate-800 text-amber-400 border border-slate-700">
                Staff Portal
              </span>
            </div>
          </div>
          <div className="flex items-center space-x-3 text-xs text-slate-400">
            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span>Admin Dev Server (Port 3001)</span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <section className="flex-1 max-w-4xl mx-auto px-6 py-16 flex flex-col items-center text-center justify-center">
        <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-800 border border-slate-700 text-amber-400 text-xs font-semibold mb-6">
          <ShieldCheck className="w-4 h-4 text-emerald-400" />
          Role-Gated Supermarket Operations
        </div>

        <h1 className="text-4xl sm:text-5xl font-extrabold text-white tracking-tight leading-tight mb-4">
          Quickopia Admin & Fulfillment
        </h1>

        <p className="text-slate-400 max-w-xl text-base sm:text-lg mb-12">
          Central dashboard for store staff to review incoming orders, pack grocery items, notify pickup customers, and dispatch delivery drivers.
        </p>

        {/* Feature Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 w-full max-w-2xl mb-12 text-left">
          <div className="p-5 rounded-xl bg-slate-800/80 border border-slate-700">
            <PackageCheck className="w-6 h-6 text-quickopia-amber mb-2" />
            <h3 className="font-bold text-white text-sm">Order Packing Queue</h3>
            <p className="text-xs text-slate-400 mt-1">
              Live checklist for warehouse and shelf packers.
            </p>
          </div>

          <div className="p-5 rounded-xl bg-slate-800/80 border border-slate-700">
            <Truck className="w-6 h-6 text-blue-400 mb-2" />
            <h3 className="font-bold text-white text-sm">Driver Dispatch</h3>
            <p className="text-xs text-slate-400 mt-1">
              Assign delivery orders with customer landmarks & phone.
            </p>
          </div>

          <div className="p-5 rounded-xl bg-slate-800/80 border border-slate-700">
            <BarChart3 className="w-6 h-6 text-emerald-400 mb-2" />
            <h3 className="font-bold text-white text-sm">Catalog & Inventory</h3>
            <p className="text-xs text-slate-400 mt-1">
              TZS prices, stock levels, and AI product descriptions.
            </p>
          </div>
        </div>

        <div className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-slate-800 text-xs text-slate-300 border border-slate-700">
          <LayoutDashboard className="w-4 h-4 text-quickopia-amber" />
          <span>Admin Portal Scaffolding Ready — Functional UI in Phase 5</span>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-800 py-6 text-center text-xs text-slate-500 bg-slate-950">
        <p>Quickopia Operations Dashboard • Localized for Tanzania</p>
      </footer>
    </main>
  );
}
