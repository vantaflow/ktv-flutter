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
  String get tabParental => 'Parental control';

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

  @override
  String get filterShow => 'Show filters';

  @override
  String get filterHide => 'Hide filters';

  @override
  String get catAll => '⭐ All';

  @override
  String get emptyNoMovie => 'No movie';

  @override
  String get emptyNoMovieFilter => 'No movie for these filters';

  @override
  String get emptyNoSeries => 'No series';

  @override
  String get emptyNoSeriesFilter => 'No series for these filters';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortAZ => 'A→Z';

  @override
  String get allRatings => 'All ratings';

  @override
  String get hq4kHdr => '4K / HDR';

  @override
  String get searchMin => 'Type at least 2 characters';

  @override
  String get secNow => '📡 On TV now';

  @override
  String get secChannels => '📺 Channels';

  @override
  String get secMovies => '🎬 Movies';

  @override
  String get secSeries => '🎞️ Series';

  @override
  String get trackAudio => 'Audio track';

  @override
  String get trackSubtitles => 'Subtitles';

  @override
  String get trackOff => 'Off';

  @override
  String get trackAuto => 'Auto';

  @override
  String get trackLive => 'Live';

  @override
  String get playbackSettings => 'Playback settings';

  @override
  String get speed => 'Speed';

  @override
  String get audioBoost => 'Audio boost';

  @override
  String get subDelay => 'Subtitle delay';

  @override
  String get reset => 'Reset';

  @override
  String get nextEpisode => 'Next episode';

  @override
  String get sAccErr => 'Couldn\'t fetch subscription info.';

  @override
  String get sNotConnected => 'Not connected.';

  @override
  String get sStatus => 'Status';

  @override
  String get sExpiration => 'Expiration';

  @override
  String get sConnections => 'Connections';

  @override
  String get sTrial => 'Trial';

  @override
  String get sUser => 'Username';

  @override
  String get sServer => 'Server';

  @override
  String get sCreatedOn => 'Created on';

  @override
  String get sTimezone => 'Timezone';

  @override
  String get sFormats => 'Formats';

  @override
  String get sUnlimited => 'Unlimited';

  @override
  String get sYes => 'Yes';

  @override
  String get sNo => 'No';

  @override
  String get sBufferHint =>
      '\"Low latency\" = closer to live. \"Stable\" = large buffer, fewer interruptions.';

  @override
  String get sBufLow => 'Low latency';

  @override
  String get sBufBalanced => 'Balanced (default)';

  @override
  String get sBufStable => 'Stable (large buffer)';

  @override
  String get sBufApplied =>
      'Applied on next playback (mpv cache-secs property).';

  @override
  String get sAutoplay => 'Auto-play next episode';

  @override
  String get sAutoplayHint => 'Continues the series at the end of an episode';

  @override
  String get sEpgHint =>
      'Provider XMLTV guide (get_short_epg is blocked, 403). 6 h cache.';

  @override
  String get sRefreshEpg => 'Refresh EPG';

  @override
  String get sEpgReloading => 'Reloading EPG…';

  @override
  String get sCatalogHint =>
      'Reload movies & series from the provider (after new content is added).';

  @override
  String get sRefreshMovies => 'Refresh movies';

  @override
  String get sRefreshSeries => 'Refresh series';

  @override
  String get sRefreshAll => 'Refresh everything';

  @override
  String get sMoviesRefreshed => 'Movies refreshed';

  @override
  String get sSeriesRefreshed => 'Series refreshed';

  @override
  String get sCatalogRefreshed => 'Catalog and EPG refreshed';

  @override
  String get sTmdbHint =>
      'Posters, ratings, synopsis and cast for movies & series.';

  @override
  String get sTmdbEnable => 'Enable TMDB';

  @override
  String get sTmdbLang => 'Metadata language';

  @override
  String get sTmdbKeyHint =>
      'Personal v4 key (optional — otherwise KTV proxy):';

  @override
  String get sTmdbKey => 'TMDB v4 key (optional)';

  @override
  String get sTraktHint =>
      'Leave empty to use KTV (recommended): just connect with the device code. Otherwise paste your own Trakt Client ID + Secret.';

  @override
  String get sClientId => 'Client ID';

  @override
  String get sClientSecret => 'Client Secret';

  @override
  String get sTraktScrobble => 'Mark watched automatically at the end';

  @override
  String get sTraktReco => '\"Recommended for you\" suggestions';

  @override
  String get sTraktConnect => 'Connect (device code)';

  @override
  String get sTraktConnDialog => 'Trakt connection';

  @override
  String get sGoTo => 'Go to:';

  @override
  String get sEnterCode => 'and enter the code:';

  @override
  String get sTraktCodeErr => 'Trakt code request failed.';

  @override
  String get sNeedClientId => 'Enter the Client ID first.';

  @override
  String get sSyncHint1 =>
      'Sync resume, favorites, history, categories and profiles across your devices. ';

  @override
  String get sSyncHint2 =>
      'Identity = your Trakt account. Everything is encrypted with your passphrase: the server can\'t read anything.';

  @override
  String get sSyncNeedTrakt => 'Connect Trakt first (\"Trakt sync\" section).';

  @override
  String get sPassphraseLabel => 'Passphrase (same on all your devices)';

  @override
  String get sPassphraseChoose => 'Choose a passphrase';

  @override
  String get sPassphraseSet => 'Already set — type to change';

  @override
  String get sSyncEnable => 'Enable sync';

  @override
  String get sSyncNow => 'Sync now';

  @override
  String get sDisable => 'Disable';

  @override
  String get sPassphraseShort => 'Passphrase too short (min. 4 characters).';

  @override
  String get sSyncEnabledNoSync => 'Enabled — not synced yet.';

  @override
  String get sSyncDisabled => 'Disabled.';

  @override
  String get sSyncServer => 'Sync server (advanced)';

  @override
  String get sAutoRefreshHint =>
      'Periodically reloads channels, movies, series and EPG in the background.';

  @override
  String get sFrequency => 'Frequency';

  @override
  String get sEvery30 => 'Every 30 min';

  @override
  String get sEvery1h => 'Every hour';

  @override
  String get sEvery3h => 'Every 3 h';

  @override
  String get sEvery6h => 'Every 6 h';

  @override
  String get sRefreshNow => 'Refresh now';

  @override
  String get sRefreshed => 'Refreshed';

  @override
  String get sNoRecording => 'No recording.';

  @override
  String get sStop => 'Stop';

  @override
  String get sInProgress => 'In progress…';

  @override
  String get sCancel => 'Cancel';

  @override
  String get sNoDownload => 'No downloads. ⬇ button on a movie or episode.';

  @override
  String get sNoHistory => 'No history.';

  @override
  String get sHistoryCleared => 'History cleared';

  @override
  String get sClear => 'Clear';

  @override
  String get sDiagHint =>
      'Tests API latency, connections and stream throughput.';

  @override
  String get sRunTest => 'Run test';

  @override
  String get sLogout => 'Sign out';

  @override
  String get sActivate => 'Activate';

  @override
  String get sManage => 'Manage';

  @override
  String get sCatManageHint =>
      'Choose which provider categories to show or hide, for each section. ';

  @override
  String get sCatDefault =>
      'Without settings, KTV applies its default filter (FR / Morocco / beIN Sports).';

  @override
  String get sHomeRowsHint => 'Check the rows to show on the home screen.';

  @override
  String get sCheckUpdates => 'Check for updates';

  @override
  String get sSeeReleases => 'See releases';

  @override
  String get sUpdateErr => 'Couldn\'t check for updates.';

  @override
  String get sUpToDate => '✓ You have the latest version.';

  @override
  String get sDownloadErr => 'Download failed.';

  @override
  String get sChangeFolder => 'Change folder…';

  @override
  String get sChooseFolder => 'Choose folder';

  @override
  String get sOpen => 'Open';

  @override
  String get sNoData => 'no data';

  @override
  String get sQueued2 => 'queued';

  @override
  String get sFailed2 => 'failed';

  @override
  String get sCanceled2 => 'canceled';

  @override
  String get sFreqOff => 'Off';

  @override
  String dlSeasonBtn(Object n) {
    return 'Season ($n)';
  }

  @override
  String dlWholeSeries(Object n) {
    return 'Whole series ($n)';
  }

  @override
  String dlEnqueued(Object n) {
    return '$n episodes added to downloads';
  }

  @override
  String seasonN(Object n) {
    return 'Season $n';
  }

  @override
  String episodeN(Object n) {
    return 'Episode $n';
  }

  @override
  String get catchupNoArchive => 'No channel offers catch-up on this provider.';

  @override
  String get catchupWatch => 'Watch again (catch-up)';

  @override
  String get catchupUnavailable => 'Catch-up not available on this channel.';

  @override
  String get epgSchedule => 'Schedule';

  @override
  String get epgRecord => 'Record';

  @override
  String get hwdec => 'Hardware decoding';

  @override
  String get hwdecHint =>
      'Disable if playback crashes or freezes (especially on Windows). Applied on next playback.';

  @override
  String get syncLoginBtn => 'Sign in from another device';

  @override
  String get syncOrManual => 'OR MANUAL LOGIN';

  @override
  String get syncWaiting => 'Waiting for authorization…';

  @override
  String get syncTraktCanceled => 'Trakt connection canceled or expired.';

  @override
  String get syncNoProfile =>
      'No synced profile found. Enable sync first on an already-connected device.';

  @override
  String get updTitle => 'Update available';

  @override
  String updBody(Object v, Object cur) {
    return 'KTV $v is available (you have $cur).';
  }

  @override
  String get updNow => 'Update';

  @override
  String get updLater => 'Later';

  @override
  String get updDownloading => 'Downloading update…';

  @override
  String get updInstalling => 'Installing… the app will restart.';

  @override
  String get updCheckAtStart => 'Check for updates on startup';
}
