import React from 'react';

export default function MetricCard({
  title,
  value,
  subtitle,
  icon,
  badge,
}: {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: React.ReactNode;
  badge?: { text: string; color: 'green' | 'amber' | 'blue' | 'gray' };
}) {
  const badgeClasses = {
    green: 'bg-green-100 text-green-800',
    amber: 'bg-amber-100 text-amber-800',
    blue: 'bg-blue-100 text-blue-800',
    gray: 'bg-gray-100 text-gray-700',
  };

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs flex flex-col justify-between space-y-3">
      <div className="flex justify-between items-start">
        <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
          {title}
        </span>
        {icon && <span className="text-xl">{icon}</span>}
      </div>

      <div>
        <div className="text-2xl font-black text-quickopia-navy tracking-tight">
          {value}
        </div>
        {subtitle && (
          <p className="text-xs text-gray-500 mt-1 font-medium">{subtitle}</p>
        )}
      </div>

      {badge && (
        <div className="pt-1">
          <span
            className={`inline-block text-[10px] font-extrabold px-2 py-0.5 rounded-full ${badgeClasses[badge.color]}`}
          >
            {badge.text}
          </span>
        </div>
      )}
    </div>
  );
}
