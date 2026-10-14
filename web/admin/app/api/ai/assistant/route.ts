import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

function getKeys(keyName: string, poolName: string): string[] {
  const pool = process.env[poolName];
  if (pool) {
    return pool.split(',').map((s) => s.trim()).filter(Boolean);
  }
  const single = process.env[keyName];
  return single ? [single.trim()] : [];
}

function cleanAiReply(text: string): string {
  if (!text) return '';
  return text
    .replace(/^#{1,6}\s*/gm, '')
    .replace(/\*{2,}/g, '')
    .replace(/^\*\s+/gm, '• ')
    .replace(/\b(llama|openrouter|groq)\b/gi, '')
    .trim();
}

export async function POST(request: NextRequest) {
  try {
    const { message, history } = await request.json();

    if (!message || typeof message !== 'string') {
      return NextResponse.json({ error: 'Message is required' }, { status: 400 });
    }

    const supabase = await createClient();
    const { data: settings } = await supabase
      .from('settings')
      .select('*')
      .eq('id', 'branch_settings')
      .maybeSingle();

    const storeName = settings?.supermarket_name || settings?.restaurant_name || 'Shoppers Supermarket';
    const storeAddress = settings?.branch_address || 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam';
    const operatingHours = settings?.operating_hours || 'Mon - Sun: 07:30 AM - 10:30 PM';
    const phone = settings?.phone || '+255 712 345 678';
    const returnHours = settings?.return_window_hours || 2;

    const systemPrompt = `You are the intelligent AI Concierge & Shopping Assistant for "${storeName}" located at ${storeAddress}, Dar es Salaam, Tanzania.
Operating Hours: ${operatingHours}.
Customer Hotline: ${phone}.
Delivery Coverage: All Dar es Salaam wards (Kinondoni, Ilala, Ubungo, Kigamboni, Temeke). 30-minute express delivery.
Payment Options: Lipa Namba (M-Pesa, Tigo Pesa, Airtel Money, HaloPesa) and Bank transfers. Cash on delivery available.
Return Claim Window: ${returnHours} hours for perishable items via in-app Support.

Your personality:
- Warm, polite, exceptionally knowledgeable Tanzanian supermarket shopping guide.
- Fluent in both Swahili and English.
- Suggest items with typical prices in TZS and package sizes.
- Never use markdown headers like ### or ## and never use double asterisks **** or **. Keep formatting clean and readable without raw markdown symbols.
- Never mention internal model names, providers, Llama, Groq, or OpenRouter.

CRITICAL ACTION TAG:
If suggesting products (watches, sugar, flour, oil, diapers, etc.), end your message with:
[SEARCH: <search keyword>] so the customer sees real product cards.
If user asks to add to cart: [ADD_TO_CART: <item>]
`;

    const messages = [
      { role: 'system', content: systemPrompt },
      ...(Array.isArray(history) ? history.slice(-8) : []),
      { role: 'user', content: message.trim() },
    ];

    // Priority 1: Groq Rotation Pool
    const groqKeys = getKeys('GROQ_API_KEY', 'GROQ_KEYS');
    for (const key of groqKeys) {
      try {
        const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${key}`,
          },
          body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages,
            temperature: 0.6,
            max_tokens: 450,
          }),
        });

        if (res.ok) {
          const data = await res.json();
          const reply = data.choices?.[0]?.message?.content;
          if (reply) {
            return NextResponse.json({ reply: cleanAiReply(reply), provider: 'concierge' });
          }
        }
      } catch {
        continue;
      }
    }

    // Priority 2: Google Gemini Rotation Pool (15 keys - AQ. format and AIzaSy)
    const geminiKeys = getKeys('GEMINI_API_KEY', 'GEMINI_KEYS');
    for (const key of geminiKeys) {
      try {
        const geminiContents = (messages || [])
          .filter((m: { role: string }) => m.role !== 'system')
          .map((m: { role: string; content: string }) => ({
            role: m.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: m.content || '' }],
          }));

        if (geminiContents.length === 0) {
          geminiContents.push({ role: 'user', parts: [{ text: message.trim() }] });
        }

        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${key}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              systemInstruction: {
                parts: [{ text: systemPrompt }],
              },
              contents: geminiContents,
              generationConfig: {
                temperature: 0.6,
                maxOutputTokens: 450,
              },
            }),
          }
        );

        if (res.ok) {
          const data = await res.json();
          const reply = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (reply && reply.trim().length > 0) {
            return NextResponse.json({ reply: cleanAiReply(reply), provider: 'concierge' });
          }
        }
      } catch {
        continue;
      }
    }

    // Priority 3: OpenRouter Pool
    const openRouterKeys = getKeys('OPENROUTER_API_KEY', 'OPENROUTER_KEYS');
    for (const key of openRouterKeys) {
      try {
        const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${key}`,
            'HTTP-Referer': 'https://quickopia.app',
            'X-Title': 'Quickopia Supermarket AI',
          },
          body: JSON.stringify({
            model: 'meta-llama/llama-3.2-3b-instruct:free',
            messages,
            temperature: 0.6,
            max_tokens: 400,
          }),
        });

        if (res.ok) {
          const data = await res.json();
          const reply = data.choices?.[0]?.message?.content;
          if (reply) {
            return NextResponse.json({ reply: cleanAiReply(reply), provider: 'concierge' });
          }
        }
      } catch {
        continue;
      }
    }

    return NextResponse.json({
      reply: `Habari! Karibu ${storeName}. Niko hapa kukusaidia kupata bidhaa bora kwenye stoo yetu au kuangalia oda yako.`,
      provider: 'fallback',
    });
  } catch (err) {
    return NextResponse.json({ error: `Internal server error: ${err}` }, { status: 500 });
  }
}
