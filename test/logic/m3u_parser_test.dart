import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/m3u/m3u_parser.dart';

void main() {
  group('parseM3u', () {
    test('entrée complète avec attributs', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1 tvg-id="france2.fr" tvg-name="France 2" tvg-logo="http://logo/f2.png" group-title="FR| TNT",France 2 HD
http://srv/live/u/p/12345.ts
''';
      final r = parseM3u(m3u);
      expect(r.length, 1);
      expect(r.first.name, 'France 2 HD');
      expect(r.first.url, 'http://srv/live/u/p/12345.ts');
      expect(r.first.tvgId, 'france2.fr');
      expect(r.first.logo, 'http://logo/f2.png');
      expect(r.first.group, 'FR| TNT');
    });

    test('plusieurs entrées', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1 group-title="A",Chaîne 1
http://a/1
#EXTINF:-1 group-title="B",Chaîne 2
http://a/2
''';
      final r = parseM3u(m3u);
      expect(r.map((e) => e.name), ['Chaîne 1', 'Chaîne 2']);
      expect(r.map((e) => e.group), ['A', 'B']);
    });

    test('#EXTGRP en repli de group-title', () {
      const m3u = '''
#EXTINF:-1,Chaîne
#EXTGRP:Sports
http://a/1
''';
      final r = parseM3u(m3u);
      expect(r.single.group, 'Sports');
    });

    test('ignore directives inconnues et lignes vides', () {
      const m3u = '''
#EXTM3U

#EXTINF:-1,Chaîne
#EXTVLCOPT:http-user-agent=Mozilla
#KODIPROP:inputstream=ffmpeg
http://a/1
''';
      final r = parseM3u(m3u);
      expect(r.length, 1);
      expect(r.single.url, 'http://a/1');
    });

    test('EXTINF sans URL → ignoré', () {
      const m3u = '''
#EXTINF:-1,Orpheline
#EXTINF:-1,Valide
http://a/1
''';
      final r = parseM3u(m3u);
      expect(r.length, 1);
      expect(r.single.name, 'Valide');
    });

    test('nom vide → repli sur l\'URL', () {
      const m3u = '''
#EXTINF:-1,
http://a/1
''';
      final r = parseM3u(m3u);
      expect(r.single.name, 'http://a/1');
    });

    test('contenu vide → liste vide', () => expect(parseM3u(''), isEmpty));
  });
}
