import 'dart:io';
import 'package:dio/dio.dart';
import 'package:diacritic/diacritic.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml_events.dart';
import '../../core/logic/text_utils.dart';
import '../../core/models/models.dart';

/// EPG via XMLTV (xmltv.php) : de nombreux fournisseurs bloquent get_short_epg
/// (403) mais exposent le XMLTV. On parse une fois, on indexe par tvg-id et par
/// nom normalisé, puis on résout les programmes now/next par chaîne.
class XmltvIndex {
  final Map<String, List<EpgProgram>> byId; // tvg-id (minuscule) → programmes triés
  final Map<String, String> nameToId; // nom normalisé → tvg-id
  const XmltvIndex(this.byId, this.nameToId);

  // Normalise un nom de chaîne pour le matching : cleanTitle retire préfixes
  // (« FR: », « 4K: »), exposants (ᵁᴴᴰ), tags qualité et parenthèses, puis on
  // réduit à [a-z0-9]. Ainsi « 4K: TF1 ᵁᴴᴰ » et « FR: TF1 (UHD) » → « tf1 ».
  static String norm(String s) =>
      removeDiacritics(cleanTitle(s).toLowerCase()).replaceAll(RegExp(r'[^a-z0-9]+'), '');

  /// Programmes (triés) d'une chaîne : par tvg-id sinon par nom normalisé.
  List<EpgProgram> forChannel(LiveChannel ch) {
    final id = (ch.epgChannelId ?? '').toLowerCase();
    if (id.isNotEmpty && byId.containsKey(id)) return byId[id]!;
    final nid = nameToId[norm(ch.name)];
    if (nid != null) return byId[nid] ?? const [];
    return const [];
  }

  /// now/next à l'instant présent.
  (EpgProgram?, EpgProgram?) nowNext(LiveChannel ch) {
    final progs = forChannel(ch);
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    EpgProgram? now, next;
    for (final p in progs) {
      if (p.start <= t && t < p.stop) {
        now = p;
      } else if (p.start > t) {
        next = p;
        break;
      }
    }
    return (now, next);
  }
}

class XmltvService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(seconds: 40), headers: {'User-Agent': 'KTV'}, responseType: ResponseType.plain));

  static int _ts(String? s) {
    // Format XMLTV : "YYYYMMDDHHMMSS +ZZZZ"
    if (s == null || s.length < 14) return 0;
    try {
      final y = int.parse(s.substring(0, 4)), mo = int.parse(s.substring(4, 6)), d = int.parse(s.substring(6, 8));
      final h = int.parse(s.substring(8, 10)), mi = int.parse(s.substring(10, 12)), se = int.parse(s.substring(12, 14));
      var dt = DateTime.utc(y, mo, d, h, mi, se);
      final tz = RegExp(r'([+-]\d{4})').firstMatch(s);
      if (tz != null) {
        final off = tz.group(1)!;
        final sign = off[0] == '-' ? -1 : 1;
        dt = dt.subtract(Duration(hours: sign * int.parse(off.substring(1, 3)), minutes: sign * int.parse(off.substring(3, 5))));
      }
      return dt.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return 0;
    }
  }

  /// Télécharge (cache disque 6 h) + parse le XMLTV en flux. Ne garde que les
  /// programmes autour de maintenant (−2 h … +2 j) pour limiter la mémoire.
  Future<XmltvIndex> load(String xmltvUrl) async {
    String body = '';
    try {
      final dir = await getApplicationSupportDirectory();
      final cache = File('${dir.path}/xmltv.xml');
      final fresh = cache.existsSync() &&
          DateTime.now().difference(cache.lastModifiedSync()) < const Duration(hours: 6) &&
          cache.lengthSync() > 1000;
      if (fresh) {
        body = await cache.readAsString();
      } else {
        final r = await _dio.get<String>(xmltvUrl);
        body = r.data ?? '';
        if (body.length > 1000) await cache.writeAsString(body, flush: true);
      }
    } catch (_) {
      final r = await _dio.get<String>(xmltvUrl);
      body = r.data ?? '';
    }
    final nowS = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final windowStart = nowS - 7200; // −2 h
    final windowEnd = nowS + 2 * 86400; // +2 j
    final byId = <String, List<EpgProgram>>{};
    final nameToId = <String, String>{};

    String? curChanId; // <channel id=...> en cours (pour display-name)
    final displayNames = <String>[];
    // Programme en cours
    String? pChan, pStart, pStop, textTag;
    final titleBuf = StringBuffer(), descBuf = StringBuffer();

    for (final e in parseEvents(body)) {
      if (e is XmlStartElementEvent) {
        switch (e.name) {
          case 'channel':
            curChanId = e.attributes.firstWhere((a) => a.name == 'id', orElse: () => XmlEventAttribute('id', '', XmlAttributeType.DOUBLE_QUOTE)).value;
            displayNames.clear();
            break;
          case 'display-name':
            if (curChanId != null) textTag = 'dn';
            break;
          case 'programme':
            pChan = e.attributes.firstWhere((a) => a.name == 'channel', orElse: () => XmlEventAttribute('channel', '', XmlAttributeType.DOUBLE_QUOTE)).value;
            pStart = e.attributes.firstWhere((a) => a.name == 'start', orElse: () => XmlEventAttribute('start', '', XmlAttributeType.DOUBLE_QUOTE)).value;
            pStop = e.attributes.firstWhere((a) => a.name == 'stop', orElse: () => XmlEventAttribute('stop', '', XmlAttributeType.DOUBLE_QUOTE)).value;
            titleBuf.clear();
            descBuf.clear();
            break;
          case 'title':
            textTag = 'title';
            break;
          case 'desc':
            textTag = 'desc';
            break;
        }
      } else if (e is XmlTextEvent || e is XmlCDATAEvent) {
        final txt = (e is XmlTextEvent) ? e.value : (e as XmlCDATAEvent).value;
        if (textTag == 'dn' && curChanId != null) {
          displayNames.add(txt.trim());
        } else if (textTag == 'title') {
          titleBuf.write(txt);
        } else if (textTag == 'desc') {
          descBuf.write(txt);
        }
      } else if (e is XmlEndElementEvent) {
        switch (e.name) {
          case 'display-name':
            textTag = null;
            break;
          case 'title':
          case 'desc':
            textTag = null;
            break;
          case 'channel':
            if (curChanId != null && curChanId.isNotEmpty) {
              for (final dn in displayNames) {
                if (dn.isNotEmpty) nameToId.putIfAbsent(XmltvIndex.norm(dn), () => curChanId!.toLowerCase());
              }
            }
            curChanId = null;
            break;
          case 'programme':
            if (pChan != null && pChan.isNotEmpty) {
              final prog = EpgProgram(title: titleBuf.toString().trim(), description: descBuf.toString().trim(), start: _ts(pStart), stop: _ts(pStop));
              // Fenêtre temporelle : on ignore le passé lointain et le futur lointain.
              if (prog.start > 0 && prog.stop >= windowStart && prog.start <= windowEnd) {
                (byId[pChan.toLowerCase()] ??= []).add(prog);
              }
            }
            pChan = pStart = pStop = null;
            break;
        }
      }
    }
    for (final l in byId.values) {
      l.sort((a, b) => a.start.compareTo(b.start));
    }
    return XmltvIndex(byId, nameToId);
  }
}
