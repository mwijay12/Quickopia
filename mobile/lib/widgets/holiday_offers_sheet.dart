import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'liquid_glass_container.dart';

class HolidayOffer {
  final String id;
  final String title;
  final String tag;
  final Color tagColor;
  final String description;
  final String promoCode;
  final String validity;
  final IconData icon;

  const HolidayOffer({
    required this.id,
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.description,
    required this.promoCode,
    required this.validity,
    required this.icon,
  });
}

class HolidayOffersSheet extends StatelessWidget {
  final VoidCallback? onShopOffer;

  const HolidayOffersSheet({super.key, this.onShopOffer});

  static const List<HolidayOffer> holidayOffers = [
    HolidayOffer(
      id: 'h1',
      title: 'Sikukuu Super Feast (25% OFF)',
      tag: '🔥 HOT SIKUKUU DEAL',
      tagColor: Colors.deepOrange,
      description:
          'Punguzo la 25% kwa mahitaji yote ya sikukuu: Mchele wa Super Kyela, Mafuta ya Kupikia, Nyama Choma, na Vinywaji. Usikose ofa hii ya msimu!',
      promoCode: 'SIKUKUU25',
      validity: 'Inaisha Jumapili saa 5:59 usiku',
      icon: Icons.celebration_rounded,
    ),
    HolidayOffer(
      id: 'h2',
      title: 'Usafiri Bure Popote Dar es Salaam',
      tag: '⚡ USARIFI BURE',
      tagColor: Colors.teal,
      description:
          'Oda bidhaa za supermarket kuanzia TZS 30,000 na uletewe mlangoni bila gharama yoyote ya usafiri (Free 30-Min Delivery)!',
      promoCode: 'USAFIRIBURE',
      validity: 'Ofa ya Wikiendi Hii',
      icon: Icons.electric_bolt_rounded,
    ),
    HolidayOffer(
      id: 'h3',
      title: 'Kikapu cha Zawadi (Holiday Gift Hamper)',
      tag: '🎁 POPULAR GIFT',
      tagColor: Colors.purple,
      description:
          'Zawadi bora kwa familia na marafiki. Vifurushi vilivyopakiwa vizuri vyenye biskuti, chokoleti, juisi na kahawa safi kuanzia TZS 45,000.',
      promoCode: 'HAMPER10',
      validity: 'Mpaka mzigo uishe stoo',
      icon: Icons.card_giftcard_rounded,
    ),
    HolidayOffer(
      id: 'h4',
      title: 'Choma & Refreshments Combo',
      tag: '🍗 SUPERMARKET SPECIAL',
      tagColor: Colors.amber,
      description:
          'Nunua kuku au nyama kuanzia kilo 2 upate Soda ya 1.5L au Juisi ya Embe ya bure kabisa!',
      promoCode: 'CHOMACOMBO',
      validity: 'Ofa ya Sikukuu',
      icon: Icons.restaurant_rounded,
    ),
  ];

  static void show(BuildContext context, {VoidCallback? onShopOffer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HolidayOffersSheet(onShopOffer: onShopOffer),
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.accentAmber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Kodi ya Promo "$code" imenakiliwa! Iweke wakati wa kulipia.'),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF07192E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const LiquidGlassContainer(
                  padding: EdgeInsets.all(8),
                  borderRadius: 12,
                  baseColor: AppTheme.accentAmber,
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: AppTheme.accentAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ofa za Sikukuu & Taarifa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Holiday Season Offers & Live Alerts',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // List of offers
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: holidayOffers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final offer = holidayOffers[index];
                return _buildOfferCard(context, offer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, HolidayOffer offer) {
    return LiquidGlassContainer(
      borderRadius: 16,
      blur: 16,
      borderWidth: 1.2,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      offer.tagColor.withValues(alpha: 0.8),
                      offer.tagColor.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(offer.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: offer.tagColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: offer.tagColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        offer.tag,
                        style: TextStyle(
                          color: offer.tagColor.computeLuminance() > 0.4
                              ? AppTheme.accentAmber
                              : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            offer.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppTheme.accentAmber),
              const SizedBox(width: 4),
              Text(
                offer.validity,
                style: const TextStyle(
                  color: AppTheme.accentAmber,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _copyCode(context, offer.promoCode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.discount_outlined, size: 15, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              offer.promoCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'KODI YA OFA',
                          style: TextStyle(
                            color: AppTheme.accentAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.black),
                label: const Text(
                  'Copy & Shop',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _copyCode(context, offer.promoCode);
                  Navigator.pop(context);
                  onShopOffer?.call();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
