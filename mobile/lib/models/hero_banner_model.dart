import 'package:flutter/material.dart';

class HeroBannerSlide {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final String iconName;
  final List<Color> gradient;
  final Color badgeColor;
  final String? imageUrl;
  final String? targetCategory; // Category ID or category keyword (e.g. 'Fresh Produce', 'veggies')

  const HeroBannerSlide({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    this.iconName = 'electric_bolt',
    required this.gradient,
    required this.badgeColor,
    this.imageUrl,
    this.targetCategory,
  });

  HeroBannerSlide copyWith({
    String? id,
    String? tag,
    String? title,
    String? subtitle,
    String? actionLabel,
    IconData? icon,
    String? iconName,
    List<Color>? gradient,
    Color? badgeColor,
    String? imageUrl,
    String? targetCategory,
  }) {
    return HeroBannerSlide(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actionLabel: actionLabel ?? this.actionLabel,
      icon: icon ?? this.icon,
      iconName: iconName ?? this.iconName,
      gradient: gradient ?? this.gradient,
      badgeColor: badgeColor ?? this.badgeColor,
      imageUrl: imageUrl ?? this.imageUrl,
      targetCategory: targetCategory ?? this.targetCategory,
    );
  }

  static IconData getIconByName(String? name) {
    switch (name?.toLowerCase()) {
      case 'eco':
      case 'vegetables':
      case 'veggies':
      case 'produce':
      case 'mboga':
        return Icons.eco_rounded;
      case 'storefront':
      case 'store':
      case 'shop':
        return Icons.storefront_rounded;
      case 'local_offer':
      case 'offer':
      case 'deals':
      case 'discount':
        return Icons.local_offer_rounded;
      case 'local_drink':
      case 'drink':
      case 'beverage':
        return Icons.local_drink_rounded;
      case 'bakery_dining':
      case 'bakery':
      case 'bread':
        return Icons.bakery_dining_rounded;
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'cleaning_services':
      case 'clean':
        return Icons.cleaning_services_rounded;
      case 'electric_bolt':
      case 'express':
      case 'flash':
      default:
        return Icons.electric_bolt_rounded;
    }
  }

  static String getIconName(IconData icon) {
    if (icon == Icons.eco_rounded) return 'eco';
    if (icon == Icons.storefront_rounded) return 'storefront';
    if (icon == Icons.local_offer_rounded) return 'local_offer';
    if (icon == Icons.local_drink_rounded) return 'local_drink';
    if (icon == Icons.bakery_dining_rounded) return 'bakery_dining';
    if (icon == Icons.restaurant_rounded) return 'restaurant';
    if (icon == Icons.cleaning_services_rounded) return 'cleaning_services';
    return 'electric_bolt';
  }

  factory HeroBannerSlide.fromMap(Map<String, dynamic> map, [int index = 0]) {
    const gradients = [
      [Color(0xFF0F172A), Color(0xFF1E293B)],
      [Color(0xFF064E3B), Color(0xFF047857)],
      [Color(0xFF7C2D12), Color(0xFF9A3412)],
      [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
      [Color(0xFF581C87), Color(0xFF6B21A8)],
    ];
    const badgeColors = [
      Color(0xFFF5A623),
      Color(0xFF34D399),
      Color(0xFFF97316),
      Color(0xFF60A5FA),
      Color(0xFFA855F7),
    ];
    const defaultIcons = [
      'electric_bolt',
      'storefront',
      'local_offer',
      'local_drink',
      'cleaning_services',
    ];

    final colorIdx = index % gradients.length;
    final iconName = map['icon_name'] as String? ?? defaultIcons[colorIdx];

    return HeroBannerSlide(
      id: map['id']?.toString() ?? 'slide_$index',
      tag: (map['tag'] as String?)?.toUpperCase() ?? 'PROMO',
      title: (map['title'] as String?) ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      actionLabel: (map['button_text'] != null && map['button_text'].toString().isNotEmpty)
          ? '${map['button_text']} ➔'
          : 'ORDER NOW ➔',
      icon: getIconByName(iconName),
      iconName: iconName,
      gradient: gradients[colorIdx],
      badgeColor: badgeColors[colorIdx],
      imageUrl: map['image_url'] as String?,
      targetCategory: map['target_category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag': tag,
      'title': title,
      'subtitle': subtitle,
      'button_text': actionLabel.replaceAll(' ➔', '').trim(),
      'icon_name': iconName,
      'image_url': imageUrl,
      'target_category': targetCategory,
    };
  }

  static const List<HeroBannerSlide> defaultSlides = [
    HeroBannerSlide(
      id: 'slide_1',
      tag: '⚡ 30-MIN EXPRESS DISPATCH',
      title: 'Fresh Groceries\nDelivered in 30 Mins',
      subtitle: 'Fast doorstep delivery across Dar es Salaam.',
      actionLabel: 'ORDER NOW ➔',
      icon: Icons.electric_bolt_rounded,
      iconName: 'electric_bolt',
      gradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
      badgeColor: Color(0xFFF5A623),
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
      targetCategory: null,
    ),
    HeroBannerSlide(
      id: 'slide_2',
      tag: '🥦 FRESH GREENS & VEGGIES',
      title: 'Crisp Farm Veggies\nOrganic & Handpicked',
      subtitle: 'Fresh spinach, cabbages, tomatoes, carrots and local produce.',
      actionLabel: 'EXPLORE VEGGIES ➔',
      icon: Icons.eco_rounded,
      iconName: 'eco',
      gradient: [Color(0xFF064E3B), Color(0xFF047857)],
      badgeColor: Color(0xFF34D399),
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80',
      targetCategory: 'Fresh Produce',
    ),
    HeroBannerSlide(
      id: 'slide_3',
      tag: '🔥 WEEKLY SUPER DEALS',
      title: 'Save Up To 20%\nOn Kitchen Staples',
      subtitle: 'Rice, cooking oil, fresh milk, and bakery essentials.',
      actionLabel: 'EXPLORE DEALS ➔',
      icon: Icons.local_offer_rounded,
      iconName: 'local_offer',
      gradient: [Color(0xFF7C2D12), Color(0xFF9A3412)],
      badgeColor: Color(0xFFF97316),
      imageUrl: 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?w=800&q=80',
      targetCategory: null,
    ),
  ];
}
