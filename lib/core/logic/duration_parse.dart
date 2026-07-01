/// Port Dart de lib/duration-parse.js — durée réelle d'un contenu Xtream en
/// secondes. PRIORITÉ à la chaîne "H:MM:SS"/"MM:SS" (fiable), repli sur
/// duration_secs (certains panels renvoient un duration_secs faux, ex. minutes).
int? parseXtreamDuration(Map<String, dynamic>? info) {
  if (info == null) return null;
  final s = (info['duration']?.toString() ?? '').trim();
  if (s.isNotEmpty) {
    final parts = s.split(':').map((p) => int.tryParse(p.trim())).toList();
    if (parts.length >= 2 && parts.every((p) => p != null)) {
      var total = 0;
      for (final p in parts) {
        total = total * 60 + p!;
      }
      if (total > 0) return total;
    }
  }
  final secs = num.tryParse(info['duration_secs']?.toString() ?? '');
  if (secs != null && secs.isFinite && secs > 0) return secs.toInt();
  return null;
}
