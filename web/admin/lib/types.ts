export interface OrderItem {
  id: string;
  product_id: string;
  title: string;
  unit_price_tzs: number;
  quantity: number;
  total_tzs: number;
}

export interface Order {
  id: string;
  order_number: string;
  fulfillment_type: 'delivery' | 'pickup';
  status:
    | 'placed'
    | 'packing'
    | 'ready'
    | 'out_for_delivery'
    | 'delivered'
    | 'cancelled';
  pickup_code: string;
  customer_phone: string;
  delivery_city: string | null;
  delivery_neighborhood: string | null;
  delivery_landmark: string | null;
  delivery_house_details: string | null;
  driver_id: string | null;
  subtotal_tzs: number;
  delivery_fee_tzs: number;
  total_amount_tzs: number;
  payment_method: 'cod' | 'lipa_namba' | 'mobile_money';
  payment_status: 'pending' | 'paid' | 'failed';
  branch_id?: string | null;
  failed_pickup_attempts?: number;
  created_at: string;
  order_items: OrderItem[];
  customer?: { full_name: string | null } | null;
  driver?: { full_name: string | null; phone: string | null } | null;
}

export interface DriverProfile {
  id: string;
  full_name: string | null;
  phone: string | null;
}
