/**
 * Plays a short two-tone chime using the Web Audio API — no MP3 file needed.
 * Note: browsers block audio playback before any user interaction with the
 * page has occurred ("autoplay policy"). Once a staff member interacts with
 * the dashboard, subsequent chimes play normally for the session.
 */
export function playNewOrderChime() {
  try {
    if (typeof window === 'undefined') return;
    const AudioCtx =
      window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AudioCtx) return;

    const ctx = new AudioCtx();
    const playTone = (freq: number, start: number, duration: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.frequency.value = freq;
      osc.type = 'sine';
      gain.gain.setValueAtTime(0.15, ctx.currentTime + start);
      gain.gain.exponentialRampToValueAtTime(
        0.001,
        ctx.currentTime + start + duration
      );
      osc.connect(gain).connect(ctx.destination);
      osc.start(ctx.currentTime + start);
      osc.stop(ctx.currentTime + start + duration);
    };

    playTone(880, 0, 0.15);
    playTone(1175, 0.18, 0.2);
  } catch {
    // Silently ignore — a missed chime should not crash the dashboard.
  }
}
