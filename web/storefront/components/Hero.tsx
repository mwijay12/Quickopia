export default function Hero() {
  return (
    <section className="bg-quickopia-navy text-white py-12 md:py-16 px-4 text-center border-b border-white/10">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight">
          Everything your supermarket sells — delivered fast, or ready for pickup.
        </h1>
        <p className="mt-4 text-base md:text-lg text-white/85 max-w-xl mx-auto">
          Fast doorstep delivery and quick Click &amp; Collect in Dar es Salaam. Browse the shelves and order directly — no app download required.
        </p>
        <div className="mt-6 flex flex-wrap justify-center items-center gap-4 text-xs font-semibold text-white/70">
          <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-full">
            📍 Dar es Salaam
          </span>
          <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-full">
            ⚡ Doorstep Delivery &amp; Store Pickup
          </span>
          <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-full">
            💬 Easy WhatsApp Ordering
          </span>
        </div>
      </div>
    </section>
  );
}
