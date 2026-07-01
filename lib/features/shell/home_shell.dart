import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../live/live_screen.dart';
import '../vod/vod_screen.dart';
import '../series/series_screen.dart';
import '../guide/guide_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = int.fromEnvironment('KTV_TAB', defaultValue: 0);

  static const _dests = [
    (icon: Icons.home_rounded, label: 'Accueil'),
    (icon: Icons.live_tv_rounded, label: 'Live TV'),
    (icon: Icons.movie_rounded, label: 'Films'),
    (icon: Icons.grid_view_rounded, label: 'Séries'),
    (icon: Icons.calendar_view_day_rounded, label: 'Guide'),
    (icon: Icons.search_rounded, label: 'Recherche'),
    (icon: Icons.settings_rounded, label: 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _NavRail(index: _index, onSelect: (i) => setState(() => _index = i)),
          const VerticalDivider(width: 1, color: KtvColors.line),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                HomeScreen(),
                LiveScreen(),
                VodScreen(),
                SeriesScreen(),
                GuideScreen(),
                SearchScreen(),
                SettingsScreen(),
              ],
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
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(gradient: KtvColors.accentGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
          ),
        ],
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
        decoration: BoxDecoration(
          color: active ? KtvColors.panel2 : null,
          borderRadius: BorderRadius.circular(12),
        ),
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
