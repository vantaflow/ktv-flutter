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

  @override
  String get sAccErr => 'تعذّر جلب معلومات الاشتراك.';

  @override
  String get sNotConnected => 'غير متصل.';

  @override
  String get sStatus => 'الحالة';

  @override
  String get sExpiration => 'انتهاء الصلاحية';

  @override
  String get sConnections => 'الاتصالات';

  @override
  String get sTrial => 'تجريبي';

  @override
  String get sUser => 'المستخدم';

  @override
  String get sServer => 'الخادم';

  @override
  String get sCreatedOn => 'أُنشئ في';

  @override
  String get sTimezone => 'المنطقة الزمنية';

  @override
  String get sFormats => 'الصيغ';

  @override
  String get sUnlimited => 'غير محدود';

  @override
  String get sYes => 'نعم';

  @override
  String get sNo => 'لا';

  @override
  String get sBufferHint =>
      '«زمن انتقال منخفض» = أقرب للبث المباشر. «مستقر» = تخزين مؤقت أكبر وانقطاعات أقل.';

  @override
  String get sBufLow => 'زمن انتقال منخفض';

  @override
  String get sBufBalanced => 'متوازن (افتراضي)';

  @override
  String get sBufStable => 'مستقر (تخزين مؤقت كبير)';

  @override
  String get sBufApplied =>
      'يُطبَّق عند التشغيل التالي (خاصية mpv cache-secs).';

  @override
  String get sAutoplay => 'تشغيل الحلقة التالية تلقائيًا';

  @override
  String get sAutoplayHint => 'يتابع المسلسل عند انتهاء الحلقة';

  @override
  String get sEpgHint =>
      'دليل XMLTV من المزود (get_short_epg محجوب 403). تخزين مؤقت 6 س.';

  @override
  String get sRefreshEpg => 'تحديث الدليل';

  @override
  String get sEpgReloading => 'جارٍ إعادة تحميل الدليل…';

  @override
  String get sCatalogHint =>
      'أعد تحميل الأفلام والمسلسلات من المزود (بعد إضافة محتوى جديد).';

  @override
  String get sRefreshMovies => 'تحديث الأفلام';

  @override
  String get sRefreshSeries => 'تحديث المسلسلات';

  @override
  String get sRefreshAll => 'تحديث الكل';

  @override
  String get sMoviesRefreshed => 'تم تحديث الأفلام';

  @override
  String get sSeriesRefreshed => 'تم تحديث المسلسلات';

  @override
  String get sCatalogRefreshed => 'تم تحديث الكتالوج والدليل';

  @override
  String get sTmdbHint => 'ملصقات وتقييمات وملخصات وطاقم للأفلام والمسلسلات.';

  @override
  String get sTmdbEnable => 'تفعيل TMDB';

  @override
  String get sTmdbLang => 'لغة البيانات الوصفية';

  @override
  String get sTmdbKeyHint => 'مفتاح v4 خاص (اختياري — وإلا وسيط KTV):';

  @override
  String get sTmdbKey => 'مفتاح TMDB v4 (اختياري)';

  @override
  String get sTraktHint =>
      'اتركه فارغًا لاستخدام KTV (مستحسن): اتصل فقط برمز الجهاز. أو ألصق Client ID + Secret الخاصين بك من Trakt.';

  @override
  String get sClientId => 'معرّف العميل';

  @override
  String get sClientSecret => 'سر العميل';

  @override
  String get sTraktScrobble => 'تحديد كمشاهد تلقائيًا عند الانتهاء';

  @override
  String get sTraktReco => 'اقتراحات «موصى به لك»';

  @override
  String get sTraktConnect => 'اتصال (رمز الجهاز)';

  @override
  String get sTraktConnDialog => 'اتصال Trakt';

  @override
  String get sGoTo => 'اذهب إلى:';

  @override
  String get sEnterCode => 'وأدخل الرمز:';

  @override
  String get sTraktCodeErr => 'فشل طلب رمز Trakt.';

  @override
  String get sNeedClientId => 'أدخل معرّف العميل أولًا.';

  @override
  String get sSyncHint1 =>
      'يزامن المتابعة والمفضلة والسجل والفئات والملفات بين أجهزتك. ';

  @override
  String get sSyncHint2 =>
      'الهوية = حساب Trakt. كل شيء مشفّر بعبارتك السرية: لا يمكن للخادم قراءة أي شيء.';

  @override
  String get sSyncNeedTrakt => 'اتصل بـ Trakt أولًا (قسم «مزامنة Trakt»).';

  @override
  String get sPassphraseLabel => 'العبارة السرية (نفسها على كل أجهزتك)';

  @override
  String get sPassphraseChoose => 'اختر عبارة سرية';

  @override
  String get sPassphraseSet => 'محدّدة مسبقًا — اكتب للتغيير';

  @override
  String get sSyncEnable => 'تفعيل المزامنة';

  @override
  String get sSyncNow => 'زامن الآن';

  @override
  String get sDisable => 'تعطيل';

  @override
  String get sPassphraseShort => 'العبارة قصيرة جدًا (4 أحرف على الأقل).';

  @override
  String get sSyncEnabledNoSync => 'مُفعّلة — لم تتم المزامنة بعد.';

  @override
  String get sSyncDisabled => 'معطّلة.';

  @override
  String get sSyncServer => 'خادم المزامنة (متقدّم)';

  @override
  String get sAutoRefreshHint =>
      'يعيد تحميل القنوات والأفلام والمسلسلات والدليل دوريًا في الخلفية.';

  @override
  String get sFrequency => 'التكرار';

  @override
  String get sEvery30 => 'كل 30 دقيقة';

  @override
  String get sEvery1h => 'كل ساعة';

  @override
  String get sEvery3h => 'كل 3 ساعات';

  @override
  String get sEvery6h => 'كل 6 ساعات';

  @override
  String get sRefreshNow => 'حدّث الآن';

  @override
  String get sRefreshed => 'تم التحديث';

  @override
  String get sNoRecording => 'لا توجد تسجيلات.';

  @override
  String get sStop => 'إيقاف';

  @override
  String get sInProgress => 'قيد التنفيذ…';

  @override
  String get sCancel => 'إلغاء';

  @override
  String get sNoDownload => 'لا توجد تنزيلات. زر ⬇ على فيلم أو حلقة.';

  @override
  String get sNoHistory => 'لا يوجد سجل.';

  @override
  String get sHistoryCleared => 'تم مسح السجل';

  @override
  String get sClear => 'مسح';

  @override
  String get sDiagHint => 'يختبر زمن استجابة API والاتصالات وسرعة التدفق.';

  @override
  String get sRunTest => 'بدء الاختبار';

  @override
  String get sLogout => 'تسجيل الخروج';

  @override
  String get sActivate => 'تفعيل';

  @override
  String get sManage => 'إدارة';

  @override
  String get sCatManageHint =>
      'اختر فئات المزود التي تريد إظهارها أو إخفاءها لكل قسم. ';

  @override
  String get sCatDefault =>
      'بدون ضبط، يطبّق KTV مرشحه الافتراضي (FR / المغرب / beIN Sports).';

  @override
  String get sHomeRowsHint => 'حدّد الصفوف المراد عرضها في الشاشة الرئيسية.';

  @override
  String get sCheckUpdates => 'التحقق من التحديثات';

  @override
  String get sSeeReleases => 'عرض الإصدارات';

  @override
  String get sUpdateErr => 'تعذّر التحقق من التحديثات.';

  @override
  String get sUpToDate => '✓ لديك أحدث إصدار.';

  @override
  String get sDownloadErr => 'فشل التنزيل.';

  @override
  String get sChangeFolder => 'تغيير المجلد…';

  @override
  String get sChooseFolder => 'اختيار المجلد';

  @override
  String get sOpen => 'فتح';

  @override
  String get sNoData => 'لا توجد بيانات';

  @override
  String get sQueued2 => 'في الانتظار';

  @override
  String get sFailed2 => 'فشل';

  @override
  String get sCanceled2 => 'أُلغي';

  @override
  String get sFreqOff => 'معطّلة';

  @override
  String dlSeasonBtn(Object n) {
    return 'الموسم ($n)';
  }

  @override
  String dlWholeSeries(Object n) {
    return 'المسلسل كامل ($n)';
  }

  @override
  String dlEnqueued(Object n) {
    return 'تمت إضافة $n حلقة إلى التنزيلات';
  }

  @override
  String seasonN(Object n) {
    return 'الموسم $n';
  }

  @override
  String episodeN(Object n) {
    return 'الحلقة $n';
  }

  @override
  String get catchupNoArchive => 'لا توجد قناة تدعم الإعادة لدى هذا المزوّد.';

  @override
  String get catchupWatch => 'إعادة المشاهدة';

  @override
  String get catchupUnavailable => 'الإعادة غير متاحة على هذه القناة.';

  @override
  String get epgSchedule => 'جدولة';

  @override
  String get epgRecord => 'تسجيل';

  @override
  String get hwdec => 'فك التشفير بالعتاد';

  @override
  String get hwdecHint =>
      'عطّله إذا تعطّل التشغيل أو تجمّد (خاصة على Windows). يُطبَّق عند التشغيل التالي.';

  @override
  String get syncLoginBtn => 'تسجيل الدخول من جهاز آخر';

  @override
  String get syncOrManual => 'أو تسجيل الدخول يدويًا';

  @override
  String get syncWaiting => 'في انتظار الإذن…';

  @override
  String get syncTraktCanceled => 'أُلغي اتصال Trakt أو انتهت صلاحيته.';

  @override
  String get syncNoProfile =>
      'لم يُعثر على ملف متزامن. فعّل المزامنة أولًا على جهاز متصل.';

  @override
  String get updTitle => 'يتوفر تحديث';

  @override
  String updBody(Object v, Object cur) {
    return 'يتوفر KTV $v (لديك $cur).';
  }

  @override
  String get updNow => 'تحديث';

  @override
  String get updLater => 'لاحقًا';

  @override
  String get updDownloading => 'جارٍ تنزيل التحديث…';

  @override
  String get updCheckAtStart => 'التحقق من التحديثات عند البدء';
}
