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

/// Écran « Gérer les catégories » pour une section (Live / Films / Séries).
/// Deux modes : **Visibilité** (garder/masquer chaque catégorie du fournisseur)
/// et **Ordre** (glisser-déposer, uniquement sur les catégories actives).
class CategoryManagerScreen extends ConsumerStatefulWidget {
  final CatSection section;
  const CategoryManagerScreen({super.key, required this.section});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  String _query = '';
  int _mode = 0; // 0 = visibilité, 1 = ordre

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

  List<String> _order() {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return const [];
    return ref.read(prefsProvider).categoryOrder(prof.id, widget.section.key);
  }

  bool _visible(Category c, Map<String, bool> ov) =>
      categoryVisible(catId: c.id, name: c.name, overrides: ov, heuristic: _heuristic);

  /// Catégories actives (visibles) dans l'ordre effectif.
  List<Category> _activeOrdered(List<Category> all) {
    final ov = _overrides();
    final visible = all.where((c) => _visible(c, ov)).toList();
    return orderCategories(visible, _order());
  }

  Future<void> _toggle(Category c, bool value) async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    await ref.read(prefsProvider).setCategoryVisible(prof.id, widget.section.key, c.id, value);
    _bump();
  }

  Future<void> _setAll(List<Category> cats, bool value) async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    final merged = Map<String, bool>.from(_overrides())..addAll({for (final c in cats) c.id: value});
    await ref.read(prefsProvider).setCategoryVisibilityBulk(prof.id, widget.section.key, merged);
    _bump();
  }

  Future<void> _saveOrder(List<Category> active) async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    await ref.read(prefsProvider).setCategoryOrder(prof.id, widget.section.key, [for (final c in active) c.id]);
    _bump();
  }

  Future<void> _reset() async {
    final prof = ref.read(authControllerProvider);
    if (prof == null) return;
    final prefs = ref.read(prefsProvider);
    await prefs.clearCategoryVisibility(prof.id, widget.section.key);
    await prefs.clearCategoryOrder(prof.id, widget.section.key);
    _bump();
  }

  void _bump() {
    ref.read(categoryVisibilityTickProvider.notifier).state++;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoryVisibilityTickProvider);
    return Scaffold(
      backgroundColor: KtvColors.bg,
      appBar: AppBar(
        backgroundColor: KtvColors.panel,
        title: Text('Catégories · ${widget.section.label}'),
        actions: [
          TextButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt, size: 18), label: const Text('Réinitialiser')),
        ],
      ),
      body: AsyncView<List<Category>>(
        value: ref.watch(_allProvider),
        emptyBuilder: () => Center(child: Text('Aucune catégorie', style: TextStyle(color: KtvColors.muted))),
        data: (all) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.visibility_outlined, size: 18), label: Text('Visibilité')),
                  ButtonSegment(value: 1, icon: Icon(Icons.swap_vert, size: 18), label: Text('Ordre')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            Expanded(child: _mode == 0 ? _visibilityView(all) : _orderView(all)),
          ],
        ),
      ),
    );
  }

  // --- Mode Visibilité : toutes les catégories + interrupteurs ---
  Widget _visibilityView(List<Category> all) {
    final ov = _overrides();
    final q = removeDiacritics(_query.toLowerCase()).trim();
    final filtered = q.isEmpty ? all : all.where((c) => removeDiacritics(c.name.toLowerCase()).contains(q)).toList();
    final shownCount = all.where((c) => _visible(c, ov)).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            Text('$shownCount / ${all.length} affichées', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
            const Spacer(),
            TextButton(onPressed: () => _setAll(filtered, true), child: const Text('Tout afficher')),
            TextButton(onPressed: () => _setAll(filtered, false), child: const Text('Tout masquer')),
          ]),
        ),
        Divider(height: 1, color: KtvColors.line),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final c = filtered[i];
              return SwitchListTile(
                dense: true,
                value: _visible(c, ov),
                onChanged: (v) => _toggle(c, v),
                title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Mode Ordre : seulement les catégories actives, glisser-déposer ---
  Widget _orderView(List<Category> all) {
    final active = _activeOrdered(all);
    if (active.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Aucune catégorie active.\nActivez-en dans l\'onglet Visibilité.',
              textAlign: TextAlign.center, style: TextStyle(color: KtvColors.muted)),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Glissez pour changer l\'ordre d\'affichage (${active.length} catégories actives).',
                style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
          ),
        ),
        Divider(height: 1, color: KtvColors.line),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: active.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final list = [...active];
              final moved = list.removeAt(oldIndex);
              list.insert(newIndex, moved);
              _saveOrder(list);
            },
            itemBuilder: (_, i) {
              final c = active[i];
              // Toute la ligne est glissable (pas seulement la poignée).
              return ReorderableDragStartListener(
                key: ValueKey(c.id),
                index: i,
                child: ListTile(
                  dense: true,
                  mouseCursor: SystemMouseCursors.grab,
                  leading: Text('${i + 1}', style: TextStyle(color: KtvColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                  trailing: Icon(Icons.drag_handle, color: KtvColors.muted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
