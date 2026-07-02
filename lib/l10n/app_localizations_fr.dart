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
}
