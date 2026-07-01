import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../live/live_screen.dart';
import '../vod/vod_screen.dart';
import '../series/series_screen.dart';
import '../guide/guide_screen.dart';
import '../search/search_screen.dart';
import '../search/search_providers.dart';
import '../settings/settings_screen.dart';
import '../home/home_providers.dart';
import '../../services/recording/recording_service.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = int.fromEnvironment('KTV_TAB', defaultValue: 0);
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _dests = [
    (icon: Icons.home_rounded, label: 'Accueil'),
    (icon: Icons.live_tv_rounded, label: 'Live TV'),
    (icon: Icons.movie_rounded, label: 'Films'),
    (icon: Icons.grid_view_rounded, label: 'Séries'),
    (icon: Icons.calendar_view_day_rounded, label: 'Guide'),
    (icon: Icons.settings_rounded, label: 'Réglages'),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = v.trim();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searching = query.length >= 2;
    ref.watch(autoRefreshControllerProvider); // maintient le timer de rafraîchissement actif
    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            controller: _searchCtrl,
            onChanged: _onSearch,
            onClear: _clearSearch,
            recordingCount: ref.watch(recordingControllerProvider).where((r) => r.status == RecStatus.recording).length,
            onRecTap: () {
              _clearSearch();
              setState(() => _index = 5); // Réglages → section Enregistrements
            },
          ),
          Divider(height: 1, color: KtvColors.line),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // rail pleine hauteur → couleur uniforme
              children: [
                _NavRail(index: _index, onSelect: (i) {
                  _clearSearch(); // choisir un onglet quitte les résultats de recherche
                  setState(() => _index = i);
                }),
                VerticalDivider(width: 1, color: KtvColors.line),
                Expanded(
                  child: searching
                      ? const SearchResults()
                      : IndexedStack(
                          index: _index,
                          children: const [
                            HomeScreen(),
                            LiveScreen(),
                            VodScreen(),
                            SeriesScreen(),
                            GuideScreen(),
                            SettingsScreen(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final int recordingCount;
  final VoidCallback onRecTap;
  const _TopBar({required this.controller, required this.onChanged, required this.onClear, this.recordingCount = 0, required this.onRecTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: KtvColors.panel,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(gradient: KtvColors.accentGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('KTV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(width: 20),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher chaînes, films, séries…',
                  prefixIcon: Icon(Icons.search, size: 20, color: KtvColors.muted),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (recordingCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: onRecTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: KtvColors.rec, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.white, size: 13),
                    const SizedBox(width: 6),
                    Text(recordingCount > 1 ? 'REC ×$recordingCount' : 'REC', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _NavRail({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: KtvColors.panel,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            for (var i = 0; i < _HomeShellState._dests.length; i++)
              _NavItem(
                icon: _HomeShellState._dests[i].icon,
                label: _HomeShellState._dests[i].label,
                active: i == index,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: active ? KtvColors.panel2 : null, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: active ? KtvColors.accent : KtvColors.muted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: active ? KtvColors.txt : KtvColors.muted)),
          ],
        ),
      ),
    );
  }
}
