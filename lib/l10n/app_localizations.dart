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
  /// **'Derniers films'**
  String get railLatestMovies;

  /// No description provided for @railLatestSeries.
  ///
  /// In fr, this message translates to:
  /// **'Dernières séries'**
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
