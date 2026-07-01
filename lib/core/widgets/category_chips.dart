import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Barre horizontale de catégories cliquables (chips), style KTV.
class CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const CategoryChips({super.key, required this.categories, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final active = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: active ? KtvColors.accentGradient : null,
                color: active ? null : KtvColors.panel2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Colors.transparent : KtvColors.line),
              ),
              child: Text(
                c.name,
                style: TextStyle(
                  fontSize: 13,
                  color: active ? Colors.white : KtvColors.txt,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
