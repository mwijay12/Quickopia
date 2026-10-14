import { createClient } from './supabase/client';
import type { Order, CheckoutFormData } from './types';
import type { CartLine } from '@/context/CartContext';

export class OrderPlacementError extends Error {}

export interface CartRevalidationResult {
  valid: boolean;
  message?: string;
  priceChanged?: boolean;
}

/**
 * Re-validates current price, availability, and stock quantity for each cart item
 * against the database prior to placing an order.
 */
export async function revalidateCartItems(
  items: CartLine[]
): Promise<CartRevalidationResult> {
  if (items.length === 0) return { valid: false, message: 'Your cart is empty.' };

  const supabase = createClient();
  const productIds = items.map((i) => i.productId);

  const { data: products, error } = await supabase
    .from('products')
    .select('id, title, price_tzs, stock_quantity, is_available')
    .in('id', productIds);

  if (error || !products) {
    return {
      valid: false,
      message: 'Could not verify current catalog stock. Please try again.',
    };
  }

  for (const item of items) {
    const prod = products.find((p) => p.id === item.productId);
    if (!prod || !prod.is_available) {
      return {
        valid: false,
        message: `"${item.title}" is no longer available. Please remove it from your cart.`,
      };
    }
    if (prod.stock_quantity < item.quantity) {
      return {
        valid: false,
        message: `"${item.title}" only has ${prod.stock_quantity} left in stock (you requested ${item.quantity}). Please update your cart quantity.`,
      };
    }
    if (prod.price_tzs !== item.priceTzs) {
      return {
        valid: false,
        priceChanged: true,
        message: `The price for "${item.title}" has changed to TZS ${prod.price_tzs.toLocaleString(
          'en-US'
        )}. Please review your updated total before placing your order.`,
      };
    }
  }

  return { valid: true };
}

export async function placeOrder(
  customerId: string,
  branchId: string,
  form: CheckoutFormData,
  items: CartLine[],
  deliveryFeeTzs: number
): Promise<Order> {
  const supabase = createClient();

  const itemsPayload = items.map((i) => ({
    product_id: i.productId,
    quantity: i.quantity,
  }));

  const { data: orderId, error } = await supabase.rpc('place_order', {
    p_customer_id: customerId,
    p_branch_id: branchId,
    p_fulfillment_type: form.fulfillmentType,
    p_delivery_city: form.fulfillmentType === 'delivery' ? form.city : null,
    p_delivery_neighborhood:
      form.fulfillmentType === 'delivery' ? form.neighborhood : null,
    p_delivery_landmark:
      form.fulfillmentType === 'delivery' ? form.landmark : null,
    p_delivery_house_details:
      form.fulfillmentType === 'delivery' ? form.houseDetails : null,
    p_delivery_latitude: form.latitude,
    p_delivery_longitude: form.longitude,
    p_customer_phone: form.phone,
    p_payment_method: form.paymentMethod,
    p_delivery_fee_tzs: deliveryFeeTzs,
    p_items: itemsPayload,
  });

  if (error) {
    throw new OrderPlacementError(parseRpcError(error.message));
  }

  return getOrderById(orderId as string);
}

export async function getOrderById(orderId: string): Promise<Order> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('orders')
    .select('*, order_items(*)')
    .eq('id', orderId)
    .single();

  if (error) throw new Error('Could not load order details.');
  return data as Order;
}

export function subscribeToOrder(
  orderId: string,
  onUpdate: (order: Order) => void
) {
  const supabase = createClient();
  const channel = supabase
    .channel(`order_tracking_${orderId}`)
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'orders',
        filter: `id=eq.${orderId}`,
      },
      async () => {
        // Re-fetch full row (with items) on any change
        try {
          const refreshed = await getOrderById(orderId);
          onUpdate(refreshed);
        } catch (e) {
          console.error('Failed to reload updated order:', e);
        }
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}

function parseRpcError(raw: string): string {
  const lower = raw.toLowerCase();
  if (lower.includes('insufficient stock')) {
    return 'Sorry, one or more items just sold out. Please review your cart and try again.';
  }
  if (lower.includes('not found')) {
    return 'One of the items in your cart is no longer available.';
  }
  return 'We could not place your order right now. Please try again.';
}
