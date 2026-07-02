import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diacritic/diacritic.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/logic/text_utils.dart';
import '../../core/widgets/async_view.dart';
import '../auth/auth_controller.dart';
import '../live/live_providers.dart';
import '../vod/vod_providers.dart';
import '../series/series_providers.dart';
import 'category_prefs.dart';

/// Écran « Gérer les catégories » : liste toutes les catégories du fournisseur
/// pour une section (Live / Films / Séries) et permet de garder/masquer chacune.
/// Sans override, on retombe sur l'heuristique par défaut (FR/Maroc/beIN…).
class CategoryManagerScreen extends ConsumerStatefulWidget {
  final CatSection section;
  const CategoryManagerScreen({super.key, required this.section});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  String _query = '';

  FutureProvider<List<Category>> get _allProvider => switch (widget.section) {
        CatSection.live => liveCategoriesAllProvider,
        CatSection.vod => vodCategoriesAllProvider,
        CatSection.series => seriesCategoriesAllProvider,
      };

  bool Function(String?) get _heuristic =>
      widget.section == CatSection.live ? categoryAllowed : frCategoryAllowed;

  Map<String, bool> _overrides() {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return {};
    return ref.read(prefsProvider).categoryVisibility(prof.id, widget.section.key);
  }

  bool _visible(Category c, Map<String, bool> ov) =>
      categoryVisible(catId: c.id, name: c.name, overrides: ov, heuristic: _heuristic);

  Future<void> _toggle(Category c, bool value) async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    await ref.read(prefsProvider).setCategoryVisible(prof.id, widget.section.key, c.id, value);
    _bump();
  }

  Future<void> _setAll(List<Category> cats, bool value) async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    final vis = {for (final c in cats) c.id: value};
    // On fusionne avec les overrides existants pour ne pas perdre les catégories hors filtre de recherche.
    final merged = Map<String, bool>.from(_overrides())..addAll(vis);
    await ref.read(prefsProvider).setCategoryVisibilityBulk(prof.id, widget.section.key, merged);
    _bump();
  }

  Future<void> _reset() async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    await ref.read(prefsProvider).clearCategoryVisibility(prof.id, widget.section.key);
    _bump();
  }

  void _bump() {
    ref.read(categoryVisibilityTickProvider.notifier).state++;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoryVisibilityTickProvider); // rebuild après toggle
    final ov = _overrides();
    return Scaffold(
      backgroundColor: KtvColors.bg,
      appBar: AppBar(
        backgroundColor: KtvColors.panel,
        title: Text('Catégories · ${widget.section.label}'),
        actions: [
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: AsyncView<List<Category>>(
        value: ref.watch(_allProvider),
        emptyBuilder: () => Center(child: Text('Aucune catégorie', style: TextStyle(color: KtvColors.muted))),
        data: (all) {
          final q = removeDiacritics(_query.toLowerCase()).trim();
          final filtered = q.isEmpty
              ? all
              : all.where((c) => removeDiacritics(c.name.toLowerCase()).contains(q)).toList();
          final shownCount = all.where((c) => _visible(c, ov)).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Filtrer les catégories…',
                          prefixIcon: Icon(Icons.search, size: 20, color: KtvColors.muted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: [
                    Text('$shownCount / ${all.length} affichées', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
                    const Spacer(),
                    TextButton(onPressed: () => _setAll(filtered, true), child: const Text('Tout afficher')),
                    TextButton(onPressed: () => _setAll(filtered, false), child: const Text('Tout masquer')),
                  ],
                ),
              ),
              Divider(height: 1, color: KtvColors.line),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final vis = _visible(c, ov);
                    return SwitchListTile(
                      dense: true,
                      value: vis,
                      onChanged: (v) => _toggle(c, v),
                      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
