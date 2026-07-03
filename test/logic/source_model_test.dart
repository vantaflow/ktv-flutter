import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/models/models.dart';

void main() {
  group('XtreamProfile — rétrocompat', () {
    test('JSON sans kind → xtream', () {
      final p = XtreamProfile.fromJson({'id': 'x|u', 'label': 'L', 'srv': 'http://x', 'usr': 'u', 'pwd': 'p'});
      expect(p.kind, SourceKind.xtream);
      expect(p.isM3u, isFalse);
    });
    test('create() reste xtream', () {
      expect(XtreamProfile.create('http://x/', 'u', 'p').kind, SourceKind.xtream);
    });
  });

  group('XtreamProfile — M3U', () {
    test('createM3u : id dérivé de l\'URL, kind m3u', () {
      final p = XtreamProfile.createM3u('http://host/list.m3u', epgUrl: 'http://host/epg.xml');
      expect(p.isM3u, isTrue);
      expect(p.id, 'm3u|http://host/list.m3u');
      expect(p.m3uUrl, 'http://host/list.m3u');
      expect(p.epgUrl, 'http://host/epg.xml');
      expect(p.label, 'host');
    });
    test('roundtrip JSON conserve kind/m3uUrl/epgUrl', () {
      final p = XtreamProfile.createM3u('http://h/l.m3u8', label: 'Ma liste', epgUrl: 'http://h/e.xml');
      final r = XtreamProfile.fromJson(p.toJson());
      expect(r.kind, SourceKind.m3u);
      expect(r.m3uUrl, 'http://h/l.m3u8');
      expect(r.epgUrl, 'http://h/e.xml');
      expect(r.label, 'Ma liste');
    });
    test('toJson xtream n\'ajoute pas les champs m3u', () {
      final j = XtreamProfile.create('http://x', 'u', 'p').toJson();
      expect(j.containsKey('kind'), isFalse);
      expect(j.containsKey('m3uUrl'), isFalse);
    });
  });
}
