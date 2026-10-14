import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickopiaLogo extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool showSubtitle;

  const QuickopiaLogo({
    super.key,
    this.size = 28.0,
    this.isDark = false,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.primaryNavy : Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Official Brand Icon Emblem
        SizedBox(
          width: size * 1.35,
          height: size * 1.35,
          child: Image.asset(
            'assets/icons/icon.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), AppTheme.accentAmber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(size * 0.35),
              ),
              child: Icon(
                Icons.shopping_cart_rounded,
                size: size * 0.75,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Wordmark
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
                children: const [
                  TextSpan(text: 'Quick'),
                  TextSpan(
                    text: 'opia',
                    style: TextStyle(color: Color(0xFFFF6C00)),
                  ),
                ],
              ),
            ),
            if (showSubtitle)
              Text(
                'SUPERMARKET DIRECT',
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? AppTheme.neutralGray : Colors.white70,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
