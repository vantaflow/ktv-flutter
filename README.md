# KTV — lecteur Xtream (Flutter + media_kit)

Lecteur IPTV **KTV** pour **macOS · Windows**, propulsé par **media_kit / libmpv**. Interface **FR / EN / AR** (avec RTL).

**▶︎ [Télécharger la dernière version](https://github.com/khalilbenaz/ktv-flutter/releases/latest)** · **[Site](https://khalilbenaz.github.io/ktv-flutter/)**

> Version précédente en Electron : [github.com/khalilbenaz/ktv](https://github.com/khalilbenaz/ktv).

## Pourquoi Flutter + libmpv

Le moteur `<video>` de Chromium (Electron) ne lit pas les MKV/HEVC/multi-pistes servis par l'IPTV VOD, ce qui imposait un relais ffmpeg cassant le seek, la durée, la reprise et la sélection audio/sous-titres. **libmpv (media_kit)** lit tout ça **nativement**, avec **seek instantané** et **pistes audio/sous-titres** — la famille de bugs disparaît.

## Fonctionnalités

- **Sources multiples** : comptes **Xtream** ET playlists **M3U/M3U8**, avec bascule. **Fusion multi-sources** du Live : active plusieurs sources → catalogue unifié **dédoublonné** (par tvg-id/nom), avec **bascule automatique** sur une source de secours si l'une tombe (Réglages → Profils)
- **Contrôle parental** : code PIN, verrou **par catégorie ou par chaîne**, modes **verrouiller** (cadenas + PIN) ou **masquer**, **détection automatique des contenus adulte** (XXX, 18+, …)
- **Accueil personnalisable** : affichage **rangées ou grille**, choix des sections affichées · Reprendre (avec **temps restant** ⏳) · Vu récemment · Favoris · **Recommandé pour vous** (TMDB fondé sur ton catalogue) · **Ma liste (Trakt)** · Derniers ajouts. Les **cartes de chaînes live** montrent le **logo tel quel** + le **programme EPG en cours**.
- **Live TV** : EPG en cours (description + horaires), favoris, enregistrement, **recherche par programme en cours**
- **Films / Séries** : fiches TMDB (affiche, backdrop, synopsis, note, casting), **filtres & tri** (note, 4K/HDR), **favoris**, **téléchargement par épisode, par saison ou série complète**, **marquer vu** (Trakt)
- **Rediffusion (catch-up dédié)** : onglet dédié — par catégorie → chaîne (celles qui proposent l'archive) → programmes des derniers jours **groupés par jour**, à **revoir** ou **télécharger**
- **Gestion des catégories** : afficher/masquer **et réorganiser** (glisser-déposer) les catégories du fournisseur, **séparément pour Live · Films · Séries** (Réglages → Catégories)
- **Guide TV → action** : **catch-up** (revoir un programme passé), regarder en direct, **programmer l'enregistrement** sur la plage du programme
- **Recherche globale** (chaînes + films + séries + programmes EPG)
- **Lecteur avancé** : MKV/HEVC natif, seek instantané, pistes audio & sous-titres **mémorisées par contenu**, **vitesse**, **boost audio**, **délai sous-titres**, **autoplay épisode suivant**, zapping, plein écran, raccourcis, reprise, tampon réglable
- **Enregistrement** : sans couper la lecture, **heure de début précise**, qualité **compact (720p)** ou originale, indicateur REC, **dossier configurable**
- **Trakt** : connexion (code), scrobble auto, **watchlist**, marquage films & épisodes
- **Synchro inter-appareils** : reprise, favoris, historique, catégories **et profils IPTV** synchronisés entre tes machines. Identité = compte **Trakt**, **chiffrement de bout en bout** avec ta phrase secrète (le serveur ne peut rien lire)
- **Téléchargements** : **onglet dédié** (file séquentielle avec progression, **lecture locale** des éléments terminés, révéler dans le dossier), **dossier configurable**
- **Restream / partage** : relais **HLS local partagé** (une seule connexion fournisseur — la lecture locale continue) diffusé sur le **réseau local** + **tunnel Cloudflare** (`cloudflared` **bundlé**, aucune installation) pour regarder sur un autre appareil
- **Picture-in-Picture** : fenêtre flottante toujours au premier plan
- **Thèmes** : **clair / sombre** + **accent personnalisable** (7 couleurs)
- **Catalogue** : catégorie **« Toutes »** (agrège toutes les catégories), **filtres masquables**
- **Multilingue** : **Français · English · العربية** (avec mise en page **RTL** en arabe), bascule à chaud
- **Système** : **mise à jour in-app auto-installée** (télécharge, remplace l'app et relance), **rafraîchissement automatique** catalogue/EPG, **diagnostic réseau**, **historique complet**, dossiers configurables
- Démarrage agrandi · fenêtre centrée

## Développement

```bash
flutter pub get
bash tool/fetch_ffmpeg.sh   # récupère ffmpeg + cloudflared (bundlés, non versionnés)
flutter run -d macos        # ou: flutter run -d windows
```

Prérequis : Flutter 3.41+, et sur macOS **CocoaPods** (`brew install cocoapods`) + **Xcode** pour le build.

## Build

```bash
bash tool/fetch_ffmpeg.sh          # desktop uniquement (ffmpeg + cloudflared)
flutter build macos --release      # → build/macos/Build/Products/Release/KTV.app
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
lib/core/      modèles · client Xtream · stockage · logique pure (+tests) · thème · widgets · process (ffmpeg/cloudflared)
lib/features/  auth · home · live · vod · series · guide · catchup · categories · downloads · search · player · settings
lib/services/  tmdb · trakt · epg (xmltv) · downloads · recording · restream · update · sync (chiffré)
worker/        ktv-sync (Cloudflare Worker : synchro chiffrée, identité Trakt)
```

## Licence

MIT.
