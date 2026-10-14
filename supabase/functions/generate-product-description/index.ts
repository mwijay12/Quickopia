// supabase/functions/generate-product-description/index.ts
// Secure AI Product Description Generator for Quickopia Supermarket

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { captureEdgeError } from '../_shared/sentry.ts';


const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

// Rate limiter: max 10 calls per minute per user/IP
const rateLimitMap = new Map<string, number[]>();
function checkRateLimit(key: string): boolean {
  const now = Date.now();
  const windowMs = 60 * 1000;
  const timestamps = (rateLimitMap.get(key) || []).filter(
    (t) => now - t < windowMs
  );
  if (timestamps.length >= 10) {
    return false;
  }
  timestamps.push(now);
  rateLimitMap.set(key, timestamps);
  return true;
}

// System instructions: strict, factual, Tanzanian supermarket tone
const SYSTEM_INSTRUCTION = `You are writing short product descriptions for an online supermarket in Tanzania.
Rules:
- 2 to 3 sentences maximum.
- Plain, informative, factual tone suited to local supermarket shoppers.
- Never invent specifications, health claims, or ingredients not provided in the input.
- Do not use superlatives like "best", "amazing", "ultimate", or "revolutionary".
- Output only the plain description text. No markdown formatting, no bullet points, no quotation marks, no headers.`;

// Modular AI Provider Interface
interface AIProvider {
  generate(systemPrompt: string, userPrompt: string): Promise<string>;
}

class GeminiProvider implements AIProvider {
  private apiKey: string;
  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async generate(systemPrompt: string, userPrompt: string): Promise<string> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${this.apiKey}`;
    const payload = {
      systemInstruction: {
        parts: [{ text: systemPrompt }],
      },
      contents: [
        {
          role: 'user',
          parts: [{ text: userPrompt }],
        },
      ],
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 200,
      },
    };

    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Gemini API error (${res.status}): ${err}`);
    }

    const data = await res.json();
    return data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  }
}

class GroqProvider implements AIProvider {
  private apiKey: string;
  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async generate(systemPrompt: string, userPrompt: string): Promise<string> {
    const url = 'https://api.groq.com/openai/v1/chat/completions';
    const payload = {
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.3,
      max_tokens: 200,
    };

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Groq API error (${res.status}): ${err}`);
    }

    const data = await res.json();
    return data?.choices?.[0]?.message?.content ?? '';
  }
}

class OpenRouterProvider implements AIProvider {
  private apiKey: string;
  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async generate(systemPrompt: string, userPrompt: string): Promise<string> {
    const url = 'https://openrouter.ai/api/v1/chat/completions';
    const payload = {
      model: 'google/gemini-flash-1.5',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.3,
      max_tokens: 200,
    };

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`OpenRouter API error (${res.status}): ${err}`);
    }

    const data = await res.json();
    return data?.choices?.[0]?.message?.content ?? '';
  }
}

function sanitizeOutput(raw: string): string {
  let text = raw.trim();

  // Strip leading and trailing quotes
  text = text.replace(/^["'`]|["'`]$/g, '').trim();

  // Strip common markdown bold/italic/header symbols
  text = text.replace(/[*_#`]/g, '');

  // Collapse multiple spaces or newlines into single spaces
  text = text.replace(/\s+/g, ' ').trim();

  return text;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Auth check: verify admin role
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'admin') {
      return new Response(
        JSON.stringify({ error: 'Only admin staff can generate descriptions' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Rate limiting check
    if (!checkRateLimit(user.id)) {
      return new Response(
        JSON.stringify({
          error: 'Rate limit exceeded. Please wait a minute before generating again.',
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Request parsing & input validation
    const { name, category, keywords } = await req.json();
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Product name is required.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const userPrompt = `Product: ${name.trim()}\nCategory: ${
      category?.trim() || 'General Supermarket'
    }\nKeywords: ${keywords?.trim() || 'none provided'}`;

    // 4. Select AI Provider with fallback
    const groqKey = Deno.env.get('GROQ_API_KEY');
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    const openRouterKey = Deno.env.get('OPENROUTER_API_KEY');

    let provider: AIProvider;
    if (groqKey) {
      provider = new GroqProvider(groqKey);
    } else if (geminiKey) {
      provider = new GeminiProvider(geminiKey);
    } else if (openRouterKey) {
      provider = new OpenRouterProvider(openRouterKey);
    } else {
      return new Response(
        JSON.stringify({
          error: 'AI provider is not configured (missing GROQ_API_KEY or GEMINI_API_KEY).',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 5. Generate and sanitize output
    const rawResult = await provider.generate(SYSTEM_INSTRUCTION, userPrompt);
    const cleaned = sanitizeOutput(rawResult);

    if (cleaned.length < 15 || cleaned.length > 450) {
      return new Response(
        JSON.stringify({
          error:
            'Generated description failed quality check. Please try again with more specific keywords.',
        }),
        { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify({ description: cleaned }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: unknown) {
    await captureEdgeError(err, { functionName: 'generate-product-description' });
    const error = err instanceof Error ? err.message : 'Internal server error';
    return new Response(
      JSON.stringify({ error }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
