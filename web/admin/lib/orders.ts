import { createClient } from './supabase/client';
import type { Order } from './types';

export const ACTIVE_STATUSES: Order['status'][] = [
  'placed',
  'packing',
  'ready',
  'out_for_delivery',
];

export class AdminActionError extends Error {}

export interface Branch {
  id: string;
  name: string;
  city: string;
  neighborhood?: string;
  landmark?: string;
}

export async function fetchAllBranches(): Promise<Branch[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('branches')
    .select('id, name, city, neighborhood, landmark')
    .order('name', { ascending: true });

  if (error) {
    console.error('fetchAllBranches error:', error.message);
    return [];
  }
  return data as Branch[];
}

export async function fetchActiveOrders(branchId?: string): Promise<Order[]> {
  const supabase = createClient();
  let query = supabase
    .from('orders')
    .select(
      '*, order_items(*), customer:profiles!orders_customer_id_fkey(full_name)'
    )
    .in('status', ACTIVE_STATUSES);

  if (branchId && branchId !== 'all') {
    query = query.eq('branch_id', branchId);
  }

  const { data, error } = await query.order('created_at', { ascending: true });

  if (error) {
    console.error('fetchActiveOrders error:', error.message);
    return [];
  }
  return data as unknown as Order[];
}

export async function fetchOrderById(orderId: string): Promise<Order | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('orders')
    .select(
      '*, order_items(*), customer:profiles!orders_customer_id_fkey(full_name)'
    )
    .eq('id', orderId)
    .single();

  if (error || !data) return null;
  return data as unknown as Order;
}

export interface RealtimeOrderEvent {
  eventType: 'INSERT' | 'UPDATE' | 'DELETE';
  orderId: string;
  newStatus?: Order['status'];
}

/**
 * Subscribes to Realtime order changes.
 * Passes targeted events so the Kanban board can update or remove only the affected card.
 */
export function subscribeToOrderChanges(
  onEvent: (event: RealtimeOrderEvent) => void
) {
  const supabase = createClient();
  const channel = supabase
    .channel('admin_orders_realtime_v2')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'orders' },
      (payload) => {
        onEvent({
          eventType: 'INSERT',
          orderId: (payload.new as { id: string }).id,
          newStatus: (payload.new as { status: Order['status'] }).status,
        });
      }
    )
    .on(
      'postgres_changes',
      { event: 'UPDATE', schema: 'public', table: 'orders' },
      (payload) => {
        onEvent({
          eventType: 'UPDATE',
          orderId: (payload.new as { id: string }).id,
          newStatus: (payload.new as { status: Order['status'] }).status,
        });
      }
    )
    .on(
      'postgres_changes',
      { event: 'DELETE', schema: 'public', table: 'orders' },
      (payload) => {
        onEvent({
          eventType: 'DELETE',
          orderId: (payload.old as { id: string }).id,
        });
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}

export async function advanceStatus(
  orderId: string,
  newStatus: Order['status'],
  driverId?: string
) {
  const supabase = createClient();
  const { error } = await supabase.rpc('admin_update_order_status', {
    p_order_id: orderId,
    p_new_status: newStatus,
    p_driver_id: driverId ?? null,
  });
  if (error) throw new AdminActionError(error.message);
}

export async function completePickup(
  orderId: string,
  enteredCode: string,
  paymentStatus: 'paid' = 'paid'
) {
  const supabase = createClient();
  const { error } = await supabase.rpc('complete_delivery', {
    p_order_id: orderId,
    p_entered_code: enteredCode,
    p_payment_status: paymentStatus,
  });
  if (error) {
    const msg = error.message.toLowerCase().includes('incorrect')
      ? 'That code does not match this order. Please check with the customer.'
      : 'Could not complete this order.';
    throw new AdminActionError(msg);
  }
}

export async function cancelOrder(orderId: string, reason?: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc('cancel_order', {
    p_order_id: orderId,
    p_reason: reason ?? null,
  });
  if (error) throw new AdminActionError(error.message);
}

/**
 * Flags an out-of-stock item discovered on physical supermarket shelves during packing.
 * Automatically marks the product unavailable and resets stock to 0 to prevent further sales.
 */
export async function markProductOutOfStock(productId: string) {
  const supabase = createClient();
  const { error } = await supabase
    .from('products')
    .update({ is_available: false, stock_quantity: 0 })
    .eq('id', productId);

  if (error) {
    console.error('Failed to mark product out of stock:', error.message);
  }
}

/**
 * Updates an order's payment status (e.g. verifying Lipa Namba M-Pesa / Tigo Pesa deposit)
 */
export async function updatePaymentStatus(
  orderId: string,
  paymentStatus: 'paid' | 'pending'
) {
  const supabase = createClient();
  const { error } = await supabase
    .from('orders')
    .update({ payment_status: paymentStatus, updated_at: new Date().toISOString() })
    .eq('id', orderId);

  if (error) throw new AdminActionError(error.message);
}
