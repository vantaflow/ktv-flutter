// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navLive => 'Live TV';

  @override
  String get navMovies => 'Movies';

  @override
  String get navSeries => 'Series';

  @override
  String get navGuide => 'Guide';

  @override
  String get navCatchup => 'Catch-up';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navSettings => 'Settings';

  @override
  String get searchHint => 'Search channels, movies, series…';

  @override
  String get railFavChannels => 'Favorite channels';

  @override
  String get railMediaFavs => 'Favorite movies & series';

  @override
  String get railResume => 'Continue watching';

  @override
  String get railRecent => 'Recently watched';

  @override
  String get railWatchlist => 'My list (Trakt)';

  @override
  String get railRecoMovies => 'Recommended for you';

  @override
  String get railRecoSeries => 'Recommended series';

  @override
  String get railLatestMovies => 'Latest movies';

  @override
  String get railLatestSeries => 'Latest series';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionWatch => 'Watch';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionAddFav => 'Add to favorites';

  @override
  String get actionFav => 'Favorite';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionMarkWatched => 'Mark as watched';

  @override
  String get actionWatched => 'Watched';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get emptyNoChannel => 'No channel';

  @override
  String get emptyNoResult => 'No result';

  @override
  String get emptyNoEpisode => 'No episode';

  @override
  String get noDescription => 'No description available.';

  @override
  String get loginServer => 'Server (http://…)';

  @override
  String get loginUser => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginConnect => 'Sign in';

  @override
  String get loginSavedProfiles => 'Saved profiles';

  @override
  String get loginNeedServer => 'Enter at least the server and username.';

  @override
  String get guideTitle => 'TV Guide';

  @override
  String get catchupTitle => 'Catch-up';

  @override
  String get catchupSubtitle =>
      'Replay the last few days on channels that offer catch-up.';

  @override
  String get catchupSelectChannel => 'Select a channel';

  @override
  String catchupNone(Object channel) {
    return 'No catch-up available for \"$channel\".\nNo EPG guide or catch-up not offered.';
  }

  @override
  String get catchupDownload => 'Download the replay';

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsFolder => 'Folder';

  @override
  String get downloadsClearDone => 'Clear finished';

  @override
  String downloadsInProgress(Object n) {
    return 'In progress ($n)';
  }

  @override
  String downloadsDone(Object n) {
    return 'Finished ($n)';
  }

  @override
  String get downloadsEmpty =>
      'No downloads.\n⬇ button on a movie, an episode or a replay.';

  @override
  String get downloadsQueued => 'queued';

  @override
  String get downloadsFailed => 'failed';

  @override
  String get downloadsCanceled => 'canceled';

  @override
  String get downloadsPlayHint => 'Downloaded · tap to play';

  @override
  String get downloadsReveal => 'Reveal in folder';

  @override
  String get downloadsRemove => 'Remove from list';

  @override
  String get downloadsCancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tabAccount => 'Account & subscription';

  @override
  String get tabPlayback => 'Playback & buffer';

  @override
  String get tabTheme => 'Theme';

  @override
  String get tabHome => 'Home';

  @override
  String get tabEpg => 'External EPG';

  @override
  String get tabCatalog => 'Catalog';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabTmdb => 'TMDB enrichment';

  @override
  String get tabTrakt => 'Trakt sync';

  @override
  String get tabSync => 'Device sync';

  @override
  String get tabAutoUpdate => 'Auto update';

  @override
  String get tabRecordings => 'Recordings';

  @override
  String get tabDownloads => 'Downloads';

  @override
  String get tabHistory => 'History';

  @override
  String get tabDiagnostic => 'Diagnostics';

  @override
  String get tabProfiles => 'Profiles';

  @override
  String get tabApp => 'Application';

  @override
  String get themeAppearance => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeAccent => 'Accent color';

  @override
  String get themeAccentHint => 'Applies immediately to the whole interface.';
}
