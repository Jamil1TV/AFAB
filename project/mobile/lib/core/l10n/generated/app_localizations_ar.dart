// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'AFAB';

  @override
  String get appTagline => 'المساعد المالي الذكي للأعمال';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonReload => 'تحديث';

  @override
  String get commonLoading => 'جاري التحميل...';

  @override
  String get commonNoData => 'لا توجد بيانات';

  @override
  String get commonComingSoon => 'قريباً';

  @override
  String get commonComingSoonDesc =>
      'سيتم توفير هذا القسم في المرحلة القادمة من التطبيق.';

  @override
  String get commonViewAll => 'عرض الكل';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonCreate => 'إنشاء';

  @override
  String get commonActive => 'نشط';

  @override
  String get commonLocked => 'مقفل';

  @override
  String get commonReadOnly => 'للقراءة فقط';

  @override
  String get commonOfflineBanner =>
      'أنت غير متصل بالإنترنت. تتطلب بعض الإجراءات اتصالاً نشطاً.';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get languageSwitchShort => 'EN';

  @override
  String get periodWeekly => 'أسبوعي';

  @override
  String get periodMonthly => 'شهري';

  @override
  String get periodYearly => 'سنوي';

  @override
  String get periodVsLastWeek => 'مقارنة بالأسبوع الماضي';

  @override
  String get periodVsLastMonth => 'مقارنة بالشهر الماضي';

  @override
  String get periodVsLastYear => 'مقارنة بالعام الماضي';

  @override
  String get authLoginTab => 'تسجيل الدخول';

  @override
  String get authSignupTab => 'إنشاء حساب';

  @override
  String get authLoginTitle => 'تسجيل الدخول إلى حسابك';

  @override
  String get authLoginSubtitle => 'مرحباً بعودتك! يرجى إدخال بياناتك.';

  @override
  String get authSignupTitle => 'إنشاء حساب جديد';

  @override
  String get authSignupSubtitle => 'انضم إلى آلاف أصحاب الأعمال اليوم.';

  @override
  String get authFirstName => 'الاسم الأول';

  @override
  String get authFirstNamePlaceholder => 'سارة';

  @override
  String get authLastName => 'اسم العائلة';

  @override
  String get authLastNamePlaceholder => 'أحمد';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authPasswordPlaceholder => 'أدخل كلمة المرور';

  @override
  String get authPasswordCreatePlaceholder => 'أنشئ كلمة مرور';

  @override
  String get authBusinessName => 'اسم الشركة';

  @override
  String get authBusinessNamePlaceholder => 'شركة التقنية';

  @override
  String get authLoginButton => 'تسجيل الدخول';

  @override
  String get authSignupButton => 'إنشاء حساب';

  @override
  String get authRememberMe => 'تذكرني لمدة 30 يوماً';

  @override
  String get authForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authHasAccount => 'لديك حساب بالفعل؟';

  @override
  String get authVerifyEmailTitle => 'تأكيد البريد الإلكتروني';

  @override
  String authVerifyEmailSubtitle(String email) {
    return 'أرسلنا رمز تأكيد مكون من 6 أرقام إلى $email';
  }

  @override
  String get authVerifyButton => 'تأكيد البريد الإلكتروني';

  @override
  String get authDidntReceiveCode => 'لم تصلك الرسالة؟';

  @override
  String get authResendCode => 'إعادة إرسال الرمز';

  @override
  String authResendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get authCodeResent => 'تم إرسال رمز التأكيد! تحقق من صندوق الوارد.';

  @override
  String get authVerifySuccess => 'تم تأكيد البريد الإلكتروني بنجاح!';

  @override
  String get authVerifyCodeIncomplete =>
      'يرجى إدخال الرمز الكامل المكون من 6 أرقام.';

  @override
  String get authNoEmailFound =>
      'الجلسة غير صالحة. يرجى إنشاء حساب أو تسجيل الدخول مجدداً.';

  @override
  String get authUseDifferentAccount => 'تسجيل الخروج واستخدام حساب آخر';

  @override
  String authDevOtpNotice(String code) {
    return 'رمز التحقق للتطوير: $code';
  }

  @override
  String get authForgotPasswordTitle => 'هل نسيت كلمة المرور؟';

  @override
  String get authForgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String get authEmailRequired => 'البريد الإلكتروني مطلوب.';

  @override
  String get authEmailInvalid => 'يرجى إدخال بريد إلكتروني صالح.';

  @override
  String get authFieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get authPasswordMinLength =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.';

  @override
  String get authSendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get authResetEmailSent => 'تحقق من بريدك الإلكتروني';

  @override
  String authResetEmailSentSubtitle(String email) {
    return 'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get authHaveResetToken => 'هل لديك رمز إعادة تعيين؟';

  @override
  String get authEnterTokenManually => 'إدخال الرمز يدوياً';

  @override
  String get authBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get authResetPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get authResetPasswordSubtitle =>
      'يجب أن تستوفي كلمة المرور الجديدة جميع المتطلبات أدناه.';

  @override
  String get authResetPasswordValidating =>
      'جاري التحقق من رابط إعادة التعيين...';

  @override
  String get authResetTokenLabel => 'رمز إعادة التعيين';

  @override
  String get authResetTokenHint => 'الصق رمز إعادة تعيين كلمة المرور';

  @override
  String get authValidateTokenButton => 'التحقق من الرمز';

  @override
  String get authNewPassword => 'كلمة المرور الجديدة';

  @override
  String get authNewPasswordPlaceholder => 'أدخل كلمة المرور الجديدة';

  @override
  String get authConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authConfirmPasswordPlaceholder => 'أعد إدخال كلمة المرور الجديدة';

  @override
  String get authResetButton => 'إعادة تعيين كلمة المرور';

  @override
  String get authResetPasswordWeak => 'كلمة المرور لا تستوفي جميع المتطلبات.';

  @override
  String get authResetPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get authPasswordResetSuccessTitle => 'تم إعادة تعيين كلمة المرور!';

  @override
  String get authPasswordResetSuccessMessage =>
      'تم إعادة تعيين كلمة المرور بنجاح. يمكنك تسجيل الدخول الآن.';

  @override
  String get authTokenExpiredTitle => 'انتهت صلاحية الرابط';

  @override
  String get authTokenExpiredMessage =>
      'انتهت صلاحية رابط إعادة تعيين كلمة المرور. يرجى طلب رابط جديد.';

  @override
  String get authTokenInvalidTitle => 'رابط غير صالح';

  @override
  String get authTokenInvalidMessage =>
      'رابط إعادة تعيين كلمة المرور غير صالح أو تم استخدامه بالفعل.';

  @override
  String get authRequestNewLink => 'طلب رابط جديد';

  @override
  String get authPwStrengthLabel => 'قوة كلمة المرور';

  @override
  String get authPwStrengthWeak => 'ضعيفة';

  @override
  String get authPwStrengthFair => 'مقبولة';

  @override
  String get authPwStrengthGood => 'جيدة';

  @override
  String get authPwStrengthStrong => 'قوية';

  @override
  String get authPwStrengthVeryStrong => 'قوية جداً';

  @override
  String get authPwReqLength => '8 أحرف على الأقل';

  @override
  String get authPwReqUppercase => 'حرف كبير واحد';

  @override
  String get authPwReqLowercase => 'حرف صغير واحد';

  @override
  String get authPwReqNumber => 'رقم واحد';

  @override
  String get authPwReqSpecial => 'رمز خاص واحد';

  @override
  String get authTwoFactorTitle => 'المصادقة الثنائية (2FA)';

  @override
  String get authTwoFactorSubtitle =>
      'أدخل الرمز المكون من 6 أرقام من تطبيق المصادقة لإتمام تسجيل الدخول.';

  @override
  String get authTwoFactorVerifyButton => 'تحقق وتسجيل الدخول';

  @override
  String get authTwoFactorEnterCode => 'رمز المصادقة';

  @override
  String get authUseBackupCode => 'استخدام رمز استرداد الطوارئ الاحتياطي';

  @override
  String get authUseTotpCode => 'استخدام رمز المصادقة المكون من 6 أرقام';

  @override
  String get authBackupCodeLabel => 'رمز الاسترداد الاحتياطي';

  @override
  String get authBackupCodePlaceholder => 'مثال: ABCD-1234';

  @override
  String get authErrorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authErrorAccountDisabled => 'حسابك غير نشط.';

  @override
  String get authErrorAccountLocked =>
      'تم قفل حسابك مؤقتاً بسبب محاولات تسجيل دخول فاشلة.';

  @override
  String get authErrorRateLimited =>
      'طلبات كثيرة جداً. يرجى الانتظار والمحاولة مرة أخرى.';

  @override
  String get authErrorNetworkFailure =>
      'تعذر الاتصال بالخادم. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';

  @override
  String get authErrorServerFailure =>
      'حدث خطأ ما. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get authErrorInvalid2FaCode =>
      'رمز المصادقة أو رمز الاسترداد الاحتياطي غير صالح.';

  @override
  String get authErrorSessionExpired =>
      'انتهت جلستك. يرجى تسجيل الدخول مجدداً.';

  @override
  String onboardingStep(int step) {
    return 'الخطوة $step من 3';
  }

  @override
  String get onboardingStep1Tab => 'معلومات الشركة';

  @override
  String get onboardingStep2Tab => 'الإعداد المالي';

  @override
  String get onboardingStep3Tab => 'المراجعة والتأكيد';

  @override
  String get onboardingStep1Title => 'أخبرنا عن شركتك';

  @override
  String get onboardingStep1Subtitle =>
      'يساعدنا هذا في تخصيص التقارير المالية ورؤى الذكاء الاصطناعي لك.';

  @override
  String get onboardingStep2Title => 'إعداد تفضيلاتك المالية';

  @override
  String get onboardingStep2Subtitle =>
      'حدد العملة الأساسية، والمنطقة الزمنية، وبداية السنة المالية.';

  @override
  String get onboardingStep3Title => 'أنت جاهز للبدء!';

  @override
  String get onboardingStep3Subtitle => 'راجع إعدادات شركتك أدناه.';

  @override
  String get onboardingCountryLabel => 'بلد النشاط';

  @override
  String get onboardingIndustryLabel => 'قطاع العمل';

  @override
  String get onboardingBusinessTypeLabel => 'نوع الكيان';

  @override
  String get onboardingCurrencyLabel => 'العملة الأساسية';

  @override
  String get onboardingTimezoneLabel => 'المنطقة الزمنية';

  @override
  String get onboardingFiscalYearLabel => 'بداية السنة المالية';

  @override
  String get onboardingSummaryCountry => 'الدولة';

  @override
  String get onboardingSummaryIndustry => 'القطاع';

  @override
  String get onboardingSummaryBusinessType => 'نوع الكيان';

  @override
  String get onboardingSummaryCurrency => 'العملة الأساسية';

  @override
  String get onboardingSummaryTimezone => 'المنطقة الزمنية';

  @override
  String get onboardingSummaryFiscalYear => 'بداية السنة المالية';

  @override
  String get onboardingSearchHint => 'بحث...';

  @override
  String get onboardingLaunchDashboard => 'الانتقال للوحة التحكم';

  @override
  String get splashTagline => 'المساعد المالي الذكي للأعمال';

  @override
  String get splashRestoring => 'جاري استعادة مساحة عملك الآمنة...';

  @override
  String get splashOfflineTitle => 'مشكلة في الاتصال';

  @override
  String get splashOfflineSubtitle =>
      'تعذر الوصول إلى خوادم AFAB للتحقق من جلستك.';

  @override
  String get splashContinueToLogin => 'الانتقال لتسجيل الدخول';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navFinance => 'المالية';

  @override
  String get navCopilot => 'المساعد';

  @override
  String get navInvoices => 'الفواتير';

  @override
  String get navMore => 'المزيد';

  @override
  String get navOverview => 'نظرة عامة';

  @override
  String get navTransactions => 'المعاملات';

  @override
  String get navExpenses => 'المصروفات';

  @override
  String get navRevenue => 'الإيرادات';

  @override
  String get navCustomers => 'العملاء';

  @override
  String get navBudgets => 'الميزانيات';

  @override
  String get navRecurring => 'المتكررة';

  @override
  String get navReports => 'التقارير';

  @override
  String get navCurrencies => 'العملات والصرف';

  @override
  String get navAiAssistant => 'المساعد الذكي';

  @override
  String get navCalendar => 'التقويم';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navPlans => 'الخطط والفوترة';

  @override
  String get navNewBadge => 'جديد';

  @override
  String get navLogout => 'تسجيل الخروج';

  @override
  String dashboardGoodMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String dashboardGoodAfternoon(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String dashboardGoodEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get dashboardSubtitle => 'إليك ما يحدث في عملك اليوم.';

  @override
  String get dashboardTotalRevenue => 'إجمالي الإيرادات';

  @override
  String get dashboardTotalExpenses => 'إجمالي المصروفات';

  @override
  String get dashboardNetProfit => 'صافي الربح';

  @override
  String get dashboardCashFlow => 'التدفق النقدي';

  @override
  String get dashboardRevenueChartTitle => 'الإيرادات والمصروفات';

  @override
  String get dashboardRevenueChartSubtitle =>
      'أداء التدفق النقدي خلال آخر 6 أشهر';

  @override
  String get dashboardRevenueLabel => 'الإيرادات';

  @override
  String get dashboardExpensesLabel => 'المصروفات';

  @override
  String get dashboardAwaitingData => 'بانتظار البيانات';

  @override
  String get dashboardExpenseCategoriesTitle => 'فئات المصروفات';

  @override
  String get dashboardExpenseCategoriesTotal => 'المجموع';

  @override
  String get dashboardExpenseCategoriesEmpty =>
      'لا يوجد توزيع للمصروفات في هذه الفترة بعد.';

  @override
  String get dashboardAiTitle => 'رؤى المساعد الذكي';

  @override
  String get dashboardAiLivePulse => 'نبض مباشر';

  @override
  String get dashboardAiAskBtn => 'اسأل المساعد الذكي';

  @override
  String get dashboardAiInvestigate => 'تحليل عبر المساعد';

  @override
  String get dashboardAiAwaitingActivity => 'بانتظار النشاط المالي';

  @override
  String get dashboardAiAwaitingActivityDesc =>
      'سجل معاملات أو فواتير لتفعيل تنبيهات النبض المالي المباشر.';

  @override
  String get dashboardRecentTransactionsTitle => 'أحدث المعاملات';

  @override
  String get dashboardRecentTransactionsEmpty => 'لم يتم تسجيل معاملات بعد.';

  @override
  String get dashboardBudgetsTitle => 'تقدم الميزانيات';

  @override
  String dashboardBudgetsSubtitleActive(int active, int over, int approaching) {
    return '$active نشطة • $over متجاوزة • $approaching قريبة من الحد';
  }

  @override
  String get dashboardBudgetsSubtitleEmpty =>
      'ضع حدود إنفاق شهرية أو حسب الفئة لمتابعة تكاليف عملك.';

  @override
  String get dashboardBudgetsManageLink => 'إدارة الميزانيات';

  @override
  String get dashboardBudgetsEmpty => 'لا توجد ميزانيات نشطة للفترة الحالية.';

  @override
  String get dashboardBudgetsOverBy => 'تجاوز بمقدار';

  @override
  String get dashboardBudgetsRemaining => 'المتبقي';

  @override
  String get dashboardBudgetsOverLabel => 'تجاوز الحد';

  @override
  String get dashboardBudgetsApproachingLabel => 'قريب من الحد';

  @override
  String get dashboardBudgetsOnTrackLabel => 'ضمن المسار';

  @override
  String get dashboardRemindersTitle => 'التذكيرات القادمة';

  @override
  String get dashboardRemindersEmpty =>
      'لا توجد تنبيهات عاجلة للميزانيات أو الفواتير.';

  @override
  String get dashboardCustomersTitle => 'أفضل العملاء';

  @override
  String get dashboardCustomersEmpty => 'لا يوجد نشاط مدفوع للعملاء بعد.';

  @override
  String get dashboardCustomersInRevenue => 'من الإيرادات';

  @override
  String get dashboardUpgradeTitle => 'عزز رؤاك المالية';

  @override
  String get dashboardUpgradeDesc =>
      'افتح حصصاً أكبر للمساعد الذكي وإدارة مساحات عمل متعددة وتقارير متقدمة.';

  @override
  String get dashboardUpgradeBtn => 'الترقية الآن';

  @override
  String get dashboardUpgradeProCta => 'الترقية إلى Pro';

  @override
  String get dashboardLoadError => 'تعذر تحميل لوحة التحكم المالية.';

  @override
  String get businessSwitcherTitle => 'مساحات العمل';

  @override
  String businessSwitcherCapacity(int editable, int limit) {
    return '$editable / $limit نشطة';
  }

  @override
  String get businessSwitcherAddNew => 'إضافة شركة';

  @override
  String get businessSwitcherCreateTitle => 'إنشاء شركة جديدة';

  @override
  String get businessSwitcherNameLabel => 'اسم الشركة';

  @override
  String get businessSwitcherNamePlaceholder => 'مثال: استوديو النور';

  @override
  String get businessSwitcherCurrencyLabel => 'العملة الأساسية';

  @override
  String get businessSwitcherCreateBtn => 'إنشاء مساحة العمل';

  @override
  String get businessSwitcherCreateSuccess => 'تم إنشاء مساحة العمل وتفعيلها.';

  @override
  String businessSwitcherSwitched(String name) {
    return 'تم التبديل إلى $name';
  }

  @override
  String get businessSwitcherLockedTitle => 'مساحة العمل مقفلة (للقراءة فقط)';

  @override
  String businessSwitcherLockedDesc(String name) {
    return 'تتيح خطتك الحالية عدداً أقل من مساحات العمل النشطة. بيانات $name محفوظة بأمان، ولكن التعديل أو التبديل يتطلب إعادة التخصيص أو ترقية خطتك.';
  }

  @override
  String get businessSwitcherLimitTitle => 'تم الوصول إلى حد الشركات';

  @override
  String businessSwitcherLimitDesc(int limit) {
    return 'تتيح خطتك الحالية حتى $limit مساحات عمل نشطة مملوكة. قم بالترقية إلى Plus أو Pro لإضافة المزيد.';
  }

  @override
  String get businessSwitcherManagePlans => 'عرض الخطط والتخصيص';

  @override
  String get businessRoleOwner => 'المالك';

  @override
  String get businessRoleAdmin => 'مدير';

  @override
  String get businessRoleMember => 'عضو';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات غير مقروءة';

  @override
  String get notificationsEmptyDesc =>
      'ستظهر هنا تنبيهات الفوترة ومساحة العمل والحساب الجديدة.';

  @override
  String bannerPastDueTitle(int hours) {
    return 'تأخر السداد — متبقي $hours ساعة مهلة';
  }

  @override
  String get bannerPastDueDesc =>
      'حدّث وسيلة الدفع للحفاظ على ميزات Plus/Pro ومساحات العمل نشطة.';

  @override
  String get bannerAllocationTitle => 'مطلوب تخصيص مساحات العمل';

  @override
  String get bannerAllocationDesc =>
      'اختر الشركات التي تبقى نشطة ضمن حد خطتك الحالية.';

  @override
  String get bannerManageAction => 'إدارة';

  @override
  String get moreHubSectionOperations => 'المال والعمليات';

  @override
  String get moreHubSectionIntelligence => 'الذكاء المالي';

  @override
  String get moreHubSectionWorkspace => 'مساحة العمل والتفضيلات';

  @override
  String get moreHubPreferences => 'التفضيلات السريعة';

  @override
  String get moreHubThemeMode => 'مظهر التطبيق';

  @override
  String get moreHubLanguage => 'اللغة';

  @override
  String get moreHubAskCopilotTooltip => 'اسأل مساعد AFAB';

  @override
  String get planLimitTitle => 'تم الوصول إلى حد الخطة';

  @override
  String planLimitMessage(String feature, int used, int limit, String plan) {
    return 'لقد بلغت الحد الشهري لميزة $feature ($used/$limit). قم بالترقية إلى $plan للمتابعة.';
  }

  @override
  String get planReadOnlyTitle => 'مساحة العمل للقراءة فقط';

  @override
  String planReadOnlyMessage(String name) {
    return 'مساحة العمل $name مقفلة حالياً للقراءة فقط وفق تخصيص خطتك.';
  }

  @override
  String get maintenanceTitle => 'الموقع قيد الصيانة';

  @override
  String get maintenanceDesc =>
      'خدمات AFAB غير متاحة مؤقتاً أثناء إجراء التحديثات المجدولة. بياناتك المالية محفوظة بأمان.';

  @override
  String get maintenanceCheckStatus => 'فحص حالة الخادم';

  @override
  String get maintenanceStatusOnline => 'الخادم متصل';

  @override
  String get maintenanceStatusOffline => 'تعذر الوصول للخادم';

  @override
  String get notFoundTitle => 'الصفحة غير موجودة';

  @override
  String get notFoundDesc => 'الشاشة التي طلبتها غير موجودة أو تم نقلها.';

  @override
  String get notFoundGoHome => 'العودة للوحة التحكم';

  @override
  String get errorGenericTitle => 'حدث خطأ ما';

  @override
  String get errorGenericDesc => 'حدث خطأ غير متوقع أثناء عرض هذه الصفحة.';

  @override
  String get navCategories => 'الفئات';

  @override
  String get periodAllTime => 'الكل';

  @override
  String get commonAll => 'الكل';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonView => 'عرض';

  @override
  String get commonExportCsv => 'تصدير CSV';

  @override
  String get commonDiscardTitle => 'تجاهل التغييرات غير المحفوظة؟';

  @override
  String get commonDiscardDesc =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد أنك تريد المغادرة دون حفظ؟';

  @override
  String get commonDiscardConfirm => 'تجاهل';

  @override
  String get commonKeepEditing => 'متابعة التعديل';

  @override
  String get commonReadOnlyNotice =>
      'مساحة العمل هذه في وضع الخزينة للقراءة فقط. تم تعطيل التعديل والحذف.';

  @override
  String get commonCopiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get txTitle => 'المعاملات';

  @override
  String get txSubtitle => 'ابحث وصفّ وقسّم وطابق السجل النقدي لشركتك.';

  @override
  String get txAddButton => 'إضافة معاملة';

  @override
  String get txSplitButton => 'تقسيم';

  @override
  String get txManageCategoriesButton => 'الفئات';

  @override
  String get txAllTimeLedgerCaption => 'إجماليات السجل الكلي';

  @override
  String txFilteredResultsCount(int count) {
    return '$count مطابقة';
  }

  @override
  String get txKpiInflow => 'إجمالي التدفقات الداخلة';

  @override
  String get txKpiOutflow => 'إجمالي المصروفات الخارجة';

  @override
  String get txKpiNetBalance => 'صافي الرصيد';

  @override
  String get txKpiCount => 'إجمالي السجلات';

  @override
  String get txQuickAddTitle => 'الإدخال السريع الذكي';

  @override
  String get txQuickAddHint => 'مثال: دفعت 120 دولار لـ Figma أمس بالبطاقة';

  @override
  String get txQuickAddSubmit => 'تسجيل سريع';

  @override
  String get txQuickAddParsedAs => 'معاينة التحليل';

  @override
  String get txQuickAddNoAmount =>
      'يرجى إدخال مبلغ (مثل 45.50 دولار أو 120 د.ت) للإضافة السريعة.';

  @override
  String get txQuickAddSuccess => 'تم تسجيل المعاملة عبر الإدخال السريع.';

  @override
  String get txSearchHint => 'ابحث في الوصف...';

  @override
  String get txFiltersTitle => 'تصفية المعاملات';

  @override
  String get txFilterReset => 'إعادة ضبط';

  @override
  String get txFilterApply => 'تطبيق الفلاتر';

  @override
  String get txFilterType => 'النوع';

  @override
  String get txFilterCategory => 'الفئة';

  @override
  String get txFilterStatus => 'الحالة';

  @override
  String get txFilterPaymentMethod => 'طريقة الدفع';

  @override
  String get txFilterTaxDeductibleOnly => 'المعفاة ضريبياً فقط';

  @override
  String get txFilterDateRange => 'النطاق الزمني';

  @override
  String get txFilterStartDate => 'من تاريخ';

  @override
  String get txFilterEndDate => 'إلى تاريخ';

  @override
  String get txTypeIncome => 'إيراد';

  @override
  String get txTypeExpense => 'مصروف';

  @override
  String get txStatusCompleted => 'مكتملة';

  @override
  String get txStatusPending => 'قيد الانتظار';

  @override
  String get txStatusCancelled => 'ملغاة';

  @override
  String get txMethodBankTransfer => 'تحويل بنكي';

  @override
  String get txMethodCard => 'بطاقة';

  @override
  String get txMethodCreditCard => 'بطاقة ائتمان';

  @override
  String get txMethodCash => 'نقداً';

  @override
  String get txMethodOther => 'أخرى';

  @override
  String get txSortDate => 'التاريخ';

  @override
  String get txSortAmount => 'المبلغ';

  @override
  String txPageSummary(int page, int total) {
    return 'صفحة $page من $total';
  }

  @override
  String get txPageOnlySortHint => 'الترتيب ينطبق على الصفحة المحملة حالياً.';

  @override
  String txShowingRange(int start, int end, int total) {
    return 'عرض $start–$end من أصل $total نتيجة';
  }

  @override
  String get txEmptyTitle => 'لا توجد معاملات مطابقة';

  @override
  String get txEmptyDesc => 'جرّب تعديل فلاتر البحث أو سجل معاملة جديدة.';

  @override
  String get txEmptyDetailPrompt =>
      'اختر معاملة لعرض أسعار الصرف والتقسيمات والإيصالات الخاصة.';

  @override
  String get txBadgeTax => 'ضريبة';

  @override
  String get txBadgeSplit => 'مقسّمة';

  @override
  String get txBadgeDuplicate => 'مكررة؟';

  @override
  String txBadgePriceHike(String pct) {
    return '+$pct% ارتفاع';
  }

  @override
  String get txActionDuplicate => 'تكرار';

  @override
  String get txDeleteConfirmTitle => 'حذف المعاملة؟';

  @override
  String txDeleteConfirmDesc(String description, String amount) {
    return 'سيتم حذف \"$description\" ($amount) وأي توزيعات فرعية مرتبطة بها.';
  }

  @override
  String get txDeletedToast => 'تم حذف المعاملة.';

  @override
  String get txCsvExportChoiceTitle => 'تصدير المعاملات CSV';

  @override
  String txCsvExportCurrentPage(int count) {
    return 'تصدير الصفحة الحالية ($count صفوف)';
  }

  @override
  String get txCsvExportUpTo100 => 'تصدير حتى 100 نتيجة مطابقة';

  @override
  String get txDetailsTitle => 'تفاصيل المعاملة';

  @override
  String get txDetailsUnavailable =>
      'المعاملة غير متاحة في مساحة العمل الحالية';

  @override
  String get txDetailsUnavailableDesc =>
      'ربما تم حذفها أو تنتمي إلى شركة أخرى.';

  @override
  String get txDetailsBackToLedger => 'العودة للسجل';

  @override
  String txDetailsOriginalFx(
    String origAmount,
    String rate,
    String origCurr,
    String baseCurr,
  ) {
    return 'الأصل: $origAmount @ $rate $origCurr/$baseCurr';
  }

  @override
  String get txDetailsDuplicateAlertTitle => 'تنبيه تكرار محتمل';

  @override
  String get txDetailsDuplicateAlertDesc =>
      'تم العثور على معاملة نشطة أخرى بنفس المبلغ والوصف خلال 48 ساعة.';

  @override
  String txDetailsPriceHikeTitle(String pct) {
    return 'ارتفاع ملحوظ في السعر (+$pct%)';
  }

  @override
  String get txDetailsPriceHikeDesc =>
      'هذا المصروف أعلى بشكل ملحوظ من الدفعة السابقة بنفس الوصف.';

  @override
  String get txDetailsFxSnapshot => 'سجل سعر الصرف';

  @override
  String txDetailsLegacyFx(String currency) {
    return 'سجل قديم ($currency)';
  }

  @override
  String get txDetailsTaxRate => 'نسبة الضريبة';

  @override
  String get txDetailsSplitSection => 'توزيع التقسيم';

  @override
  String get txDetailsChildSplitBanner => 'جزء من معاملة مقسمة إلى عدة فئات';

  @override
  String get txDetailsViewParent => 'عرض الأصل';

  @override
  String get txDetailsNotes => 'ملاحظات';

  @override
  String get txDetailsAuditId => 'الرقم المرجعي';

  @override
  String get txDetailsUncategorized => 'غير مصنف';

  @override
  String get txFormAddTitle => 'إضافة معاملة';

  @override
  String get txFormDuplicateTitle => 'تكرار معاملة';

  @override
  String get txFormEditTitle => 'تعديل معاملة';

  @override
  String get txFormDescriptionLabel => 'الوصف';

  @override
  String get txFormDescriptionHint => 'المورد أو العميل أو البيان';

  @override
  String get txFormAmountLabel => 'المبلغ';

  @override
  String get txFormCurrencyLabel => 'العملة';

  @override
  String get txFormCustomRateToggle => 'سعر صرف مخصص (اختياري)';

  @override
  String txFormCustomRateLabel(String base) {
    return 'سعر الصرف إلى $base';
  }

  @override
  String get txFormFxOfflineHint =>
      'معاينة الصرف غير متاحة بدون إنترنت — أدخل سعراً مخصصاً أو أرسل عند الاتصال.';

  @override
  String get txFormFxLockedNotice =>
      'العملة وسعر الصرف التاريخي مقفلان في المعاملات الموجودة.';

  @override
  String get txFormSplitEditNotice =>
      'ملاحظة: تعديل المعاملة المقسمة يحدث بياناتها وإجماليها دون تعديل بنود التقسيم الحالية.';

  @override
  String get txFormDateLabel => 'تاريخ المعاملة';

  @override
  String get txFormNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get txFormTaxSwitch => 'مصروف عمل قابل للخصم الضريبي';

  @override
  String get txFormTaxRateLabel => 'نسبة الضريبة %';

  @override
  String get txFormTaxRateInvalid => 'أدخل نسبة ضريبة بين 0 و 100.';

  @override
  String get txFormAmountInvalid => 'أدخل مبلغاً موجباً (الحد الأدنى 0.0001).';

  @override
  String get txFormSubmitCreate => 'تسجيل المعاملة';

  @override
  String get txFormSubmitEdit => 'حفظ التغييرات';

  @override
  String get txFormSavedToast => 'تم حفظ المعاملة.';

  @override
  String get txSplitTitle => 'تقسيم المعاملة';

  @override
  String get txSplitSubtitle => 'توزيع دفعة واحدة على عدة فئات';

  @override
  String get txSplitVendorLabel => 'الوصف الرئيسي / المورد';

  @override
  String get txSplitTotalAmount => 'المبلغ الإجمالي';

  @override
  String txSplitLinesHeader(int count) {
    return 'بنود التقسيم ($count)';
  }

  @override
  String get txSplitAddLine => 'إضافة بند';

  @override
  String get txSplitLineMemoHint => 'ملاحظة البند (اختياري)';

  @override
  String get txSplitFillRemaining => 'تعبئة';

  @override
  String get txSplitAllocated => 'الموزع';

  @override
  String get txSplitRemaining => 'المتبقي';

  @override
  String txSplitBalanced(String zero) {
    return 'متوازن ($zero)';
  }

  @override
  String get txSplitMinLinesError => 'تتطلب المعاملة المقسمة بندين على الأقل.';

  @override
  String get txSplitUnbalancedError =>
      'يجب أن يساوي مجموع البنود الإجمالي تماماً.';

  @override
  String get txSplitConfirmBtn => 'تأكيد المعاملة المقسمة';

  @override
  String get txCatTitle => 'إدارة الفئات';

  @override
  String get txCatExpenseTab => 'فئات المصروفات';

  @override
  String get txCatIncomeTab => 'فئات الإيرادات';

  @override
  String get txCatNewBtn => 'فئة جديدة';

  @override
  String get txCatEditTitle => 'تعديل الفئة';

  @override
  String get txCatNameLabel => 'اسم الفئة';

  @override
  String get txCatNameHint => 'مثال: الاستضافة السحابية';

  @override
  String get txCatColorLabel => 'اللون';

  @override
  String get txCatIconLabel => 'الأيقونة';

  @override
  String get txCatSystemBadge => 'افتراضي للنظام';

  @override
  String get txCatCustomBadge => 'مخصصة';

  @override
  String txCatDeleteConfirm(String name) {
    return 'حذف الفئة \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get txCatCreatedToast => 'تم إنشاء الفئة.';

  @override
  String get txCatUpdatedToast => 'تم تحديث الفئة.';

  @override
  String get txCatDeletedToast => 'تم حذف الفئة.';

  @override
  String get txCatDuplicateError => 'توجد فئة بهذا الاسم بالفعل.';

  @override
  String txCatInUseWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لا يمكن الحذف: مستخدمة في $count معاملات.',
      one: 'لا يمكن الحذف: مستخدمة في معاملة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get txCatInUseGeneric => 'لا يمكن حذف الفئة لوجود معاملات مرتبطة بها.';

  @override
  String receiptsSectionTitle(int count) {
    return 'الإيصالات ($count)';
  }

  @override
  String get receiptsAttachBtn => 'إرفاق إيصال';

  @override
  String get receiptsEmptyDesc =>
      'لا توجد إيصالات مرفقة. ارفع PDF أو PNG أو JPEG أو WEBP (بحد أقصى 10 ميجابايت).';

  @override
  String get receiptsSourceTitle => 'إرفاق إيصال خاص';

  @override
  String get receiptsSourceSubtitle =>
      'الصيغ المدعومة: PDF وJPEG وPNG وWEBP حتى 10 ميجابايت';

  @override
  String get receiptsTakePhoto => 'التقاط صورة';

  @override
  String get receiptsChooseGallery => 'اختيار من معرض الصور';

  @override
  String get receiptsBrowseFile => 'تصفح PDF أو مستند';

  @override
  String get receiptsUploading => 'جارٍ رفع الإيصال...';

  @override
  String get receiptsUploadedToast => 'تم رفع الإيصال بأمان.';

  @override
  String get receiptsDeletedToast => 'تم حذف الإيصال.';

  @override
  String get receiptsTooLarge =>
      'يتجاوز حجم ملف الإيصال الحد الأقصى 10 ميجابايت.';

  @override
  String get receiptsInvalidType =>
      'صيغة غير مدعومة. يقبل فقط PDF وJPEG وPNG وWEBP.';

  @override
  String get receiptsEmptyFile => 'ملف الإيصال المحدد فارغ.';

  @override
  String get receiptsViewerLoading => 'جارٍ فك تشفير الإيصال الخاص...';

  @override
  String get receiptsShareAction => 'مشاركة الملف';

  @override
  String get receiptsCopyLinkAction => 'نسخ رابط مؤقت';

  @override
  String receiptsPresignedNotice(int seconds) {
    return 'تم نسخ الرابط المؤقت (ينتهي خلال $seconds ثانية).';
  }

  @override
  String get receiptsPdfReady => 'إيصال PDF الخاص جاهز';

  @override
  String get receiptsPdfHint => 'افتحه عبر قائمة المشاركة أو عارض النظام.';

  @override
  String get receiptsDeleteConfirmTitle => 'حذف الإيصال؟';

  @override
  String receiptsDeleteConfirmDesc(String filename) {
    return 'سيتم حذف \"$filename\" نهائياً من التخزين المشفر.';
  }

  @override
  String get expensesTitle => 'المصروفات';

  @override
  String get expensesSubtitle => 'تحليل مرئي للإنفاق وتكاليف التشغيل.';

  @override
  String get expensesCreateBtn => 'مصروف جديد';

  @override
  String get expensesKpiTotal => 'إجمالي المصروفات';

  @override
  String get expensesKpiAvgDay => 'المتوسط اليومي';

  @override
  String get expensesKpiHighest => 'أعلى مصروف';

  @override
  String get expensesKpiCategories => 'الفئات';

  @override
  String get expensesKpiRecurring => 'المتكررة';

  @override
  String get expensesOverviewTitle => 'نظرة عامة على الإنفاق';

  @override
  String get expensesNoChartData => 'لا توجد مصروفات مكتملة في هذه الفترة.';

  @override
  String get expensesDonutTitle => 'حسب الفئة';

  @override
  String get expensesTotalSpend => 'إجمالي الإنفاق';

  @override
  String get expensesTopCategories => 'أعلى فئات الإنفاق';

  @override
  String get expensesRecurringCardTitle => 'الاشتراكات المتكررة';

  @override
  String get expensesRecurringEmpty =>
      'تُدار قواعد المصروفات المتكررة في صفحة المعاملات المتكررة.';

  @override
  String get expensesManageRecurring => 'إدارة المعاملات المتكررة';

  @override
  String get expensesListHeader => 'جميع سجلات المصروفات';

  @override
  String get revenueTitle => 'الإيرادات';

  @override
  String get revenueSubtitle => 'تتبع سرعة التدفقات النقدية ومصادر الدخل.';

  @override
  String get revenueCreateBtn => 'إيراد جديد';

  @override
  String get revenueKpiTotal => 'إجمالي الإيرادات';

  @override
  String get revenueKpiAvgDay => 'المتوسط اليومي';

  @override
  String get revenueKpiHighestDay => 'أعلى يوم إيراداً';

  @override
  String get revenueKpiCompletedCount => 'الإيرادات المكتملة';

  @override
  String get revenueKpiCompletedSub => 'معاملات الدخل المكتملة';

  @override
  String get revenueOverviewTitle => 'نظرة عامة على الإيرادات';

  @override
  String get revenueNoChartData => 'لا توجد إيرادات مكتملة في هذه الفترة.';

  @override
  String get revenueBySourceTitle => 'الإيرادات حسب المصدر';

  @override
  String get revenueGrossNetTitle => 'الإيراد الإجمالي مقابل الصافي';

  @override
  String get revenueGrossLabel => 'الإيراد الإجمالي';

  @override
  String get revenueDiscountsLabel => 'الخصومات';

  @override
  String get revenueRefundsLabel => 'المستردات';

  @override
  String get revenueNetLabel => 'صافي الإيراد';

  @override
  String get revenueCashBasisNote =>
      'لا يتم تتبع الخصومات والمستردات بشكل منفصل في القيود النقدية.';

  @override
  String get revenueTopProductsTitle => 'أفضل المنتجات والمصادر';

  @override
  String get revenueTopProductsEmpty =>
      'يعتمد توزيع المنتجات على بنود الفواتير.';

  @override
  String get revenueViewInvoices => 'عرض الفواتير';

  @override
  String get revenueListHeader => 'جميع قيود الإيرادات';

  @override
  String get customersTitle => 'العملاء';

  @override
  String get customersSubtitle =>
      'إدارة علاقات العملاء والفواتير والإيرادات المفوترة.';

  @override
  String get customersAddBtn => 'إضافة عميل';

  @override
  String get customersEditTitle => 'تعديل بيانات العميل';

  @override
  String get customersAddTitle => 'عميل جديد';

  @override
  String get customersPeriodToday => 'اليوم';

  @override
  String get customersPeriodWeek => 'هذا الأسبوع';

  @override
  String get customersPeriodMonth => 'هذا الشهر';

  @override
  String get customersPeriodYear => 'هذا العام';

  @override
  String get customersKpiTotal => 'إجمالي العملاء';

  @override
  String get customersKpiTotalRevenue => 'إجمالي الإيرادات';

  @override
  String get customersKpiAvgRevenue => 'المتوسط / عميل';

  @override
  String get customersKpiRepeatRate => 'نسبة التكرار';

  @override
  String customersNewPeriod(int count) {
    return '$count جديد';
  }

  @override
  String get customersOverviewTitle => 'تصنيف العملاء';

  @override
  String get customersStatusActive => 'نشط';

  @override
  String get customersStatusInactive => 'غير نشط';

  @override
  String get customersStatusNew => 'جديد';

  @override
  String get customersTopTitle => 'أفضل العملاء';

  @override
  String get customersActivityTitle => 'النشاط الأخير';

  @override
  String get customersSearchHint =>
      'ابحث بالاسم أو الرمز أو البريد أو الهاتف...';

  @override
  String get customersGroupAll => 'كل المجموعات';

  @override
  String get customersGroupStandard => 'عادي';

  @override
  String get customersGroupVip => 'كبار الشخصيات';

  @override
  String get customersGroupWholesale => 'جملة';

  @override
  String get customersGroupEnterprise => 'مؤسسات';

  @override
  String get customersGroupPartner => 'شريك';

  @override
  String get customersStatusAll => 'كل الحالات';

  @override
  String get customersSortNewest => 'الأحدث';

  @override
  String get customersSortName => 'الاسم';

  @override
  String get customersSortRevenue => 'الإيرادات';

  @override
  String get customersSortOrders => 'الطلبات';

  @override
  String get customersFieldName => 'الاسم الكامل *';

  @override
  String get customersFieldCompany => 'اسم الشركة';

  @override
  String get customersFieldEmail => 'البريد الإلكتروني';

  @override
  String get customersFieldPhone => 'رقم الهاتف';

  @override
  String get customersFieldCode => 'رمز العميل';

  @override
  String get customersFieldCodeHint => 'يُنشأ تلقائياً إذا تُرك فارغاً';

  @override
  String get customersFieldGroup => 'مجموعة العميل';

  @override
  String get customersFieldStatus => 'الحالة';

  @override
  String get customersFieldAddress => 'العنوان';

  @override
  String get customersFieldNotes => 'ملاحظات';

  @override
  String get customersCreatedToast => 'تمت إضافة العميل.';

  @override
  String get customersUpdatedToast => 'تم تحديث بيانات العميل.';

  @override
  String get customersArchivedToast => 'تمت أرشفة العميل.';

  @override
  String get customersArchiveTitle => 'أرشفة العميل؟';

  @override
  String customersArchiveDesc(String name) {
    return 'أرشفة \"$name\"؟ تبقى الفواتير والمعاملات التاريخية محفوظة.';
  }

  @override
  String get customersArchiveAction => 'أرشفة';

  @override
  String get customersCallAction => 'اتصال';

  @override
  String get customersEmailAction => 'بريد';

  @override
  String get customersDetailsTitle => 'تفاصيل العميل';

  @override
  String get customersDetailsPrompt =>
      'اختر عميلاً لعرض ملفه وأرصدته وسجل طلباته.';

  @override
  String get customersKpiInvoiced => 'المفوتر';

  @override
  String get customersKpiOutstanding => 'المستحق';

  @override
  String get customersKpiOrdersCount => 'الطلبات';

  @override
  String get customersContactCard => 'التواصل والعنوان';

  @override
  String get customersOrdersHistory => 'الطلبات والفواتير';

  @override
  String get customersAddOrderBtn => 'إضافة طلب';

  @override
  String get customersOrdersEmpty =>
      'لا توجد طلبات أو فواتير مسجلة لهذا العميل بعد.';

  @override
  String customersOrdersCount(int count) {
    return '$count طلبات';
  }

  @override
  String get customersOrderModalTitle => 'إضافة طلب للعميل';

  @override
  String get customersOrderDescLabel => 'وصف الطلب / الفاتورة *';

  @override
  String customersOrderAmountLabel(String currency) {
    return 'المبلغ ($currency) *';
  }

  @override
  String get customersOrderDateLabel => 'تاريخ الطلب';

  @override
  String get customersOrderInitialStatus => 'الحالة الأولية';

  @override
  String get customersOrderPaidHelper =>
      'يُصدر فاتورة ويسجل معاملة دخل مدفوعة مرتبطة بها.';

  @override
  String get customersOrderUnpaidHelper =>
      'يُصدر فاتورة بحالة غير مدفوعة بانتظار السداد.';

  @override
  String get customersOrderDraftHelper =>
      'يحفظ الفاتورة كمسودة للتعديل لاحقاً.';

  @override
  String get customersOrderCreatedToast => 'تم إنشاء فاتورة الطلب بنجاح.';

  @override
  String get customersEmptyTitle => 'لا يوجد عملاء';

  @override
  String get customersEmptyDesc =>
      'أضف عميلك الأول أو جرّب تعديل خيارات البحث والتصفية.';

  @override
  String get customersPickerTitle => 'اختر العميل';

  @override
  String get customersPickerWalkIn => 'عميل عابر / بدون عميل';

  @override
  String get customersPickerWalkInDesc => 'إنشاء فاتورة دون ربطها بملف عميل';

  @override
  String get invoicesTitle => 'الفواتير';

  @override
  String get invoicesSubtitle =>
      'أنشئ المسودات وأصدر الفواتير وتابع الأرصدة والمدفوعات.';

  @override
  String get invoicesCreateBtn => 'إنشاء فاتورة';

  @override
  String get invoicesKpiTotalInvoiced => 'إجمالي المفوتر';

  @override
  String get invoicesKpiPaid => 'المحصل';

  @override
  String get invoicesKpiPending => 'الرصيد المعلق';

  @override
  String get invoicesKpiOverdue => 'المتأخرة';

  @override
  String get invoicesStatusBreakdown => 'توزيع الحالات';

  @override
  String get invoicesUpcomingDue => 'فواتير مستحقة قريباً';

  @override
  String get invoicesUpcomingEmpty => 'لا توجد فواتير غير مدفوعة تستحق قريباً.';

  @override
  String invoicesDueDateLabel(String date) {
    return 'تستحق $date';
  }

  @override
  String get invoicesSearchHint => 'ابحث برقم الفاتورة أو العميل...';

  @override
  String get invoicesStatusDraft => 'مسودة';

  @override
  String get invoicesStatusSent => 'مرسلة';

  @override
  String get invoicesStatusUnpaid => 'غير مدفوعة';

  @override
  String get invoicesStatusPartiallyPaid => 'مدفوعة جزئياً';

  @override
  String get invoicesStatusPaid => 'مدفوعة';

  @override
  String get invoicesStatusOverdue => 'متأخرة';

  @override
  String get invoicesStatusCancelled => 'ملغاة';

  @override
  String get invoicesEmptyTitle => 'لا توجد فواتير';

  @override
  String get invoicesEmptyDesc =>
      'أنشئ مسودة فاتورة أو جرّب تعديل فلتر الحالة.';

  @override
  String get invoicesDetailPrompt =>
      'اختر فاتورة لعرض البنود وسجل المدفوعات وتصدير PDF.';

  @override
  String get invoicesDetailTitle => 'تفاصيل الفاتورة';

  @override
  String get invoicesOverdueBanner =>
      'تجاوزت هذه الفاتورة تاريخ الاستحقاق. يرجى المتابعة أو تسجيل دفعة.';

  @override
  String get invoicesIssueDate => 'تاريخ الإصدار';

  @override
  String get invoicesDueDate => 'تاريخ الاستحقاق';

  @override
  String get invoicesCustomerSection => 'الفاتورة إلى';

  @override
  String get invoicesWalkInCustomer => 'عميل عابر';

  @override
  String get invoicesLineItems => 'بنود الفاتورة';

  @override
  String invoicesQtyPrice(String qty, String price) {
    return 'الكمية $qty × $price';
  }

  @override
  String invoicesTaxRateBadge(String rate) {
    return 'ضريبة $rate%';
  }

  @override
  String get invoicesSubtotal => 'المجموع الفرعي';

  @override
  String get invoicesTax => 'الضريبة';

  @override
  String get invoicesDiscount => 'الخصم';

  @override
  String get invoicesTotal => 'الإجمالي';

  @override
  String get invoicesPaidAmount => 'المدفوع';

  @override
  String get invoicesOutstanding => 'الرصيد المتبقي';

  @override
  String get invoicesPaymentsHistory => 'سجل المدفوعات';

  @override
  String get invoicesPaymentsEmpty =>
      'لم يتم تسجيل أي دفعات لهذه الفاتورة بعد.';

  @override
  String get invoicesLinkedTx => 'معاملة الدخل';

  @override
  String get invoicesEditDraftBtn => 'تعديل المسودة';

  @override
  String get invoicesMarkSentBtn => 'تحديد كمرسلة';

  @override
  String get invoicesIssueUnpaidBtn => 'إصدار كغير مدفوعة';

  @override
  String get invoicesRecordPaymentBtn => 'تسجيل دفعة';

  @override
  String get invoicesCancelBtn => 'إلغاء الفاتورة';

  @override
  String get invoicesExportPdfBtn => 'تصدير PDF';

  @override
  String get invoicesAiReminderBtn => 'تذكير ذكي';

  @override
  String get invoicesIssuedSentToast => 'تم إصدار الفاتورة وتحديدها كمرسلة.';

  @override
  String get invoicesIssuedUnpaidToast => 'تم إصدار الفاتورة كغير مدفوعة.';

  @override
  String get invoicesCancelConfirmTitle => 'إلغاء الفاتورة؟';

  @override
  String invoicesCancelConfirmDesc(String number) {
    return 'إلغاء الفاتورة $number؟ لا يمكن تسجيل دفعات للفواتير الملغاة.';
  }

  @override
  String get invoicesCancelledToast => 'تم إلغاء الفاتورة.';

  @override
  String get invoicesFormCreateTitle => 'إنشاء فاتورة (مسودة)';

  @override
  String invoicesFormEditTitle(String number) {
    return 'تعديل المسودة $number';
  }

  @override
  String get invoicesFormOnlyDraftError =>
      'يمكن تعديل الفواتير في حالة المسودة فقط.';

  @override
  String get invoicesFormCustomerLabel => 'العميل (اختياري)';

  @override
  String get invoicesFormCurrencyLabel => 'عملة الفاتورة';

  @override
  String get invoicesFormAddLineBtn => 'إضافة بند';

  @override
  String get invoicesFormItemDescLabel => 'وصف البند *';

  @override
  String get invoicesFormQtyLabel => 'الكمية *';

  @override
  String get invoicesFormUnitPriceLabel => 'سعر الوحدة *';

  @override
  String get invoicesFormTaxPctLabel => 'الضريبة %';

  @override
  String get invoicesFormDiscountLabel => 'الخصم';

  @override
  String get invoicesFormNotesHint =>
      'شروط الدفع أو تفاصيل البنك أو ملاحظات مرجعية...';

  @override
  String get invoicesFormSaveDraftBtn => 'حفظ كمسودة';

  @override
  String get invoicesFormUpdateDraftBtn => 'تحديث المسودة';

  @override
  String get invoicesFormDiscountExceedsError =>
      'لا يمكن أن يتجاوز الخصم المجموع الفرعي والضريبة.';

  @override
  String invoicesFormSavedToast(String number) {
    return 'تم حفظ الفاتورة $number.';
  }

  @override
  String get paymentSheetTitle => 'تسجيل دفعة';

  @override
  String paymentRemainingLabel(String number, String amount) {
    return '$number · المتبقي: $amount';
  }

  @override
  String get paymentLedgerNotice =>
      'تسجيل هذه الدفعة ينشئ تلقائياً معاملة دخل مكتملة مطابقة في سجلك المالي ويحدث رصيد الفاتورة.';

  @override
  String get paymentFullBalanceChip => 'كامل الرصيد';

  @override
  String get paymentHalfChip => '50%';

  @override
  String paymentAmountHelper(String max) {
    return 'يدعم الدفع الكامل أو الجزئي حتى $max.';
  }

  @override
  String get paymentDateLabel => 'تاريخ الدفع *';

  @override
  String paymentFxLabel(String from, String to) {
    return 'سعر الصرف (1 $from = ؟ $to)';
  }

  @override
  String paymentFxHelper(String base) {
    return 'سعر صرف يدوي اختياري لمعاملة الدخل بالعملة الأساسية ($base). اتركه فارغاً للسعر الفوري المباشر.';
  }

  @override
  String get paymentReferenceLabel => 'المرجع';

  @override
  String get paymentReferenceHint => 'رقم التحويل البنكي أو مرجع الإيصال';

  @override
  String get paymentConfirmBtn => 'تأكيد الدفعة';

  @override
  String get paymentRetrySameBtn => 'إعادة محاولة نفس الدفعة';

  @override
  String get paymentOverBalanceError =>
      'لا يمكن أن يتجاوز المبلغ الرصيد المتبقي.';

  @override
  String get paymentRateInvalidError =>
      'يجب أن يكون سعر الصرف 0.000001 على الأقل.';

  @override
  String get paymentSuccessToast =>
      'تم تسجيل الدفعة وإنشاء معاملة الدخل بنجاح.';

  @override
  String get budgetsTitle => 'الميزانيات';

  @override
  String get budgetsSubtitle =>
      'راقب حدود الإنفاق مع تنبيهات فورية من السجل المالي.';

  @override
  String get budgetsNewBtn => 'ميزانية جديدة';

  @override
  String get budgetsEditTitle => 'تعديل الميزانية';

  @override
  String get budgetsFilterActiveOnly => 'النشطة فقط';

  @override
  String get budgetsFilterIncludeArchived => 'الكل مع المؤرشفة';

  @override
  String get budgetsKpiActive => 'الميزانيات النشطة';

  @override
  String get budgetsKpiSpent => 'الإنفاق الفعلي';

  @override
  String get budgetsKpiApproaching => 'قريبة من الحد';

  @override
  String get budgetsKpiOver => 'متجاوزة للحد';

  @override
  String budgetsTotalLimitHint(String amount) {
    return 'الحد: $amount';
  }

  @override
  String get budgetsAggregationTip =>
      'تجمع الإجماليات كل الميزانيات النشطة؛ قد تُحتسب المصروفات نفسها في الميزانية العامة وميزانيات الفئات.';

  @override
  String get budgetsAllBusinessExpenses => 'جميع مصروفات الشركة';

  @override
  String get budgetsPeriodMonthly => 'شهري';

  @override
  String get budgetsPeriodQuarterly => 'ربع سنوي';

  @override
  String get budgetsPeriodYearly => 'سنوي';

  @override
  String get budgetsPeriodCustom => 'مخصص';

  @override
  String get budgetsAlertOnTrack => 'ضمن المسار';

  @override
  String get budgetsAlertApproaching => 'قريب من الحد';

  @override
  String get budgetsAlertOver => 'متجاوز للحد';

  @override
  String get budgetsStatusArchived => 'مؤرشفة';

  @override
  String budgetsAlertAt(int pct) {
    return 'تنبيه عند $pct%';
  }

  @override
  String get budgetsAskCopilot => 'اسأل المساعد';

  @override
  String get budgetsArchiveConfirmTitle => 'أرشفة الميزانية؟';

  @override
  String budgetsArchiveConfirmDesc(String name) {
    return 'أرشفة \"$name\"؟ تتوقف الميزانيات المؤرشفة عن التنبيهات النشطة مع حفظ السجل التاريخي.';
  }

  @override
  String get budgetsArchivedToast => 'تمت أرشفة الميزانية.';

  @override
  String get budgetsSavedToast => 'تم حفظ الميزانية.';

  @override
  String get budgetsEmptyTitle => 'لا توجد ميزانيات بعد';

  @override
  String get budgetsEmptyDesc =>
      'أنشئ ميزانية عامة أو لفئة مصروفات للحصول على تنبيهات إنفاق تلقائية.';

  @override
  String get budgetsCreateFirstBtn => 'إنشاء أول ميزانية';

  @override
  String get budgetsFieldName => 'اسم الميزانية *';

  @override
  String get budgetsFieldNameHint => 'مثال: ميزانية التسويق الشهرية';

  @override
  String budgetsFieldAmount(String currency) {
    return 'سقف الإنفاق ($currency) *';
  }

  @override
  String get budgetsFieldThreshold => 'نسبة التنبيه (%)';

  @override
  String get budgetsFieldCategory => 'فئة المصروفات';

  @override
  String get budgetsFieldPeriod => 'نوع الفترة *';

  @override
  String get budgetsAutoDateHint =>
      'اتركه فارغاً للحساب التلقائي للفترة الحالية';

  @override
  String get budgetsCustomDatesRequired =>
      'تاريخ البداية والنهاية مطلوبان للميزانيات المخصصة.';

  @override
  String get budgetsEndBeforeStart =>
      'يجب أن يكون تاريخ النهاية في أو بعد تاريخ البداية.';

  @override
  String get budgetsThresholdInvalid => 'أدخل نسبة بين 1 و 100.';

  @override
  String get recurringTitle => 'المعاملات المتكررة';

  @override
  String get recurringSubtitle =>
      'أتمتة الإيرادات والمصروفات الدورية المتكررة.';

  @override
  String get recurringNewBtn => 'جدول جديد';

  @override
  String get recurringEditTitle => 'تعديل الجدول المتكرر';

  @override
  String get recurringFilterActive => 'نشط';

  @override
  String get recurringFilterPaused => 'متوقف مؤقتاً';

  @override
  String get recurringFreqWeekly => 'أسبوعي';

  @override
  String get recurringFreqMonthly => 'شهري';

  @override
  String get recurringFreqQuarterly => 'ربع سنوي';

  @override
  String get recurringFreqYearly => 'سنوي';

  @override
  String recurringNextRun(String date) {
    return 'التنفيذ القادم: $date';
  }

  @override
  String recurringLastRun(String date) {
    return 'آخر تنفيذ: $date';
  }

  @override
  String recurringEndDate(String date) {
    return 'ينتهي: $date';
  }

  @override
  String get recurringRunDueBtn => 'تنفيذ المستحق';

  @override
  String get recurringPauseBtn => 'إيقاف مؤقت';

  @override
  String get recurringResumeBtn => 'استئناف';

  @override
  String recurringGeneratedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إنشاء $count معاملات مستحقة.',
      one: 'تم إنشاء معاملة مستحقة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get recurringNoneDueToast =>
      'لا توجد دفعات مستحقة حالياً لهذا الجدول.';

  @override
  String get recurringPausedToast => 'تم إيقاف الجدول مؤقتاً.';

  @override
  String get recurringResumedToast => 'تم استئناف الجدول.';

  @override
  String get recurringDeleteTitle => 'حذف أو تعطيل الجدول؟';

  @override
  String recurringDeleteDesc(String name) {
    return 'إذا كان \"$name\" قد أنشأ معاملات سابقاً فسيتم تعطيله (إيقافه مؤقتاً) للحفاظ على السجل المالي. وإلا فسيتم حذفه نهائياً.';
  }

  @override
  String get recurringDeactivatedToast =>
      'تم تعطيل الجدول للحفاظ على السجل المالي.';

  @override
  String get recurringDeletedToast => 'تم حذف الجدول نهائياً.';

  @override
  String get recurringSavedToast => 'تم حفظ الجدول المتكرر.';

  @override
  String get recurringEmptyTitle => 'لا توجد جداول متكررة';

  @override
  String get recurringEmptyDesc =>
      'أنشئ قاعدة تلقائية للإيجار أو الرواتب أو الاشتراكات.';

  @override
  String get recurringCreateFirstBtn => 'إنشاء أول جدول';

  @override
  String get recurringFieldFrequency => 'التكرار';

  @override
  String get recurringFieldEndDate => 'تاريخ الانتهاء (اختياري)';

  @override
  String get calendarTitle => 'التقويم المالي';

  @override
  String get calendarSubtitle =>
      'استعرض التدفقات النقدية اليومية والمستحقات المالية المجدولة.';

  @override
  String get calendarTodayBtn => 'اليوم';

  @override
  String get calendarKpiInflow => 'إجمالي دخل الشهر';

  @override
  String get calendarKpiOutflow => 'إجمالي مصروفات الشهر';

  @override
  String get calendarKpiPending => 'معاملات معلقة';

  @override
  String get calendarKpiEntries => 'إجمالي السجلات';

  @override
  String get calendarAwaitingSettlement => 'بانتظار التسوية';

  @override
  String get calendarOverlayTransactions => 'المعاملات';

  @override
  String get calendarOverlayInvoicesDue => 'فواتير مستحقة';

  @override
  String get calendarOverlayRecurring => 'الدفعات المتكررة';

  @override
  String get calendarOverlayNotice =>
      'تدمج طبقات التقويم المعاملات المسجلة مع تواريخ استحقاق الفواتير المفتوحة والجداول المتكررة.';

  @override
  String get calendarSelectedDateTitle => 'نشاط التاريخ المحدد';

  @override
  String calendarEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجلات',
      one: 'سجل واحد',
      zero: '0 سجلات',
    );
    return '$_temp0';
  }

  @override
  String get calendarNoActivityDate =>
      'لا توجد معاملات أو أحداث في هذا التاريخ.';

  @override
  String get calendarTruncatedNotice => 'يتم عرض أول 1,000 سجل لهذا الشهر.';

  @override
  String get currenciesTitle => 'العملات وأسواق الصرف';

  @override
  String get currenciesSubtitle =>
      'أسعار الصرف المباشرة وتأثير العملات ومحاكي المخاطر.';

  @override
  String get currenciesLiveActive => 'الأسعار المباشرة نشطة';

  @override
  String get currenciesFeedUnavailable => 'تعذر جلب الأسعار المباشرة';

  @override
  String get currenciesViewPrefix => 'عرض:';

  @override
  String currenciesBasePrefix(String code) {
    return 'الأساس: $code';
  }

  @override
  String get currenciesRegionAll => 'الكل';

  @override
  String get currenciesRegionMajors => 'الرئيسية';

  @override
  String get currenciesRegionMena => 'الشرق الأوسط والخليج';

  @override
  String get currenciesRegionAsia => 'آسيا والمحيط الهادئ';

  @override
  String get currenciesTabMarkets => 'الأسواق';

  @override
  String get currenciesTabSimulated => 'محاكاة اللحظات';

  @override
  String get currenciesTabRisk => 'محاكي المخاطر';

  @override
  String get currenciesTabAlerts => 'التنبيهات المحلية';

  @override
  String get currenciesTabDirectory => 'الدليل';

  @override
  String get currenciesFeaturedPairs => 'الأزواج المميزة';

  @override
  String get currenciesChartModeHistory => 'المسار التاريخي';

  @override
  String get currenciesChartModeSimulated => 'محاكاة اللحظات (1ث)';

  @override
  String get currenciesSimulatedBadge => 'محاكاة 1ث (مرتبطة بالسعر الفوري)';

  @override
  String get currenciesSimulatedTooltip =>
      'محاكاة حركة لحظية على الجهاز مرتبطة بسعر الصرف الفوري المباشر (وليس سجل أوامر حقيقي).';

  @override
  String get currenciesSimulatedTrendCaption => 'اتجاه محاكى';

  @override
  String get currenciesChartWave => 'موجي';

  @override
  String get currenciesChartCandles => 'شموع';

  @override
  String get currenciesChartBar => 'أعمدة';

  @override
  String get currenciesChartLine => 'خطي';

  @override
  String get currenciesPause => 'إيقاف';

  @override
  String get currenciesResume => 'تشغيل';

  @override
  String get currenciesSimulatedTrades => 'صفقات محاكاة';

  @override
  String get currenciesSpreadFooter => 'الفارق المحاكى: 0.04%';

  @override
  String get currenciesConverterTitle => 'محول العملات المباشر';

  @override
  String get currenciesYouSend => 'المبلغ المرسل';

  @override
  String get currenciesYouReceive => 'المبلغ المستلم';

  @override
  String get currenciesSwap => 'تبديل';

  @override
  String get currenciesMidMarketRate => 'سعر السوق الوسطي';

  @override
  String get currenciesPortfolioImpactTitle => 'تقييم رصيد الشركة';

  @override
  String get currenciesPortfolioReadOnlyHint =>
      'تقييم المحفظة غير متاح في وضع القراءة فقط.';

  @override
  String get currenciesRiskAmountLabel => 'مبلغ الفاتورة الأجنبية';

  @override
  String get currenciesRiskCurrencyLabel => 'عملة الفوترة';

  @override
  String get currenciesRiskTermsLabel => 'شروط الدفع';

  @override
  String currenciesRiskNetDays(int days) {
    return 'صافي $days يوماً';
  }

  @override
  String get currenciesRiskSpotCardTitle => 'التقييم الفوري اليوم';

  @override
  String get currenciesRiskScenariosTitle => 'سيناريوهات حساسية الصرف';

  @override
  String get currenciesRiskSpotLabel => 'فوري';

  @override
  String get currenciesAlertsLocalBanner =>
      'تنبيهات محلية على الجهاز (تُفحص عند التحديث)';

  @override
  String get currenciesAlertsTriggeredTitle => 'تم الوصول للسعر المستهدف';

  @override
  String get currenciesAlertsNewBtn => 'تنبيه جديد';

  @override
  String get currenciesAlertsPairLabel => 'زوج العملات';

  @override
  String get currenciesAlertsConditionLabel => 'الشرط';

  @override
  String get currenciesAlertsAbove => 'يرتفع فوق (≥)';

  @override
  String get currenciesAlertsBelow => 'ينخفض تحت (≤)';

  @override
  String get currenciesAlertsTargetRate => 'السعر المستهدف';

  @override
  String get currenciesAlertsSaveBtn => 'حفظ التنبيه';

  @override
  String get currenciesAlertsInvalidRate => 'أدخل سعراً مستهدفاً موجباً.';

  @override
  String get currenciesAlertsEmptyTitle => 'لا توجد تنبيهات أسعار بعد';

  @override
  String get currenciesAlertsEmptyDesc =>
      'أنشئ تنبيهاً محلياً لمتابعة الوصول إلى سعر الصرف المستهدف عند التحديث.';

  @override
  String currenciesAlertsAwayPct(String pct) {
    return 'فارق $pct%';
  }

  @override
  String get currenciesDirectorySearchHint => 'ابحث عن العملة أو الرمز...';

  @override
  String currenciesDirectoryEmpty(String query) {
    return 'لا توجد عملات تطابق \"$query\"';
  }

  @override
  String get currenciesDirectoryConvertBtn => 'تحويل';

  @override
  String get migrationTitle => 'تغيير العملة الأساسية للشركة';

  @override
  String get migrationSubtitle =>
      'ينطبق على المعاملات المستقبلية مع معاينة سعر الصرف';

  @override
  String get migrationTargetLabel => 'العملة الأساسية الجديدة';

  @override
  String get migrationFetchingPreview => 'جارٍ جلب سعر الصرف الفوري...';

  @override
  String get migrationLiveMarketRate => 'سعر السوق المباشر';

  @override
  String get migrationCurrentBalance => 'صافي الرصيد الحالي';

  @override
  String get migrationProjectedBalance => 'المعادل المتوقع';

  @override
  String get migrationPreservedLabel => 'حفظ المعاملات التاريخية';

  @override
  String migrationPreservedCount(int count) {
    return '$count معاملة';
  }

  @override
  String get migrationImmutabilityTitle => 'سياسة ثبات السجلات التاريخية مفعلة';

  @override
  String migrationImmutabilityBody(String newCurrency, int count) {
    return 'يُطبق تحديث العملة الأساسية إلى $newCurrency على المعاملات المستقبلية فقط. تحتفظ جميع المعاملات التاريخية ($count) بعملتها الأصلية وأسعار صرفها المثبتة دون تعديل.';
  }

  @override
  String get migrationConfirmBtn => 'تأكيد تغيير العملة';

  @override
  String get migrationUpdating => 'جارٍ التحديث...';

  @override
  String get migrationPermissionNotice =>
      'يمكن لمالكي أو مدراء مساحة العمل النشطة فقط تغيير العملة الأساسية.';

  @override
  String migrationSuccessToast(String newCurrency) {
    return 'تم تحديث العملة الأساسية إلى $newCurrency مع حفظ السجلات التاريخية.';
  }

  @override
  String get reportsTitle => 'التقارير المالية';

  @override
  String get reportsSubtitle =>
      'تحليل قائمة الأرباح والخسائر والتدفقات النقدية ومقارنة الفترات.';

  @override
  String reportsMonthlyQuota(int used, int limit) {
    return 'التصديرات الشهرية: $used / $limit';
  }

  @override
  String get reportsMonthlyUnlimited => 'التصديرات الشهرية: غير محدودة';

  @override
  String get reportsExplainBtn => 'تفسير التقرير';

  @override
  String get reportsExportCsvBtn => 'تصدير الأرباح CSV';

  @override
  String get reportsExportPdfBtn => 'تصدير الأرباح PDF';

  @override
  String get reportsArabicPdfWarning =>
      'تستخدم ملفات PDF من الخادم خطوطاً لاتينية؛ استخدم تصدير CSV (UTF-8 BOM) لدعم كامل للنصوص العربية.';

  @override
  String get reportsTabPnl => 'الأرباح والخسائر';

  @override
  String get reportsTabCashFlow => 'التدفق النقدي';

  @override
  String get reportsTabComparison => 'مقارنة الفترات';

  @override
  String get reportsPeriodThisMonth => 'هذا الشهر';

  @override
  String get reportsPeriodLastMonth => 'الشهر الماضي';

  @override
  String get reportsPeriodThisQuarter => 'هذا الربع';

  @override
  String get reportsPeriodThisYear => 'هذا العام';

  @override
  String get reportsPeriodLastYear => 'العام الماضي';

  @override
  String get reportsPeriodCustom => 'نطاق مخصص';

  @override
  String get reportsPrimaryPeriod => 'الفترة الأساسية';

  @override
  String get reportsCompareAgainst => 'المقارنة مع';

  @override
  String get reportsIdenticalPeriodsHint => 'تتم مقارنة فترتين متطابقتين.';

  @override
  String get reportsGatedTitle => 'يتطلب التقرير المتقدم ترقية الخطة';

  @override
  String get reportsGatedBtn => 'الترقية الآن';

  @override
  String get reportsPnlRevenue => 'إجمالي الإيرادات';

  @override
  String get reportsPnlExpenses => 'إجمالي المصروفات';

  @override
  String get reportsPnlNetIncome => 'صافي الدخل التشغيلي';

  @override
  String get reportsPnlMargin => 'هامش صافي الربح';

  @override
  String get reportsPnlCashReceived => 'نقد محصل';

  @override
  String get reportsPnlCashSpent => 'نقد منصرف';

  @override
  String get reportsPnlPositiveMargin => 'هامش موجب';

  @override
  String get reportsPnlDeficit => 'عجز تشغيلي';

  @override
  String get reportsPnlRevByCategory => 'الإيرادات حسب الفئة';

  @override
  String get reportsPnlExpByCategory => 'المصروفات حسب الفئة';

  @override
  String get reportsPnlNoIncome => 'لا توجد إيرادات مسجلة في هذه الفترة.';

  @override
  String get reportsPnlNoExpenses => 'لا توجد مصروفات مسجلة في هذه الفترة.';

  @override
  String get reportsCfInflow => 'إجمالي التدفق الداخل';

  @override
  String get reportsCfOutflow => 'إجمالي التدفق الخارج';

  @override
  String get reportsCfNetChange => 'صافي التغير النقدي';

  @override
  String get reportsCfTrendTitle => 'اتجاه التدفق النقدي (آخر 6 أشهر)';

  @override
  String get reportsCfTrendEmpty => 'لا يوجد نشاط تدفق نقدي خلال آخر 6 أشهر.';

  @override
  String get reportsCompRevGrowth => 'نمو الإيرادات';

  @override
  String get reportsCompExpChange => 'تغير المصروفات';

  @override
  String get reportsCompNetChange => 'تغير صافي الدخل';

  @override
  String get reportsSelectDateRange => 'اختر النطاق الزمني';

  @override
  String get aiTitle => 'مساعد AFAB الذكي';

  @override
  String get aiLoading => 'جاري تحميل مساعد AFAB...';

  @override
  String get aiSubtitle => 'ذكاء مالي خاص ومحلي مبني على سجلاتك الفعلية.';

  @override
  String get aiBadge => 'Hybrid RAG';

  @override
  String get aiHeroBadge => 'ذكاء اصطناعي محلي بخصوصية تامة 100%';

  @override
  String get aiHeroTitleStart => 'وضوح مالي دقيق ';

  @override
  String get aiHeroTitleHighlight => 'لكل قرار.';

  @override
  String get aiCapPrivate => 'خصوصية Ollama محلياً';

  @override
  String get aiCapMath => 'حسابات BigDecimal موثقة';

  @override
  String get aiCapMultilingual => 'العربية · الدارجة · الإنجليزية · الفرنسية';

  @override
  String get aiAttachLabel => 'إرفاق';

  @override
  String get aiListeningLabel => 'جاري الاستماع';

  @override
  String get aiNewChat => 'محادثة جديدة';

  @override
  String get aiHistoryTitle => 'المحادثات';

  @override
  String get aiSearchConversations => 'ابحث في المحادثات...';

  @override
  String get aiGroupToday => 'اليوم';

  @override
  String get aiGroupYesterday => 'أمس';

  @override
  String get aiGroupWeek => 'آخر 7 أيام';

  @override
  String get aiGroupEarlier => 'سابقاً';

  @override
  String get aiToggleSidebar => 'إظهار أو إخفاء قائمة المحادثات';

  @override
  String get aiNoConversations => 'لا توجد محادثات محفوظة لهذه الشركة بعد.';

  @override
  String get aiDeleteConversation => 'حذف المحادثة';

  @override
  String get aiDeleteConvConfirmTitle => 'حذف المحادثة؟';

  @override
  String aiDeleteConvConfirmDesc(String title) {
    return 'هل تريد إزالة \"$title\" من سجل المحادثات؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get aiMemoryButton => 'ذاكرة العمل';

  @override
  String get aiSyncIndexButton => 'مزامنة الفهرس';

  @override
  String get aiSyncing => 'جاري المزامنة...';

  @override
  String aiSyncSuccess(int indexed, int embeddings) {
    return 'تمت مزامنة الفهرس الذكي ($indexed سجل محدث، $embeddings متجه).';
  }

  @override
  String get aiSyncError => 'تعذرت مزامنة الفهرس.';

  @override
  String get aiModelReady => 'النموذج جاهز';

  @override
  String get aiModelOffline => 'خادم Ollama غير متصل';

  @override
  String get aiModelMissing => 'يجب تحميل النموذج';

  @override
  String get aiOfflineTitle => 'نموذج الذكاء الاصطناعي المحلي غير متصل';

  @override
  String get aiOfflineDescription =>
      'يعمل مساعد AFAB بخصوصية تامة عبر خادم Ollama المحلي. تأكد من تشغيل Ollama وتثبيت النموذجين:';

  @override
  String get aiTokensLabel => 'رموز AI';

  @override
  String get aiQueriesLabel => 'الاستفسارات';

  @override
  String get aiRemaining => 'متبقي';

  @override
  String get aiUnlimited => 'غير محدود';

  @override
  String get aiUpgradeCta => 'ترقية الخطة';

  @override
  String get aiQuotaExhaustedTitle =>
      'تم استنفاد الرصيد الشهري للذكاء الاصطناعي';

  @override
  String get aiQuotaExhaustedDesc =>
      'لقد وصلت إلى الحد الشهري المتاح للرموز أو الاستفسارات في باقتك الحالية.';

  @override
  String aiQuotaRatio(String used, String limit) {
    return '$used / $limit';
  }

  @override
  String get aiWelcomeTitle => 'وضوح مالي دقيق لكل قرار';

  @override
  String get aiWelcomeSubtitle =>
      'مدير مالي ذكي ومحلي مبني على سجلاتك وفواتيرك وإيصالاتك وملفاتك بخصوصية تامة.';

  @override
  String get aiPlaceholder =>
      'اسأل مساعدك المالي، أرفق وصلاً أو ملفاً، أو اكتب بالدارجة...';

  @override
  String get aiComposerFooter =>
      'يعمل محلياً عبر Gemma 4 · أرفق صوراً أو ملفات PDF / Excel / CSV';

  @override
  String get aiComposerLanguages => 'عربي · دارجة · FR · EN';

  @override
  String get aiScrollToBottom => 'الانتقال إلى أحدث رسالة';

  @override
  String get aiFollowUpsLabel => 'أسئلة مقترحة للمتابعة';

  @override
  String get aiYou => 'أنت';

  @override
  String get aiCopilotName => 'مساعد AFAB';

  @override
  String get aiCopy => 'نسخ';

  @override
  String get aiCopied => 'تم النسخ';

  @override
  String get aiRegenerate => 'إعادة التوليد';

  @override
  String aiSourcesCount(int count) {
    return '$count مصدر موثق';
  }

  @override
  String get aiSend => 'إرسال';

  @override
  String get aiStop => 'إيقاف';

  @override
  String get aiThinking => 'جاري فحص الأدوات المالية والتحقق من الأرقام...';

  @override
  String get aiStreamingLabel => 'استجابة مباشرة';

  @override
  String get aiToolRunning => 'جاري تشغيل الأداة';

  @override
  String get aiToolDone => 'تم التحقق';

  @override
  String aiElapsedSeconds(String seconds) {
    return '$secondsث';
  }

  @override
  String get aiPhaseMemory => 'استرجاع ذاكرة العمل والسياق الدلالي...';

  @override
  String get aiPhaseLedger => 'فحص الدفاتر واختيار الأدوات المالية الموثقة...';

  @override
  String get aiPhaseSynthesis => 'صياغة التحليل المالي التنفيذي...';

  @override
  String get aiPhaseWarmingModel =>
      'جاري تحميل نموذج Gemma 4 المحلي على بطاقة الرسوميات (أول رسالة تستغرق ~10-15 ثانية)...';

  @override
  String get aiLiveTitle => 'حالة توفر نموذج الذكاء الاصطناعي المباشرة';

  @override
  String get aiLiveRealtimeBadge => 'مباشر';

  @override
  String get aiLiveBackendLabel => 'خادم AFAB الخلفي';

  @override
  String get aiLiveOllamaLabel => 'خادم Ollama المحلي';

  @override
  String get aiLiveChatModelLabel => 'نموذج المحادثة';

  @override
  String get aiLiveEmbedModelLabel => 'نموذج المتجهات';

  @override
  String get aiLiveConnected => 'متصل';

  @override
  String get aiLiveReconnecting => 'جاري إعادة الاتصال...';

  @override
  String get aiLiveOnline => 'متصل';

  @override
  String get aiLiveOffline => 'غير متصل';

  @override
  String get aiLiveHotInGpu => 'جاهز في الذاكرة';

  @override
  String get aiLiveHotShort => 'نشط GPU';

  @override
  String get aiLiveColdShort => 'جاهز';

  @override
  String get aiLiveReadyShort => 'جاهز';

  @override
  String get aiLiveBusy => 'جاري التوليد...';

  @override
  String get aiLiveMissing => 'غير مثبت';

  @override
  String get aiLiveBackendOffline => 'الخادم غير متصل';

  @override
  String get aiLiveChecking => 'جاري الفحص...';

  @override
  String get aiLiveCheckNow => 'فحص الآن';

  @override
  String get aiLiveLastChecked => 'آخر فحص';

  @override
  String get aiToolBusinessSummary => 'تدقيق ملخص الأرباح والخسائر';

  @override
  String get aiToolComparePeriods => 'مقارنة الفترات الزمنية';

  @override
  String get aiToolCategoryBreakdown => 'تحليل توزيع الفئات';

  @override
  String get aiToolSearchTransactions => 'البحث في سجل المعاملات';

  @override
  String get aiToolInvoicesOverview => 'فحص الفواتير والمستحقات';

  @override
  String get aiToolCustomersOverview => 'تحليل إيرادات العملاء';

  @override
  String get aiToolBudgetsStatus => 'فحص استهلاك الميزانيات';

  @override
  String get aiToolRecurringCommitments => 'مراجعة الالتزامات المتكررة';

  @override
  String get aiToolDataCoverage => 'التحقق من نطاق البيانات المتاح';

  @override
  String get aiToolCashflowForecast => 'تشغيل محاكاة التدفق النقدي';

  @override
  String get aiToolFinancialPulse => 'فحص التنبيهات والمؤشرات المالية';

  @override
  String get aiToolProposeTransaction => 'إعداد مسودة معاملة مالية';

  @override
  String get aiToolProposeInvoice => 'إعداد مسودة فاتورة';

  @override
  String get aiToolProposeBudget => 'إعداد مسودة ميزانية';

  @override
  String get aiToolProposeReminder => 'إعداد تذكير دفع موثق';

  @override
  String get aiToolProposeMemory => 'إعداد قاعدة لذاكرة العمل';

  @override
  String get aiToolFallback => 'تشغيل فحص مالي موثق';

  @override
  String get aiFastMode => 'سريع';

  @override
  String get aiDeepMode => 'تحليل معمق';

  @override
  String get aiDeepModeBadge => 'تحليل معمق';

  @override
  String get aiDeepThinkingLive => 'يفكر خطوة بخطوة...';

  @override
  String get aiReasoningTrace => 'مسار التحليل';

  @override
  String get aiMorningBriefButton => 'موجز الصباح المالي';

  @override
  String get aiMorningBriefPrompt =>
      'شغّل أداة get_financial_pulse و get_business_summary وأعطني موجزاً مالياً تنفيذياً لليوم يشمل صافي الربح، الارتفاعات غير المعتادة في المصاريف، مخاطر التكرار، سرعة استهلاك الميزانيات، الإيصالات الناقصة، والفواتير المتأخرة.';

  @override
  String get aiDrawerTitle => 'مساعد AFAB';

  @override
  String get aiDrawerSubtitle => 'تحليل سريع، مسودات، وفحص ملفات';

  @override
  String get aiDrawerEmptyTitle => 'اسأل مساعد AFAB أي سؤال';

  @override
  String get aiDrawerEmptyDesc =>
      'أرفق صورة وصل أو ملف PDF/Excel/CSV، استخدم الميكروفون للتحدث، أو اطلب توقعات التدفق النقدي ومذكرات الدفع.';

  @override
  String get aiOpenWorkspace => 'ملء الشاشة';

  @override
  String get aiLangEn => 'EN';

  @override
  String get aiLangFr => 'FR';

  @override
  String get aiLangArMsa => 'عربي';

  @override
  String get aiLangDerjaScript => 'دارجة';

  @override
  String get aiLangDerjaArabizi => 'Derja';

  @override
  String get aiAttachTitle => 'إرفاق صورة وصل أو مستند';

  @override
  String get aiAttachCamera => 'التقاط صورة إيصال';

  @override
  String get aiAttachGallery => 'مكتبة الصور';

  @override
  String get aiAttachDocument => 'مستند (PDF, XLSX, CSV, TXT, JSON)';

  @override
  String get aiAttachMaxThree => 'الحد الأقصى 3 مرفقات لكل رسالة.';

  @override
  String get aiAttachSupportedHint =>
      'JPG, PNG, WEBP, PDF, XLSX, CSV, TXT, JSON (≤ 10 MB)';

  @override
  String get aiAttachUploadFailed => 'تعذر رفع الملف المرفق.';

  @override
  String get aiVoiceStart => 'بدء الإملاء الصوتي';

  @override
  String get aiVoiceStop => 'إيقاف التسجيل';

  @override
  String get aiVoiceSwitchLang => 'تغيير لغة الصوت (EN / FR / TN)';

  @override
  String get aiVoicePermissionDenied =>
      'تم رفض إذن الميكروفون. فعّل صلاحية الميكروفون لاستخدام الإملاء الصوتي.';

  @override
  String get aiVoiceUnavailable => 'التعرف على الصوت غير متاح على هذا الجهاز.';

  @override
  String get aiVoiceError => 'توقف التعرف على الصوت. حاول مرة أخرى.';

  @override
  String get aiDraftPendingReview => 'مراجعة واعتماد';

  @override
  String get aiDraftReviewHint =>
      'لم يتم حفظ أي بيانات بعد. عدّل الحقول أدناه واضغط اعتماد وحفظ.';

  @override
  String get aiDraftSavedBadge => 'تم الحفظ';

  @override
  String get aiDraftDismissedBadge => 'تم التجاهل';

  @override
  String get aiDraftViewRecord => 'عرض السجل';

  @override
  String get aiDraftApproveSave => 'اعتماد وحفظ';

  @override
  String get aiDraftDismiss => 'تجاهل';

  @override
  String get aiDraftSaving => 'جاري الحفظ...';

  @override
  String get aiDraftApprovedToast => 'تم اعتماد السجل وحفظه!';

  @override
  String get aiDraftApproveFailed => 'تعذر حفظ المسودة.';

  @override
  String get aiDraftDismissFailed => 'تعذر تجاهل المسودة.';

  @override
  String get aiDraftInvalidAmount => 'يرجى إدخال مبلغ صحيح أكبر من الصفر.';

  @override
  String get aiDraftReceiptLinked => 'إيصال مرفق من المحادثة';

  @override
  String get aiDraftReceiptWillSave => 'سيُحفظ في الإيصالات ويُفهرس تلقائياً.';

  @override
  String get aiDraftType => 'النوع';

  @override
  String get aiDraftAmount => 'المبلغ';

  @override
  String get aiDraftCurrency => 'العملة';

  @override
  String get aiDraftDescription => 'الوصف';

  @override
  String get aiDraftDate => 'التاريخ';

  @override
  String get aiDraftCategory => 'الفئة';

  @override
  String get aiDraftPaymentMethod => 'طريقة الدفع';

  @override
  String get aiDraftNotes => 'ملاحظات';

  @override
  String get aiDraftCustomer => 'العميل';

  @override
  String get aiDraftIssueDate => 'تاريخ الإصدار';

  @override
  String get aiDraftDueDate => 'تاريخ الاستحقاق';

  @override
  String get aiDraftTotal => 'الإجمالي';

  @override
  String get aiDraftIssueImmediately => 'إصدار الفاتورة فوراً';

  @override
  String get aiDraftBudgetName => 'اسم الميزانية';

  @override
  String get aiDraftPeriod => 'الفترة';

  @override
  String get aiDraftAlertPct => 'تنبيه %';

  @override
  String get aiReminderCopy => 'نسخ الرسالة';

  @override
  String get aiReminderCopied => 'تم النسخ';

  @override
  String get aiReminderOpenEmail => 'إرسال بالبريد';

  @override
  String get aiReminderOpenWhatsapp => 'فتح واتساب';

  @override
  String get aiReminderSubject => 'الموضوع';

  @override
  String get aiMemoryProposalHeading => 'حفظ في ذاكرة العمل؟';

  @override
  String get aiMemoryProposalIgnore => 'تجاهل';

  @override
  String get aiMemoryProposalRemember => 'اعتماد وحفظ';

  @override
  String get aiMemoryProposalSaved => 'تم الحفظ في ذاكرة العمل';

  @override
  String get aiMemoryProposalSaveFailed => 'تعذر حفظ الذاكرة.';

  @override
  String get aiEvidenceTitle => 'المصادر والأدلة الموثقة';

  @override
  String get aiCoveragePartial =>
      'موثق من الدفاتر والفواتير (أرصدة البنوك وفواتير الموردين غير مفعلة بعد)';

  @override
  String get aiCoverageRag => 'مدعوم بذاكرة العمل والسجلات المفهرسة';

  @override
  String aiTokensUsedBadge(String tokens) {
    return '$tokens رمز';
  }

  @override
  String get aiPulseMonthNet => 'صافي الشهر';

  @override
  String get aiPulseOverdue => 'متأخرة';

  @override
  String get aiPulseAlerts => 'تنبيهات';

  @override
  String get aiPulseAllClear => 'سليم';

  @override
  String get aiPulseHealthy => 'مستقر';

  @override
  String get aiPromptPnlTag => 'الأرباح والخسائر';

  @override
  String get aiPromptPnlTitle => 'ملخص الأرباح والخسائر الشهري';

  @override
  String get aiPromptPnlShortDesc =>
      'قارن الإيرادات والمصروفات وصافي الربح بالشهر الماضي';

  @override
  String get aiPromptPnlText =>
      'أعطني تفصيلاً للإيرادات والمصروفات وصافي الربح هذا الشهر مقارنة بالشهر الماضي.';

  @override
  String get aiPromptForecastTitle => 'توقعات التدفق النقدي لـ 90 يوماً';

  @override
  String get aiPromptForecastShortDesc =>
      'توقع السيولة ومحاكاة التوظيف أو تأخر الدفعات';

  @override
  String get aiPromptForecastText =>
      'شغّل محاكاة دقيقة للتدفق النقدي لـ 90 يوماً القادمة بناءً على متوسطاتي والالتزامات المتكررة والفواتير غير المدفوعة مع رسم بياني.';

  @override
  String get aiPromptScanTitle => 'مسح إيصال أو استيراد ملف';

  @override
  String get aiPromptScanShortDesc =>
      'ارفع صورة إيصال أو ملف PDF أو Excel أو CSV لتحليله';

  @override
  String get aiPromptScanBadge => 'رفع';

  @override
  String get aiPromptInvoicesTitle => 'الفواتير المتأخرة والمستحقات';

  @override
  String get aiPromptInvoicesText =>
      'ما هي الفواتير غير المدفوعة أو المتأخرة حالياً، وما إجمالي المبالغ المستحقة؟';

  @override
  String get aiPromptBudgetsTitle => 'فحص صحة الميزانيات';

  @override
  String get aiPromptBudgetsText =>
      'تحقق من جميع الميزانيات النشطة الآن وأخبرني إن كان أي منها يقترب من الحد أو يتجاوزه.';

  @override
  String get aiPromptDerjaTitle => 'تجربة الدارجة التونسية';

  @override
  String get aiPromptDerjaShortDesc =>
      'تحدث بالعربية أو الدارجة التونسية أو الفرنسية أو الإنجليزية';

  @override
  String get aiPromptDerjaText => 'قداش صرفت هذا الشهر وشنية أكثر المصاريف؟';

  @override
  String get aiPromptQuickCaptureChip => 'تسجيل مصروف بالمحادثة';

  @override
  String get aiPromptQuickCapturePrefill => 'سجّل مصروف: ';

  @override
  String get aiMemoryTitle => 'ذاكرة العمل';

  @override
  String get aiMemorySubtitle =>
      'علّم AFAB عادات الموردين، المواسم، وقواعد التصنيف المرتبطة بهذه الشركة حصرياً.';

  @override
  String get aiMemoryAddTitle => 'إضافة ذاكرة جديدة';

  @override
  String get aiMemoryEditTitle => 'تعديل الذاكرة';

  @override
  String get aiMemoryTitleLabel => 'عنوان مختصر';

  @override
  String get aiMemoryTitlePlaceholder => 'مثال: موسم ذروة المبيعات قبل العيد';

  @override
  String get aiMemoryTypeLabel => 'نوع الذاكرة';

  @override
  String get aiMemoryStatusLabel => 'الحالة';

  @override
  String get aiMemoryContentLabel => 'السياق أو القاعدة المالية';

  @override
  String get aiMemoryContentPlaceholder =>
      'مثال: فاتورة الكهرباء تصدر كل شهرين وتصنف تحت المرافق.';

  @override
  String get aiMemorySaveButton => 'حفظ وفهرسة';

  @override
  String get aiMemorySaveChanges => 'حفظ التغييرات';

  @override
  String get aiMemorySaving => 'جاري الحفظ...';

  @override
  String get aiMemoryEmpty =>
      'لا توجد ذكريات عمل مضافة بعد. أضف ملاحظاتك وقواعد الموردين ليتذكرها المساعد.';

  @override
  String get aiMemoryFilteredEmpty => 'لا توجد ذكريات ضمن هذه الحالة.';

  @override
  String get aiMemoryVectorReady => 'مفهرس متجهياً';

  @override
  String get aiMemoryLexicalOnly => 'فهرسة نصية';

  @override
  String get aiMemoryApprove => 'اعتماد';

  @override
  String get aiMemoryDelete => 'حذف';

  @override
  String get aiMemoryDeleteConfirmTitle => 'حذف هذه الذاكرة؟';

  @override
  String aiMemoryDeleteConfirmDesc(String title) {
    return 'سيتوقف المساعد عن استخدام \"$title\" في الإجابات القادمة.';
  }

  @override
  String get aiMemoryFilterAll => 'الكل';

  @override
  String get aiMemoryFilterProposed => 'مقترح';

  @override
  String get aiMemoryFilterApproved => 'معتمد';

  @override
  String get aiMemoryFilterExpired => 'منتهي';

  @override
  String get aiMemoryTypeBusinessProfile => 'ملف العمل';

  @override
  String get aiMemoryTypeTransactionContext => 'سياق معاملة';

  @override
  String get aiMemoryTypeSupplierPattern => 'نمط مورد';

  @override
  String get aiMemoryTypeCategorizationPreference => 'قاعدة تصنيف';

  @override
  String get aiMemoryTypeDecisionHistory => 'سجل قرار';

  @override
  String get aiMemoryTypeOperationalConstraint => 'قيد تشغيلي';

  @override
  String get aiIncompleteStreamError =>
      'انقطع بث المساعد الذكي قبل اكتمال الإجابة. يرجى المحاولة مرة أخرى.';

  @override
  String get aiAlreadyRespondingToast =>
      'المساعد الذكي يجيب حالياً. اضغط إيقاف أولاً إذا أردت الإلغاء.';

  @override
  String get aiDismissError => 'إخفاء';

  @override
  String get plansPageTitle => 'الخطط والاشتراكات';

  @override
  String get plansHeaderManage => 'إدارة الاشتراك والخطط';

  @override
  String plansActiveBusinesses(int count, int limit) {
    return 'الشركات النشطة: $count / $limit';
  }

  @override
  String get plansActiveBusinessesHint =>
      'تبقى الشركات الإضافية مقفلة بأمان حتى تقوم بالترقية أو التبديل.';

  @override
  String plansCurrentPlanLabel(String name) {
    return 'الخطة الحالية: $name';
  }

  @override
  String get plansIntervalMonthly => 'فوترة شهرية';

  @override
  String get plansIntervalYearly => 'فوترة سنوية';

  @override
  String get plansStatusTrialing => 'فترة تجريبية';

  @override
  String get plansStatusActive => 'نشط';

  @override
  String get plansStatusPastDue => 'متأخر السداد';

  @override
  String get plansStatusCanceled => 'ملغى';

  @override
  String plansTrialCountdown(int days, String date) {
    return 'تجربة بلس 7 أيام: متبقي $days يوم (تنتهي في $date)';
  }

  @override
  String plansRenewsOn(String date) {
    return 'يتجدد في $date';
  }

  @override
  String plansEndsOn(String date) {
    return 'ينتهي الوصول المدفوع في $date';
  }

  @override
  String plansScheduledDowngradeBadge(String plan) {
    return 'مجدول: $plan';
  }

  @override
  String get plansScheduledCancelBadge => 'إلغاء في نهاية الفترة';

  @override
  String get plansUpgradeToPro => 'الترقية إلى Pro';

  @override
  String get plansHideOptions => 'إخفاء خيارات الخطة';

  @override
  String get plansChangePlan => 'تغيير / تخفيض الخطة';

  @override
  String get plansKeepResume => 'الإبقاء / استئناف الاشتراك';

  @override
  String get plansCancelScheduledDowngrade => 'إلغاء التخفيض المجدول';

  @override
  String get plansManageBilling => 'إدارة الفوترة وطرق الدفع';

  @override
  String get plansCancelTrial => 'إلغاء الفترة التجريبية';

  @override
  String get plansCancelSubscription => 'إلغاء الاشتراك';

  @override
  String get plansAiMeterTitle => 'الاستهلاك الشهري لمساعد AFAB الذكي';

  @override
  String plansAiMeterSummary(
    String tokensUsed,
    String tokensLimit,
    String queriesUsed,
    String queriesLimit,
  ) {
    return '$tokensUsed / $tokensLimit رمز · $queriesUsed / $queriesLimit استعلام';
  }

  @override
  String plansPendingChangeDesc(String date) {
    return 'ستحتفظ بجميع صلاحياتك الحالية حتى $date.';
  }

  @override
  String get plansConfigureFutureBusinesses => 'تحديد الشركات المستقبلية';

  @override
  String plansGracePeriodTitle(int hours) {
    return 'فشل الدفع — فترة سماح 3 أيام (متبقي $hours ساعة)';
  }

  @override
  String get plansGracePeriodDesc =>
      'قم بتحديث وسيلة الدفع عبر بوابة Stripe قبل قفل الشركات المدفوعة.';

  @override
  String get plansUpdatePaymentMethod => 'تحديث وسيلة الدفع';

  @override
  String get plansOwnedWorkspacesTitle => 'توزيع مساحات العمل المملوكة';

  @override
  String get plansChangeEditableBusinesses => 'تغيير الشركات القابلة للتعديل';

  @override
  String get plansPrimaryBadge => 'رئيسية';

  @override
  String get plansCurrentBadge => 'الحالية';

  @override
  String get plansStatusUnlocked => 'نشطة';

  @override
  String get plansStatusLocked => 'مقفلة';

  @override
  String get plansBillingToggleMonthly => 'شهري';

  @override
  String get plansBillingToggleYearly => 'سنوي';

  @override
  String get plansSave20Badge => 'وفر 20%';

  @override
  String get plansTrialBannerTitle =>
      'ابدأ بتجربة مجانية لمدة 7 أيام لخطة Plus';

  @override
  String get plansTrialBannerDesc =>
      'جرّب إدارة عدة شركات والتقارير المتقدمة و150 ألف رمز للمساعد الذكي بدون مخاطرة.';

  @override
  String get plansMostPopularTrial => 'الأكثر شعبية · تجربة 7 أيام';

  @override
  String get plansVipBadge => 'VIP';

  @override
  String get plansPerMonth => '/ شهر';

  @override
  String get plansBilledAnnually => 'تُدفع سنوياً';

  @override
  String get plansCurrentPlanBtn => 'الخطة الحالية';

  @override
  String get plansStartTrialBtn => 'ابدأ تجربة 7 أيام مجاناً';

  @override
  String plansUpgradeToBtn(String plan) {
    return 'الترقية إلى $plan';
  }

  @override
  String plansDowngradeToBtn(String plan) {
    return 'التخفيض إلى $plan';
  }

  @override
  String get plansCompareTitle => 'مقارنة الخطط';

  @override
  String get plansHistorySubTitle => 'سجل تغييرات الاشتراك';

  @override
  String get plansHistoryPayTitle => 'سجل المدفوعات والفواتير';

  @override
  String get plansNoPaymentsYet => 'لا توجد مدفوعات مسجلة بعد.';

  @override
  String get plansNoSubHistory => 'لا توجد تغييرات في الاشتراك بعد.';

  @override
  String get plansViewInvoice => 'الفاتورة';

  @override
  String get plansCheckoutCanceled =>
      'تم إلغاء عملية الدفع ولم يتم خصم أي مبلغ.';

  @override
  String get plansCheckoutVerifying => 'جاري التحقق من اشتراك Stripe...';

  @override
  String plansCheckoutVerified(String plan) {
    return 'تم تحديث الاشتراك إلى $plan!';
  }

  @override
  String plansDirectUpgradeSuccess(String plan) {
    return 'تمت الترقية مباشرة إلى $plan!';
  }

  @override
  String get plansResumedSuccess =>
      'تم استئناف الاشتراك وإلغاء التغيير المجدول.';

  @override
  String plansImmediateDowngradeSuccess(String plan) {
    return 'تم تحويل الخطة فوراً إلى $plan.';
  }

  @override
  String plansScheduledDowngradeSuccess(String plan) {
    return 'تمت جدولة التخفيض إلى $plan لنهاية الفترة.';
  }

  @override
  String get plansBillingNotConfigured =>
      'خدمة الفوترة غير مهيأة في هذه البيئة.';

  @override
  String get plansLoading => 'جاري تحميل تفاصيل الاشتراك...';

  @override
  String get plansTierFreeSub => 'دفتر البداية';

  @override
  String get plansTierFreeDesc => 'إدارة مالية أساسية للمشاريع الفردية.';

  @override
  String get plansTierPlusSub => 'الشركات النامية';

  @override
  String get plansTierPlusDesc =>
      'أتمتة مالية كاملة وتقارير PDF/Excel و3 شركات نشطة.';

  @override
  String get plansTierProSub => 'منظومة المدير المالي المتعددة';

  @override
  String get plansTierProDesc =>
      'أقصى سعة مع 5 شركات نشطة وتصدير غير محدود وتقارير مخصصة.';

  @override
  String get plansFeaturesHeader => 'ما تتضمنه الخطة:';

  @override
  String allocationTitleDowngrade(String plan) {
    return 'اختر الشركات النشطة لخطة $plan';
  }

  @override
  String allocationTitlePending(String plan) {
    return 'تحديث التوزيع المجدول لخطة $plan';
  }

  @override
  String get allocationTitleManage => 'إدارة توزيع الشركات النشطة';

  @override
  String allocationSubtitle(int max) {
    return 'اختر حتى $max شركة لتبقى نشطة (قابلة للتعديل). تبقى الشركات الأخرى محفوظة بالكامل في وضع القراءة فقط.';
  }

  @override
  String allocationSelectedCounter(int count, int max) {
    return 'المختار $count / $max';
  }

  @override
  String get allocationCurrentUnlocked => 'الحالة: نشطة (قابلة للتعديل)';

  @override
  String get allocationCurrentLocked => 'الحالة: مقفلة (البيانات محفوظة)';

  @override
  String get allocationOutcomeActive => 'ستبقى نشطة (قابلة للتعديل):';

  @override
  String get allocationOutcomeLocked => 'ستصبح مقفلة (البيانات محفوظة بأمان):';

  @override
  String allocationExactError(int count) {
    return 'يرجى اختيار $count شركة بالضبط للمتابعة.';
  }

  @override
  String allocationSubmitDowngrade(String plan) {
    return 'تأكيد التخفيض إلى $plan';
  }

  @override
  String get allocationSubmitSave => 'حفظ توزيع الشركات';

  @override
  String get allocationUpdatedSuccess => 'تم تحديث توزيع مساحات العمل بنجاح.';

  @override
  String cancelSubTrialTitle(String plan) {
    return 'إلغاء تجربة $plan المجانية (7 أيام)؟';
  }

  @override
  String cancelSubPaidTitle(String plan) {
    return 'إلغاء اشتراك $plan؟';
  }

  @override
  String get cancelSubSubtitle =>
      'يرجى مراجعة موعد انتهاء الصلاحيات وكيفية الحفاظ على بيانات شركاتك.';

  @override
  String get cancelSubEndAccessLabel => 'متى ينتهي الوصول المدفوع';

  @override
  String cancelSubEndAccessDesc(String plan, String date) {
    return 'ستحتفظ بوصول $plan الكامل حتى $date.';
  }

  @override
  String get cancelSubFuturePayLabel => 'المدفوعات والفوترة المستقبلية';

  @override
  String get cancelSubTrialNoCharge =>
      'لن يتم تحصيل أي مبلغ عند انتهاء التجربة المجانية.';

  @override
  String get cancelSubPaidNoRenew =>
      'لن يتم تجديد الاشتراك ولن تُفرض رسوم إضافية.';

  @override
  String get cancelSubBizSafeLabel => 'ماذا يحدث لشركاتك';

  @override
  String get cancelSubBizSafeDesc =>
      'لن يتم حذف أي بيانات. تبقى شركة واحدة نشطة وتُقفل الشركات الإضافية مع حفظ كافة السجلات المالية حتى الترقية أو التبديل.';

  @override
  String cancelSubSelectOne(int total) {
    return 'اختر الشركة الوحيدة التي ستبقى نشطة في الخطة المجانية (1 من $total):';
  }

  @override
  String get cancelSubRemainsActive => 'تبقى نشطة';

  @override
  String get cancelSubBecomesLocked => 'ستُقفل';

  @override
  String get cancelSubKeepBtn => 'الإبقاء على الاشتراك';

  @override
  String get cancelSubConfirmBtn => 'تأكيد الإلغاء';

  @override
  String get cancelSubScheduledSuccess =>
      'تمت جدولة إلغاء الاشتراك لنهاية الفترة الحالية.';

  @override
  String get settingsHubSubtitle =>
      'إدارة الحساب، إعدادات مساحة العمل، الأمان، والتفضيلات.';

  @override
  String get settingsGroupAccountWorkspace => 'الحساب ومساحة العمل';

  @override
  String get settingsGroupSecurityPrefs => 'الأمان والتفضيلات';

  @override
  String get settingsGroupDataConnections => 'البيانات والاتصالات';

  @override
  String get settingsTabGeneral => 'عام';

  @override
  String get settingsTabGeneralSub =>
      'إعدادات الشركة الأساسية، التنسيقات، والملف الشخصي';

  @override
  String get settingsTabBusinessProfile => 'ملف الشركة';

  @override
  String get settingsTabBusinessProfileSub =>
      'بيانات الشركة، الرقم الضريبي، والعنوان';

  @override
  String get settingsTabSubscription => 'الاشتراك والفوترة';

  @override
  String get settingsTabSubscriptionSub =>
      'حدود الخطة، فواتير Stripe، والشركات';

  @override
  String get settingsTabUsersPermissions => 'المستخدمون والصلاحيات';

  @override
  String get settingsTabUsersPermissionsSub =>
      'أدوار الفريق وأعضاء مساحة العمل';

  @override
  String get settingsTabSecurity => 'الأمان والتحقق الثنائي';

  @override
  String get settingsTabSecuritySub =>
      'كلمة المرور، المصادقة الثنائية، الجلسات والبصمة';

  @override
  String get settingsTabAppearance => 'المظهر والسمات';

  @override
  String get settingsTabAppearanceSub => 'نمط العرض، الألوان، الخطوط، والكثافة';

  @override
  String get settingsTabSignature => 'خزنة التوقيع الحي';

  @override
  String get settingsTabSignatureSub =>
      'أختام التوقيع للفواتير والتقارير المصدرة';

  @override
  String get settingsTabLanguage => 'اللغة';

  @override
  String get settingsTabLanguageSub => 'العربية / English واتجاه الواجهة';

  @override
  String get settingsTabNotifications => 'الإشعارات';

  @override
  String get settingsTabNotificationsSub => 'تفضيلات تنبيهات البريد والتطبيق';

  @override
  String get settingsTabDataExport => 'البيانات والتصدير';

  @override
  String get settingsTabDataExportSub =>
      'ملفات Excel وPDF بالعربية وأرشيف الأرباح';

  @override
  String get settingsTabIntegrations => 'التكاملات';

  @override
  String get settingsTabIntegrationsSub =>
      'ربط البنوك وواجهات Webhook الخارجية';

  @override
  String get settingsBadgeSoon => 'قريباً';

  @override
  String get settingsBadgeLocal => 'محلي على الجهاز';

  @override
  String get settingsBadge2faOn => '2FA مفعل';

  @override
  String get settingsBadge2faOff => '2FA معطل';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get settingsReadOnlyBanner =>
      'مساحة العمل هذه في وضع القراءة فقط. حقول الشركة مقفلة بينما تبقى إعداداتك الشخصية قابلة للتعديل.';

  @override
  String get settingsSignOutConfirmTitle => 'تسجيل الخروج من AFAB؟';

  @override
  String get settingsSignOutConfirmDesc =>
      'ستنتهي جلستك على هذا الجهاز وسيتم مسح رموز الدخول المحلية.';

  @override
  String get settingsAppVersion => 'AFAB Mobile v1.0.0';

  @override
  String get generalSettingsTitle => 'الإعدادات العامة';

  @override
  String get generalSettingsUnsavedBadge => 'تغييرات غير محفوظة';

  @override
  String get generalSettingsMemberNotice =>
      'يقتصر تعديل إعدادات الشركة على المالكين والمسؤولين. تبقى التفضيلات الشخصية أدناه قابلة للتعديل.';

  @override
  String get generalSettingsAccountCard => 'الملف الشخصي للحساب';

  @override
  String get generalSettingsBusinessCard => 'إعدادات الشركة';

  @override
  String get generalSettingsRegionalCard => 'التنسيقات الإقليمية';

  @override
  String get generalSettingsPrefsCard => 'التفضيلات';

  @override
  String get generalSettingsOtherCard => 'إعدادات أخرى';

  @override
  String get generalSettingsBizName => 'اسم الشركة';

  @override
  String get generalSettingsBizEmail => 'البريد الإلكتروني للشركة';

  @override
  String get generalSettingsCurrency => 'العملة الأساسية';

  @override
  String get generalSettingsLiveFx => 'محرك الصرف الحي';

  @override
  String get generalSettingsTimezone => 'المنطقة الزمنية';

  @override
  String get generalSettingsFiscalStart => 'بداية السنة المالية';

  @override
  String get generalSettingsAccountingCycle => 'الدورة المحاسبية النشطة';

  @override
  String get generalSettingsDateFormat => 'تنسيق التاريخ';

  @override
  String get generalSettingsNumberFormat => 'تنسيق الأرقام';

  @override
  String get generalSettingsPrefAi => 'تفعيل رؤى الذكاء الاصطناعي';

  @override
  String get generalSettingsPrefAiSub =>
      'عرض توصيات المساعد المالي الذكي على لوحة التحكم';

  @override
  String get generalSettingsPrefCompact => 'الوضع المضغوط';

  @override
  String get generalSettingsPrefCompactSub =>
      'استخدام مسافات أكثر إحكاماً في القوائم والحقول';

  @override
  String get generalSettingsPrefAutoCat => 'تصنيف المعاملات تلقائياً';

  @override
  String get generalSettingsPrefAutoCatSub =>
      'اقتراح التصنيفات تلقائياً من وصف المعاملة';

  @override
  String get generalSettingsPrefTips => 'عرض النصائح والإرشادات';

  @override
  String get generalSettingsPrefTipsSub => 'إظهار تلميحات إرشادية داخل الوحدات';

  @override
  String get generalSettingsExportData => 'تصدير بياناتي';

  @override
  String get generalSettingsExportDataSub =>
      'تنزيل نسخة JSON شاملة لحسابك ودفاترك';

  @override
  String generalSettingsExportComplete(
    int bizCount,
    int txCount,
    int sessCount,
  ) {
    return 'تم تصدير $bizCount شركة، $txCount معاملة، و$sessCount جلسة.';
  }

  @override
  String get generalSettingsDeleteAccount => 'حذف الحساب';

  @override
  String get generalSettingsDeleteAccountSub =>
      'إخفاء الهوية الشخصية وإلغاء جميع جلسات الدخول';

  @override
  String get generalSettingsSaveChanges => 'حفظ التغييرات';

  @override
  String get generalSettingsSavedToast => 'تم حفظ الإعدادات بنجاح.';

  @override
  String generalSettingsPartialSaveError(String msg) {
    return 'تعذر حفظ بعض التغييرات: $msg';
  }

  @override
  String get generalSettingsDiscardTitle => 'تجاهل التغييرات غير المحفوظة؟';

  @override
  String get generalSettingsDiscardDesc =>
      'لديك تعديلات غير محفوظة في الإعدادات. هل تريد تجاهلها والمغادرة؟';

  @override
  String get generalSettingsDiscardBtn => 'تجاهل';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get editProfileUploadPhoto => 'رفع صورة';

  @override
  String get editProfileRemovePhoto => 'إزالة';

  @override
  String get editProfilePresetAvatars => 'صور رمزية جاهزة';

  @override
  String get editProfileFirstName => 'الاسم الأول';

  @override
  String get editProfileLastName => 'اسم العائلة';

  @override
  String get editProfilePhone => 'رقم الهاتف';

  @override
  String get editProfileEmailReadOnly => 'البريد الإلكتروني (للقراءة فقط)';

  @override
  String get editProfileVerified => 'مُوثّق';

  @override
  String get editProfileSave => 'حفظ الملف';

  @override
  String get editProfileSaved => 'تم تحديث الملف الشخصي.';

  @override
  String get editProfileInvalidPhoto => 'تعذر معالجة الصورة المختارة.';

  @override
  String deleteAccountTitle(String name) {
    return 'حذف حساب $name';
  }

  @override
  String deleteAccountStepOf(int step) {
    return '$step / 3';
  }

  @override
  String get deleteAccountExportBtn => 'تصدير بياناتي أولاً (.json)';

  @override
  String deleteAccountExportDone(int txCount, int bizCount) {
    return 'النسخة الاحتياطية جاهزة ($txCount معاملة، $bizCount شركة).';
  }

  @override
  String get deleteAccountShareAgain => 'مشاركة / حفظ مجدداً';

  @override
  String get deleteAccountContinueBtn => 'المتابعة لحذف الحساب';

  @override
  String get deleteAccountSkipExportBtn => 'تخطي التصدير — أريد حذف هذا الحساب';

  @override
  String get deleteAccountWarningBanner =>
      'انتبه جيداً لما سيحدث قبل المتابعة!';

  @override
  String deleteAccountConsequence1(String name, String email) {
    return 'سيؤدي هذا إلى تعطيل حساب $name ($email) وإخفاء بياناته الشخصية ضمن سجل أرشيفي مغلق.';
  }

  @override
  String get deleteAccountConsequence2 =>
      'سيتم فوراً إلغاء جميع الجلسات النشطة ومفاتيح التحقق الثنائي والعضويات، وإيقاف أي اشتراك نشط بأفضل جهد ممكن.';

  @override
  String get deleteAccountConsequence3 =>
      'يتم الاحتفاظ بسجلات الشركات المالية وسجلات التدقيق بأمان — يجب نقل ملكية الشركات النشطة التي تملكها أو أرشفتها أولاً.';

  @override
  String get deleteAccountIrreversible =>
      'هذا الإجراء نهائي ولا يمكن التراجع عنه.';

  @override
  String get deleteAccountReadConfirmBtn => 'قرأت وأفهم هذه الآثار';

  @override
  String get deleteAccountPreflightError =>
      'تعذر التحقق من الشركات المانعة للحذف حالياً.';

  @override
  String get deleteAccountBlockingTitle =>
      'قم بمعالجة الشركات المملوكة النشطة أولاً';

  @override
  String deleteAccountMembersBadge(int count) {
    return '$count عضو';
  }

  @override
  String get deleteAccountReadOnlyDeadlock =>
      'مساحة العمل هذه في وضع القراءة فقط بعد تخفيض الخطة ولا يمكن أرشفتها أو نقلها وهي مقفلة. قم بإعادة توزيع فتحات النشاط أو ترقية خطتك أولاً.';

  @override
  String get deleteAccountManageAllocBtn => 'إدارة التوزيع';

  @override
  String get deleteAccountArchiveBizBtn => 'أرشفة الشركة';

  @override
  String deleteAccountArchiveConfirmTitle(String name) {
    return 'أرشفة \"$name\"؟';
  }

  @override
  String get deleteAccountArchiveConfirmDesc =>
      'تزيل الأرشفة مساحة العمل هذه من الاستخدام النشط حتى يمكن إكمال حذف حسابك.';

  @override
  String get deleteAccountTransferBtn => 'نقل الملكية';

  @override
  String deleteAccountTransferTitle(String name) {
    return 'نقل ملكية $name';
  }

  @override
  String deleteAccountTransferWarning(String name) {
    return 'ستصبح مسؤولاً (Admin) وتفقد صلاحيات المالك لـ $name بشكل دائم.';
  }

  @override
  String get deleteAccountNoEligibleMembers =>
      'لا يوجد أعضاء نشطون آخرون لنقل الملكية إليهم.';

  @override
  String deleteAccountPhrasePrompt(String phrase) {
    return 'للتأكيد، اكتب \"$phrase\" أدناه:';
  }

  @override
  String get deleteAccountFinalBtn => 'حذف هذا الحساب';

  @override
  String get deleteAccountSuccessToast =>
      'تم تعطيل حسابك وإخفاء بياناته الشخصية بأمان.';

  @override
  String get businessProfileTitle => 'ملف الشركة';

  @override
  String get businessProfileSummaryCard => 'ملخص مساحة العمل';

  @override
  String get businessProfileLogoCard => 'شعار الشركة';

  @override
  String get businessProfileLogoUrl => 'رابط الشعار (HTTPS)';

  @override
  String get businessProfileUseMonogram => 'استخدام شعار الأحرف';

  @override
  String get businessProfileLogoHelp =>
      'أدخل رابط صورة HTTPS بطول أقصى 500 حرف (روابط base64 غير مدعومة).';

  @override
  String get businessProfileLogoInvalid =>
      'يجب أن يكون رابط الشعار http(s) صالحاً وبحد أقصى 500 حرف.';

  @override
  String get businessProfileInfoCard => 'معلومات الشركة';

  @override
  String get businessProfileIndustry => 'القطاع';

  @override
  String get businessProfileWebsite => 'الموقع الإلكتروني';

  @override
  String get businessProfileTaxId => 'الرقم الضريبي';

  @override
  String get businessProfileTaxIdHelp =>
      'يظهر في الفواتير والتقارير المالية المعتمدة.';

  @override
  String get businessProfileAddress => 'العنوان التفصيلي';

  @override
  String get businessProfileCity => 'المدينة';

  @override
  String get businessProfileState => 'الولاية / المنطقة';

  @override
  String get businessProfilePostal => 'الرمز البريدي';

  @override
  String get businessProfileCountry => 'الدولة';

  @override
  String get businessProfileDesc => 'وصف النشاط (اختياري)';

  @override
  String get businessProfileMemberSince => 'تاريخ التأسيس';

  @override
  String get businessProfileLocation => 'الموقع';

  @override
  String get businessProfileSavedToast => 'تم تحديث ملف الشركة بنجاح.';

  @override
  String get securityTitle => 'الأمان والتحقق الثنائي';

  @override
  String get securityOverviewSecure => 'حسابك محمي بالمصادقة الثنائية';

  @override
  String get securityOverviewRecommend =>
      'إجراء موصى به: فعّل المصادقة الثنائية';

  @override
  String get securityTwoFactorLabel => 'المصادقة الثنائية';

  @override
  String get securityPasswordLabel => 'كلمة المرور';

  @override
  String securityPasswordChanged(String date) {
    return 'تغيرت في $date';
  }

  @override
  String get securityPasswordStrong => 'مضبوطة';

  @override
  String securityActiveSessionsCount(int count) {
    return '$count جلسة نشطة';
  }

  @override
  String get securityChangePasswordBtn => 'تغيير كلمة المرور';

  @override
  String get securityEnable2faBtn => 'تفعيل 2FA';

  @override
  String get securityManage2faBtn => 'إدارة 2FA';

  @override
  String get securityBiometricTitle => 'قفل التطبيق بالبصمة';

  @override
  String get securityBiometricSub => 'طلب بصمة الوجه أو الإصبع لفتح AFAB';

  @override
  String get securityBiometricUnavailable =>
      'المصادقة البيومترية غير مفعلة على هذا الجهاز.';

  @override
  String get securityBiometricPrompt => 'تحقق من هويتك لفتح AFAB';

  @override
  String get securityUnlockBtn => 'فتح باستخدام البصمة';

  @override
  String get securityCurrentPwd => 'كلمة المرور الحالية';

  @override
  String get securityNewPwd => 'كلمة المرور الجديدة';

  @override
  String get securityConfirmPwd => 'تأكيد كلمة المرور الجديدة';

  @override
  String get securityChangePwdWarning =>
      'سيتم تسجيل خروجك من جميع الأجهزة وسيُطلب منك تسجيل الدخول مجدداً بكلمة المرور الجديدة.';

  @override
  String get securityChangePwdSuccess =>
      'تم تحديث كلمة المرور. يرجى تسجيل الدخول بالكلمة الجديدة.';

  @override
  String get securitySetup2faTitle => 'إعداد المصادقة الثنائية';

  @override
  String get security2faStep1Desc =>
      'امسح رمز QR عبر تطبيق المصادقة أو انسخ المفتاح السري:';

  @override
  String get securityCopySecret => 'نسخ مفتاح الإعداد';

  @override
  String get security2faStep2Desc =>
      'أدخل الرمز المكون من 6 أرقام من تطبيق المصادقة:';

  @override
  String get security2faVerifyEnable => 'تحقق وتفعيل 2FA';

  @override
  String get security2faBackupTitle => 'احفظ رموز الاسترداد الاحتياطية';

  @override
  String get security2faBackupDesc =>
      'احتفظ بهذه الرموز الثمانية للاستخدام لمرة واحدة في مكان آمن.';

  @override
  String get securityCopyAllCodes => 'نسخ جميع الرموز';

  @override
  String get securityShareTxt => 'حفظ / مشاركة (.txt)';

  @override
  String get securityManage2faTitle => 'إدارة المصادقة الثنائية';

  @override
  String get securityRegenerateCodes => 'إعادة توليد رموز الاسترداد';

  @override
  String get securityDisable2faTitle => 'تعطيل المصادقة الثنائية';

  @override
  String get securityDisable2faDesc =>
      'أدخل كلمة المرور الحالية لإزالة حماية 2FA من هذا الحساب.';

  @override
  String get securityDisable2faBtn => 'تعطيل 2FA';

  @override
  String get securitySessionsTitle => 'الجلسات النشطة';

  @override
  String get securityLogOutAllBtn => 'تسجيل الخروج من كل الجلسات';

  @override
  String get securitySessionCaveatNote =>
      'ملاحظة: يؤدي إنهاء كل الجلسات إلى تسجيل خروج هذا الجهاز أيضاً.';

  @override
  String get securityLogOutAllTitle => 'تسجيل الخروج من كل الجلسات النشطة؟';

  @override
  String get securityLogOutAllDesc =>
      'سيتم تسجيل الخروج من جميع الجلسات النشطة — بما في ذلك هذا الجهاز — فوراً.';

  @override
  String get securityRevokeSessionConfirm => 'إنهاء صلاحية هذه الجلسة؟';

  @override
  String get securityNoSessions => 'لا توجد جلسات نشطة حالياً.';

  @override
  String get securityTipsTitle => 'أفضل ممارسات الأمان';

  @override
  String get securityTip1Title => 'استخدم كلمة مرور قوية وفريدة';

  @override
  String get securityTip1Desc =>
      'امزج بين الأحرف الكبيرة والصغيرة والأرقام والرموز (8 أحرف على الأقل).';

  @override
  String get securityTip2Title => 'حافظ على تفعيل المصادقة الثنائية';

  @override
  String get securityTip2Desc => 'تحمي حسابك حتى في حال تسرب كلمة المرور.';

  @override
  String get securityTip3Title => 'راجع الجلسات النشطة شهرياً';

  @override
  String get securityTip3Desc => 'ألغِ أي جلسات أو أجهزة غير معروفة فوراً.';

  @override
  String get securityTip4Title => 'احفظ رموز الاسترداد دون اتصال';

  @override
  String get securityTip4Desc => 'احتفظ برموز الطوارئ بعيداً عن هاتف المصادقة.';

  @override
  String get appearanceTitle => 'المظهر والسمات';

  @override
  String get appearanceDeviceLocalNote =>
      'تُطبق السمات والألوان والخطوط والأسطح فوراً على هذا الجهاز؛ كما يتزامن الوضع المضغوط مع حسابك.';

  @override
  String get appearanceLivePreviewJump => 'معاينة حية';

  @override
  String get appearanceResetBtn => 'إعادة ضبط';

  @override
  String get appearanceSaveBtn => 'حفظ التفضيلات';

  @override
  String get appearanceSavedToast => 'تم حفظ تفضيلات المظهر.';

  @override
  String get appearanceSavedLocalOffline =>
      'تم الحفظ محلياً؛ سيتزامن الوضع المضغوط عند توفر الاتصال.';

  @override
  String get appearanceThemeModeTitle => 'وضع السمة';

  @override
  String get appearanceModeLight => 'فاتح';

  @override
  String get appearanceModeDark => 'داكن';

  @override
  String get appearanceModeSystem => 'النظام';

  @override
  String get appearanceDarkSurfaceTitle => 'نمط السطح الداكن';

  @override
  String get appearanceSurfaceMidnight => 'أزرق منتصف الليل';

  @override
  String get appearanceSurfaceOled => 'أسود OLED النقي';

  @override
  String get appearanceSurfaceSlate => 'أردوازي عميق';

  @override
  String get appearanceSurfaceCharcoal => 'فحمي داكن';

  @override
  String get appearanceAccentTitle => 'لون العلامة المميز';

  @override
  String get appearanceCustomHex => 'رمز لون مخصص (#RRGGBB)';

  @override
  String get appearanceLowContrastWarn => 'تباين منخفض مع نص الأزرار الأبيض';

  @override
  String get appearanceTypographyTitle => 'الخطوط والطباعة';

  @override
  String get appearanceFontSizeTitle => 'مقياس حجم الخط';

  @override
  String get appearanceRadiusTitle => 'استدارة الزوايا';

  @override
  String get appearanceDensityEffectsTitle => 'الكثافة والمؤثرات البصرية';

  @override
  String get appearanceDensityComfortable => 'مريح';

  @override
  String get appearanceDensityCompact => 'مضغوط';

  @override
  String get appearanceEnableGlow => 'توهج نيون محيطي';

  @override
  String get appearanceSmoothTransitions => 'انتقالات سلسة';

  @override
  String get appearanceLivePreviewTitle => 'معاينة حية فورية';

  @override
  String get signatureTitle => 'خزنة التوقيع الحي';

  @override
  String signatureSavedCount(int count) {
    return '$count محفوظ';
  }

  @override
  String get signatureDeviceLocalNotice =>
      'تُحفظ التوقيعات محلياً على هذا الجهاز فقط للشركة النشطة ولا تتزامن مع الخوادم السحابية أو الأجهزة الأخرى.';

  @override
  String get signatureVaultTitle => 'خزنة التوقيعات المحفوظة';

  @override
  String get signatureEmptyTitle => 'لا توجد توقيعات محفوظة بعد';

  @override
  String get signatureEmptyDesc =>
      'ارسم توقيعك باليد أو ارفع صورة توقيع لإدراجها في الفواتير والتقارير المصدرة.';

  @override
  String get signatureActiveBadge => 'نشط ومستخدم';

  @override
  String get signatureSetActive => 'تعيين كنشط';

  @override
  String signatureEditingBanner(String label) {
    return 'جاري التعديل: $label';
  }

  @override
  String get signatureTabDraw => 'لوحة الرسم';

  @override
  String get signatureTabUpload => 'رفع صورة';

  @override
  String get signatureInkBlack => 'حبر أسود';

  @override
  String get signatureInkBlue => 'أزرق ملكي';

  @override
  String get signatureResetPad => 'مسح اللوحة';

  @override
  String get signatureUseDrawing => 'اعتماد هذا الرسم';

  @override
  String get signatureTakePhoto => 'التقاط صورة';

  @override
  String get signatureChooseFile => 'اختيار صورة';

  @override
  String get signatureTransparentBg => 'إزالة خلفية الورق تلقائياً (حبر شفاف)';

  @override
  String get signatureLabelField => 'تسمية التوقيع';

  @override
  String get signatureSignatoryName => 'الاسم الكامل للموقّع';

  @override
  String get signatureSignatoryTitle => 'الصفة / المسمى الوظيفي';

  @override
  String get signatureSetDefaultCheck => 'تعيين هذا التوقيع كنشط فوراً';

  @override
  String get signatureAutoApplySwitch =>
      'ختم التوقيع النشط تلقائياً على الفواتير والتقارير المصدرة';

  @override
  String get signatureSaveVaultBtn => 'حفظ التوقيع في الخزنة';

  @override
  String get signatureUpdateVaultBtn => 'تحديث التوقيع';

  @override
  String get signaturePreviewTitle => 'معاينة المستند المعتمد';

  @override
  String get signatureCertifiedStamp => 'معتمد';

  @override
  String signatureDeleteConfirm(String label) {
    return 'حذف التوقيع \"$label\"؟';
  }

  @override
  String get signatureTooLarge =>
      'حجم الصورة كبير جداً (الحد الأقصى 5 ميغابايت).';

  @override
  String get signatureSavedToast => 'تم حفظ التوقيع في الخزنة المحلية.';

  @override
  String get dataExportTitle => 'البيانات والتصدير';

  @override
  String dataExportTruncationBanner(int loaded, int total) {
    return 'يتم عرض $loaded من أصل $total سجل للتصدير (الحد الأقصى 1,000 لكل مجموعة). ضيّق الفترة الزمنية أو صدّر JSON الكامل من الإعدادات العامة.';
  }

  @override
  String get dataExportPeriodLabel => 'الفترة';

  @override
  String get dataExportCurrencyLabel => 'عملة العرض';

  @override
  String get dataExportCurrencyNote =>
      'تظهر السجلات بعملتها الأصلية دون تحويل صرف فوري.';

  @override
  String get dataExportCountTx => 'معاملات الفترة';

  @override
  String get dataExportCountCustomers => 'دليل العملاء';

  @override
  String get dataExportCountInvoices => 'فواتير الفترة';

  @override
  String get dataExportCountNetFlow => 'صافي التدفق (الفترة)';

  @override
  String get dataExportMasterBadge => 'الأرشيف الكامل للشركة';

  @override
  String get dataExportMasterDesc =>
      'تصدير المؤشرات والمعاملات والعملاء والفواتير معاً بدعم كامل للعربية وUTF-8.';

  @override
  String get dataExportAllExcel => 'تصدير Excel (.xlsx)';

  @override
  String get dataExportAllPdf => 'تصدير PDF (.pdf)';

  @override
  String get dataExportPrintPreview => 'معاينة / مشاركة PDF';

  @override
  String get dataExportModularTx => 'المعاملات والتدفق النقدي';

  @override
  String get dataExportModularCustomers => 'سجل العملاء والطلبات';

  @override
  String get dataExportModularInvoices => 'سجل الفواتير والتحصيل';

  @override
  String get dataExportModularPnl => 'الأداء المالي (الأرباح والخسائر)';

  @override
  String get dataExportBackendCsv => 'CSV من الخادم';

  @override
  String get dataExportBackendPdf => 'PDF رسمي من الخادم';

  @override
  String get dataExportComplianceFooter =>
      'تدعم ملفات Excel وPDF بخط Cairo اللغة العربية واتجاه RTL بالكامل.';

  @override
  String get dataExportSheetTitle => 'تأكيد نطاق التصدير';

  @override
  String get dataExportFiscalMatricule => 'الرقم الضريبي';

  @override
  String get dataExportBusinessPurpose => 'النشاط / الغرض التجاري';

  @override
  String get dataExportOfficialAddress => 'العنوان الرسمي للشركة';

  @override
  String get dataExportIncludeLogo => 'تضمين بيانات شعار الشركة';

  @override
  String get dataExportIncludeSig => 'تضمين التوقيع الحي النشط';

  @override
  String get dataExportGenerateShare => 'إنشاء ومشاركة';

  @override
  String get languageSettingsTitle => 'اللغة';

  @override
  String get languageSystemTitle => 'لغة النظام الافتراضية';

  @override
  String get languageSystemSub =>
      'اتّباع لغة نظام التشغيل (مع الرجوع إلى الإنجليزية)';

  @override
  String get languageEnglishSub =>
      'من اليسار إلى اليمين (LTR) · التقويم الميلادي · أرقام قياسية (0-9)';

  @override
  String get languageArabicSub =>
      'من اليمين إلى اليسار (RTL) · التقويم الميلادي · أرقام قياسية (0-9)';

  @override
  String get languagePreviewTitle => 'معاينة حية للاتجاه والتنسيق';

  @override
  String languagePreviewDir(String dir) {
    return 'الاتجاه: $dir';
  }

  @override
  String get languageCopilotNote =>
      'لغة واجهة التطبيق مستقلة عن لغات استجابة المساعد الذكي الخمس (الإنجليزية والفرنسية والعربية الفصحى والدارجة التونسية والعربيزي) التي يمكنك اختيارها داخل المساعد.';

  @override
  String get languageUpdatedToast => 'تم تحديث لغة الواجهة.';

  @override
  String get comingSoonBadge => 'قريباً';

  @override
  String get comingSoonBackBtn => 'العودة إلى الإعدادات';

  @override
  String get comingSoonUsersDesc =>
      'دعوة أعضاء الفريق وتعديل الأدوار وإدارة الصلاحيات الدقيقة قيد التطوير لإصدار قادم.';

  @override
  String get comingSoonMembersTitle =>
      'أعضاء مساحة العمل الحاليون (للقراءة فقط)';

  @override
  String get comingSoonOnlyYou =>
      'أنت العضو النشط الوحيد في مساحة العمل هذه حالياً.';

  @override
  String get comingSoonNotificationsDesc =>
      'ستتوفر قريباً إعدادات تفصيلية لجداول ملخص البريد وقواعد التنبيهات الفورية.';

  @override
  String get comingSoonOpenNotifCenter => 'عرض مركز الإشعارات';

  @override
  String get comingSoonIntegrationsDesc =>
      'ستتوفر قريباً تكاملات الحسابات البنكية وواجهات Webhook الخارجية هنا.';
}
