import { ShoppingBag, Truck, Store, ArrowRight, ShieldCheck } from "lucide-react";

export default function Home() {
  return (
    <main className="min-h-screen bg-slate-50 flex flex-col justify-between">
      {/* Header */}
      <header className="border-b border-slate-200 bg-white/80 backdrop-blur sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-quickopia-amber flex items-center justify-center shadow-md shadow-amber-200">
              <ShoppingBag className="w-5 h-5 text-quickopia-dark" />
            </div>
            <span className="text-2xl font-black text-quickopia-navy tracking-tight">
              Quickopia
            </span>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-xs font-semibold px-3 py-1 rounded-full bg-slate-100 text-slate-600 border border-slate-200">
              Dar es Salaam, Tanzania
            </span>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="flex-1 max-w-4xl mx-auto px-6 py-16 flex flex-col items-center text-center justify-center">
        <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-amber-50 border border-amber-200 text-amber-900 text-xs font-semibold mb-6">
          <span className="w-2 h-2 rounded-full bg-quickopia-amber animate-pulse"></span>
          Supermarket Shopping Reimagined
        </div>

        <h1 className="text-4xl sm:text-6xl font-extrabold text-quickopia-navy tracking-tight leading-tight mb-6">
          Everything You Need, <br className="hidden sm:inline" />
          <span className="text-quickopia-amber">Delivered in Minutes</span> or Ready for Pickup.
        </h1>

        <p className="text-lg sm:text-xl text-slate-600 max-w-2xl mb-10">
          Skip the aisles, avoid the queues. Order anything from the supermarket for express doorstep delivery or swift 30-second in-store collection.
        </p>

        {/* Action Cards Preview */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full max-w-xl mb-12 text-left">
          <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-sm hover:border-quickopia-amber transition-colors">
            <div className="w-10 h-10 rounded-lg bg-blue-50 text-quickopia-navy flex items-center justify-center mb-3">
              <Truck className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-quickopia-navy text-base">Express Doorstep Delivery</h3>
            <p className="text-xs text-slate-500 mt-1">
              Real-time driver dispatch to your neighborhood & landmark.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-sm hover:border-quickopia-amber transition-colors">
            <div className="w-10 h-10 rounded-lg bg-amber-50 text-amber-700 flex items-center justify-center mb-3">
              <Store className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-quickopia-navy text-base">Click & Collect Pickup</h3>
            <p className="text-xs text-slate-500 mt-1">
              Packed and waiting for you. Grab and go in under a minute.
            </p>
          </div>
        </div>

        {/* Coming Soon Callout */}
        <div className="inline-flex items-center gap-3 px-6 py-3 rounded-full bg-quickopia-navy text-white text-sm font-semibold shadow-lg shadow-slate-900/10">
          <span>Web Storefront Launching with Phase 4</span>
          <ArrowRight className="w-4 h-4 text-quickopia-amber" />
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-200 py-6 text-center text-xs text-slate-500 bg-white">
        <div className="max-w-6xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-2">
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-emerald-600" />
            <span>Supabase Backend Connected & Secured</span>
          </div>
          <p>© 2026 Quickopia Tanzania. All rights reserved.</p>
        </div>
      </footer>
    </main>
  );
}
