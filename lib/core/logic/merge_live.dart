import '../models/models.dart';
import 'text_utils.dart';

/// Une chaîne d'une source donnée, avec le NOM de sa catégorie d'origine
/// (nécessaire pour fusionner les catégories entre sources par nom normalisé).
typedef SourcedChannel = ({String sourceId, LiveChannel ch, String catName});

/// Résultat de la fusion multi-sources : chaînes dédoublonnées + catégories
/// fusionnées (par nom normalisé).
class MergedLive {
  final List<LiveChannel> channels;
  final List<Category> categories;
  const MergedLive(this.channels, this.categories);
}

/// Id de catégorie fusionnée (stable) à partir d'un nom de catégorie.
String mergedCatId(String catName) {
  final n = ktvNormTitle(catName);
  return 'm::${n.isEmpty ? 'autres' : n}';
}

/// Clé de dédoublonnage d'une chaîne : tvg-id si présent, sinon nom normalisé.
String dedupKey(LiveChannel ch) {
  final tvg = (ch.epgChannelId ?? '').trim().toLowerCase();
  if (tvg.isNotEmpty) return 'tvg:$tvg';
  return 'name:${ktvNormTitle(ch.name)}';
}

/// Fusionne les chaînes de plusieurs sources :
/// - regroupe les catégories par nom normalisé (id `m::<norm>`) ;
/// - dédoublonne les chaînes identiques (même tvg-id sinon même nom normalisé) :
///   la 1re rencontrée est la représentante (source primaire), les suivantes
///   deviennent des `alts` (sources de secours pour le failover).
/// L'ordre des sources en entrée = priorité (la 1re source est préférée).
MergedLive mergeLive(List<SourcedChannel> items) {
  final byKey = <String, LiveChannel>{};
  final altsByKey = <String, List<({String sourceId, String streamId})>>{};
  final order = <String>[]; // ordre d'apparition des chaînes
  final catNames = <String, String>{}; // mergedCatId → nom d'affichage
  final catOrder = <String>[];

  for (final it in items) {
    final mcat = mergedCatId(it.catName);
    if (!catNames.containsKey(mcat)) {
      catNames[mcat] = it.catName.trim().isEmpty ? 'Autres' : it.catName.trim();
      catOrder.add(mcat);
    }
    final key = dedupKey(it.ch);
    if (!byKey.containsKey(key)) {
      byKey[key] = it.ch.copyWith(sourceId: it.sourceId, categoryId: mcat);
      altsByKey[key] = [];
      order.add(key);
    } else {
      // Doublon → source de secours.
      altsByKey[key]!.add((sourceId: it.sourceId, streamId: it.ch.streamId));
    }
  }

  final channels = [
    for (final key in order) byKey[key]!.copyWith(alts: altsByKey[key]),
  ];
  final categories = [for (final id in catOrder) Category(id, catNames[id]!)];
  return MergedLive(channels, categories);
}
