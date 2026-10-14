import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  return profile?.role === 'admin' ? user : null;
}

const SYSTEM_INSTRUCTION = `You are writing short product descriptions for an online supermarket in Tanzania.
Rules:
- 2 to 3 sentences maximum.
- Plain, informative, factual tone suited to local supermarket shoppers.
- Never invent specifications, health claims, or ingredients not provided in the input.
- Do not use superlatives like "best", "amazing", "ultimate", or "revolutionary".
- Output only the plain description text. No markdown formatting, no bullet points, no quotation marks, no headers.`;

function sanitizeOutput(raw: string): string {
  let text = raw.trim();
  text = text.replace(/^["'`]|["'`]$/g, '').trim();
  text = text.replace(/[*_#`]/g, '');
  text = text.replace(/\s+/g, ' ').trim();
  return text;
}

function getKeys(keyName: string, poolName: string): string[] {
  const pool = process.env[poolName];
  if (pool) {
    return pool.split(',').map((s) => s.trim()).filter(Boolean);
  }
  const single = process.env[keyName];
  return single ? [single.trim()] : [];
}

export async function POST(request: NextRequest) {
  const admin = await requireAdmin();
  if (!admin) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
  }

  const { name, category, keywords } = await request.json();
  if (!name || typeof name !== 'string' || !name.trim()) {
    return NextResponse.json(
      { error: 'Product name is required' },
      { status: 400 }
    );
  }

  const supabase = await createClient();

  // 1. Try calling the Supabase Edge Function first
  try {
    const { data, error } = await supabase.functions.invoke(
      'generate-product-description',
      {
        body: { name, category, keywords },
      }
    );

    if (!error && data?.description) {
      return NextResponse.json({ description: data.description });
    }
  } catch {
    // Edge function not running locally, proceed to multi-provider fallback
  }

  const userPrompt = `Product: ${name.trim()}\nCategory: ${
    category?.trim() || 'General Supermarket'
  }\nKeywords: ${keywords?.trim() || 'none provided'}`;

  // 2. High-Speed Priority 1: Groq LLM Rotation Pool
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
          messages: [
            { role: 'system', content: SYSTEM_INSTRUCTION },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.3,
          max_tokens: 200,
        }),
      });

      if (res.ok) {
        const d = await res.json();
        const raw = d?.choices?.[0]?.message?.content ?? '';
        const cleaned = sanitizeOutput(raw);
        if (cleaned.length >= 15) {
          return NextResponse.json({ description: cleaned, provider: 'groq' });
        }
      }
    } catch {
      // Rotate to next Groq key
    }
  }

  // 3. Priority 2: Gemini Multi-Key Rotation Pool
  const geminiKeys = getKeys('GEMINI_API_KEY', 'GEMINI_KEYS');
  for (const key of geminiKeys) {
    try {
      const isAuthKey = key.startsWith('AQ.');
      const url = isAuthKey
        ? 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent'
        : `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${key}`;

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (isAuthKey) {
        headers['x-goog-api-key'] = key;
      }

      const res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: SYSTEM_INSTRUCTION }] },
          contents: [{ role: 'user', parts: [{ text: userPrompt }] }],
          generationConfig: { temperature: 0.3, maxOutputTokens: 200 },
        }),
      });

      if (res.ok) {
        const d = await res.json();
        const raw = d?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
        const cleaned = sanitizeOutput(raw);
        if (cleaned.length >= 15) {
          return NextResponse.json({ description: cleaned, provider: 'gemini' });
        }
      }
    } catch {
      // Rotate to next Gemini key
    }
  }

  // 4. Priority 3: OpenRouter Multi-Key Rotation Pool
  const openRouterKeys = getKeys('OPENROUTER_API_KEY', 'OPENROUTER_KEYS');
  for (const key of openRouterKeys) {
    try {
      const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${key}`,
        },
        body: JSON.stringify({
          model: 'google/gemini-2.0-flash-exp:free',
          messages: [
            { role: 'system', content: SYSTEM_INSTRUCTION },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.3,
          max_tokens: 200,
        }),
      });

      if (res.ok) {
        const d = await res.json();
        const raw = d?.choices?.[0]?.message?.content ?? '';
        const cleaned = sanitizeOutput(raw);
        if (cleaned.length >= 15) {
          return NextResponse.json({ description: cleaned, provider: 'openrouter' });
        }
      }
    } catch {
      // Rotate to next OpenRouter key
    }
  }

  // 5. Ultimate Fallback Draft (Ensures zero admin disruption)
  const fallbackDraft = `${name.trim()} is available at Quickopia Supermarket. Ideal for your daily household needs in ${
    category || 'the store'
  }, carefully packaged for freshness and prompt delivery.`;

  return NextResponse.json({ description: fallbackDraft, isFallback: true });
}
