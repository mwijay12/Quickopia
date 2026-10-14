'use client';

import { useState, useEffect, useMemo } from 'react';
import {
  fetchAllProducts,
  fetchAllCategories,
  adjustStockDelta,
  Product,
  Category,
} from '@/lib/catalog';
import {
  CreditCard,
  Receipt,
  Coins,
  Search,
  Trash2,
  Plus,
  Minus,
  Printer,
  ShoppingBag,
  CheckCircle2,
  RotateCcw,
  User,
  Barcode,
  ArrowRight,
  Sparkles,
  Smartphone,
} from 'lucide-react';

interface CartItem {
  product: Product;
  quantity: number;
}

export default function PosPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Cart State
  const [cart, setCart] = useState<CartItem[]>([]);
  const [customerPhone, setCustomerPhone] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'lipa_namba' | 'card'>('cash');
  const [cashTendered, setCashTendered] = useState<number>(0);
  const [lipaProvider, setLipaProvider] = useState<'mpesa' | 'tigo' | 'airtel'>('mpesa');
  const [lipaReference, setLipaReference] = useState('');

  // Processing & Receipt
  const [isCompleting, setIsCompleting] = useState(false);
  const [completedReceipt, setCompletedReceipt] = useState<{
    receiptNumber: string;
    items: CartItem[];
    subtotal: number;
    total: number;
    paymentMethod: string;
    tendered: number;
    change: number;
    reference?: string;
    date: string;
    customerPhone?: string;
  } | null>(null);

  useEffect(() => {
    async function loadData() {
      try {
        const [prodList, catList] = await Promise.all([
          fetchAllProducts(),
          fetchAllCategories(),
        ]);
        setProducts(prodList);
        setCategories(catList);
      } catch (err) {
        console.error('Failed to load POS catalog:', err);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  // Filtered Products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchCat =
        selectedCategory === 'all' || p.category_id === selectedCategory;
      const matchQuery =
        p.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.description &&
          p.description.toLowerCase().includes(searchQuery.toLowerCase()));
      return matchCat && matchQuery;
    });
  }, [products, selectedCategory, searchQuery]);

  // Calculations
  const cartSubtotal = useMemo(() => {
    return cart.reduce(
      (acc, item) => acc + item.product.price_tzs * item.quantity,
      0
    );
  }, [cart]);

  const cartTotal = cartSubtotal; // In supermarket retail in TZ, retail shelf prices include VAT
  const changeDue = Math.max(0, cashTendered - cartTotal);
  const isUnderpaid = paymentMethod === 'cash' && cashTendered > 0 && cashTendered < cartTotal;

  // Cart Operations
  const addToCart = (product: Product) => {
    if (product.stock_quantity <= 0) return;
    setCart((prev) => {
      const existing = prev.find((item) => item.product.id === product.id);
      if (existing) {
        if (existing.quantity >= product.stock_quantity) return prev;
        return prev.map((item) =>
          item.product.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { product, quantity: 1 }];
    });
  };

  const updateQuantity = (productId: string, delta: number) => {
    setCart((prev) => {
      return prev
        .map((item) => {
          if (item.product.id === productId) {
            const nextQty = item.quantity + delta;
            if (nextQty <= 0) return null;
            if (nextQty > item.product.stock_quantity) return item;
            return { ...item, quantity: nextQty };
          }
          return item;
        })
        .filter(Boolean) as CartItem[];
    });
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product.id !== productId));
  };

  const clearCart = () => {
    setCart([]);
    setCashTendered(0);
    setLipaReference('');
    setCustomerPhone('');
  };

  const handleQuickCash = (amount: number) => {
    setCashTendered(amount);
  };

  // Complete Transaction
  const handleCompleteSale = async () => {
    if (cart.length === 0 || isCompleting) return;

    if (paymentMethod === 'cash' && cashTendered < cartTotal) {
      alert(`Amount tendered (TZS ${cashTendered.toLocaleString()}) is less than total due (TZS ${cartTotal.toLocaleString()}).`);
      return;
    }

    if (paymentMethod === 'lipa_namba' && !lipaReference.trim()) {
      alert('Please enter the Lipa Namba M-Pesa/Tigo/Airtel transaction confirmation code.');
      return;
    }

    setIsCompleting(true);

    try {
      // Decrement stock in catalog for all items
      for (const item of cart) {
        await adjustStockDelta(item.product.id, -item.quantity);
      }

      // Update local product stock
      setProducts((prev) =>
        prev.map((p) => {
          const inCart = cart.find((c) => c.product.id === p.id);
          if (inCart) {
            return {
              ...p,
              stock_quantity: Math.max(0, p.stock_quantity - inCart.quantity),
            };
          }
          return p;
        })
      );

      const receiptNum = `POS-${Date.now().toString().slice(-6)}`;
      const nowStr = new Date().toLocaleString('en-GB', {
        dateStyle: 'medium',
        timeStyle: 'short',
      });

      setCompletedReceipt({
        receiptNumber: receiptNum,
        items: [...cart],
        subtotal: cartSubtotal,
        total: cartTotal,
        paymentMethod:
          paymentMethod === 'cash'
            ? 'Cash'
            : paymentMethod === 'lipa_namba'
            ? `Lipa Namba (${lipaProvider.toUpperCase()})`
            : 'Debit/Credit Card',
        tendered: paymentMethod === 'cash' ? cashTendered : cartTotal,
        change: paymentMethod === 'cash' ? changeDue : 0,
        reference: lipaReference.trim() || undefined,
        date: nowStr,
        customerPhone: customerPhone.trim() || undefined,
      });

      clearCart();
    } catch (err) {
      console.error('Failed to complete POS sale:', err);
      alert('An error occurred completing the sale. Stock levels could not be synchronized.');
    } finally {
      setIsCompleting(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 bg-white p-4 rounded-2xl border border-gray-200 shadow-xs">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-quickopia-navy text-quickopia-amber flex items-center justify-center font-black shadow-xs">
            <CreditCard className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-xl font-black text-quickopia-navy flex items-center gap-2">
              Supermarket Counter POS Terminal
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-200">
                Register #01 &bull; Active
              </span>
            </h1>
            <p className="text-xs text-gray-500">
              Fast walk-in billing &bull; Barcode/Search lookup &bull; Lipa Namba &amp; Cash Tender
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 text-xs font-semibold text-gray-600 bg-gray-50 px-3 py-2 rounded-xl border border-gray-200">
          <Barcode className="w-4 h-4 text-quickopia-navy" />
          <span>Shelf Mode: Realtime Stock Sync</span>
        </div>
      </div>

      {/* Main POS Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        {/* Left Column: Product Selection (7 cols) */}
        <div className="lg:col-span-7 space-y-4">
          {/* Search & Category Filter */}
          <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs space-y-3">
            <div className="relative">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Scan barcode or type product name (e.g., Milk, Rice, Sugar, Soap)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-quickopia-amber focus:bg-white transition"
              />
            </div>

            {/* Category Pills */}
            <div className="flex gap-1.5 overflow-x-auto pb-1 text-xs font-bold scrollbar-none">
              <button
                type="button"
                onClick={() => setSelectedCategory('all')}
                className={`px-3 py-1.5 rounded-lg whitespace-nowrap transition ${
                  selectedCategory === 'all'
                    ? 'bg-quickopia-navy text-white shadow-xs'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                All Shelf Goods ({products.length})
              </button>
              {categories.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => setSelectedCategory(c.id)}
                  className={`px-3 py-1.5 rounded-lg whitespace-nowrap transition ${
                    selectedCategory === c.id
                      ? 'bg-quickopia-navy text-white shadow-xs'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {c.name}
                </button>
              ))}
            </div>
          </div>

          {/* Product Grid */}
          <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs min-h-[440px]">
            {loading ? (
              <div className="py-24 text-center text-gray-400 text-sm">
                Loading supermarket inventory...
              </div>
            ) : filteredProducts.length === 0 ? (
              <div className="py-24 text-center text-gray-400 text-sm">
                No matching supermarket products found on shelves.
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3">
                {filteredProducts.map((prod) => {
                  const isOutOfStock = prod.stock_quantity <= 0;
                  const inCartItem = cart.find((i) => i.product.id === prod.id);

                  return (
                    <div
                      key={prod.id}
                      onClick={() => !isOutOfStock && addToCart(prod)}
                      className={`relative border rounded-xl p-3 flex flex-col justify-between transition group text-left select-none ${
                        isOutOfStock
                          ? 'opacity-50 bg-gray-50 border-gray-200 cursor-not-allowed'
                          : 'cursor-pointer hover:border-quickopia-amber hover:shadow-md bg-white border-gray-200'
                      }`}
                    >
                      {inCartItem && (
                        <span className="absolute -top-2 -right-2 bg-quickopia-navy text-quickopia-amber text-[10px] font-black w-6 h-6 rounded-full flex items-center justify-center shadow-sm">
                          {inCartItem.quantity}
                        </span>
                      )}

                      <div className="space-y-2">
                        <div className="w-full h-24 bg-gray-100 rounded-lg overflow-hidden flex items-center justify-center">
                          {prod.image_url ? (
                            <img
                              src={prod.image_url}
                              alt={prod.title}
                              className="w-full h-full object-cover group-hover:scale-105 transition duration-200"
                            />
                          ) : (
                            <ShoppingBag className="w-8 h-8 text-gray-300" />
                          )}
                        </div>

                        <div>
                          <p className="text-xs font-bold text-gray-900 line-clamp-2 leading-tight">
                            {prod.title}
                          </p>
                          {prod.unit && (
                            <p className="text-[11px] text-gray-400 mt-0.5">
                              {prod.unit}
                            </p>
                          )}
                        </div>
                      </div>

                      <div className="mt-2.5 pt-2 border-t border-gray-100 flex items-center justify-between">
                        <div>
                          <p className="text-xs font-black text-quickopia-navy">
                            TZS {prod.price_tzs.toLocaleString()}
                          </p>
                          <p
                            className={`text-[10px] font-semibold ${
                              isOutOfStock
                                ? 'text-red-500'
                                : prod.stock_quantity <= 5
                                ? 'text-amber-600'
                                : 'text-gray-400'
                            }`}
                          >
                            {isOutOfStock
                              ? 'Out of stock'
                              : `${prod.stock_quantity} left`}
                          </p>
                        </div>

                        <button
                          type="button"
                          disabled={isOutOfStock}
                          className="w-7 h-7 rounded-lg bg-gray-100 group-hover:bg-quickopia-navy group-hover:text-white text-gray-700 font-bold flex items-center justify-center transition shrink-0"
                        >
                          <Plus className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Active Register Cart & Tender (5 cols) */}
        <div className="lg:col-span-5 space-y-4">
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <Receipt className="w-5 h-5 text-quickopia-navy" />
                <h2 className="text-sm font-bold text-quickopia-navy">
                  Current Register Cart ({cart.reduce((a, b) => a + b.quantity, 0)} items)
                </h2>
              </div>
              {cart.length > 0 && (
                <button
                  type="button"
                  onClick={clearCart}
                  className="text-xs text-red-600 hover:text-red-800 font-semibold flex items-center gap-1"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  Clear Cart
                </button>
              )}
            </div>

            {/* Cart Items List */}
            <div className="max-h-56 overflow-y-auto space-y-2 pr-1">
              {cart.length === 0 ? (
                <div className="py-12 text-center text-gray-400 space-y-1">
                  <ShoppingBag className="w-8 h-8 mx-auto text-gray-300" />
                  <p className="text-xs font-semibold">Cart is currently empty</p>
                  <p className="text-[11px] text-gray-400">
                    Tap shelf products on the left or scan barcodes
                  </p>
                </div>
              ) : (
                cart.map((item) => (
                  <div
                    key={item.product.id}
                    className="p-2.5 bg-gray-50 rounded-xl border border-gray-200/80 flex items-center justify-between gap-3 text-xs"
                  >
                    <div className="flex-1 min-w-0">
                      <p className="font-bold text-gray-900 truncate">
                        {item.product.title}
                      </p>
                      <p className="text-gray-500 text-[11px]">
                        TZS {item.product.price_tzs.toLocaleString()} each
                      </p>
                    </div>

                    <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-lg p-0.5 shrink-0">
                      <button
                        type="button"
                        onClick={() => updateQuantity(item.product.id, -1)}
                        className="w-6 h-6 rounded flex items-center justify-center text-gray-600 hover:bg-gray-100 transition"
                      >
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="w-6 text-center font-bold text-quickopia-navy text-xs">
                        {item.quantity}
                      </span>
                      <button
                        type="button"
                        onClick={() => updateQuantity(item.product.id, 1)}
                        disabled={item.quantity >= item.product.stock_quantity}
                        className="w-6 h-6 rounded flex items-center justify-center text-gray-600 hover:bg-gray-100 disabled:opacity-30 transition"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                    </div>

                    <div className="text-right shrink-0 min-w-[70px]">
                      <p className="font-black text-quickopia-navy">
                        TZS {(item.product.price_tzs * item.quantity).toLocaleString()}
                      </p>
                      <button
                        type="button"
                        onClick={() => removeFromCart(item.product.id)}
                        className="text-[10px] text-gray-400 hover:text-red-600 transition"
                      >
                        Remove
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Totals Breakdown */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5 text-xs">
              <div className="flex justify-between text-gray-600">
                <span>Subtotal</span>
                <span>TZS {cartSubtotal.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-gray-500 text-[11px]">
                <span>VAT (18% inclusive)</span>
                <span>TZS {Math.round((cartSubtotal * 0.18) / 1.18).toLocaleString()}</span>
              </div>
              <div className="pt-2 border-t border-slate-200 flex justify-between text-sm font-black text-quickopia-navy">
                <span>Total Due</span>
                <span className="text-base text-quickopia-amber">
                  TZS {cartTotal.toLocaleString()}
                </span>
              </div>
            </div>

            {/* Customer Phone (Optional Loyalty) */}
            <div>
              <label className="block text-[11px] font-bold text-gray-600 mb-1">
                Walk-in Customer Phone (Optional &bull; Loyalty / SMS Receipt)
              </label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
                <input
                  type="text"
                  placeholder="0712 345 678"
                  value={customerPhone}
                  onChange={(e) => setCustomerPhone(e.target.value)}
                  className="w-full pl-9 pr-3 py-1.5 text-xs bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-quickopia-amber"
                />
              </div>
            </div>

            {/* Payment Method Selector */}
            <div className="space-y-2">
              <label className="block text-[11px] font-bold text-gray-600">
                Select Tender Payment Method
              </label>
              <div className="grid grid-cols-3 gap-2 text-xs font-bold">
                <button
                  type="button"
                  onClick={() => setPaymentMethod('cash')}
                  className={`p-2.5 rounded-xl border flex flex-col items-center gap-1 transition ${
                    paymentMethod === 'cash'
                      ? 'bg-quickopia-navy text-white border-quickopia-navy shadow-xs'
                      : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <Coins className="w-4 h-4 text-quickopia-amber" />
                  <span>Cash Tender</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPaymentMethod('lipa_namba')}
                  className={`p-2.5 rounded-xl border flex flex-col items-center gap-1 transition ${
                    paymentMethod === 'lipa_namba'
                      ? 'bg-quickopia-navy text-white border-quickopia-navy shadow-xs'
                      : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <Smartphone className="w-4 h-4 text-quickopia-amber" />
                  <span>Lipa Namba</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPaymentMethod('card')}
                  className={`p-2.5 rounded-xl border flex flex-col items-center gap-1 transition ${
                    paymentMethod === 'card'
                      ? 'bg-quickopia-navy text-white border-quickopia-navy shadow-xs'
                      : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <CreditCard className="w-4 h-4 text-quickopia-amber" />
                  <span>Debit / POS Card</span>
                </button>
              </div>
            </div>

            {/* Cash Tender Calculation */}
            {paymentMethod === 'cash' && (
              <div className="space-y-2 p-3 bg-amber-50/70 border border-amber-200 rounded-xl text-xs">
                <div className="flex items-center justify-between font-bold text-gray-700">
                  <span>Cash Handed by Customer</span>
                  <input
                    type="number"
                    value={cashTendered || ''}
                    placeholder="Enter amount"
                    onChange={(e) => setCashTendered(Number(e.target.value))}
                    className="w-32 px-2.5 py-1 text-right bg-white border border-amber-300 rounded-lg font-black text-quickopia-navy"
                  />
                </div>

                {/* Quick Tender Shortcuts */}
                <div className="flex flex-wrap gap-1 pt-1">
                  <button
                    type="button"
                    onClick={() => handleQuickCash(cartTotal)}
                    className="px-2 py-1 bg-white border border-amber-300 rounded-md font-bold text-[10px] text-amber-900 hover:bg-amber-100"
                  >
                    Exact (TZS {cartTotal.toLocaleString()})
                  </button>
                  {[5000, 10000, 20000, 50000, 100000].map((amt) => (
                    <button
                      key={amt}
                      type="button"
                      onClick={() => handleQuickCash(amt)}
                      className="px-2 py-1 bg-white border border-amber-300 rounded-md font-bold text-[10px] text-amber-900 hover:bg-amber-100"
                    >
                      {amt.toLocaleString()}
                    </button>
                  ))}
                </div>

                <div className="pt-2 border-t border-amber-200/80 flex items-center justify-between font-bold">
                  <span>Change to Return:</span>
                  <span
                    className={`text-sm font-black ${
                      isUnderpaid ? 'text-red-600' : 'text-emerald-700'
                    }`}
                  >
                    {isUnderpaid
                      ? `Short by TZS ${(cartTotal - cashTendered).toLocaleString()}`
                      : `TZS ${changeDue.toLocaleString()}`}
                  </span>
                </div>
              </div>
            )}

            {/* Lipa Namba Input */}
            {paymentMethod === 'lipa_namba' && (
              <div className="space-y-2 p-3 bg-blue-50/70 border border-blue-200 rounded-xl text-xs">
                <div className="flex gap-2">
                  {(['mpesa', 'tigo', 'airtel'] as const).map((net) => (
                    <button
                      key={net}
                      type="button"
                      onClick={() => setLipaProvider(net)}
                      className={`flex-1 py-1 rounded-md font-bold uppercase text-[10px] border ${
                        lipaProvider === net
                          ? 'bg-blue-600 text-white border-blue-600'
                          : 'bg-white text-blue-900 border-blue-200'
                      }`}
                    >
                      {net === 'mpesa' ? 'M-Pesa (Vodacom)' : net === 'tigo' ? 'Mixx (Tigo)' : 'Airtel Money'}
                    </button>
                  ))}
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-blue-900 mb-1">
                    Customer Transaction Ref ID (SMS Confirmation)
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 9JA76BV2C1"
                    value={lipaReference}
                    onChange={(e) => setLipaReference(e.target.value.toUpperCase())}
                    className="w-full px-2.5 py-1.5 bg-white border border-blue-300 rounded-lg font-mono text-xs uppercase"
                  />
                </div>
              </div>
            )}

            {/* Complete Sale Button */}
            <button
              type="button"
              disabled={cart.length === 0 || isCompleting || isUnderpaid}
              onClick={handleCompleteSale}
              className="w-full py-3.5 bg-quickopia-navy hover:bg-slate-900 text-white font-black text-sm rounded-xl shadow-md disabled:opacity-40 transition flex items-center justify-center gap-2 group"
            >
              {isCompleting ? (
                <span>Syncing Inventory &amp; Generating Receipt...</span>
              ) : (
                <>
                  <CheckCircle2 className="w-4 h-4 text-quickopia-amber group-hover:scale-110 transition-transform" />
                  <span>
                    Complete Sale &bull; TZS {cartTotal.toLocaleString()}
                  </span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Thermal Receipt Modal */}
      {completedReceipt && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4 backdrop-blur-xs animate-in fade-in duration-150">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl border border-gray-200 space-y-4">
            {/* Printable Area */}
            <div className="font-mono text-xs text-gray-800 space-y-3 p-4 bg-gray-50 border border-dashed border-gray-300 rounded-xl print:m-0 print:border-none">
              <div className="text-center space-y-1 pb-3 border-b border-dashed border-gray-300">
                <p className="font-black text-sm tracking-wider uppercase">
                  QUICKOPIA SUPERMARKET
                </p>
                <p className="text-[10px] text-gray-600">
                  Dar es Salaam Central Branch #01
                </p>
                <p className="text-[10px] text-gray-600">TIN: 142-998-310 &bull; VRN: 40019283</p>
                <p className="text-[10px] text-gray-600">{completedReceipt.date}</p>
                <p className="font-bold text-[11px] text-quickopia-navy mt-1">
                  TAX INVOICE / RECEIPT #{completedReceipt.receiptNumber}
                </p>
              </div>

              {/* Items */}
              <div className="space-y-1.5 py-2 border-b border-dashed border-gray-300">
                {completedReceipt.items.map((item) => (
                  <div key={item.product.id} className="flex justify-between items-start text-[11px]">
                    <div className="flex-1">
                      <p className="font-bold">{item.product.title}</p>
                      <p className="text-gray-500 text-[10px]">
                        {item.quantity} &times; TZS {item.product.price_tzs.toLocaleString()}
                      </p>
                    </div>
                    <p className="font-bold shrink-0">
                      TZS {(item.quantity * item.product.price_tzs).toLocaleString()}
                    </p>
                  </div>
                ))}
              </div>

              {/* Totals */}
              <div className="space-y-1 pt-1 text-[11px]">
                <div className="flex justify-between">
                  <span>TOTAL AMOUNT:</span>
                  <span className="font-black text-xs">
                    TZS {completedReceipt.total.toLocaleString()}
                  </span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>PAYMENT METHOD:</span>
                  <span>{completedReceipt.paymentMethod}</span>
                </div>
                {completedReceipt.reference && (
                  <div className="flex justify-between text-gray-600">
                    <span>TRANSACTION REF:</span>
                    <span>{completedReceipt.reference}</span>
                  </div>
                )}
                {completedReceipt.tendered > 0 && (
                  <>
                    <div className="flex justify-between text-gray-600">
                      <span>CASH TENDERED:</span>
                      <span>TZS {completedReceipt.tendered.toLocaleString()}</span>
                    </div>
                    <div className="flex justify-between font-bold text-gray-800">
                      <span>CHANGE GIVEN:</span>
                      <span>TZS {completedReceipt.change.toLocaleString()}</span>
                    </div>
                  </>
                )}
              </div>

              <div className="text-center pt-3 border-t border-dashed border-gray-300 space-y-1">
                <p className="font-bold text-[10px]">
                  ASANTE KWA KUFANYA MANUNUZI NASI!
                </p>
                <p className="text-[9px] text-gray-500">
                  Goods once sold in good condition are not returnable without receipt.
                </p>
                <div className="pt-2 flex justify-center">
                  <div className="font-mono text-[9px] tracking-widest bg-white px-3 py-1 border border-gray-300 rounded">
                    ||||| ||| |||||| |||| | ||||||||
                  </div>
                </div>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => window.print()}
                className="flex-1 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-800 font-bold text-xs rounded-xl flex items-center justify-center gap-1.5 transition"
              >
                <Printer className="w-4 h-4" />
                <span>Print Receipt</span>
              </button>
              <button
                type="button"
                onClick={() => setCompletedReceipt(null)}
                className="flex-1 py-2.5 bg-quickopia-navy hover:bg-slate-900 text-white font-bold text-xs rounded-xl flex items-center justify-center gap-1.5 transition"
              >
                <span>Next Customer</span>
                <ArrowRight className="w-4 h-4 text-quickopia-amber" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
