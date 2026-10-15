// supabase/functions/ai-assistant/index.ts
// Server-side AI Concierge & Shopping Assistant for Quickopia Supermarket.
// Keeps LLM provider API keys securely in Supabase Secrets — never in the mobile APK.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { captureEdgeError } from '../_shared/sentry.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function getKeys(keyName: string, poolName: string): string[] {
  const pool = Deno.env.get(poolName);
  if (pool) {
    return pool.split(',').map((s) => s.trim()).filter(Boolean);
  }
  const single = Deno.env.get(keyName);
  return single ? [single.trim()] : [];
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { message, history, settings } = await req.json();

    if (!message || typeof message !== 'string') {
      return new Response(
        JSON.stringify({ error: 'Message is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const storeName = settings?.supermarketName || 'Shoppers Supermarket';
    const storeAddress = settings?.branchAddress || 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam';
    const operatingHours = settings?.operatingHours || 'Mon - Sun: 07:30 AM - 10:30 PM';
    const phone = settings?.phone || '+255 712 345 678';
    const email = settings?.email || 'support@quickopia.co.tz';
    const returnHours = settings?.returnWindowHours || 2;

    const systemPrompt = `You are the intelligent AI Concierge & Shopping Assistant for "${storeName}" located at ${storeAddress}, Dar es Salaam, Tanzania.
Operating Hours: ${operatingHours}.
Support Phone: ${phone}. Support Email: ${email}.
Delivery Coverage: All Dar es Salaam wards (Kinondoni, Ilala, Ubungo, Kigamboni, Temeke). Express 30-min delivery.
Payment Options: Official Lipa Namba (M-Pesa, Tigo Pesa, Airtel Money, HaloPesa) and Bank (NMB, CRDB). Cash on Delivery available for verified shoppers.
Perishable Returns Claim Window: ${returnHours} hours of delivery via in-app Live Support.
Mandatory OTP: A 6-digit confirmation code is generated for courier handoff.

Your personality:
- Warm, polite, exceptionally helpful Tanzanian supermarket expert.
- Fluent in both English and Swahili (respond in the language the user addresses you in).
- Concise, clear, and actionable advice without rambling.
- Write in clean, natural conversational text.
- Do NOT use markdown headers (never use ### or ## or #).
- Do NOT use excessive asterisks (never use **** or **).
- Do NOT mention underlying AI providers, models, or APIs (such as Llama, Groq, OpenRouter, or Gemini). You represent ${storeName} directly.
- Use clean bullet points (•) when listing items.

CRITICAL ACTION TAGS:
When you suggest products or answer product requests (e.g. watches, sugar, rice, cooking oil, diapers, milk):
1. Recommend specific items, their typical price in TZS, and pack sizes.
2. Include the tag: [SEARCH: <concise search keyword>] so the app can instantly render interactive product cards for the customer! Example: [SEARCH: watch] or [SEARCH: sugar] or [SEARCH: rice].
3. If the user explicitly asks you to add an item to their cart, output: [ADD_TO_CART: <item name>].
4. If the user asks about tracking an order, output: [TRACK_ORDER].
Always keep the tag at the very end of your message.`;

    const formattedMessages = [
      { role: 'system', content: systemPrompt },
      ...(Array.isArray(history)
        ? history
            .filter((m: any) => m && m.content)
            .slice(-8)
            .map((m: any) => ({
              role: m.role === 'assistant' ? 'assistant' : 'user',
              content: String(m.content),
            }))
        : []),
      { role: 'user', content: message.trim() },
    ];

    let reply: string | null = null;

    // 1. Try Groq Pool (llama-3.3-70b-versatile)
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
            messages: formattedMessages,
            temperature: 0.6,
            max_tokens: 450,
          }),
        });

        if (res.ok) {
          const data = await res.json();
          const content = data.choices?.[0]?.message?.content;
          if (content && content.trim().length > 0) {
            reply = content;
            break;
          }
        }
      } catch (err) {
        console.warn('Groq edge attempt failed:', err);
      }
    }

    // 2. Fallback to Gemini Pool
    if (!reply) {
      const geminiKeys = getKeys('GEMINI_API_KEY', 'GEMINI_KEYS');
      const geminiContents = formattedMessages
        .filter((m) => m.role !== 'system')
        .map((m) => ({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: m.content }],
        }));

      for (const key of geminiKeys) {
        try {
          const res = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${key}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                systemInstruction: { parts: [{ text: systemPrompt }] },
                contents: geminiContents,
                generationConfig: { temperature: 0.6, maxOutputTokens: 450 },
              }),
            }
          );

          if (res.ok) {
            const data = await res.json();
            const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text && text.trim().length > 0) {
              reply = text;
              break;
            }
          }
        } catch (err) {
          console.warn('Gemini edge attempt failed:', err);
        }
      }
    }

    // 3. Fallback to OpenRouter Pool
    if (!reply) {
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
              messages: formattedMessages,
              temperature: 0.6,
              max_tokens: 400,
            }),
          });

          if (res.ok) {
            const data = await res.json();
            const content = data.choices?.[0]?.message?.content;
            if (content && content.trim().length > 0) {
              reply = content;
              break;
            }
          }
        } catch (err) {
          console.warn('OpenRouter edge attempt failed:', err);
        }
      }
    }

    if (!reply) {
      return new Response(
        JSON.stringify({
          error: 'All AI providers are currently busy. Please try again shortly.',
          reply:
            'Samahani, mtandao wa AI unakabiliwa na msongamano kwa sasa. Tafadhali jaribu tena baada ya muda mfupi.',
        }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ reply }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    await captureEdgeError(err, { function: 'ai-assistant' });
    return new Response(
      JSON.stringify({ error: `Internal edge error: ${err}` }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
