'use client';

import React, { useEffect, useState } from 'react';
import { Activity, AlertTriangle, CheckCircle, Clock, RefreshCw, Zap } from 'lucide-react';

interface HeartbeatData {
  status: 'ALIVE' | 'PINGER_STALLED' | 'PAUSED' | 'UNKNOWN';
  last_ping_at?: string;
  seconds_since_last_ping?: number;
  grace_hours_remaining?: number;
  ping_count?: number;
  pinger_id?: string;
}

interface HealthResponse {
  status: string;
  heartbeat?: HeartbeatData;
  latencyMs?: number;
  error?: string;
}

export default function BackendHealthCard() {
  const [data, setData] = useState<HealthResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);

  const fetchHealth = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    try {
      const res = await fetch('/api/system/health');
      const json = await res.json();
      setData(json);
    } catch (e: any) {
      setData({
        status: 'DOWN',
        error: e.message || 'Network error checking health',
      });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchHealth();
    // Poll every 5 minutes in admin console
    const interval = setInterval(() => fetchHealth(), 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="bg-white border border-gray-200 rounded-xl p-4 shadow-sm animate-pulse">
        <div className="h-4 bg-gray-200 rounded w-1/3 mb-2"></div>
        <div className="h-6 bg-gray-200 rounded w-1/2"></div>
      </div>
    );
  }

  const hb = data?.heartbeat;
  const status = hb?.status || (data?.status === 'OK' ? 'ALIVE' : 'UNKNOWN');
  const graceRemaining = hb?.grace_hours_remaining ?? 168;
  const totalGraceHours = 168; // 7 days
  const progressPercent = Math.min(
    100,
    Math.max(0, (graceRemaining / totalGraceHours) * 100)
  );

  const isAlive = status === 'ALIVE';
  const isStalled = status === 'PINGER_STALLED';
  const isPaused = status === 'PAUSED' || data?.status === 'DOWN';

  return (
    <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Activity className="w-5 h-5 text-quickopia-orange" />
          <h3 className="text-sm font-bold text-quickopia-navy uppercase tracking-wider">
            Backend Liveness & Keep-Alive
          </h3>
        </div>

        <div className="flex items-center space-x-2">
          {isAlive && (
            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-800">
              <CheckCircle className="w-3.5 h-3.5 mr-1 text-green-600" />
              ALIVE &bull; PROTECTED
            </span>
          )}
          {isStalled && (
            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
              <AlertTriangle className="w-3.5 h-3.5 mr-1 text-amber-600" />
              PINGER STALLED
            </span>
          )}
          {isPaused && (
            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800">
              <AlertTriangle className="w-3.5 h-3.5 mr-1 text-red-600" />
              PAUSED OR UNREACHABLE
            </span>
          )}

          <button
            onClick={() => fetchHealth(true)}
            disabled={refreshing}
            className="p-1.5 text-gray-400 hover:text-quickopia-navy transition-colors rounded-lg hover:bg-gray-100 disabled:opacity-50"
            title="Refresh health status"
          >
            <RefreshCw
              className={`w-4 h-4 ${refreshing ? 'animate-spin text-quickopia-orange' : ''}`}
            />
          </button>
        </div>
      </div>

      {/* Grace Window Progress Bar */}
      <div className="space-y-1.5">
        <div className="flex justify-between text-xs text-gray-500 font-medium">
          <span>Inactivity Pause Grace Window</span>
          <span>
            {graceRemaining}h remaining ({Math.round(graceRemaining / 24)} days)
          </span>
        </div>
        <div className="w-full bg-gray-100 rounded-full h-2.5 overflow-hidden">
          <div
            className={`h-2.5 rounded-full transition-all duration-500 ${
              isAlive
                ? 'bg-green-500'
                : isStalled
                  ? 'bg-amber-500'
                  : 'bg-red-500'
            }`}
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-3 gap-3 pt-1 border-t border-gray-100 text-xs">
        <div>
          <span className="text-gray-400 block font-medium">DB Latency</span>
          <span className="font-bold text-gray-800 flex items-center mt-0.5">
            <Zap className="w-3 h-3 mr-1 text-amber-500" />
            {data?.latencyMs !== undefined ? `${data.latencyMs} ms` : '—'}
          </span>
        </div>

        <div>
          <span className="text-gray-400 block font-medium">Last Ping</span>
          <span className="font-bold text-gray-800 flex items-center mt-0.5">
            <Clock className="w-3 h-3 mr-1 text-blue-500" />
            {hb?.last_ping_at
              ? new Date(hb.last_ping_at).toLocaleTimeString([], {
                  hour: '2-digit',
                  minute: '2-digit',
                })
              : 'Unknown'}
          </span>
        </div>

        <div>
          <span className="text-gray-400 block font-medium">Total Pings</span>
          <span className="font-bold text-gray-800 mt-0.5 block">
            {hb?.ping_count ? hb.ping_count.toLocaleString() : '1'}
          </span>
        </div>
      </div>

      {isStalled && (
        <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-900 leading-relaxed">
          <strong>Warning:</strong> No keep-alive ping received in &gt; 26 hours.
          Check GitHub Actions workflow status or verify external cron-job.org configuration.
        </div>
      )}
    </div>
  );
}
