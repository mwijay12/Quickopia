import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../theme/app_theme.dart';

class CategoryChipList extends StatelessWidget {
  const CategoryChipList({super.key});

  IconData _getCategoryIcon(String? name) {
    if (name == null) return Icons.grid_view_rounded;
    final lower = name.toLowerCase();
    if (lower.contains('fruit') ||
        lower.contains('vegetable') ||
        lower.contains('produce') ||
        lower.contains('mboga')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('coffee') ||
        lower.contains('kahawa') ||
        lower.contains('beverage') ||
        lower.contains('drink') ||
        lower.contains('juice')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('bakery') ||
        lower.contains('mkate') ||
        lower.contains('pastr') ||
        lower.contains('snack')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('dairy') ||
        lower.contains('maziwa') ||
        lower.contains('egg') ||
        lower.contains('cheese')) {
      return Icons.egg_alt_rounded;
    }
    if (lower.contains('meat') ||
        lower.contains('nyama') ||
        lower.contains('fish') ||
        lower.contains('samaki')) {
      return Icons.set_meal_rounded;
    }
    if (lower.contains('grain') ||
        lower.contains('nafaka') ||
        lower.contains('unga') ||
        lower.contains('rice') ||
        lower.contains('mchele')) {
      return Icons.grass_rounded;
    }
    if (lower.contains('house') ||
        lower.contains('home') ||
        lower.contains('safi') ||
        lower.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.shopping_bag_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          _buildCircleItem(
            context,
            label: 'All',
            id: null,
            icon: Icons.grid_view_rounded,
            selected: catalog.selectedCategoryId == null,
          ),
          ...catalog.categories.map((cat) => _buildCircleItem(
                context,
                label: cat.name,
                id: cat.id,
                icon: _getCategoryIcon(cat.name),
                selected: catalog.selectedCategoryId == cat.id,
              )),
        ],
      ),
    );
  }

  Widget _buildCircleItem(
    BuildContext context, {
    required String label,
    required String? id,
    required IconData icon,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: InkWell(
        onTap: () => context.read<CatalogProvider>().selectCategory(id),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primaryNavy : Colors.white,
                border: Border.all(
                  color: selected ? AppTheme.primaryNavy : Colors.grey.shade300,
                  width: selected ? 2.2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? AppTheme.primaryNavy.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 62,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primaryNavy : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

