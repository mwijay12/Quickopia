import type { CartLine } from '@/context/CartContext';

const formatTzs = (n: number) => `TZS ${n.toLocaleString('en-US')}`;

export function buildWhatsAppOrderUrl(items: CartLine[], subtotal: number): string {
  const phone = process.env.NEXT_PUBLIC_BRANCH_WHATSAPP_NUMBER || '255700000000';
  const lines = items.map(
    (i) =>
      `• ${i.title} (${i.unit ?? 'unit'}) x${i.quantity} — ${formatTzs(i.priceTzs * i.quantity)}`
  );
  const message = [
    'Hello Quickopia! I would like to place an order:',
    '',
    ...lines,
    '',
    `Subtotal: ${formatTzs(subtotal)}`,
    '',
    'Please confirm availability and let me know delivery/pickup options. Thank you!',
  ].join('\n');

  return `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;
}
