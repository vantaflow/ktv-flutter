# KTV — lecteur Xtream (Flutter + media_kit)

Réécriture **Flutter desktop** (macOS + Windows) du lecteur IPTV **KTV**, propulsée par **media_kit / libmpv**.

**▶︎ [Télécharger la dernière version](https://github.com/khalilbenaz/ktv-flutter/releases/latest)** · **[Site](https://khalilbenaz.github.io/ktv-flutter/)**

> Version précédente en Electron : [github.com/khalilbenaz/ktv](https://github.com/khalilbenaz/ktv).

## Pourquoi Flutter + libmpv

Le moteur `<video>` de Chromium (Electron) ne lit pas les MKV/HEVC/multi-pistes servis par l'IPTV VOD, ce qui imposait un relais ffmpeg cassant le seek, la durée, la reprise et la sélection audio/sous-titres. **libmpv (media_kit)** lit tout ça **nativement**, avec **seek instantané** et **pistes audio/sous-titres** — la famille de bugs disparaît.

## Fonctionnalités

- **Connexion Xtream** multi-profils (reconnexion auto)
- **Accueil cinématographique** : Reprendre la lecture · Vu récemment · Chaînes favorites · **Recommandé pour vous** (TMDB, contextuel) · Derniers films/séries ajoutés
- **Live TV** : grille par catégorie (FR), **EPG en cours** + progression, favoris, enregistrement
- **Films / Séries** : fiches enrichies **TMDB** (affiche, backdrop, synopsis, note, **casting**), épisodes par saison
- **Guide TV** : grille EPG par chaîne (en cours + à venir)
- **Recherche globale** (chaînes + films + séries)
- **Lecteur** : MKV/HEVC natif, seek instantané, **pistes audio & sous-titres**, plein écran, raccourcis clavier, **reprise de lecture**, tampon réglable
- **Trakt** : connexion (code), scrobble automatique à ~90 %
- **Téléchargements** (file séquentielle) · **Enregistrement** MP4 (ffmpeg)
- Thème sombre « premium » (accent orange)

### Feuille de route
Restream LAN + tunnel Cloudflare · export WhatsApp · sources multiples M3U · catch-up/timeshift · mise à jour automatique in-app.

## Développement

```bash
flutter pub get
bash tool/fetch_ffmpeg.sh   # récupère le binaire ffmpeg statique (bundlé, non versionné)
flutter run -d macos        # ou: flutter run -d windows
```

Prérequis : Flutter 3.41+, et sur macOS **CocoaPods** (`brew install cocoapods`) + **Xcode** pour le build.

## Build

```bash
bash tool/fetch_ffmpeg.sh
flutter build macos --release      # → build/macos/Build/Products/Release/ktv.app
flutter build windows --release    # (sur Windows)
```

## Tests

```bash
flutter test
```

Toute la logique métier pure (nettoyage de titres, matching TMDB, parsing de durée, recommandations) est testée unitairement.

## Architecture

Feature-first, sans code monolithique :

```
lib/core/      modèles · client Xtream · stockage · logique pure (+tests) · thème · widgets
lib/features/  auth · home · live · vod · series · guide · search · player · settings
lib/services/  tmdb · trakt · downloads · recording
```

## Licence

MIT.
