import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';
import '../models/pantry_enums.dart';
import 'category_chip.dart';

/// Spec-styled search field matching token colors and measurements
class SpecSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final String hintText;
  const SpecSearchField({
    super.key,
    required this.controller,
    required this.onClear,
    this.hintText = 'Search pantry',
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return FocusTraversalGroup(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: BackgroundColors.primary,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: BorderColors.primary, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: BorderColors.primary, width: 1),
          ),
        ),
      ),
    );
  }
}

/// Reusable header for Pantry: search input + horizontal category chips + filter icon
class PantrySearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterTap;
  final Set<FoodCategory> selectedCategories;
  final ValueChanged<Set<FoodCategory>> onCategoriesChanged;

  const PantrySearchHeader({
    super.key,
    required this.searchController,
    required this.onFilterTap,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BackgroundColors.secondary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SpecSearchField(
                  controller: searchController,
                  onClear: () => searchController.clear(),
                ),
              ),
              const SizedBox(width: 16),
              Tooltip(
                message: 'Filter & sort',
                child: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: onFilterTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CategoryRow(
            selected: selectedCategories,
            onChanged: onCategoriesChanged,
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Set<FoodCategory> selected;
  final ValueChanged<Set<FoodCategory>> onChanged;
  const _CategoryRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categories = FoodCategory.values;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CategoryChip(
              label: 'All',
              selected: selected.isEmpty,
              onTap: () => onChanged(<FoodCategory>{}),
            ),
          ),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CategoryChip(
                  label: cat.display,
                  selected: selected.contains(cat),
                  onTap: () {
                    final next = Set<FoodCategory>.from(selected);
                    if (next.contains(cat)) {
                      next.remove(cat);
                    } else {
                      next.add(cat);
                    }
                    onChanged(next);
                  },
                ),
              )),
        ],
      ),
    );
  }
}
