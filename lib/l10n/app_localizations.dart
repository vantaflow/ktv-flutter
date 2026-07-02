import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L? of(BuildContext context) {
    return Localizations.of<L>(context, L);
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navLive.
  ///
  /// In fr, this message translates to:
  /// **'Live TV'**
  String get navLive;

  /// No description provided for @navMovies.
  ///
  /// In fr, this message translates to:
  /// **'Films'**
  String get navMovies;

  /// No description provided for @navSeries.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get navSeries;

  /// No description provided for @navGuide.
  ///
  /// In fr, this message translates to:
  /// **'Guide'**
  String get navGuide;

  /// No description provided for @navCatchup.
  ///
  /// In fr, this message translates to:
  /// **'Rediffusion'**
  String get navCatchup;

  /// No description provided for @navDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get navDownloads;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher chaînes, films, séries…'**
  String get searchHint;

  /// No description provided for @railFavChannels.
  ///
  /// In fr, this message translates to:
  /// **'Chaînes favorites'**
  String get railFavChannels;

  /// No description provided for @railMediaFavs.
  ///
  /// In fr, this message translates to:
  /// **'Films & séries favoris'**
  String get railMediaFavs;

  /// No description provided for @railResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la lecture'**
  String get railResume;

  /// No description provided for @railRecent.
  ///
  /// In fr, this message translates to:
  /// **'Vu récemment'**
  String get railRecent;

  /// No description provided for @railWatchlist.
  ///
  /// In fr, this message translates to:
  /// **'Ma liste (Trakt)'**
  String get railWatchlist;

  /// No description provided for @railRecoMovies.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé pour vous'**
  String get railRecoMovies;

  /// No description provided for @railRecoSeries.
  ///
  /// In fr, this message translates to:
  /// **'Séries recommandées'**
  String get railRecoSeries;

  /// No description provided for @railLatestMovies.
  ///
  /// In fr, this message translates to:
  /// **'Derniers films ajoutés'**
  String get railLatestMovies;

  /// No description provided for @railLatestSeries.
  ///
  /// In fr, this message translates to:
  /// **'Dernières séries ajoutées'**
  String get railLatestSeries;

  /// No description provided for @actionPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get actionPlay;

  /// No description provided for @actionWatch.
  ///
  /// In fr, this message translates to:
  /// **'Regarder'**
  String get actionWatch;

  /// No description provided for @actionDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get actionDownload;

  /// No description provided for @actionAddFav.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get actionAddFav;

  /// No description provided for @actionFav.
  ///
  /// In fr, this message translates to:
  /// **'Favori'**
  String get actionFav;

  /// No description provided for @actionClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get actionClose;

  /// No description provided for @actionRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir'**
  String get actionRefresh;

  /// No description provided for @actionMarkWatched.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme vu'**
  String get actionMarkWatched;

  /// No description provided for @actionWatched.
  ///
  /// In fr, this message translates to:
  /// **'Vu'**
  String get actionWatched;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get langSystem;

  /// No description provided for @langFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @emptyNoChannel.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne'**
  String get emptyNoChannel;

  /// No description provided for @emptyNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get emptyNoResult;

  /// No description provided for @emptyNoEpisode.
  ///
  /// In fr, this message translates to:
  /// **'Aucun épisode'**
  String get emptyNoEpisode;

  /// No description provided for @noDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucune description disponible.'**
  String get noDescription;

  /// No description provided for @loginServer.
  ///
  /// In fr, this message translates to:
  /// **'Serveur (http://…)'**
  String get loginServer;

  /// No description provided for @loginUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get loginUser;

  /// No description provided for @loginPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPassword;

  /// No description provided for @loginConnect.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginConnect;

  /// No description provided for @loginSavedProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Profils enregistrés'**
  String get loginSavedProfiles;

  /// No description provided for @loginNeedServer.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne au moins le serveur et l\'utilisateur.'**
  String get loginNeedServer;

  /// No description provided for @guideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Guide TV'**
  String get guideTitle;

  /// No description provided for @catchupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rediffusion'**
  String get catchupTitle;

  /// No description provided for @catchupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejouez les programmes des derniers jours sur les chaînes qui proposent le catch-up.'**
  String get catchupSubtitle;

  /// No description provided for @catchupSelectChannel.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une chaîne'**
  String get catchupSelectChannel;

  /// No description provided for @catchupNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune rediffusion disponible pour « {channel} ».\nGuide EPG absent ou catch-up non proposé.'**
  String catchupNone(Object channel);

  /// No description provided for @catchupDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger la rediffusion'**
  String get catchupDownload;

  /// No description provided for @dayToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get dayYesterday;

  /// No description provided for @downloadsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloadsTitle;

  /// No description provided for @downloadsFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier'**
  String get downloadsFolder;

  /// No description provided for @downloadsClearDone.
  ///
  /// In fr, this message translates to:
  /// **'Vider terminés'**
  String get downloadsClearDone;

  /// No description provided for @downloadsInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours ({n})'**
  String downloadsInProgress(Object n);

  /// No description provided for @downloadsDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminés ({n})'**
  String downloadsDone(Object n);

  /// No description provided for @downloadsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement.\nBouton ⬇ sur un film, un épisode ou une rediffusion.'**
  String get downloadsEmpty;

  /// No description provided for @downloadsQueued.
  ///
  /// In fr, this message translates to:
  /// **'en file'**
  String get downloadsQueued;

  /// No description provided for @downloadsFailed.
  ///
  /// In fr, this message translates to:
  /// **'échec'**
  String get downloadsFailed;

  /// No description provided for @downloadsCanceled.
  ///
  /// In fr, this message translates to:
  /// **'annulé'**
  String get downloadsCanceled;

  /// No description provided for @downloadsPlayHint.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargé · appuyez pour lire'**
  String get downloadsPlayHint;

  /// No description provided for @downloadsReveal.
  ///
  /// In fr, this message translates to:
  /// **'Révéler dans le dossier'**
  String get downloadsReveal;

  /// No description provided for @downloadsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la liste'**
  String get downloadsRemove;

  /// No description provided for @downloadsCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get downloadsCancel;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @tabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte & abonnement'**
  String get tabAccount;

  /// No description provided for @tabPlayback.
  ///
  /// In fr, this message translates to:
  /// **'Lecture & tampon'**
  String get tabPlayback;

  /// No description provided for @tabTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get tabTheme;

  /// No description provided for @tabHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// No description provided for @tabEpg.
  ///
  /// In fr, this message translates to:
  /// **'EPG externe'**
  String get tabEpg;

  /// No description provided for @tabCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue'**
  String get tabCatalog;

  /// No description provided for @tabCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get tabCategories;

  /// No description provided for @tabTmdb.
  ///
  /// In fr, this message translates to:
  /// **'Enrichissement TMDB'**
  String get tabTmdb;

  /// No description provided for @tabTrakt.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation Trakt'**
  String get tabTrakt;

  /// No description provided for @tabSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchro appareils'**
  String get tabSync;

  /// No description provided for @tabAutoUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour auto'**
  String get tabAutoUpdate;

  /// No description provided for @tabRecordings.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrements'**
  String get tabRecordings;

  /// No description provided for @tabDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get tabDownloads;

  /// No description provided for @tabHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get tabHistory;

  /// No description provided for @tabDiagnostic.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get tabDiagnostic;

  /// No description provided for @tabProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Profils'**
  String get tabProfiles;

  /// No description provided for @tabApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get tabApp;

  /// No description provided for @themeAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get themeAppearance;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeAccent.
  ///
  /// In fr, this message translates to:
  /// **'Couleur d\'accent'**
  String get themeAccent;

  /// No description provided for @themeAccentHint.
  ///
  /// In fr, this message translates to:
  /// **'S\'applique immédiatement à toute l\'interface.'**
  String get themeAccentHint;

  /// No description provided for @filterShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les filtres'**
  String get filterShow;

  /// No description provided for @filterHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les filtres'**
  String get filterHide;

  /// No description provided for @catAll.
  ///
  /// In fr, this message translates to:
  /// **'⭐ Toutes'**
  String get catAll;

  /// No description provided for @emptyNoMovie.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film'**
  String get emptyNoMovie;

  /// No description provided for @emptyNoMovieFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film pour ces filtres'**
  String get emptyNoMovieFilter;

  /// No description provided for @emptyNoSeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série'**
  String get emptyNoSeries;

  /// No description provided for @emptyNoSeriesFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série pour ces filtres'**
  String get emptyNoSeriesFilter;

  /// No description provided for @sortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Récents'**
  String get sortRecent;

  /// No description provided for @sortAZ.
  ///
  /// In fr, this message translates to:
  /// **'A→Z'**
  String get sortAZ;

  /// No description provided for @allRatings.
  ///
  /// In fr, this message translates to:
  /// **'Toutes notes'**
  String get allRatings;

  /// No description provided for @hq4kHdr.
  ///
  /// In fr, this message translates to:
  /// **'4K / HDR'**
  String get hq4kHdr;

  /// No description provided for @searchMin.
  ///
  /// In fr, this message translates to:
  /// **'Tape au moins 2 caractères'**
  String get searchMin;

  /// No description provided for @secNow.
  ///
  /// In fr, this message translates to:
  /// **'📡 En ce moment à la TV'**
  String get secNow;

  /// No description provided for @secChannels.
  ///
  /// In fr, this message translates to:
  /// **'📺 Chaînes'**
  String get secChannels;

  /// No description provided for @secMovies.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Films'**
  String get secMovies;

  /// No description provided for @secSeries.
  ///
  /// In fr, this message translates to:
  /// **'🎞️ Séries'**
  String get secSeries;

  /// No description provided for @trackAudio.
  ///
  /// In fr, this message translates to:
  /// **'Piste audio'**
  String get trackAudio;

  /// No description provided for @trackSubtitles.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres'**
  String get trackSubtitles;

  /// No description provided for @trackOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get trackOff;

  /// No description provided for @trackAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get trackAuto;

  /// No description provided for @trackLive.
  ///
  /// In fr, this message translates to:
  /// **'Direct'**
  String get trackLive;

  /// No description provided for @playbackSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de lecture'**
  String get playbackSettings;

  /// No description provided for @speed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse'**
  String get speed;

  /// No description provided for @audioBoost.
  ///
  /// In fr, this message translates to:
  /// **'Boost audio'**
  String get audioBoost;

  /// No description provided for @subDelay.
  ///
  /// In fr, this message translates to:
  /// **'Délai sous-titres'**
  String get subDelay;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @nextEpisode.
  ///
  /// In fr, this message translates to:
  /// **'Épisode suivant'**
  String get nextEpisode;

  /// No description provided for @sAccErr.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer les infos d\'abonnement.'**
  String get sAccErr;

  /// No description provided for @sNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté.'**
  String get sNotConnected;

  /// No description provided for @sStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get sStatus;

  /// No description provided for @sExpiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get sExpiration;

  /// No description provided for @sConnections.
  ///
  /// In fr, this message translates to:
  /// **'Connexions'**
  String get sConnections;

  /// No description provided for @sTrial.
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get sTrial;

  /// No description provided for @sUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get sUser;

  /// No description provided for @sServer.
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get sServer;

  /// No description provided for @sCreatedOn.
  ///
  /// In fr, this message translates to:
  /// **'Créé le'**
  String get sCreatedOn;

  /// No description provided for @sTimezone.
  ///
  /// In fr, this message translates to:
  /// **'Fuseau'**
  String get sTimezone;

  /// No description provided for @sFormats.
  ///
  /// In fr, this message translates to:
  /// **'Formats'**
  String get sFormats;

  /// No description provided for @sUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Illimité'**
  String get sUnlimited;

  /// No description provided for @sYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get sYes;

  /// No description provided for @sNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get sNo;

  /// No description provided for @sBufferHint.
  ///
  /// In fr, this message translates to:
  /// **'« Faible latence » = plus proche du direct. « Stable » = gros tampon, moins de coupures.'**
  String get sBufferHint;

  /// No description provided for @sBufLow.
  ///
  /// In fr, this message translates to:
  /// **'Faible latence'**
  String get sBufLow;

  /// No description provided for @sBufBalanced.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré (défaut)'**
  String get sBufBalanced;

  /// No description provided for @sBufStable.
  ///
  /// In fr, this message translates to:
  /// **'Stable (gros tampon)'**
  String get sBufStable;

  /// No description provided for @sBufApplied.
  ///
  /// In fr, this message translates to:
  /// **'Appliqué au prochain lancement de lecture (propriété mpv cache-secs).'**
  String get sBufApplied;

  /// No description provided for @sAutoplay.
  ///
  /// In fr, this message translates to:
  /// **'Lecture auto de l\'épisode suivant'**
  String get sAutoplay;

  /// No description provided for @sAutoplayHint.
  ///
  /// In fr, this message translates to:
  /// **'Enchaîne la série à la fin d\'un épisode'**
  String get sAutoplayHint;

  /// No description provided for @sEpgHint.
  ///
  /// In fr, this message translates to:
  /// **'Guide (XMLTV) du fournisseur, utilisé car get_short_epg est bloqué (403). Cache 6 h.'**
  String get sEpgHint;

  /// No description provided for @sRefreshEpg.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir l\'EPG'**
  String get sRefreshEpg;

  /// No description provided for @sEpgReloading.
  ///
  /// In fr, this message translates to:
  /// **'EPG en cours de rechargement…'**
  String get sEpgReloading;

  /// No description provided for @sCatalogHint.
  ///
  /// In fr, this message translates to:
  /// **'Recharge films & séries depuis le fournisseur (après ajout de nouveaux contenus).'**
  String get sCatalogHint;

  /// No description provided for @sRefreshMovies.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir les films'**
  String get sRefreshMovies;

  /// No description provided for @sRefreshSeries.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir les séries'**
  String get sRefreshSeries;

  /// No description provided for @sRefreshAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout rafraîchir'**
  String get sRefreshAll;

  /// No description provided for @sMoviesRefreshed.
  ///
  /// In fr, this message translates to:
  /// **'Films rafraîchis'**
  String get sMoviesRefreshed;

  /// No description provided for @sSeriesRefreshed.
  ///
  /// In fr, this message translates to:
  /// **'Séries rafraîchies'**
  String get sSeriesRefreshed;

  /// No description provided for @sCatalogRefreshed.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue et EPG rafraîchis'**
  String get sCatalogRefreshed;

  /// No description provided for @sTmdbHint.
  ///
  /// In fr, this message translates to:
  /// **'Affiches, notes, synopsis et casting pour les films & séries.'**
  String get sTmdbHint;

  /// No description provided for @sTmdbEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer TMDB'**
  String get sTmdbEnable;

  /// No description provided for @sTmdbLang.
  ///
  /// In fr, this message translates to:
  /// **'Langue des métadonnées'**
  String get sTmdbLang;

  /// No description provided for @sTmdbKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'Clé v4 perso (optionnel — sinon proxy KTV) :'**
  String get sTmdbKeyHint;

  /// No description provided for @sTmdbKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé TMDB v4 (optionnel)'**
  String get sTmdbKey;

  /// No description provided for @sTraktHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée une appli sur trakt.tv/oauth/applications, colle Client ID + Secret.'**
  String get sTraktHint;

  /// No description provided for @sClientId.
  ///
  /// In fr, this message translates to:
  /// **'Client ID'**
  String get sClientId;

  /// No description provided for @sClientSecret.
  ///
  /// In fr, this message translates to:
  /// **'Client Secret'**
  String get sClientSecret;

  /// No description provided for @sTraktScrobble.
  ///
  /// In fr, this message translates to:
  /// **'Marquer vu automatiquement à la fin'**
  String get sTraktScrobble;

  /// No description provided for @sTraktReco.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations « Recommandé pour vous »'**
  String get sTraktReco;

  /// No description provided for @sTraktConnect.
  ///
  /// In fr, this message translates to:
  /// **'Connecter (code device)'**
  String get sTraktConnect;

  /// No description provided for @sTraktConnDialog.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Trakt'**
  String get sTraktConnDialog;

  /// No description provided for @sGoTo.
  ///
  /// In fr, this message translates to:
  /// **'Va sur :'**
  String get sGoTo;

  /// No description provided for @sEnterCode.
  ///
  /// In fr, this message translates to:
  /// **'et saisis le code :'**
  String get sEnterCode;

  /// No description provided for @sTraktCodeErr.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la demande de code Trakt.'**
  String get sTraktCodeErr;

  /// No description provided for @sNeedClientId.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne d\'abord le Client ID.'**
  String get sNeedClientId;

  /// No description provided for @sSyncHint1.
  ///
  /// In fr, this message translates to:
  /// **'Synchronise reprise, favoris, historique, catégories et profils entre tes appareils. '**
  String get sSyncHint1;

  /// No description provided for @sSyncHint2.
  ///
  /// In fr, this message translates to:
  /// **'Identité = ton compte Trakt. Tout est chiffré avec ta phrase secrète : le serveur ne peut rien lire.'**
  String get sSyncHint2;

  /// No description provided for @sSyncNeedTrakt.
  ///
  /// In fr, this message translates to:
  /// **'Connecte d\'abord Trakt (section « Synchronisation Trakt »).'**
  String get sSyncNeedTrakt;

  /// No description provided for @sPassphraseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Phrase secrète (identique sur tous tes appareils)'**
  String get sPassphraseLabel;

  /// No description provided for @sPassphraseChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une phrase secrète'**
  String get sPassphraseChoose;

  /// No description provided for @sPassphraseSet.
  ///
  /// In fr, this message translates to:
  /// **'Déjà définie — saisir pour changer'**
  String get sPassphraseSet;

  /// No description provided for @sSyncEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer la synchro'**
  String get sSyncEnable;

  /// No description provided for @sSyncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get sSyncNow;

  /// No description provided for @sDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get sDisable;

  /// No description provided for @sPassphraseShort.
  ///
  /// In fr, this message translates to:
  /// **'Phrase trop courte (min. 4 caractères).'**
  String get sPassphraseShort;

  /// No description provided for @sSyncEnabledNoSync.
  ///
  /// In fr, this message translates to:
  /// **'Activée — pas encore synchronisée.'**
  String get sSyncEnabledNoSync;

  /// No description provided for @sSyncDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée.'**
  String get sSyncDisabled;

  /// No description provided for @sSyncServer.
  ///
  /// In fr, this message translates to:
  /// **'Serveur de synchro (avancé)'**
  String get sSyncServer;

  /// No description provided for @sAutoRefreshHint.
  ///
  /// In fr, this message translates to:
  /// **'Recharge périodiquement chaînes, films, séries et EPG en arrière-plan.'**
  String get sAutoRefreshHint;

  /// No description provided for @sFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get sFrequency;

  /// No description provided for @sEvery30.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les 30 min'**
  String get sEvery30;

  /// No description provided for @sEvery1h.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les heures'**
  String get sEvery1h;

  /// No description provided for @sEvery3h.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les 3 h'**
  String get sEvery3h;

  /// No description provided for @sEvery6h.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les 6 h'**
  String get sEvery6h;

  /// No description provided for @sRefreshNow.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser maintenant'**
  String get sRefreshNow;

  /// No description provided for @sRefreshed.
  ///
  /// In fr, this message translates to:
  /// **'Actualisé'**
  String get sRefreshed;

  /// No description provided for @sNoRecording.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enregistrement.'**
  String get sNoRecording;

  /// No description provided for @sStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get sStop;

  /// No description provided for @sInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours…'**
  String get sInProgress;

  /// No description provided for @sCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get sCancel;

  /// No description provided for @sNoDownload.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement. Bouton ⬇ sur un film ou un épisode.'**
  String get sNoDownload;

  /// No description provided for @sNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique.'**
  String get sNoHistory;

  /// No description provided for @sHistoryCleared.
  ///
  /// In fr, this message translates to:
  /// **'Historique effacé'**
  String get sHistoryCleared;

  /// No description provided for @sClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get sClear;

  /// No description provided for @sDiagHint.
  ///
  /// In fr, this message translates to:
  /// **'Teste la latence de l\'API, les connexions et le débit du flux.'**
  String get sDiagHint;

  /// No description provided for @sRunTest.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le test'**
  String get sRunTest;

  /// No description provided for @sLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get sLogout;

  /// No description provided for @sActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get sActivate;

  /// No description provided for @sManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get sManage;

  /// No description provided for @sCatManageHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les catégories du fournisseur à afficher ou masquer, pour chaque section. '**
  String get sCatManageHint;

  /// No description provided for @sCatDefault.
  ///
  /// In fr, this message translates to:
  /// **'Sans réglage, KTV applique son filtre par défaut (FR / Maroc / beIN Sports).'**
  String get sCatDefault;

  /// No description provided for @sHomeRowsHint.
  ///
  /// In fr, this message translates to:
  /// **'Coche les rangées à afficher sur l\'accueil.'**
  String get sHomeRowsHint;

  /// No description provided for @sCheckUpdates.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier les mises à jour'**
  String get sCheckUpdates;

  /// No description provided for @sSeeReleases.
  ///
  /// In fr, this message translates to:
  /// **'Voir les releases'**
  String get sSeeReleases;

  /// No description provided for @sUpdateErr.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier les mises à jour.'**
  String get sUpdateErr;

  /// No description provided for @sUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'✓ Vous avez la dernière version.'**
  String get sUpToDate;

  /// No description provided for @sDownloadErr.
  ///
  /// In fr, this message translates to:
  /// **'Échec du téléchargement.'**
  String get sDownloadErr;

  /// No description provided for @sChangeFolder.
  ///
  /// In fr, this message translates to:
  /// **'Changer le dossier…'**
  String get sChangeFolder;

  /// No description provided for @sChooseFolder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le dossier'**
  String get sChooseFolder;

  /// No description provided for @sOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get sOpen;

  /// No description provided for @sNoData.
  ///
  /// In fr, this message translates to:
  /// **'aucune donnée'**
  String get sNoData;

  /// No description provided for @sQueued2.
  ///
  /// In fr, this message translates to:
  /// **'en file'**
  String get sQueued2;

  /// No description provided for @sFailed2.
  ///
  /// In fr, this message translates to:
  /// **'échec'**
  String get sFailed2;

  /// No description provided for @sCanceled2.
  ///
  /// In fr, this message translates to:
  /// **'annulé'**
  String get sCanceled2;

  /// No description provided for @sFreqOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get sFreqOff;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
    case 'fr':
      return LFr();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
