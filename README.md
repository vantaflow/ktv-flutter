# KTV — lecteur Xtream (Flutter + media_kit)

Lecteur IPTV **KTV** pour **macOS · Windows · Android**, propulsé par **media_kit / libmpv**. Interface **FR / EN / AR** (avec RTL).

**▶︎ [Télécharger la dernière version](https://github.com/khalilbenaz/ktv-flutter/releases/latest)** · **[Site](https://khalilbenaz.github.io/ktv-flutter/)**

> Version précédente en Electron : [github.com/khalilbenaz/ktv](https://github.com/khalilbenaz/ktv).

## Pourquoi Flutter + libmpv

Le moteur `<video>` de Chromium (Electron) ne lit pas les MKV/HEVC/multi-pistes servis par l'IPTV VOD, ce qui imposait un relais ffmpeg cassant le seek, la durée, la reprise et la sélection audio/sous-titres. **libmpv (media_kit)** lit tout ça **nativement**, avec **seek instantané** et **pistes audio/sous-titres** — la famille de bugs disparaît.

## Fonctionnalités

- **Connexion Xtream** multi-profils (bascule + infos abonnement)
- **Accueil personnalisable** : affichage **rangées ou grille**, choix des sections affichées · Reprendre (avec **temps restant** ⏳) · Vu récemment · Favoris · **Recommandé pour vous** (TMDB fondé sur ton catalogue) · **Ma liste (Trakt)** · Derniers ajouts. Les **cartes de chaînes live** montrent le **logo tel quel** + le **programme EPG en cours**.
- **Live TV** : EPG en cours (description + horaires), favoris, enregistrement, **recherche par programme en cours**
- **Films / Séries** : fiches TMDB (affiche, backdrop, synopsis, note, casting), **filtres & tri** (note, 4K/HDR), **téléchargement par épisode/saison**, **marquer vu** (Trakt)
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
- **Multi-plateforme** : **macOS · Windows · Android** (mêmes données grâce à la synchro). Sur Android, les fonctions reposant sur des binaires (enregistrement, restream, PiP) sont masquées.
- **Multilingue** : **Français · English · العربية** (avec mise en page **RTL** en arabe), bascule à chaud
- **Système** : **mise à jour in-app** (GitHub), **rafraîchissement automatique** catalogue/EPG, **diagnostic réseau**, **historique complet**, dossiers configurables
- Démarrage agrandi · fenêtre centrée

### Feuille de route (à venir)
- **Multi-sources M3U/Xtream fusionnées** (plusieurs abonnements + playlists `.m3u` dans un catalogue unifié)
- **Contrôle parental** (verrou PIN sur les catégories)
- **Enregistrement de série entière** (enregistrer automatiquement les nouveaux épisodes)
- **Version iOS**

_Livré récemment : Android · synchro inter-appareils chiffrée · favoris Films & Séries · interface multilingue FR/EN/AR (RTL) · gestion & réorganisation des catégories · catch-up dédié._

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
flutter build apk --release --split-per-abi   # Android (sans fetch_ffmpeg)
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
