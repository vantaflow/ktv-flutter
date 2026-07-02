// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLive => 'البث المباشر';

  @override
  String get navMovies => 'أفلام';

  @override
  String get navSeries => 'مسلسلات';

  @override
  String get navGuide => 'الدليل';

  @override
  String get navCatchup => 'الإعادة';

  @override
  String get navDownloads => 'التنزيلات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get searchHint => 'ابحث عن القنوات والأفلام والمسلسلات…';

  @override
  String get railFavChannels => 'القنوات المفضلة';

  @override
  String get railMediaFavs => 'الأفلام والمسلسلات المفضلة';

  @override
  String get railResume => 'متابعة المشاهدة';

  @override
  String get railRecent => 'شوهد مؤخرًا';

  @override
  String get railWatchlist => 'قائمتي (Trakt)';

  @override
  String get railRecoMovies => 'موصى به لك';

  @override
  String get railRecoSeries => 'مسلسلات موصى بها';

  @override
  String get railLatestMovies => 'أحدث الأفلام';

  @override
  String get railLatestSeries => 'أحدث المسلسلات';

  @override
  String get actionPlay => 'تشغيل';

  @override
  String get actionWatch => 'مشاهدة';

  @override
  String get actionDownload => 'تنزيل';

  @override
  String get actionAddFav => 'إضافة إلى المفضلة';

  @override
  String get actionFav => 'مفضل';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get actionMarkWatched => 'تحديد كمشاهد';

  @override
  String get actionWatched => 'شوهد';

  @override
  String get language => 'اللغة';

  @override
  String get langSystem => 'النظام';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get emptyNoChannel => 'لا توجد قناة';

  @override
  String get emptyNoResult => 'لا توجد نتيجة';

  @override
  String get emptyNoEpisode => 'لا توجد حلقات';

  @override
  String get noDescription => 'لا يوجد وصف متاح.';

  @override
  String get loginServer => 'الخادم (http://…)';

  @override
  String get loginUser => 'اسم المستخدم';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginConnect => 'تسجيل الدخول';

  @override
  String get loginSavedProfiles => 'الملفات المحفوظة';

  @override
  String get loginNeedServer => 'أدخل الخادم واسم المستخدم على الأقل.';

  @override
  String get guideTitle => 'دليل القنوات';

  @override
  String get catchupTitle => 'الإعادة';

  @override
  String get catchupSubtitle =>
      'أعد تشغيل برامج الأيام الأخيرة على القنوات التي تدعم الإعادة.';

  @override
  String get catchupSelectChannel => 'اختر قناة';

  @override
  String catchupNone(Object channel) {
    return 'لا توجد إعادة متاحة لـ «$channel».\nلا يوجد دليل EPG أو الإعادة غير متوفرة.';
  }

  @override
  String get catchupDownload => 'تنزيل الإعادة';

  @override
  String get dayToday => 'اليوم';

  @override
  String get dayYesterday => 'أمس';

  @override
  String get downloadsTitle => 'التنزيلات';

  @override
  String get downloadsFolder => 'المجلد';

  @override
  String get downloadsClearDone => 'مسح المكتملة';

  @override
  String downloadsInProgress(Object n) {
    return 'قيد التنفيذ ($n)';
  }

  @override
  String downloadsDone(Object n) {
    return 'مكتملة ($n)';
  }

  @override
  String get downloadsEmpty =>
      'لا توجد تنزيلات.\nزر ⬇ على فيلم أو حلقة أو إعادة.';

  @override
  String get downloadsQueued => 'في الانتظار';

  @override
  String get downloadsFailed => 'فشل';

  @override
  String get downloadsCanceled => 'أُلغي';

  @override
  String get downloadsPlayHint => 'تم التنزيل · اضغط للتشغيل';

  @override
  String get downloadsReveal => 'إظهار في المجلد';

  @override
  String get downloadsRemove => 'إزالة من القائمة';

  @override
  String get downloadsCancel => 'إلغاء';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get tabAccount => 'الحساب والاشتراك';

  @override
  String get tabPlayback => 'التشغيل والتخزين المؤقت';

  @override
  String get tabTheme => 'المظهر';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabEpg => 'دليل EPG خارجي';

  @override
  String get tabCatalog => 'الكتالوج';

  @override
  String get tabCategories => 'الفئات';

  @override
  String get tabTmdb => 'إثراء TMDB';

  @override
  String get tabTrakt => 'مزامنة Trakt';

  @override
  String get tabSync => 'مزامنة الأجهزة';

  @override
  String get tabAutoUpdate => 'التحديث التلقائي';

  @override
  String get tabRecordings => 'التسجيلات';

  @override
  String get tabDownloads => 'التنزيلات';

  @override
  String get tabHistory => 'السجل';

  @override
  String get tabDiagnostic => 'التشخيص';

  @override
  String get tabProfiles => 'الملفات الشخصية';

  @override
  String get tabApp => 'التطبيق';

  @override
  String get themeAppearance => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeAccent => 'لون التمييز';

  @override
  String get themeAccentHint => 'يُطبَّق فورًا على كامل الواجهة.';

  @override
  String get filterShow => 'إظهار المرشحات';

  @override
  String get filterHide => 'إخفاء المرشحات';

  @override
  String get catAll => '⭐ الكل';

  @override
  String get emptyNoMovie => 'لا يوجد فيلم';

  @override
  String get emptyNoMovieFilter => 'لا يوجد فيلم لهذه المرشحات';

  @override
  String get emptyNoSeries => 'لا يوجد مسلسل';

  @override
  String get emptyNoSeriesFilter => 'لا يوجد مسلسل لهذه المرشحات';

  @override
  String get sortRecent => 'الأحدث';

  @override
  String get sortAZ => 'أ→ي';

  @override
  String get allRatings => 'كل التقييمات';

  @override
  String get hq4kHdr => '4K / HDR';

  @override
  String get searchMin => 'اكتب حرفين على الأقل';

  @override
  String get secNow => '📡 يُعرض الآن';

  @override
  String get secChannels => '📺 القنوات';

  @override
  String get secMovies => '🎬 أفلام';

  @override
  String get secSeries => '🎞️ مسلسلات';

  @override
  String get trackAudio => 'المسار الصوتي';

  @override
  String get trackSubtitles => 'الترجمة';

  @override
  String get trackOff => 'معطّل';

  @override
  String get trackAuto => 'تلقائي';

  @override
  String get trackLive => 'مباشر';

  @override
  String get playbackSettings => 'إعدادات التشغيل';

  @override
  String get speed => 'السرعة';

  @override
  String get audioBoost => 'تعزيز الصوت';

  @override
  String get subDelay => 'تأخير الترجمة';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get nextEpisode => 'الحلقة التالية';
}
