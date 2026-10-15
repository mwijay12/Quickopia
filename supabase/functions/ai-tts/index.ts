// supabase/functions/ai-tts/index.ts
// Server-side ElevenLabs Text-to-Speech proxy for Quickopia Supermarket.
// Keeps ElevenLabs API keys in Supabase Secrets rather than inside the mobile APK.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
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
    const { text } = await req.json();

    if (!text || typeof text !== 'string') {
      return new Response(
        JSON.stringify({ error: 'Text is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const cleanText = text
      .replace(/\[SEARCH:[^\]]+\]/gi, '')
      .replace(/\[ADD_TO_CART:[^\]]+\]/gi, '')
      .replace(/\[TRACK_ORDER\]/gi, '')
      .trim();

    const elevenLabsKeys = getKeys('ELEVENLABS_API_KEY', 'ELEVENLABS_KEYS');
    const voiceId = '21m00Tcm4TlvDq8ikWAM'; // Rachel

    for (const key of elevenLabsKeys) {
      try {
        const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'xi-api-key': key,
            Accept: 'audio/mpeg',
          },
          body: JSON.stringify({
            text: cleanText.length > 280 ? cleanText.slice(0, 280) : cleanText,
            model_id: 'eleven_multilingual_v2',
            voice_settings: {
              stability: 0.5,
              similarity_boost: 0.75,
            },
          }),
        });

        if (res.ok) {
          const audioBuffer = await res.arrayBuffer();
          return new Response(audioBuffer, {
            status: 200,
            headers: {
              ...corsHeaders,
              'Content-Type': 'audio/mpeg',
              'Content-Length': audioBuffer.byteLength.toString(),
            },
          });
        }
      } catch (err) {
        console.warn('ElevenLabs key failed, trying next:', err);
      }
    }

    return new Response(
      JSON.stringify({ error: 'All ElevenLabs voice keys exceeded quota or unavailable' }),
      { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    await captureEdgeError(err, { function: 'ai-tts' });
    return new Response(
      JSON.stringify({ error: `Internal error: ${err}` }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
