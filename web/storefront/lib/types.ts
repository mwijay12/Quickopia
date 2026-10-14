export interface Category {
  id: string;
  name: string;
  name_sw: string | null;
  icon: string | null;
  display_order: number;
}

export interface Product {
  id: string;
  category_id: string;
  title: string;
  description: string | null;
  price_tzs: number;
  unit: string | null;
  image_url: string | null;
  stock_quantity: number;
  is_available: boolean;
  is_popular: boolean;
}

export interface Branch {
  id: string;
  name: string;
  city: string;
  neighborhood: string | null;
  landmark: string | null;
  phone: string | null;
}

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
  status: string;
  pickup_code: string;
  subtotal_tzs: number;
  delivery_fee_tzs: number;
  total_amount_tzs: number;
  payment_method: string;
  payment_status: string;
  created_at: string;
  order_items: OrderItem[];
}

export interface CheckoutFormData {
  fulfillmentType: 'delivery' | 'pickup';
  city: string;
  neighborhood: string;
  landmark: string;
  houseDetails: string;
  latitude: number | null;
  longitude: number | null;
  phone: string;
  fullName: string;
  paymentMethod: 'cod' | 'lipa_namba';
}
