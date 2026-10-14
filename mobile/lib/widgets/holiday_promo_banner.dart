import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'holiday_offers_sheet.dart';
import 'liquid_glass_container.dart';

class HolidayPromoBanner extends StatelessWidget {
  final VoidCallback? onShopOffer;

  const HolidayPromoBanner({super.key, this.onShopOffer});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 16,
      blur: 14,
      borderWidth: 1.2,
      borderColor: AppTheme.accentAmber.withValues(alpha: 0.5),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF07192E).withValues(alpha: 0.90),
          const Color(0xFF0B2545).withValues(alpha: 0.85),
          const Color(0xFF133E68).withValues(alpha: 0.80),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: AppTheme.accentAmber,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'OFA YA SIKUKUU 🎄✨',
                    style: TextStyle(
                      color: AppTheme.accentAmber,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => HolidayOffersSheet.show(context, onShopOffer: onShopOffer),
                child: const Row(
                  children: [
                    Text(
                      'Tazama Zote',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Punguzo la 25% Vyakula vya Sikukuu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mchele, mafuta, nyama na vinywaji baridi.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => HolidayOffersSheet.show(context, onShopOffer: onShopOffer),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentAmber.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.discount_rounded, size: 14, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'SIKUKUU25',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
