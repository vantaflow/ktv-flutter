// Port Dart de lib/format.js + fmtClock — formatage de durées.

/// Temps restant compact : « ⏳ 1 h 05 » / « ⏳ 12 min ».
String fmtRemaining(num sec) {
  var s = sec.round();
  if (s < 0) s = 0;
  final h = s ~/ 3600;
  final m = ((s % 3600) / 60).round();
  if (h > 0) return '⏳ $h h ${m.toString().padLeft(2, '0')}';
  return '⏳ $m min';
}

/// Horloge « mm:ss » (< 1 h) ou « h:mm:ss ».
String fmtClock(num sec) {
  var s = sec.round();
  if (s < 0) s = 0;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final ss = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(ss)}' : '${two(m)}:${two(ss)}';
}
