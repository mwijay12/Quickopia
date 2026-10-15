import OrderKanbanBoard from '@/components/kanban/OrderKanbanBoard';
import BackendHealthCard from '@/components/system/BackendHealthCard';

export default function DashboardHomePage() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-black text-quickopia-navy">
            Live Orders Queue
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Realtime fulfillment board &bull; Updates automatically when new orders are placed
          </p>
        </div>
      </div>

      {/* Supabase Free-Tier Liveness & Keep-Alive Monitor */}
      <BackendHealthCard />

      <OrderKanbanBoard />
    </div>
  );
}

