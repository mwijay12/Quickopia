import { createClient } from './supabase/client';
import type { DriverProfile, Order } from './types';

export interface DriverListItem {
  id: string;
  full_name: string | null;
  phone: string | null;
  is_active: boolean;
  created_at: string;
}

export interface DriverWorkloadItem extends DriverListItem {
  derivedStatus: 'delivering' | 'available' | 'inactive';
  activeOrderCount: number;
  currentOrder?: {
    id: string;
    order_number: string;
    landmark: string | null;
    neighborhood: string | null;
  };
}

export class DriverManagementError extends Error {}

/**
 * Filters only ACTIVE drivers so deactivated staff cannot be assigned new dispatches.
 */
export async function fetchDrivers(): Promise<DriverProfile[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, phone')
    .eq('role', 'driver')
    .eq('is_active', true);

  if (error) {
    console.error('fetchDrivers error:', error.message);
    return [];
  }
  return data as DriverProfile[];
}

/**
 * Fetches the entire driver roster via the authenticated server-side API route.
 */
export async function fetchDriverRoster(): Promise<DriverListItem[]> {
  const res = await fetch('/api/drivers');
  const json = await res.json();
  if (!res.ok) {
    throw new DriverManagementError(json.error ?? 'Could not load drivers.');
  }
  return json.drivers as DriverListItem[];
}

/**
 * Fetches drivers along with their derived workload and real-time delivery status
 * calculated directly from the orders table.
 */
export async function fetchDriverWorkloads(): Promise<DriverWorkloadItem[]> {
  const [roster, activeOrders] = await Promise.all([
    fetchDriverRoster(),
    fetchActiveDispatches(),
  ]);

  return roster.map((d) => {
    if (!d.is_active) {
      return {
        ...d,
        derivedStatus: 'inactive',
        activeOrderCount: 0,
      };
    }

    const assigned = activeOrders.filter((o) => o.driver_id === d.id);
    const activeOrder = assigned.find((o) => o.status === 'out_for_delivery');

    return {
      ...d,
      derivedStatus: activeOrder ? 'delivering' : 'available',
      activeOrderCount: assigned.length,
      currentOrder: activeOrder
        ? {
            id: activeOrder.id,
            order_number: activeOrder.order_number,
            landmark: activeOrder.delivery_landmark,
            neighborhood: activeOrder.delivery_neighborhood,
          }
        : undefined,
    };
  });
}

/**
 * Fetches orders that are ready for delivery but have not yet been assigned to a driver.
 */
export async function fetchUnassignedDeliveries(): Promise<Order[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('orders')
    .select(
      '*, order_items(*), customer:profiles!orders_customer_id_fkey(full_name)'
    )
    .eq('fulfillment_type', 'delivery')
    .eq('status', 'ready')
    .is('driver_id', null)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('fetchUnassignedDeliveries error:', error.message);
    return [];
  }
  return data as unknown as Order[];
}

/**
 * Fetches active deliveries currently out with drivers.
 */
export async function fetchActiveDispatches(): Promise<Order[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('orders')
    .select(
      '*, order_items(*), customer:profiles!orders_customer_id_fkey(full_name), driver:profiles!orders_driver_id_fkey(full_name, phone)'
    )
    .eq('fulfillment_type', 'delivery')
    .eq('status', 'out_for_delivery')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('fetchActiveDispatches error:', error.message);
    return [];
  }
  return data as unknown as Order[];
}

/**
 * Reassigns an in-transit order to a different driver (e.g. vehicle breakdown).
 * Supabase Realtime alerts both drivers' apps immediately.
 */
export async function reassignDriver(orderId: string, newDriverId: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc('admin_update_order_status', {
    p_order_id: orderId,
    p_new_status: 'out_for_delivery',
    p_driver_id: newDriverId,
  });

  if (error) {
    throw new DriverManagementError(
      `Could not reassign driver: ${error.message}`
    );
  }
}

/**
 * Assigns a driver to a ready delivery and moves it to out_for_delivery.
 */
export async function assignDriver(orderId: string, driverId: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc('admin_update_order_status', {
    p_order_id: orderId,
    p_new_status: 'out_for_delivery',
    p_driver_id: driverId,
  });

  if (error) {
    throw new DriverManagementError(`Could not assign driver: ${error.message}`);
  }
}

/**
 * Fetches completed delivery history for settled orders.
 */
export async function fetchDeliveryHistory(driverId?: string) {
  const supabase = createClient();
  let query = supabase
    .from('orders')
    .select(
      'id, order_number, created_at, updated_at, total_amount_tzs, delivery_fee_tzs, delivery_neighborhood, delivery_landmark, customer:profiles!orders_customer_id_fkey(full_name), driver:profiles!orders_driver_id_fkey(id, full_name, phone)'
    )
    .eq('fulfillment_type', 'delivery')
    .eq('status', 'delivered')
    .order('updated_at', { ascending: false })
    .limit(50);

  if (driverId) {
    query = query.eq('driver_id', driverId);
  }

  const { data, error } = await query;
  if (error) {
    console.error('fetchDeliveryHistory error:', error.message);
    return [];
  }
  return data;
}

/**
 * Calls the server-side API route to create a driver auth user + profile.
 */
export async function createDriver(input: {
  email: string;
  password: string;
  fullName: string;
  phone: string;
}) {
  const res = await fetch('/api/drivers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  });
  const json = await res.json();
  if (!res.ok) {
    throw new DriverManagementError(json.error ?? 'Could not create driver.');
  }
  return json;
}

/**
 * Calls the server-side API route to update a driver's name and phone.
 */
export async function updateDriver(id: string, fullName: string, phone: string) {
  const res = await fetch(`/api/drivers/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fullName, phone }),
  });
  const json = await res.json();
  if (!res.ok) {
    throw new DriverManagementError(json.error ?? 'Could not update driver.');
  }
}

/**
 * Calls the server-side API route to toggle a driver's active status.
 */
export async function setDriverActive(id: string, isActive: boolean) {
  const res = await fetch(`/api/drivers/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ isActive }),
  });
  const json = await res.json();
  if (!res.ok) {
    throw new DriverManagementError(
      json.error ?? 'Could not update driver status.'
    );
  }
}
