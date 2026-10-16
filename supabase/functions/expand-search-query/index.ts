// supabase/functions/expand-search-query/index.ts
// AI-Assisted Bilingual Query Expansion for Quickopia Supermarket

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { captureEdgeError } from '../_shared/sentry.ts';


const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const SYSTEM_INSTRUCTION = `You expand short shopping search queries for a Tanzanian supermarket app.
Input may be in Swahili, English, or mixed.
Output a JSON array of 3-6 short search terms/synonyms (English and Swahili) that a customer might mean, including the original term.
Do not explain, do not add commentary, output ONLY a valid JSON array of strings.
Example: For "sukari" output: ["sukari", "sugar", "white sugar", "brown sugar"]
Example: For "cooking oil" output: ["cooking oil", "mafuta", "sunflower oil", "vegetable oil"]`;

function getPool(poolName: string, singleName: string): string[] {
  const pool = Deno.env.get(poolName);
  if (pool) return pool.split(',').map((s) => s.trim()).filter(Boolean);
  const single = Deno.env.get(singleName);
  return single ? [single.trim()] : [];
}

function extractJsonArray(raw: string, fallbackTerm: string): string[] {
  try {
    // Strip markdown codeblocks if present
    const cleaned = raw.replace(/```json/gi, '').replace(/```/g, '').trim();
    const match = cleaned.match(/\[[\s\S]*\]/);
    if (!match) return [fallbackTerm];

    const parsed = JSON.parse(match[0]);
    if (Array.isArray(parsed) && parsed.length > 0) {
      const sanitized = parsed
        .filter((item) => typeof item === 'string' && item.trim().length > 0)
        .map((item) => item.trim().toLowerCase())
        .slice(0, 6);

      if (!sanitized.includes(fallbackTerm.toLowerCase())) {
        sanitized.unshift(fallbackTerm.toLowerCase());
      }
      return sanitized;
    }
  } catch (e) {
    console.warn('Defensive JSON parse fallback:', e);
  }
  return [fallbackTerm];
}

function isValidSearchTerm(term: string): boolean {
  if (!term || typeof term !== 'string') return false;
  const trimmed = term.trim();
  if (trimmed.length < 2 || trimmed.length > 40) return false;

  // Disallow long sequences of identical characters (e.g., "aaaaa", "zzzzz")
  if (/(.)\1{3,}/.test(trimmed)) return false;

  // Must contain alphanumeric characters (Latin/Swahili text, digits with units like 1kg, 500ml)
  const validPattern = /^[a-zA-Z0-9\s\-'%&.,/]+$/;
  if (!validPattern.test(trimmed)) return false;

  // Must have at least one letter
  if (!/[a-zA-Z]/.test(trimmed)) return false;

  return true;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { query } = await req.json();
    if (!query || typeof query !== 'string' || !isValidSearchTerm(query)) {
      return new Response(
        JSON.stringify({ terms: query && typeof query === 'string' ? [query.trim()] : [] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const normalized = query.trim().toLowerCase();

    // 1. Check Postgres Cache first
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = (Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_ANON_KEY')) ?? '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: cached } = await supabase
      .from('search_query_cache')
      .select('expanded_terms')
      .eq('query_normalized', normalized)
      .maybeSingle();

    if (cached?.expanded_terms && cached.expanded_terms.length > 0) {
      // Increment hit count asynchronously
      supabase.rpc('increment_search_cache_hit', { p_query: normalized }).catch(() => {});

      return new Response(JSON.stringify({ terms: cached.expanded_terms, cached: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Call AI Provider for Query Expansion (pool failover, keys in Supabase Secrets only)
    const groqPool = getPool('GROQ_KEYS', 'GROQ_API_KEY');
    const geminiPool = getPool('GEMINI_KEYS', 'GEMINI_API_KEY');
    const openRouterPool = getPool('OPENROUTER_KEYS', 'OPENROUTER_API_KEY');

    let rawOutput = '';

    for (const groqKey of groqPool) {
      try {
        const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${groqKey}`,
          },
          body: JSON.stringify({
            model: 'openai/gpt-oss-20b',
            messages: [
              { role: 'system', content: SYSTEM_INSTRUCTION },
              { role: 'user', content: `Query: ${normalized}` },
            ],
            temperature: 0.2,
            max_tokens: 120,
          }),
        });

        if (res.ok) {
          const data = await res.json();
          rawOutput = data?.choices?.[0]?.message?.content ?? '';
          if (rawOutput.trim()) break;
        }
      } catch { /* rotate to next key */ }
    }
    if (!rawOutput.trim()) {
      for (const apiKey of geminiPool) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
          const payload = {
            systemInstruction: {
              parts: [{ text: SYSTEM_INSTRUCTION }],
            },
            contents: [
              {
                role: 'user',
                parts: [{ text: `Query: ${normalized}` }],
              },
            ],
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 120,
            },
          };

          const res = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          });

          if (res.ok) {
            const data = await res.json();
            rawOutput = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
            if (rawOutput.trim()) break;
          }
        } catch { /* rotate */ }
      }
    }
    if (!rawOutput.trim()) {
      for (const openRouterKey of openRouterPool) {
        try {
          const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${openRouterKey}`,
            },
            body: JSON.stringify({
              model: 'google/gemini-flash-1.5',
              messages: [
                { role: 'system', content: SYSTEM_INSTRUCTION },
                { role: 'user', content: `Query: ${normalized}` },
              ],
              temperature: 0.2,
              max_tokens: 120,
            }),
          });

          if (res.ok) {
            const data = await res.json();
            rawOutput = data?.choices?.[0]?.message?.content ?? '';
            if (rawOutput.trim()) break;
          }
        } catch { /* rotate */ }
      }
    }

    // 3. Defensive Output Parsing
    const rawExpandedTerms = extractJsonArray(rawOutput, normalized);
    const expandedTerms = rawExpandedTerms.filter(isValidSearchTerm);
    if (expandedTerms.length === 0) {
      expandedTerms.push(normalized);
    }

    // 4. Cache in Postgres for future customers (only sanitized, non-poisoned terms)
    if (expandedTerms.length > 1 && isValidSearchTerm(normalized)) {
      supabase
        .from('search_query_cache')
        .insert({
          query_normalized: normalized,
          expanded_terms: expandedTerms,
        })
        .then(() => {})
        .catch(() => {});
    }

    return new Response(JSON.stringify({ terms: expandedTerms }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: unknown) {
    console.error('expand-search-query error:', err);
    // Noise filtering: do not flood free-tier Sentry with graceful fallback events,
    // only capture unexpected exceptions/crashes
    if (err instanceof TypeError || (err instanceof Error && !err.message.includes('timeout'))) {
      await captureEdgeError(err, { functionName: 'expand-search-query' });
    }
    return new Response(
      JSON.stringify({ terms: [], error: 'Fallback to direct search' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
