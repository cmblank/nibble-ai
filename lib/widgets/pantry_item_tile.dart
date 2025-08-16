import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';
import '../models/pantry_enums.dart';
import '../models/pantry_item.dart';

/// PantryCard – spec-based card for pantry items
/// - Rounded 12, 1px gray300 border, subtle shadow
/// - Left: 12x12 category square + name (bold 14)
/// - Right: status tag (Expiring Soon | Use First) + menu
class PantryCard extends StatelessWidget {
  final PantryItem item;
  final bool showUseFirst;
  final bool showExpiringSoon;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PantryCard({
    super.key,
    required this.item,
    this.showUseFirst = false,
    this.showExpiringSoon = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
  final tag = showUseFirst
    ? const _PantryTag(label: 'Use First', variant: _TagVariant.first)
    : (showExpiringSoon ? const _PantryTag(label: 'Expiring Soon', variant: _TagVariant.soon) : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: BackgroundColors.primary,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: BorderColors.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x0C000000), // 5% black-ish per spec
                blurRadius: 2,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CategoryDot(category: item.category),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.43,
                    color: Colors.black,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              const SizedBox(width: 24),
              if (tag != null) tag,
              const SizedBox(width: 10),
              _MenuButton(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _MenuButton({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: TextStyle(
            color: Colors.black,
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.43,
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        onSelected: (v) {
          if (v == 'edit') onEdit?.call();
          if (v == 'delete') onDelete?.call();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.black), SizedBox(width: 8), Text('Edit')]),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete')]),
          ),
        ],
        icon: const Icon(Icons.more_horiz),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final FoodCategory category;
  const _CategoryDot({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _categoryColor(category),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Basic mapping approximating the design tokens from the spec
  Color _categoryColor(FoodCategory c) {
    switch (c) {
      case FoodCategory.produce:
        return const Color(0xFF54C9A6); // sage-700
      case FoodCategory.dairy:
        return const Color(0xFF87A8F4); // sky-ish
      case FoodCategory.grains:
        return const Color(0xFFF8A23E); // amber-700
      case FoodCategory.protein:
        return DesignTokens.brick900; // strong red for meats
      case FoodCategory.baking:
        return const Color(0xFFB7BEC8); // neutral
      case FoodCategory.herbsAndSpices:
        return const Color(0xFF40BDAA); // teal-ish
      case FoodCategory.bakery:
        return const Color(0xFFEDB660); // golden crust
      case FoodCategory.condiments:
        return const Color(0xFFBF572B); // brick-700
      case FoodCategory.frozenFoods:
        return const Color(0xFF2B87E8); // blue-700
      case FoodCategory.beverages:
        return const Color(0xFFDE4591); // magenta-700
      case FoodCategory.snacks:
        return const Color(0xFF8B5ADB); // violet-700
      case FoodCategory.other:
        return const Color(0xFF5D50D3); // indigo-700
    }
  }
}

enum _TagVariant { soon, first }

class _PantryTag extends StatelessWidget {
  final String label;
  final _TagVariant variant;
  const _PantryTag({required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      _TagVariant.soon => (const Color(0xFFF0FAF7), const Color(0xFF319B7B)), // sage-200 / sage-1000
      _TagVariant.first => (const Color(0xFFF6EEFB), const Color(0xFF5923A4)), // violet-200 / violet-1000
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.33,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }
}

/// Backwards-compatible wrapper so existing imports keep working.
class PantryItemTile extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const PantryItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return PantryCard(
      item: item,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
