'use client';

import { useEffect, useState, useCallback } from 'react';
import type { Order } from '@/lib/types';
import {
  fetchActiveOrders,
  fetchOrderById,
  fetchAllBranches,
  Branch,
  subscribeToOrderChanges,
  ACTIVE_STATUSES,
} from '@/lib/orders';
import { playNewOrderChime } from '@/lib/sound';
import { Store, AlertTriangle } from 'lucide-react';
import OrderColumn from './OrderColumn';
import PackingChecklistModal from './PackingChecklistModal';
import DispatchModal from './DispatchModal';
import CompletePickupModal from './CompletePickupModal';
import CancelOrderDialog from './CancelOrderDialog';

type ModalState =
  | {
      type: 'packing-modal' | 'dispatch' | 'complete-pickup' | 'cancel';
      order: Order;
    }
  | null;

export default function OrderKanbanBoard() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [selectedBranchId, setSelectedBranchId] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<ModalState>(null);

  const loadAll = useCallback(async (branchId: string) => {
    const data = await fetchActiveOrders(branchId);
    setOrders(data);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchAllBranches().then(setBranches).catch(() => {});
  }, []);

  useEffect(() => {
    loadAll(selectedBranchId);

    // Granular Realtime event handler: modifies ONLY the affected card in state
    const unsubscribe = subscribeToOrderChanges(async (event) => {
      if (event.eventType === 'INSERT') {
        playNewOrderChime();
        const newOrder = await fetchOrderById(event.orderId);
        if (newOrder) {
          if (selectedBranchId === 'all' || newOrder.branch_id === selectedBranchId) {
            setOrders((prev) => [
              newOrder,
              ...prev.filter((o) => o.id !== newOrder.id),
            ]);
          }
        }
      } else if (event.eventType === 'UPDATE') {
        if (event.newStatus && ACTIVE_STATUSES.includes(event.newStatus)) {
          const updated = await fetchOrderById(event.orderId);
          if (updated) {
            if (selectedBranchId === 'all' || updated.branch_id === selectedBranchId) {
              setOrders((prev) =>
                prev.map((o) => (o.id === updated.id ? updated : o))
              );
            } else {
              setOrders((prev) => prev.filter((o) => o.id !== updated.id));
            }
          }
        } else {
          // Closed order (delivered or cancelled) — remove card from active board
          setOrders((prev) => prev.filter((o) => o.id !== event.orderId));
        }
      } else if (event.eventType === 'DELETE') {
        setOrders((prev) => prev.filter((o) => o.id !== event.orderId));
      }
    });

    return unsubscribe;
  }, [selectedBranchId, loadAll]);

  const byStatus = (status: Order['status']) =>
    orders.filter((o) => o.status === status);

  const unverifiedLipaCount = orders.filter(
    (o) => o.payment_method === 'lipa_namba' && o.payment_status === 'pending'
  ).length;

  const closeModal = () => setModal(null);
  const onModalDone = async () => {
    if (modal?.order.id) {
      const refreshed = await fetchOrderById(modal.order.id);
      if (refreshed && ACTIVE_STATUSES.includes(refreshed.status)) {
        setOrders((prev) =>
          prev.map((o) => (o.id === refreshed.id ? refreshed : o))
        );
      } else {
        setOrders((prev) => prev.filter((o) => o.id !== modal.order.id));
      }
    }
    closeModal();
  };

  if (loading) {
    return (
      <div className="py-20 text-center text-gray-500 space-y-3">
        <div className="inline-block w-8 h-8 border-4 border-quickopia-navy border-t-transparent rounded-full animate-spin" />
        <p className="text-sm font-semibold">Loading live orders queue...</p>
      </div>
    );
  }

  return (
    <>
      {/* Branch Selector & Operational Alert Bar */}
      <div className="mb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-3.5 rounded-xl border border-gray-200 shadow-sm">
        <div className="flex items-center gap-2">
          <Store className="w-4 h-4 text-quickopia-navy" />
          <span className="text-xs font-bold text-gray-700 uppercase tracking-wider">
            Supermarket Branch:
          </span>
          <select
            value={selectedBranchId}
            onChange={(e) => {
              setLoading(true);
              setSelectedBranchId(e.target.value);
            }}
            className="text-xs font-semibold bg-gray-50 border border-gray-300 rounded-lg px-2.5 py-1.5 text-gray-900 focus:outline-none focus:ring-1 focus:ring-quickopia-navy"
          >
            <option value="all">All Branches (Dar es Salaam Multi-Branch)</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name} ({b.neighborhood || b.city})
              </option>
            ))}
          </select>
          <span className="text-xs text-gray-500 ml-1">
            &bull; {orders.length} active order{orders.length === 1 ? '' : 's'}
          </span>
        </div>

        {unverifiedLipaCount > 0 && (
          <div className="flex items-center gap-1.5 px-3 py-1 bg-amber-50 border border-amber-200 rounded-lg text-amber-900 text-xs font-semibold">
            <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
            <span>
              {unverifiedLipaCount} Lipa Namba order{unverifiedLipaCount === 1 ? '' : 's'} awaiting SMS payment verification
            </span>
          </div>
        )}
      </div>

      <div className="flex gap-5 overflow-x-auto pb-6">
        <OrderColumn
          title="New Orders"
          orders={byStatus('placed')}
          onAction={(o, a) => setModal({ type: a, order: o })}
        />
        <OrderColumn
          title="Packing"
          orders={byStatus('packing')}
          onAction={(o, a) => setModal({ type: a, order: o })}
        />
        <OrderColumn
          title="Ready for Handoff"
          orders={byStatus('ready')}
          onAction={(o, a) => setModal({ type: a, order: o })}
        />
        <OrderColumn
          title="Dispatched (Delivery)"
          orders={byStatus('out_for_delivery')}
          onAction={(o, a) => setModal({ type: a, order: o })}
        />
      </div>

      {modal?.type === 'packing-modal' && (
        <PackingChecklistModal
          order={modal.order}
          onClose={closeModal}
          onDone={onModalDone}
        />
      )}
      {modal?.type === 'dispatch' && (
        <DispatchModal
          order={modal.order}
          onClose={closeModal}
          onDone={onModalDone}
        />
      )}
      {modal?.type === 'complete-pickup' && (
        <CompletePickupModal
          order={modal.order}
          onClose={closeModal}
          onDone={onModalDone}
        />
      )}
      {modal?.type === 'cancel' && (
        <CancelOrderDialog
          order={modal.order}
          onClose={closeModal}
          onDone={onModalDone}
        />
      )}
    </>
  );
}
