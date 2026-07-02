// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class LFr extends L {
  LFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navLive => 'Live TV';

  @override
  String get navMovies => 'Films';

  @override
  String get navSeries => 'Séries';

  @override
  String get navGuide => 'Guide';

  @override
  String get navCatchup => 'Rediffusion';

  @override
  String get navDownloads => 'Téléchargements';

  @override
  String get navSettings => 'Réglages';

  @override
  String get searchHint => 'Rechercher chaînes, films, séries…';

  @override
  String get railFavChannels => 'Chaînes favorites';

  @override
  String get railMediaFavs => 'Films & séries favoris';

  @override
  String get railResume => 'Reprendre la lecture';

  @override
  String get railRecent => 'Vu récemment';

  @override
  String get railWatchlist => 'Ma liste (Trakt)';

  @override
  String get railRecoMovies => 'Recommandé pour vous';

  @override
  String get railRecoSeries => 'Séries recommandées';

  @override
  String get railLatestMovies => 'Derniers films ajoutés';

  @override
  String get railLatestSeries => 'Dernières séries ajoutées';

  @override
  String get actionPlay => 'Lire';

  @override
  String get actionWatch => 'Regarder';

  @override
  String get actionDownload => 'Télécharger';

  @override
  String get actionAddFav => 'Ajouter aux favoris';

  @override
  String get actionFav => 'Favori';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionRefresh => 'Rafraîchir';

  @override
  String get actionMarkWatched => 'Marquer comme vu';

  @override
  String get actionWatched => 'Vu';

  @override
  String get language => 'Langue';

  @override
  String get langSystem => 'Système';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get emptyNoChannel => 'Aucune chaîne';

  @override
  String get emptyNoResult => 'Aucun résultat';

  @override
  String get emptyNoEpisode => 'Aucun épisode';

  @override
  String get noDescription => 'Aucune description disponible.';

  @override
  String get loginServer => 'Serveur (http://…)';

  @override
  String get loginUser => 'Utilisateur';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginConnect => 'Se connecter';

  @override
  String get loginSavedProfiles => 'Profils enregistrés';

  @override
  String get loginNeedServer =>
      'Renseigne au moins le serveur et l\'utilisateur.';

  @override
  String get guideTitle => 'Guide TV';

  @override
  String get catchupTitle => 'Rediffusion';

  @override
  String get catchupSubtitle =>
      'Rejouez les programmes des derniers jours sur les chaînes qui proposent le catch-up.';

  @override
  String get catchupSelectChannel => 'Sélectionnez une chaîne';

  @override
  String catchupNone(Object channel) {
    return 'Aucune rediffusion disponible pour « $channel ».\nGuide EPG absent ou catch-up non proposé.';
  }

  @override
  String get catchupDownload => 'Télécharger la rediffusion';

  @override
  String get dayToday => 'Aujourd\'hui';

  @override
  String get dayYesterday => 'Hier';

  @override
  String get downloadsTitle => 'Téléchargements';

  @override
  String get downloadsFolder => 'Dossier';

  @override
  String get downloadsClearDone => 'Vider terminés';

  @override
  String downloadsInProgress(Object n) {
    return 'En cours ($n)';
  }

  @override
  String downloadsDone(Object n) {
    return 'Terminés ($n)';
  }

  @override
  String get downloadsEmpty =>
      'Aucun téléchargement.\nBouton ⬇ sur un film, un épisode ou une rediffusion.';

  @override
  String get downloadsQueued => 'en file';

  @override
  String get downloadsFailed => 'échec';

  @override
  String get downloadsCanceled => 'annulé';

  @override
  String get downloadsPlayHint => 'Téléchargé · appuyez pour lire';

  @override
  String get downloadsReveal => 'Révéler dans le dossier';

  @override
  String get downloadsRemove => 'Retirer de la liste';

  @override
  String get downloadsCancel => 'Annuler';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get tabAccount => 'Compte & abonnement';

  @override
  String get tabPlayback => 'Lecture & tampon';

  @override
  String get tabTheme => 'Thème';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabEpg => 'EPG externe';

  @override
  String get tabCatalog => 'Catalogue';

  @override
  String get tabCategories => 'Catégories';

  @override
  String get tabTmdb => 'Enrichissement TMDB';

  @override
  String get tabTrakt => 'Synchronisation Trakt';

  @override
  String get tabSync => 'Synchro appareils';

  @override
  String get tabAutoUpdate => 'Mise à jour auto';

  @override
  String get tabRecordings => 'Enregistrements';

  @override
  String get tabDownloads => 'Téléchargements';

  @override
  String get tabHistory => 'Historique';

  @override
  String get tabDiagnostic => 'Diagnostic';

  @override
  String get tabProfiles => 'Profils';

  @override
  String get tabApp => 'Application';

  @override
  String get themeAppearance => 'Apparence';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeAccent => 'Couleur d\'accent';

  @override
  String get themeAccentHint =>
      'S\'applique immédiatement à toute l\'interface.';

  @override
  String get filterShow => 'Afficher les filtres';

  @override
  String get filterHide => 'Masquer les filtres';

  @override
  String get catAll => '⭐ Toutes';

  @override
  String get emptyNoMovie => 'Aucun film';

  @override
  String get emptyNoMovieFilter => 'Aucun film pour ces filtres';

  @override
  String get emptyNoSeries => 'Aucune série';

  @override
  String get emptyNoSeriesFilter => 'Aucune série pour ces filtres';

  @override
  String get sortRecent => 'Récents';

  @override
  String get sortAZ => 'A→Z';

  @override
  String get allRatings => 'Toutes notes';

  @override
  String get hq4kHdr => '4K / HDR';

  @override
  String get searchMin => 'Tape au moins 2 caractères';

  @override
  String get secNow => '📡 En ce moment à la TV';

  @override
  String get secChannels => '📺 Chaînes';

  @override
  String get secMovies => '🎬 Films';

  @override
  String get secSeries => '🎞️ Séries';

  @override
  String get trackAudio => 'Piste audio';

  @override
  String get trackSubtitles => 'Sous-titres';

  @override
  String get trackOff => 'Désactivé';

  @override
  String get trackAuto => 'Auto';

  @override
  String get trackLive => 'Direct';

  @override
  String get playbackSettings => 'Réglages de lecture';

  @override
  String get speed => 'Vitesse';

  @override
  String get audioBoost => 'Boost audio';

  @override
  String get subDelay => 'Délai sous-titres';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get nextEpisode => 'Épisode suivant';

  @override
  String get sAccErr => 'Impossible de récupérer les infos d\'abonnement.';

  @override
  String get sNotConnected => 'Non connecté.';

  @override
  String get sStatus => 'Statut';

  @override
  String get sExpiration => 'Expiration';

  @override
  String get sConnections => 'Connexions';

  @override
  String get sTrial => 'Essai';

  @override
  String get sUser => 'Utilisateur';

  @override
  String get sServer => 'Serveur';

  @override
  String get sCreatedOn => 'Créé le';

  @override
  String get sTimezone => 'Fuseau';

  @override
  String get sFormats => 'Formats';

  @override
  String get sUnlimited => 'Illimité';

  @override
  String get sYes => 'Oui';

  @override
  String get sNo => 'Non';

  @override
  String get sBufferHint =>
      '« Faible latence » = plus proche du direct. « Stable » = gros tampon, moins de coupures.';

  @override
  String get sBufLow => 'Faible latence';

  @override
  String get sBufBalanced => 'Équilibré (défaut)';

  @override
  String get sBufStable => 'Stable (gros tampon)';

  @override
  String get sBufApplied =>
      'Appliqué au prochain lancement de lecture (propriété mpv cache-secs).';

  @override
  String get sAutoplay => 'Lecture auto de l\'épisode suivant';

  @override
  String get sAutoplayHint => 'Enchaîne la série à la fin d\'un épisode';

  @override
  String get sEpgHint =>
      'Guide (XMLTV) du fournisseur, utilisé car get_short_epg est bloqué (403). Cache 6 h.';

  @override
  String get sRefreshEpg => 'Rafraîchir l\'EPG';

  @override
  String get sEpgReloading => 'EPG en cours de rechargement…';

  @override
  String get sCatalogHint =>
      'Recharge films & séries depuis le fournisseur (après ajout de nouveaux contenus).';

  @override
  String get sRefreshMovies => 'Rafraîchir les films';

  @override
  String get sRefreshSeries => 'Rafraîchir les séries';

  @override
  String get sRefreshAll => 'Tout rafraîchir';

  @override
  String get sMoviesRefreshed => 'Films rafraîchis';

  @override
  String get sSeriesRefreshed => 'Séries rafraîchies';

  @override
  String get sCatalogRefreshed => 'Catalogue et EPG rafraîchis';

  @override
  String get sTmdbHint =>
      'Affiches, notes, synopsis et casting pour les films & séries.';

  @override
  String get sTmdbEnable => 'Activer TMDB';

  @override
  String get sTmdbLang => 'Langue des métadonnées';

  @override
  String get sTmdbKeyHint => 'Clé v4 perso (optionnel — sinon proxy KTV) :';

  @override
  String get sTmdbKey => 'Clé TMDB v4 (optionnel)';

  @override
  String get sTraktHint =>
      'Crée une appli sur trakt.tv/oauth/applications, colle Client ID + Secret.';

  @override
  String get sClientId => 'Client ID';

  @override
  String get sClientSecret => 'Client Secret';

  @override
  String get sTraktScrobble => 'Marquer vu automatiquement à la fin';

  @override
  String get sTraktReco => 'Recommandations « Recommandé pour vous »';

  @override
  String get sTraktConnect => 'Connecter (code device)';

  @override
  String get sTraktConnDialog => 'Connexion Trakt';

  @override
  String get sGoTo => 'Va sur :';

  @override
  String get sEnterCode => 'et saisis le code :';

  @override
  String get sTraktCodeErr => 'Échec de la demande de code Trakt.';

  @override
  String get sNeedClientId => 'Renseigne d\'abord le Client ID.';

  @override
  String get sSyncHint1 =>
      'Synchronise reprise, favoris, historique, catégories et profils entre tes appareils. ';

  @override
  String get sSyncHint2 =>
      'Identité = ton compte Trakt. Tout est chiffré avec ta phrase secrète : le serveur ne peut rien lire.';

  @override
  String get sSyncNeedTrakt =>
      'Connecte d\'abord Trakt (section « Synchronisation Trakt »).';

  @override
  String get sPassphraseLabel =>
      'Phrase secrète (identique sur tous tes appareils)';

  @override
  String get sPassphraseChoose => 'Choisis une phrase secrète';

  @override
  String get sPassphraseSet => 'Déjà définie — saisir pour changer';

  @override
  String get sSyncEnable => 'Activer la synchro';

  @override
  String get sSyncNow => 'Synchroniser maintenant';

  @override
  String get sDisable => 'Désactiver';

  @override
  String get sPassphraseShort => 'Phrase trop courte (min. 4 caractères).';

  @override
  String get sSyncEnabledNoSync => 'Activée — pas encore synchronisée.';

  @override
  String get sSyncDisabled => 'Désactivée.';

  @override
  String get sSyncServer => 'Serveur de synchro (avancé)';

  @override
  String get sAutoRefreshHint =>
      'Recharge périodiquement chaînes, films, séries et EPG en arrière-plan.';

  @override
  String get sFrequency => 'Fréquence';

  @override
  String get sEvery30 => 'Toutes les 30 min';

  @override
  String get sEvery1h => 'Toutes les heures';

  @override
  String get sEvery3h => 'Toutes les 3 h';

  @override
  String get sEvery6h => 'Toutes les 6 h';

  @override
  String get sRefreshNow => 'Actualiser maintenant';

  @override
  String get sRefreshed => 'Actualisé';

  @override
  String get sNoRecording => 'Aucun enregistrement.';

  @override
  String get sStop => 'Arrêter';

  @override
  String get sInProgress => 'En cours…';

  @override
  String get sCancel => 'Annuler';

  @override
  String get sNoDownload =>
      'Aucun téléchargement. Bouton ⬇ sur un film ou un épisode.';

  @override
  String get sNoHistory => 'Aucun historique.';

  @override
  String get sHistoryCleared => 'Historique effacé';

  @override
  String get sClear => 'Effacer';

  @override
  String get sDiagHint =>
      'Teste la latence de l\'API, les connexions et le débit du flux.';

  @override
  String get sRunTest => 'Lancer le test';

  @override
  String get sLogout => 'Se déconnecter';

  @override
  String get sActivate => 'Activer';

  @override
  String get sManage => 'Gérer';

  @override
  String get sCatManageHint =>
      'Choisis les catégories du fournisseur à afficher ou masquer, pour chaque section. ';

  @override
  String get sCatDefault =>
      'Sans réglage, KTV applique son filtre par défaut (FR / Maroc / beIN Sports).';

  @override
  String get sHomeRowsHint => 'Coche les rangées à afficher sur l\'accueil.';

  @override
  String get sCheckUpdates => 'Vérifier les mises à jour';

  @override
  String get sSeeReleases => 'Voir les releases';

  @override
  String get sUpdateErr => 'Impossible de vérifier les mises à jour.';

  @override
  String get sUpToDate => '✓ Vous avez la dernière version.';

  @override
  String get sDownloadErr => 'Échec du téléchargement.';

  @override
  String get sChangeFolder => 'Changer le dossier…';

  @override
  String get sChooseFolder => 'Choisir le dossier';

  @override
  String get sOpen => 'Ouvrir';

  @override
  String get sNoData => 'aucune donnée';

  @override
  String get sQueued2 => 'en file';

  @override
  String get sFailed2 => 'échec';

  @override
  String get sCanceled2 => 'annulé';

  @override
  String get sFreqOff => 'Désactivée';

  @override
  String dlSeasonBtn(Object n) {
    return 'Saison ($n)';
  }

  @override
  String dlWholeSeries(Object n) {
    return 'Série complète ($n)';
  }

  @override
  String dlEnqueued(Object n) {
    return '$n épisodes ajoutés aux téléchargements';
  }

  @override
  String seasonN(Object n) {
    return 'Saison $n';
  }

  @override
  String episodeN(Object n) {
    return 'Épisode $n';
  }

  @override
  String get catchupNoArchive =>
      'Aucune chaîne ne propose la rediffusion (catch-up) chez ce fournisseur.';

  @override
  String get catchupWatch => 'Revoir (catch-up)';

  @override
  String get catchupUnavailable => 'Catch-up non disponible sur cette chaîne.';

  @override
  String get epgSchedule => 'Programmer';

  @override
  String get epgRecord => 'Enregistrer';

  @override
  String get hwdec => 'Décodage matériel';

  @override
  String get hwdecHint =>
      'Désactivez si la lecture plante ou fige (surtout sous Windows). Appliqué au prochain lancement de lecture.';
}
