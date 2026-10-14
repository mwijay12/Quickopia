import { NextRequest, NextResponse } from 'next/server';

function getKeys(keyName: string, poolName: string): string[] {
  const pool = process.env[poolName];
  if (pool) {
    return pool.split(',').map((s) => s.trim()).filter(Boolean);
  }
  const single = process.env[keyName];
  return single ? [single.trim()] : [];
}

export async function POST(request: NextRequest) {
  try {
    const { text } = await request.json();

    if (!text || typeof text !== 'string') {
      return NextResponse.json({ error: 'Text is required' }, { status: 400 });
    }

    const cleanText = text
      .replace(/\[SEARCH:[^\]]+\]/gi, '')
      .replace(/\[ADD_TO_CART:[^\]]+\]/gi, '')
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
            text: cleanText.slice(0, 300),
            model_id: 'eleven_multilingual_v2',
            voice_settings: {
              stability: 0.5,
              similarity_boost: 0.75,
            },
          }),
        });

        if (res.ok) {
          const audioBuffer = await res.arrayBuffer();
          return new NextResponse(audioBuffer, {
            headers: {
              'Content-Type': 'audio/mpeg',
              'Content-Length': audioBuffer.byteLength.toString(),
            },
          });
        }
      } catch {
        continue;
      }
    }

    return NextResponse.json(
      { error: 'All ElevenLabs voice keys exceeded quota or unavailable' },
      { status: 429 }
    );
  } catch (err) {
    return NextResponse.json({ error: `Internal server error: ${err}` }, { status: 500 });
  }
}
