'use client';

import React from 'react';

interface QuickopiaLogoProps {
  variant?: 'light' | 'dark';
  className?: string;
  size?: 'sm' | 'md' | 'lg';
  showSubtitle?: boolean;
}

export default function QuickopiaLogo({
  variant = 'light',
  className = '',
  size = 'md',
}: QuickopiaLogoProps) {
  const isDark = variant === 'dark';
  const logoSrc = isDark
    ? '/quickopia_logo_horizontal.svg'
    : '/quickopia_logo_horizontal_white.svg';

  const heights = {
    sm: 'h-8',
    md: 'h-10',
    lg: 'h-12',
  };

  return (
    <div className={`inline-flex items-center select-none ${className}`}>
      <img
        src={logoSrc}
        alt="Quickopia Supermarket"
        className={`${heights[size]} w-auto object-contain`}
      />
    </div>
  );
}
