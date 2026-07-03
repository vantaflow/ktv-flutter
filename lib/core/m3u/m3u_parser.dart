/// Parseur de playlist M3U/M3U8 (logique pure, testée).
/// Extrait les entrées `#EXTINF` : nom affiché, URL, logo (tvg-logo),
/// identifiant EPG (tvg-id) et groupe (group-title, ou #EXTGRP en repli).
library;

class M3uEntry {
  final String name;
  final String url;
  final String? logo;
  final String? tvgId;
  final String? group;
  const M3uEntry({required this.name, required this.url, this.logo, this.tvgId, this.group});
}

final _attrRe = RegExp(r'([A-Za-z0-9_-]+)="([^"]*)"');

/// Parse le contenu texte d'un fichier M3U en liste d'entrées.
/// Tolérant : ignore les lignes vides, les commentaires non pertinents et les
/// entrées sans URL. Le nom est le texte après la dernière virgule de l'EXTINF.
List<M3uEntry> parseM3u(String content) {
  final out = <M3uEntry>[];
  final lines = content.split(RegExp(r'\r?\n'));

  String? name, logo, tvgId, group;
  var pending = false; // un #EXTINF attend son URL

  void reset() {
    name = logo = tvgId = group = null;
    pending = false;
  }

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#EXTINF')) {
      // Attributs clé="valeur" puis nom après la dernière virgule.
      final attrs = {for (final m in _attrRe.allMatches(line)) m.group(1)!.toLowerCase(): m.group(2)!};
      logo = attrs['tvg-logo'];
      tvgId = attrs['tvg-id'];
      group = attrs['group-title'];
      final comma = line.lastIndexOf(',');
      name = comma >= 0 ? line.substring(comma + 1).trim() : '';
      pending = true;
    } else if (line.startsWith('#EXTGRP:')) {
      // Groupe alternatif si group-title absent.
      group ??= line.substring('#EXTGRP:'.length).trim();
    } else if (line.startsWith('#')) {
      // Autre directive (#EXTM3U, #EXTVLCOPT, #KODIPROP…) : ignorée.
      continue;
    } else if (pending) {
      // Ligne URL qui clôt l'entrée courante.
      final n = (name ?? '').isEmpty ? line : name!;
      out.add(M3uEntry(name: n, url: line, logo: logo, tvgId: tvgId, group: group));
      reset();
    }
  }
  return out;
}
