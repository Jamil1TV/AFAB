// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AFAB';

  @override
  String get appTagline => 'AI Finance Assistant for Business';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Try Again';

  @override
  String get commonReload => 'Reload';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonNoData => 'No Data';

  @override
  String get commonComingSoon => 'Coming Soon';

  @override
  String get commonComingSoonDesc =>
      'This section will be implemented in an upcoming milestone.';

  @override
  String get commonViewAll => 'View all';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonActive => 'Active';

  @override
  String get commonLocked => 'Locked';

  @override
  String get commonReadOnly => 'Read-Only';

  @override
  String get commonOfflineBanner =>
      'You are offline. Some actions require an active internet connection.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get languageSwitchShort => 'AR';

  @override
  String get periodWeekly => 'WEEKLY';

  @override
  String get periodMonthly => 'MONTHLY';

  @override
  String get periodYearly => 'YEARLY';

  @override
  String get periodVsLastWeek => 'vs last week';

  @override
  String get periodVsLastMonth => 'vs last month';

  @override
  String get periodVsLastYear => 'vs last year';

  @override
  String get authLoginTab => 'Log In';

  @override
  String get authSignupTab => 'Sign Up';

  @override
  String get authLoginTitle => 'Log in to your account';

  @override
  String get authLoginSubtitle => 'Welcome back! Please enter your details.';

  @override
  String get authSignupTitle => 'Create your account';

  @override
  String get authSignupSubtitle => 'Join thousands of business owners today.';

  @override
  String get authFirstName => 'First Name';

  @override
  String get authFirstNamePlaceholder => 'Jane';

  @override
  String get authLastName => 'Last Name';

  @override
  String get authLastNamePlaceholder => 'Doe';

  @override
  String get authEmail => 'Email address';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordPlaceholder => 'Enter your password';

  @override
  String get authPasswordCreatePlaceholder => 'Create a password';

  @override
  String get authBusinessName => 'Business Name';

  @override
  String get authBusinessNamePlaceholder => 'Acme Corp';

  @override
  String get authLoginButton => 'Log In';

  @override
  String get authSignupButton => 'Sign Up';

  @override
  String get authRememberMe => 'Remember for 30 days';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHasAccount => 'Already have an account?';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get authVerifyButton => 'Verify Email';

  @override
  String get authDidntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get authResendCode => 'Resend Code';

  @override
  String authResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authCodeResent => 'Verification code sent! Check your inbox.';

  @override
  String get authVerifySuccess => 'Email verified successfully!';

  @override
  String get authVerifyCodeIncomplete => 'Please enter the full 6-digit code.';

  @override
  String get authNoEmailFound =>
      'Session invalid. Please sign up or log in again.';

  @override
  String get authUseDifferentAccount => 'Sign out and use another account';

  @override
  String authDevOtpNotice(String code) {
    return 'Development verification code: $code';
  }

  @override
  String get authForgotPasswordTitle => 'Forgot your password?';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get authEmailRequired => 'Email address is required.';

  @override
  String get authEmailInvalid => 'Please enter a valid email address.';

  @override
  String get authFieldRequired => 'This field is required.';

  @override
  String get authPasswordMinLength => 'Password must be at least 8 characters.';

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authResetEmailSent => 'Check your email';

  @override
  String authResetEmailSentSubtitle(String email) {
    return 'We\'ve sent a password reset link to $email';
  }

  @override
  String get authHaveResetToken => 'Already have a reset token?';

  @override
  String get authEnterTokenManually => 'Enter token manually';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authResetPasswordTitle => 'Set a new password';

  @override
  String get authResetPasswordSubtitle =>
      'Your new password must meet all requirements below.';

  @override
  String get authResetPasswordValidating => 'Validating your reset link...';

  @override
  String get authResetTokenLabel => 'Reset Token';

  @override
  String get authResetTokenHint => 'Paste your password reset token';

  @override
  String get authValidateTokenButton => 'Validate Token';

  @override
  String get authNewPassword => 'New Password';

  @override
  String get authNewPasswordPlaceholder => 'Enter your new password';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authConfirmPasswordPlaceholder => 'Confirm your new password';

  @override
  String get authResetButton => 'Reset Password';

  @override
  String get authResetPasswordWeak =>
      'Password does not meet all requirements.';

  @override
  String get authResetPasswordMismatch => 'Passwords do not match.';

  @override
  String get authPasswordResetSuccessTitle => 'Password reset!';

  @override
  String get authPasswordResetSuccessMessage =>
      'Your password has been reset successfully. You can now sign in.';

  @override
  String get authTokenExpiredTitle => 'Link expired';

  @override
  String get authTokenExpiredMessage =>
      'This password reset link has expired. Please request a new one.';

  @override
  String get authTokenInvalidTitle => 'Invalid link';

  @override
  String get authTokenInvalidMessage =>
      'This password reset link is invalid or has already been used.';

  @override
  String get authRequestNewLink => 'Request a new link';

  @override
  String get authPwStrengthLabel => 'Password strength';

  @override
  String get authPwStrengthWeak => 'Weak';

  @override
  String get authPwStrengthFair => 'Fair';

  @override
  String get authPwStrengthGood => 'Good';

  @override
  String get authPwStrengthStrong => 'Strong';

  @override
  String get authPwStrengthVeryStrong => 'Very Strong';

  @override
  String get authPwReqLength => 'At least 8 characters';

  @override
  String get authPwReqUppercase => 'One uppercase letter';

  @override
  String get authPwReqLowercase => 'One lowercase letter';

  @override
  String get authPwReqNumber => 'One number';

  @override
  String get authPwReqSpecial => 'One special character';

  @override
  String get authTwoFactorTitle => 'Two-Factor Authentication';

  @override
  String get authTwoFactorSubtitle =>
      'Enter the 6-digit code from your authenticator app to complete sign-in.';

  @override
  String get authTwoFactorVerifyButton => 'Verify & Sign In';

  @override
  String get authTwoFactorEnterCode => 'Authentication Code';

  @override
  String get authUseBackupCode => 'Use emergency backup recovery code';

  @override
  String get authUseTotpCode => 'Use 6-digit authenticator code';

  @override
  String get authBackupCodeLabel => 'Backup Recovery Code';

  @override
  String get authBackupCodePlaceholder => 'e.g. ABCD-1234';

  @override
  String get authErrorInvalidCredentials => 'Invalid email or password.';

  @override
  String get authErrorAccountDisabled => 'Your account is not active.';

  @override
  String get authErrorAccountLocked =>
      'Your account has been temporarily locked due to failed attempts.';

  @override
  String get authErrorRateLimited =>
      'Too many requests. Please wait and try again.';

  @override
  String get authErrorNetworkFailure =>
      'Unable to connect to the server. Please check your connection and try again.';

  @override
  String get authErrorServerFailure =>
      'Something went wrong. Please try again later.';

  @override
  String get authErrorInvalid2FaCode =>
      'Invalid authentication code or backup recovery code.';

  @override
  String get authErrorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String onboardingStep(int step) {
    return 'Step $step of 3';
  }

  @override
  String get onboardingStep1Tab => 'Business Info';

  @override
  String get onboardingStep2Tab => 'Financial Setup';

  @override
  String get onboardingStep3Tab => 'Review & Complete';

  @override
  String get onboardingStep1Title => 'Tell us about your business';

  @override
  String get onboardingStep1Subtitle =>
      'This helps us tailor financial reports and AI insights for you.';

  @override
  String get onboardingStep2Title => 'Configure your financial preferences';

  @override
  String get onboardingStep2Subtitle =>
      'Set up your accounting currency, timezone, and fiscal calendar.';

  @override
  String get onboardingStep3Title => 'You\'re all set to launch!';

  @override
  String get onboardingStep3Subtitle =>
      'Review your business configuration below.';

  @override
  String get onboardingCountryLabel => 'Country of Operation';

  @override
  String get onboardingIndustryLabel => 'Industry';

  @override
  String get onboardingBusinessTypeLabel => 'Entity Type';

  @override
  String get onboardingCurrencyLabel => 'Main Currency';

  @override
  String get onboardingTimezoneLabel => 'Timezone';

  @override
  String get onboardingFiscalYearLabel => 'Fiscal Year Starts In';

  @override
  String get onboardingSummaryCountry => 'Country';

  @override
  String get onboardingSummaryIndustry => 'Industry';

  @override
  String get onboardingSummaryBusinessType => 'Entity Type';

  @override
  String get onboardingSummaryCurrency => 'Base Currency';

  @override
  String get onboardingSummaryTimezone => 'Timezone';

  @override
  String get onboardingSummaryFiscalYear => 'Fiscal Year Starts';

  @override
  String get onboardingSearchHint => 'Search...';

  @override
  String get onboardingLaunchDashboard => 'Launch Dashboard';

  @override
  String get splashTagline => 'AI Finance Assistant for Business';

  @override
  String get splashRestoring => 'Restoring your secure workspace...';

  @override
  String get splashOfflineTitle => 'Connection Issue';

  @override
  String get splashOfflineSubtitle =>
      'We couldn\'t reach AFAB servers to verify your session.';

  @override
  String get splashContinueToLogin => 'Go to Sign In';

  @override
  String get navHome => 'Home';

  @override
  String get navFinance => 'Finance';

  @override
  String get navCopilot => 'Copilot';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navMore => 'More';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navRevenue => 'Revenue';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navRecurring => 'Recurring';

  @override
  String get navReports => 'Reports';

  @override
  String get navCurrencies => 'Currencies & FX';

  @override
  String get navAiAssistant => 'AI Assistant';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navSettings => 'Settings';

  @override
  String get navPlans => 'Plans & Billing';

  @override
  String get navNewBadge => 'New';

  @override
  String get navLogout => 'Logout';

  @override
  String dashboardGoodMorning(String name) {
    return 'Good Morning, $name';
  }

  @override
  String dashboardGoodAfternoon(String name) {
    return 'Good Afternoon, $name';
  }

  @override
  String dashboardGoodEvening(String name) {
    return 'Good Evening, $name';
  }

  @override
  String get dashboardSubtitle =>
      'Here\'s what\'s happening with your business today.';

  @override
  String get dashboardTotalRevenue => 'Total Revenue';

  @override
  String get dashboardTotalExpenses => 'Total Expenses';

  @override
  String get dashboardNetProfit => 'Net Profit';

  @override
  String get dashboardCashFlow => 'Cash Flow';

  @override
  String get dashboardRevenueChartTitle => 'Revenue & Expenses';

  @override
  String get dashboardRevenueChartSubtitle =>
      'Trailing 6-month cash flow performance';

  @override
  String get dashboardRevenueLabel => 'Revenue';

  @override
  String get dashboardExpensesLabel => 'Expenses';

  @override
  String get dashboardAwaitingData => 'Awaiting activity';

  @override
  String get dashboardExpenseCategoriesTitle => 'Expense Categories';

  @override
  String get dashboardExpenseCategoriesTotal => 'Total';

  @override
  String get dashboardExpenseCategoriesEmpty =>
      'No expense breakdown recorded for this period yet.';

  @override
  String get dashboardAiTitle => 'AI Assistant Insights';

  @override
  String get dashboardAiLivePulse => 'Live Pulse';

  @override
  String get dashboardAiAskBtn => 'Ask AI Assistant';

  @override
  String get dashboardAiInvestigate => 'Investigate in Copilot';

  @override
  String get dashboardAiAwaitingActivity => 'Awaiting Financial Activity';

  @override
  String get dashboardAiAwaitingActivityDesc =>
      'Record transactions or invoices to unlock live financial pulse alerts.';

  @override
  String get dashboardRecentTransactionsTitle => 'Recent Transactions';

  @override
  String get dashboardRecentTransactionsEmpty =>
      'No transactions recorded yet.';

  @override
  String get dashboardBudgetsTitle => 'Budget Progress';

  @override
  String dashboardBudgetsSubtitleActive(int active, int over, int approaching) {
    return '$active active • $over over budget • $approaching approaching';
  }

  @override
  String get dashboardBudgetsSubtitleEmpty =>
      'Set monthly or category spending caps to track business costs.';

  @override
  String get dashboardBudgetsManageLink => 'Manage Budgets';

  @override
  String get dashboardBudgetsEmpty =>
      'No active budgets for the current period.';

  @override
  String get dashboardBudgetsOverBy => 'Over by';

  @override
  String get dashboardBudgetsRemaining => 'Remaining';

  @override
  String get dashboardBudgetsOverLabel => 'Over Budget';

  @override
  String get dashboardBudgetsApproachingLabel => 'Approaching';

  @override
  String get dashboardBudgetsOnTrackLabel => 'On Track';

  @override
  String get dashboardRemindersTitle => 'Upcoming Reminders';

  @override
  String get dashboardRemindersEmpty =>
      'No urgent budget or invoice reminders.';

  @override
  String get dashboardCustomersTitle => 'Top Customers';

  @override
  String get dashboardCustomersEmpty =>
      'No paid customer activity recorded yet.';

  @override
  String get dashboardCustomersInRevenue => 'in revenue';

  @override
  String get dashboardUpgradeTitle => 'Supercharge your financial insights';

  @override
  String get dashboardUpgradeDesc =>
      'Unlock expanded AI Copilot quotas, multi-business workspaces, and custom financial reports.';

  @override
  String get dashboardUpgradeBtn => 'Upgrade Now';

  @override
  String get dashboardUpgradeProCta => 'Upgrade to Pro';

  @override
  String get dashboardLoadError => 'Unable to load your financial dashboard.';

  @override
  String get businessSwitcherTitle => 'Workspaces';

  @override
  String businessSwitcherCapacity(int editable, int limit) {
    return '$editable / $limit active';
  }

  @override
  String get businessSwitcherAddNew => 'Add Business';

  @override
  String get businessSwitcherCreateTitle => 'Create New Business';

  @override
  String get businessSwitcherNameLabel => 'Business Name';

  @override
  String get businessSwitcherNamePlaceholder => 'e.g. Northwind Studio';

  @override
  String get businessSwitcherCurrencyLabel => 'Base Currency';

  @override
  String get businessSwitcherCreateBtn => 'Create Workspace';

  @override
  String get businessSwitcherCreateSuccess =>
      'Workspace created and activated.';

  @override
  String businessSwitcherSwitched(String name) {
    return 'Switched to $name';
  }

  @override
  String get businessSwitcherLockedTitle => 'Workspace Locked (Read-Only)';

  @override
  String businessSwitcherLockedDesc(String name) {
    return 'Your current plan allows fewer active workspaces. Data for $name is safely preserved, but edits and switching require swapping active workspaces or upgrading your plan.';
  }

  @override
  String get businessSwitcherLimitTitle => 'Workspace Limit Reached';

  @override
  String businessSwitcherLimitDesc(int limit) {
    return 'Your plan allows up to $limit active owned business workspaces. Upgrade to Plus or Pro to unlock more workspaces.';
  }

  @override
  String get businessSwitcherManagePlans => 'View Plans & Allocations';

  @override
  String get businessRoleOwner => 'Owner';

  @override
  String get businessRoleAdmin => 'Admin';

  @override
  String get businessRoleMember => 'Member';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmpty => 'You\'re all caught up';

  @override
  String get notificationsEmptyDesc =>
      'New billing, workspace, and account alerts will appear here.';

  @override
  String bannerPastDueTitle(int hours) {
    return 'Payment Past Due — ${hours}h Grace Remaining';
  }

  @override
  String get bannerPastDueDesc =>
      'Update your payment method to keep Plus/Pro features and workspaces active.';

  @override
  String get bannerAllocationTitle => 'Workspace Allocation Required';

  @override
  String get bannerAllocationDesc =>
      'Select which businesses remain active under your current plan limit.';

  @override
  String get bannerManageAction => 'Manage';

  @override
  String get moreHubSectionOperations => 'Money & Operations';

  @override
  String get moreHubSectionIntelligence => 'Financial Intelligence';

  @override
  String get moreHubSectionWorkspace => 'Workspace & Preferences';

  @override
  String get moreHubPreferences => 'Quick Preferences';

  @override
  String get moreHubThemeMode => 'Theme Mode';

  @override
  String get moreHubLanguage => 'Language';

  @override
  String get moreHubAskCopilotTooltip => 'Ask AFAB Copilot';

  @override
  String get planLimitTitle => 'Plan Limit Reached';

  @override
  String planLimitMessage(String feature, int used, int limit, String plan) {
    return 'You\'ve reached your monthly $feature limit ($used/$limit). Upgrade to $plan to continue.';
  }

  @override
  String get planReadOnlyTitle => 'Workspace is Read-Only';

  @override
  String planReadOnlyMessage(String name) {
    return '$name is currently read-only under your active subscription allocation.';
  }

  @override
  String get maintenanceTitle => 'We\'re Under Maintenance';

  @override
  String get maintenanceDesc =>
      'AFAB services are temporarily unavailable while we complete scheduled updates. Your financial records remain safe.';

  @override
  String get maintenanceCheckStatus => 'Check Server Health';

  @override
  String get maintenanceStatusOnline => 'Backend Online';

  @override
  String get maintenanceStatusOffline => 'Backend Unreachable';

  @override
  String get notFoundTitle => 'Page Not Found';

  @override
  String get notFoundDesc =>
      'The screen you requested doesn\'t exist or was moved.';

  @override
  String get notFoundGoHome => 'Go to Dashboard';

  @override
  String get errorGenericTitle => 'Something Went Wrong';

  @override
  String get errorGenericDesc =>
      'An unexpected error occurred while rendering this view.';

  @override
  String get navCategories => 'Categories';

  @override
  String get periodAllTime => 'ALL';

  @override
  String get commonAll => 'All';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonView => 'View';

  @override
  String get commonExportCsv => 'Export CSV';

  @override
  String get commonDiscardTitle => 'Discard unsaved changes?';

  @override
  String get commonDiscardDesc =>
      'You have unsaved changes. Are you sure you want to leave without saving?';

  @override
  String get commonDiscardConfirm => 'Discard';

  @override
  String get commonKeepEditing => 'Keep Editing';

  @override
  String get commonReadOnlyNotice =>
      'This workspace is in read-only vault mode. Editing and deletions are disabled.';

  @override
  String get commonCopiedToClipboard => 'Copied to clipboard';

  @override
  String get txTitle => 'Transactions';

  @override
  String get txSubtitle =>
      'Search, filter, split, and reconcile your business cash ledger.';

  @override
  String get txAddButton => 'Add Transaction';

  @override
  String get txSplitButton => 'Split';

  @override
  String get txManageCategoriesButton => 'Categories';

  @override
  String get txAllTimeLedgerCaption => 'All-time ledger totals';

  @override
  String txFilteredResultsCount(int count) {
    return '$count matching';
  }

  @override
  String get txKpiInflow => 'Total Inflow';

  @override
  String get txKpiOutflow => 'Total Outflow';

  @override
  String get txKpiNetBalance => 'Net Balance';

  @override
  String get txKpiCount => 'Total Records';

  @override
  String get txQuickAddTitle => 'Magic Quick-Add';

  @override
  String get txQuickAddHint => 'e.g. Paid \$120 to Figma yesterday via card';

  @override
  String get txQuickAddSubmit => 'Quick Log';

  @override
  String get txQuickAddParsedAs => 'Parsed preview';

  @override
  String get txQuickAddNoAmount =>
      'Include an amount (e.g. \$45.50 or 120 TND) to quick-add.';

  @override
  String get txQuickAddSuccess => 'Transaction logged via Quick-Add.';

  @override
  String get txSearchHint => 'Search description...';

  @override
  String get txFiltersTitle => 'Filter Transactions';

  @override
  String get txFilterReset => 'Reset Filters';

  @override
  String get txFilterApply => 'Apply Filters';

  @override
  String get txFilterType => 'Type';

  @override
  String get txFilterCategory => 'Category';

  @override
  String get txFilterStatus => 'Status';

  @override
  String get txFilterPaymentMethod => 'Payment Method';

  @override
  String get txFilterTaxDeductibleOnly => 'Tax Write-offs Only';

  @override
  String get txFilterDateRange => 'Date Range';

  @override
  String get txFilterStartDate => 'From Date';

  @override
  String get txFilterEndDate => 'To Date';

  @override
  String get txTypeIncome => 'Income';

  @override
  String get txTypeExpense => 'Expense';

  @override
  String get txStatusCompleted => 'Completed';

  @override
  String get txStatusPending => 'Pending';

  @override
  String get txStatusCancelled => 'Cancelled';

  @override
  String get txMethodBankTransfer => 'Bank Transfer';

  @override
  String get txMethodCard => 'Card';

  @override
  String get txMethodCreditCard => 'Credit Card';

  @override
  String get txMethodCash => 'Cash';

  @override
  String get txMethodOther => 'Other';

  @override
  String get txSortDate => 'Date';

  @override
  String get txSortAmount => 'Amount';

  @override
  String txPageSummary(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get txPageOnlySortHint =>
      'Sorting applies to the currently loaded page.';

  @override
  String txShowingRange(int start, int end, int total) {
    return 'Showing $start–$end of $total results';
  }

  @override
  String get txEmptyTitle => 'No transactions found';

  @override
  String get txEmptyDesc =>
      'Try adjusting your search filters or record a new transaction.';

  @override
  String get txEmptyDetailPrompt =>
      'Select a transaction to inspect FX rates, splits, and private receipts.';

  @override
  String get txBadgeTax => 'Tax';

  @override
  String get txBadgeSplit => 'Split';

  @override
  String get txBadgeDuplicate => 'Duplicate?';

  @override
  String txBadgePriceHike(String pct) {
    return '+$pct% spike';
  }

  @override
  String get txActionDuplicate => 'Duplicate';

  @override
  String get txDeleteConfirmTitle => 'Delete transaction?';

  @override
  String txDeleteConfirmDesc(String description, String amount) {
    return 'This will remove \"$description\" ($amount) and any split child allocations.';
  }

  @override
  String get txDeletedToast => 'Transaction deleted.';

  @override
  String get txCsvExportChoiceTitle => 'Export Transactions CSV';

  @override
  String txCsvExportCurrentPage(int count) {
    return 'Export current page ($count rows)';
  }

  @override
  String get txCsvExportUpTo100 => 'Export up to 100 matching rows';

  @override
  String get txDetailsTitle => 'Transaction Details';

  @override
  String get txDetailsUnavailable =>
      'Transaction unavailable in this workspace';

  @override
  String get txDetailsUnavailableDesc =>
      'It may have been deleted or belongs to another business.';

  @override
  String get txDetailsBackToLedger => 'Back to Ledger';

  @override
  String txDetailsOriginalFx(
    String origAmount,
    String rate,
    String origCurr,
    String baseCurr,
  ) {
    return 'Original: $origAmount @ $rate $origCurr/$baseCurr';
  }

  @override
  String get txDetailsDuplicateAlertTitle => 'Potential Duplicate Charge';

  @override
  String get txDetailsDuplicateAlertDesc =>
      'Another active transaction with the same amount and description was found within 48 hours.';

  @override
  String txDetailsPriceHikeTitle(String pct) {
    return 'Price Increase Detected (+$pct%)';
  }

  @override
  String get txDetailsPriceHikeDesc =>
      'This expense is noticeably higher than the previous charge with the same description.';

  @override
  String get txDetailsFxSnapshot => 'FX Snapshot';

  @override
  String txDetailsLegacyFx(String currency) {
    return 'Legacy ($currency)';
  }

  @override
  String get txDetailsTaxRate => 'VAT / Tax Rate';

  @override
  String get txDetailsSplitSection => 'Split Allocation';

  @override
  String get txDetailsChildSplitBanner =>
      'Part of a multi-category split transaction';

  @override
  String get txDetailsViewParent => 'View Parent';

  @override
  String get txDetailsNotes => 'Notes';

  @override
  String get txDetailsAuditId => 'Reference ID';

  @override
  String get txDetailsUncategorized => 'Uncategorized';

  @override
  String get txFormAddTitle => 'Add Transaction';

  @override
  String get txFormDuplicateTitle => 'Duplicate Transaction';

  @override
  String get txFormEditTitle => 'Edit Transaction';

  @override
  String get txFormDescriptionLabel => 'Description';

  @override
  String get txFormDescriptionHint => 'Vendor, client, or memo';

  @override
  String get txFormAmountLabel => 'Amount';

  @override
  String get txFormCurrencyLabel => 'Currency';

  @override
  String get txFormCustomRateToggle => 'Custom FX Rate (Optional)';

  @override
  String txFormCustomRateLabel(String base) {
    return 'Exchange Rate to $base';
  }

  @override
  String get txFormFxOfflineHint =>
      'Live FX quote unavailable offline — enter custom rate or submit online.';

  @override
  String get txFormFxLockedNotice =>
      'Historical currency and exchange rate are locked on existing transactions.';

  @override
  String get txFormSplitEditNotice =>
      'Note: Editing a split parent updates its metadata/total without modifying existing split lines.';

  @override
  String get txFormDateLabel => 'Transaction Date';

  @override
  String get txFormNotesLabel => 'Notes (Optional)';

  @override
  String get txFormTaxSwitch => 'Tax Deductible Business Expense';

  @override
  String get txFormTaxRateLabel => 'VAT / Tax %';

  @override
  String get txFormTaxRateInvalid => 'Enter a tax rate between 0 and 100.';

  @override
  String get txFormAmountInvalid => 'Enter a positive amount (minimum 0.0001).';

  @override
  String get txFormSubmitCreate => 'Record Transaction';

  @override
  String get txFormSubmitEdit => 'Save Changes';

  @override
  String get txFormSavedToast => 'Transaction saved.';

  @override
  String get txSplitTitle => 'Split Transaction';

  @override
  String get txSplitSubtitle =>
      'Allocate a single payment across multiple categories';

  @override
  String get txSplitVendorLabel => 'Master Description / Vendor';

  @override
  String get txSplitTotalAmount => 'Total Amount';

  @override
  String txSplitLinesHeader(int count) {
    return 'Split Lines ($count)';
  }

  @override
  String get txSplitAddLine => 'Add Line';

  @override
  String get txSplitLineMemoHint => 'Line memo (optional)';

  @override
  String get txSplitFillRemaining => 'Fill';

  @override
  String get txSplitAllocated => 'Allocated';

  @override
  String get txSplitRemaining => 'Remaining';

  @override
  String txSplitBalanced(String zero) {
    return 'Balanced ($zero)';
  }

  @override
  String get txSplitMinLinesError =>
      'A split transaction requires at least 2 lines.';

  @override
  String get txSplitUnbalancedError =>
      'Split lines must equal the parent total exactly.';

  @override
  String get txSplitConfirmBtn => 'Confirm Split Transaction';

  @override
  String get txCatTitle => 'Manage Categories';

  @override
  String get txCatExpenseTab => 'Expense Categories';

  @override
  String get txCatIncomeTab => 'Income Categories';

  @override
  String get txCatNewBtn => 'New Category';

  @override
  String get txCatEditTitle => 'Edit Category';

  @override
  String get txCatNameLabel => 'Category Name';

  @override
  String get txCatNameHint => 'e.g. Cloud Hosting';

  @override
  String get txCatColorLabel => 'Color';

  @override
  String get txCatIconLabel => 'Icon';

  @override
  String get txCatSystemBadge => 'System Default';

  @override
  String get txCatCustomBadge => 'Custom';

  @override
  String txCatDeleteConfirm(String name) {
    return 'Delete category \"$name\"? This cannot be undone.';
  }

  @override
  String get txCatCreatedToast => 'Category created.';

  @override
  String get txCatUpdatedToast => 'Category updated.';

  @override
  String get txCatDeletedToast => 'Category deleted.';

  @override
  String get txCatDuplicateError => 'A category with this name already exists.';

  @override
  String txCatInUseWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cannot delete: used by $count transactions.',
      one: 'Cannot delete: used by 1 transaction.',
    );
    return '$_temp0';
  }

  @override
  String get txCatInUseGeneric =>
      'Cannot delete category while transactions reference it.';

  @override
  String receiptsSectionTitle(int count) {
    return 'Receipts ($count)';
  }

  @override
  String get receiptsAttachBtn => 'Attach Receipt';

  @override
  String get receiptsEmptyDesc =>
      'No receipts attached. Upload PDF, PNG, JPEG, or WEBP (max 10 MB).';

  @override
  String get receiptsSourceTitle => 'Attach Private Receipt';

  @override
  String get receiptsSourceSubtitle =>
      'Supported formats: PDF, JPEG, PNG, WEBP up to 10 MB';

  @override
  String get receiptsTakePhoto => 'Take Photo';

  @override
  String get receiptsChooseGallery => 'Choose from Photo Library';

  @override
  String get receiptsBrowseFile => 'Browse PDF or Document';

  @override
  String get receiptsUploading => 'Uploading receipt...';

  @override
  String get receiptsUploadedToast => 'Receipt uploaded securely.';

  @override
  String get receiptsDeletedToast => 'Receipt deleted.';

  @override
  String get receiptsTooLarge =>
      'Receipt file exceeds the 10 MB maximum limit.';

  @override
  String get receiptsInvalidType =>
      'Unsupported file. Only PDF, JPEG, PNG, and WEBP receipts are accepted.';

  @override
  String get receiptsEmptyFile => 'Selected receipt file is empty.';

  @override
  String get receiptsViewerLoading => 'Decrypting private receipt...';

  @override
  String get receiptsShareAction => 'Share File';

  @override
  String get receiptsCopyLinkAction => 'Copy Presigned URL';

  @override
  String receiptsPresignedNotice(int seconds) {
    return 'Temporary link copied (expires in ${seconds}s).';
  }

  @override
  String get receiptsPdfReady => 'Private PDF Receipt Ready';

  @override
  String get receiptsPdfHint =>
      'Open with your OS share sheet or external viewer.';

  @override
  String get receiptsDeleteConfirmTitle => 'Delete receipt?';

  @override
  String receiptsDeleteConfirmDesc(String filename) {
    return 'This permanently removes \"$filename\" from encrypted private storage.';
  }

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get expensesSubtitle =>
      'Visual analysis of business spend and operating costs.';

  @override
  String get expensesCreateBtn => 'New Expense';

  @override
  String get expensesKpiTotal => 'Total Expenses';

  @override
  String get expensesKpiAvgDay => 'Avg per Day';

  @override
  String get expensesKpiHighest => 'Highest Expense';

  @override
  String get expensesKpiCategories => 'Categories';

  @override
  String get expensesKpiRecurring => 'Recurring';

  @override
  String get expensesOverviewTitle => 'Spending Overview';

  @override
  String get expensesNoChartData => 'No completed expenses in this period.';

  @override
  String get expensesDonutTitle => 'By Category';

  @override
  String get expensesTotalSpend => 'TOTAL SPEND';

  @override
  String get expensesTopCategories => 'Top Spending Categories';

  @override
  String get expensesRecurringCardTitle => 'Recurring Subscriptions';

  @override
  String get expensesRecurringEmpty =>
      'Recurring expense schedules are managed on the Recurring page.';

  @override
  String get expensesManageRecurring => 'Manage Recurring Rules';

  @override
  String get expensesListHeader => 'All Expense Entries';

  @override
  String get revenueTitle => 'Revenue';

  @override
  String get revenueSubtitle =>
      'Track cash inflow velocity and top income streams.';

  @override
  String get revenueCreateBtn => 'New Revenue';

  @override
  String get revenueKpiTotal => 'Total Revenue';

  @override
  String get revenueKpiAvgDay => 'Avg per Day';

  @override
  String get revenueKpiHighestDay => 'Highest Revenue Day';

  @override
  String get revenueKpiCompletedCount => 'Completed Income';

  @override
  String get revenueKpiCompletedSub => 'Completed income entries';

  @override
  String get revenueOverviewTitle => 'Revenue Overview';

  @override
  String get revenueNoChartData => 'No completed income in this period.';

  @override
  String get revenueBySourceTitle => 'Revenue by Source';

  @override
  String get revenueGrossNetTitle => 'Gross vs Net Revenue';

  @override
  String get revenueGrossLabel => 'Gross Revenue';

  @override
  String get revenueDiscountsLabel => 'Discounts';

  @override
  String get revenueRefundsLabel => 'Refunds';

  @override
  String get revenueNetLabel => 'Net Revenue';

  @override
  String get revenueCashBasisNote =>
      'Discounts & refunds are not tracked separately on cash-basis entries.';

  @override
  String get revenueTopProductsTitle => 'Top Products & Streams';

  @override
  String get revenueTopProductsEmpty =>
      'Product-level attribution uses invoice line items.';

  @override
  String get revenueViewInvoices => 'View Invoices';

  @override
  String get revenueListHeader => 'All Income Entries';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSubtitle =>
      'Manage client relationships, invoices, and billed revenue.';

  @override
  String get customersAddBtn => 'Add Customer';

  @override
  String get customersEditTitle => 'Edit Customer';

  @override
  String get customersAddTitle => 'New Customer';

  @override
  String get customersPeriodToday => 'Today';

  @override
  String get customersPeriodWeek => 'This Week';

  @override
  String get customersPeriodMonth => 'This Month';

  @override
  String get customersPeriodYear => 'This Year';

  @override
  String get customersKpiTotal => 'Total Customers';

  @override
  String get customersKpiTotalRevenue => 'Total Revenue';

  @override
  String get customersKpiAvgRevenue => 'Avg / Customer';

  @override
  String get customersKpiRepeatRate => 'Repeat Rate';

  @override
  String customersNewPeriod(int count) {
    return '$count new';
  }

  @override
  String get customersOverviewTitle => 'Customer Segments';

  @override
  String get customersStatusActive => 'Active';

  @override
  String get customersStatusInactive => 'Inactive';

  @override
  String get customersStatusNew => 'New';

  @override
  String get customersTopTitle => 'Top Customers';

  @override
  String get customersActivityTitle => 'Recent Activity';

  @override
  String get customersSearchHint => 'Search name, code, email, phone...';

  @override
  String get customersGroupAll => 'All Groups';

  @override
  String get customersGroupStandard => 'Standard';

  @override
  String get customersGroupVip => 'VIP';

  @override
  String get customersGroupWholesale => 'Wholesale';

  @override
  String get customersGroupEnterprise => 'Enterprise';

  @override
  String get customersGroupPartner => 'Partner';

  @override
  String get customersStatusAll => 'All Statuses';

  @override
  String get customersSortNewest => 'Newest';

  @override
  String get customersSortName => 'Name';

  @override
  String get customersSortRevenue => 'Revenue';

  @override
  String get customersSortOrders => 'Orders';

  @override
  String get customersFieldName => 'Full Name *';

  @override
  String get customersFieldCompany => 'Company Name';

  @override
  String get customersFieldEmail => 'Email';

  @override
  String get customersFieldPhone => 'Phone';

  @override
  String get customersFieldCode => 'Customer Code';

  @override
  String get customersFieldCodeHint => 'Auto-generated if blank';

  @override
  String get customersFieldGroup => 'Customer Group';

  @override
  String get customersFieldStatus => 'Status';

  @override
  String get customersFieldAddress => 'Address';

  @override
  String get customersFieldNotes => 'Notes';

  @override
  String get customersCreatedToast => 'Customer created.';

  @override
  String get customersUpdatedToast => 'Customer updated.';

  @override
  String get customersArchivedToast => 'Customer archived.';

  @override
  String get customersArchiveTitle => 'Archive customer?';

  @override
  String customersArchiveDesc(String name) {
    return 'Archive \"$name\"? Historical invoices and ledger entries remain preserved.';
  }

  @override
  String get customersArchiveAction => 'Archive';

  @override
  String get customersCallAction => 'Call';

  @override
  String get customersEmailAction => 'Email';

  @override
  String get customersDetailsTitle => 'Customer Details';

  @override
  String get customersDetailsPrompt =>
      'Select a customer to view their profile, balances, and order history.';

  @override
  String get customersKpiInvoiced => 'Invoiced';

  @override
  String get customersKpiOutstanding => 'Outstanding';

  @override
  String get customersKpiOrdersCount => 'Orders';

  @override
  String get customersContactCard => 'Contact & Address';

  @override
  String get customersOrdersHistory => 'Orders & Invoices';

  @override
  String get customersAddOrderBtn => 'Add Order';

  @override
  String get customersOrdersEmpty =>
      'No orders or invoices recorded for this customer yet.';

  @override
  String customersOrdersCount(int count) {
    return '$count orders';
  }

  @override
  String get customersOrderModalTitle => 'Add Customer Order';

  @override
  String get customersOrderDescLabel => 'Order / Invoice Description *';

  @override
  String customersOrderAmountLabel(String currency) {
    return 'Amount ($currency) *';
  }

  @override
  String get customersOrderDateLabel => 'Order Date';

  @override
  String get customersOrderInitialStatus => 'Initial Status';

  @override
  String get customersOrderPaidHelper =>
      'Issues invoice and records a linked income payment transaction.';

  @override
  String get customersOrderUnpaidHelper =>
      'Issues invoice as Unpaid awaiting customer settlement.';

  @override
  String get customersOrderDraftHelper =>
      'Saves invoice as Draft for later editing.';

  @override
  String get customersOrderCreatedToast =>
      'Order invoice created successfully.';

  @override
  String get customersEmptyTitle => 'No customers found';

  @override
  String get customersEmptyDesc =>
      'Add your first customer or adjust your search and segment filters.';

  @override
  String get customersPickerTitle => 'Select Customer';

  @override
  String get customersPickerWalkIn => 'Walk-in / No Customer';

  @override
  String get customersPickerWalkInDesc =>
      'Create invoice without linking a customer profile';

  @override
  String get invoicesTitle => 'Invoices';

  @override
  String get invoicesSubtitle =>
      'Create drafts, issue bills, track balances, and record payments.';

  @override
  String get invoicesCreateBtn => 'Create Invoice';

  @override
  String get invoicesKpiTotalInvoiced => 'Total Invoiced';

  @override
  String get invoicesKpiPaid => 'Collected';

  @override
  String get invoicesKpiPending => 'Pending Balance';

  @override
  String get invoicesKpiOverdue => 'Overdue';

  @override
  String get invoicesStatusBreakdown => 'Status Breakdown';

  @override
  String get invoicesUpcomingDue => 'Upcoming Due';

  @override
  String get invoicesUpcomingEmpty => 'No unpaid invoices coming due soon.';

  @override
  String invoicesDueDateLabel(String date) {
    return 'Due $date';
  }

  @override
  String get invoicesSearchHint => 'Search invoice # or customer...';

  @override
  String get invoicesStatusDraft => 'Draft';

  @override
  String get invoicesStatusSent => 'Sent';

  @override
  String get invoicesStatusUnpaid => 'Unpaid';

  @override
  String get invoicesStatusPartiallyPaid => 'Partially Paid';

  @override
  String get invoicesStatusPaid => 'Paid';

  @override
  String get invoicesStatusOverdue => 'Overdue';

  @override
  String get invoicesStatusCancelled => 'Cancelled';

  @override
  String get invoicesEmptyTitle => 'No invoices found';

  @override
  String get invoicesEmptyDesc =>
      'Create a draft invoice or adjust your status filter.';

  @override
  String get invoicesDetailPrompt =>
      'Select an invoice to view line items, payment history, and export PDF.';

  @override
  String get invoicesDetailTitle => 'Invoice Details';

  @override
  String get invoicesOverdueBanner =>
      'This invoice is past its due date. Follow up or record a payment.';

  @override
  String get invoicesIssueDate => 'Issue Date';

  @override
  String get invoicesDueDate => 'Due Date';

  @override
  String get invoicesCustomerSection => 'Billed To';

  @override
  String get invoicesWalkInCustomer => 'Walk-in Customer';

  @override
  String get invoicesLineItems => 'Line Items';

  @override
  String invoicesQtyPrice(String qty, String price) {
    return 'Qty $qty × $price';
  }

  @override
  String invoicesTaxRateBadge(String rate) {
    return 'Tax $rate%';
  }

  @override
  String get invoicesSubtotal => 'Subtotal';

  @override
  String get invoicesTax => 'Tax';

  @override
  String get invoicesDiscount => 'Discount';

  @override
  String get invoicesTotal => 'Total';

  @override
  String get invoicesPaidAmount => 'Paid';

  @override
  String get invoicesOutstanding => 'Outstanding Balance';

  @override
  String get invoicesPaymentsHistory => 'Payment History';

  @override
  String get invoicesPaymentsEmpty =>
      'No payments recorded against this invoice yet.';

  @override
  String get invoicesLinkedTx => 'Income Tx';

  @override
  String get invoicesEditDraftBtn => 'Edit Draft';

  @override
  String get invoicesMarkSentBtn => 'Mark as Sent';

  @override
  String get invoicesIssueUnpaidBtn => 'Issue as Unpaid';

  @override
  String get invoicesRecordPaymentBtn => 'Record Payment';

  @override
  String get invoicesCancelBtn => 'Cancel Invoice';

  @override
  String get invoicesExportPdfBtn => 'Export PDF';

  @override
  String get invoicesAiReminderBtn => 'AI Reminder';

  @override
  String get invoicesIssuedSentToast => 'Invoice marked as Sent.';

  @override
  String get invoicesIssuedUnpaidToast => 'Invoice issued as Unpaid.';

  @override
  String get invoicesCancelConfirmTitle => 'Cancel invoice?';

  @override
  String invoicesCancelConfirmDesc(String number) {
    return 'Cancel $number? Cancelled invoices cannot receive payments.';
  }

  @override
  String get invoicesCancelledToast => 'Invoice cancelled.';

  @override
  String get invoicesFormCreateTitle => 'Create Invoice (Draft)';

  @override
  String invoicesFormEditTitle(String number) {
    return 'Edit Draft $number';
  }

  @override
  String get invoicesFormOnlyDraftError => 'Only DRAFT invoices can be edited.';

  @override
  String get invoicesFormCustomerLabel => 'Customer (Optional)';

  @override
  String get invoicesFormCurrencyLabel => 'Invoice Currency';

  @override
  String get invoicesFormAddLineBtn => 'Add Line';

  @override
  String get invoicesFormItemDescLabel => 'Item Description *';

  @override
  String get invoicesFormQtyLabel => 'Qty *';

  @override
  String get invoicesFormUnitPriceLabel => 'Unit Price *';

  @override
  String get invoicesFormTaxPctLabel => 'Tax %';

  @override
  String get invoicesFormDiscountLabel => 'Discount';

  @override
  String get invoicesFormNotesHint =>
      'Payment terms, bank details, or reference notes...';

  @override
  String get invoicesFormSaveDraftBtn => 'Save Draft Invoice';

  @override
  String get invoicesFormUpdateDraftBtn => 'Update Draft';

  @override
  String get invoicesFormDiscountExceedsError =>
      'Discount cannot exceed subtotal plus tax.';

  @override
  String invoicesFormSavedToast(String number) {
    return 'Invoice $number saved.';
  }

  @override
  String get paymentSheetTitle => 'Record Payment';

  @override
  String paymentRemainingLabel(String number, String amount) {
    return '$number · Remaining: $amount';
  }

  @override
  String get paymentLedgerNotice =>
      'Recording this payment automatically creates a 1:1 COMPLETED Income transaction in your ledger and updates the invoice balance.';

  @override
  String get paymentFullBalanceChip => 'Full Balance';

  @override
  String get paymentHalfChip => '50%';

  @override
  String paymentAmountHelper(String max) {
    return 'Supports full or partial payment up to $max.';
  }

  @override
  String get paymentDateLabel => 'Payment Date *';

  @override
  String paymentFxLabel(String from, String to) {
    return 'Exchange Rate (1 $from = ? $to)';
  }

  @override
  String paymentFxHelper(String base) {
    return 'Optional manual FX rate for the linked $base income transaction. Leave blank for live spot rate.';
  }

  @override
  String get paymentReferenceLabel => 'Reference';

  @override
  String get paymentReferenceHint => 'Wire transfer # or receipt reference';

  @override
  String get paymentConfirmBtn => 'Confirm Payment';

  @override
  String get paymentRetrySameBtn => 'Retry Same Payment';

  @override
  String get paymentOverBalanceError =>
      'Amount cannot exceed outstanding balance.';

  @override
  String get paymentRateInvalidError =>
      'Exchange rate must be at least 0.000001.';

  @override
  String get paymentSuccessToast =>
      'Payment recorded and income transaction created.';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsSubtitle =>
      'Monitor expense limits with real-time ledger alerts.';

  @override
  String get budgetsNewBtn => 'New Budget';

  @override
  String get budgetsEditTitle => 'Edit Budget';

  @override
  String get budgetsFilterActiveOnly => 'Active Only';

  @override
  String get budgetsFilterIncludeArchived => 'Include Archived';

  @override
  String get budgetsKpiActive => 'Active Budgets';

  @override
  String get budgetsKpiSpent => 'Actual Spending';

  @override
  String get budgetsKpiApproaching => 'Approaching Limit';

  @override
  String get budgetsKpiOver => 'Over Budget';

  @override
  String budgetsTotalLimitHint(String amount) {
    return 'Limit: $amount';
  }

  @override
  String get budgetsAggregationTip =>
      'Totals sum all active budgets; overall and category budgets may count the same expenses.';

  @override
  String get budgetsAllBusinessExpenses => 'All Business Expenses';

  @override
  String get budgetsPeriodMonthly => 'Monthly';

  @override
  String get budgetsPeriodQuarterly => 'Quarterly';

  @override
  String get budgetsPeriodYearly => 'Yearly';

  @override
  String get budgetsPeriodCustom => 'Custom';

  @override
  String get budgetsAlertOnTrack => 'On Track';

  @override
  String get budgetsAlertApproaching => 'Approaching';

  @override
  String get budgetsAlertOver => 'Over Budget';

  @override
  String get budgetsStatusArchived => 'Archived';

  @override
  String budgetsAlertAt(int pct) {
    return 'Alert at $pct%';
  }

  @override
  String get budgetsAskCopilot => 'Ask Copilot';

  @override
  String get budgetsArchiveConfirmTitle => 'Archive budget?';

  @override
  String budgetsArchiveConfirmDesc(String name) {
    return 'Archive \"$name\"? Archived budgets stop tracking active alerts while preserving historical records.';
  }

  @override
  String get budgetsArchivedToast => 'Budget archived.';

  @override
  String get budgetsSavedToast => 'Budget saved.';

  @override
  String get budgetsEmptyTitle => 'No budgets configured';

  @override
  String get budgetsEmptyDesc =>
      'Create an overall or category expense budget to get automatic spending alerts.';

  @override
  String get budgetsCreateFirstBtn => 'Create First Budget';

  @override
  String get budgetsFieldName => 'Budget Name *';

  @override
  String get budgetsFieldNameHint => 'e.g. Monthly Marketing Budget';

  @override
  String budgetsFieldAmount(String currency) {
    return 'Spending Limit ($currency) *';
  }

  @override
  String get budgetsFieldThreshold => 'Alert Threshold (%)';

  @override
  String get budgetsFieldCategory => 'Expense Category';

  @override
  String get budgetsFieldPeriod => 'Period Type *';

  @override
  String get budgetsAutoDateHint =>
      'Leave blank to auto-calculate current period';

  @override
  String get budgetsCustomDatesRequired =>
      'Start date and end date are required for custom budgets.';

  @override
  String get budgetsEndBeforeStart =>
      'End date must be on or after start date.';

  @override
  String get budgetsThresholdInvalid => 'Enter a threshold between 1 and 100.';

  @override
  String get recurringTitle => 'Recurring Schedules';

  @override
  String get recurringSubtitle =>
      'Automate repeating income and operating expenses.';

  @override
  String get recurringNewBtn => 'New Schedule';

  @override
  String get recurringEditTitle => 'Edit Schedule';

  @override
  String get recurringFilterActive => 'Active';

  @override
  String get recurringFilterPaused => 'Paused';

  @override
  String get recurringFreqWeekly => 'Weekly';

  @override
  String get recurringFreqMonthly => 'Monthly';

  @override
  String get recurringFreqQuarterly => 'Quarterly';

  @override
  String get recurringFreqYearly => 'Yearly';

  @override
  String recurringNextRun(String date) {
    return 'Next run: $date';
  }

  @override
  String recurringLastRun(String date) {
    return 'Last run: $date';
  }

  @override
  String recurringEndDate(String date) {
    return 'Ends: $date';
  }

  @override
  String get recurringRunDueBtn => 'Run Due';

  @override
  String get recurringPauseBtn => 'Pause';

  @override
  String get recurringResumeBtn => 'Resume';

  @override
  String recurringGeneratedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generated $count due transactions.',
      one: 'Generated 1 due transaction.',
    );
    return '$_temp0';
  }

  @override
  String get recurringNoneDueToast =>
      'No occurrences are currently due for this schedule.';

  @override
  String get recurringPausedToast => 'Schedule paused.';

  @override
  String get recurringResumedToast => 'Schedule resumed.';

  @override
  String get recurringDeleteTitle => 'Delete or deactivate schedule?';

  @override
  String recurringDeleteDesc(String name) {
    return 'If \"$name\" has already generated transactions, it will be deactivated (paused) to preserve ledger history. If it has never run, it will be permanently deleted.';
  }

  @override
  String get recurringDeactivatedToast =>
      'Schedule deactivated to preserve ledger history.';

  @override
  String get recurringDeletedToast => 'Schedule permanently deleted.';

  @override
  String get recurringSavedToast => 'Recurring schedule saved.';

  @override
  String get recurringEmptyTitle => 'No recurring schedules';

  @override
  String get recurringEmptyDesc =>
      'Create an automated rule for rent, payroll, SaaS subscriptions, or retainers.';

  @override
  String get recurringCreateFirstBtn => 'Create First Schedule';

  @override
  String get recurringFieldFrequency => 'Frequency';

  @override
  String get recurringFieldEndDate => 'End Date (Optional)';

  @override
  String get calendarTitle => 'Financial Calendar';

  @override
  String get calendarSubtitle =>
      'Inspect daily inflows, outflows, and scheduled financial events.';

  @override
  String get calendarTodayBtn => 'Today';

  @override
  String get calendarKpiInflow => 'Monthly Inflow';

  @override
  String get calendarKpiOutflow => 'Monthly Outflow';

  @override
  String get calendarKpiPending => 'Pending Items';

  @override
  String get calendarKpiEntries => 'Recorded Entries';

  @override
  String get calendarAwaitingSettlement => 'Awaiting settlement';

  @override
  String get calendarOverlayTransactions => 'Transactions';

  @override
  String get calendarOverlayInvoicesDue => 'Invoices Due';

  @override
  String get calendarOverlayRecurring => 'Recurring Runs';

  @override
  String get calendarOverlayNotice =>
      'Calendar overlays combine settled ledger entries with open invoice due dates and scheduled recurring rules.';

  @override
  String get calendarSelectedDateTitle => 'Selected Date Activity';

  @override
  String calendarEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: '0 entries',
    );
    return '$_temp0';
  }

  @override
  String get calendarNoActivityDate =>
      'No transactions or events on this date.';

  @override
  String get calendarTruncatedNotice =>
      'Showing the first 1,000 entries for this month.';

  @override
  String get currenciesTitle => 'Currencies & FX Markets';

  @override
  String get currenciesSubtitle =>
      'Live mid-market rates, multi-currency impact, and risk tools.';

  @override
  String get currenciesLiveActive => 'Live Rates Active';

  @override
  String get currenciesFeedUnavailable => 'Feed Unavailable';

  @override
  String get currenciesViewPrefix => 'View:';

  @override
  String currenciesBasePrefix(String code) {
    return 'Base: $code';
  }

  @override
  String get currenciesRegionAll => 'All Pairs';

  @override
  String get currenciesRegionMajors => 'Majors';

  @override
  String get currenciesRegionMena => 'MENA / Gulf';

  @override
  String get currenciesRegionAsia => 'Asia-Pac';

  @override
  String get currenciesTabMarkets => 'Markets';

  @override
  String get currenciesTabSimulated => 'Simulated Tick';

  @override
  String get currenciesTabRisk => 'Risk Simulator';

  @override
  String get currenciesTabAlerts => 'Local Alerts';

  @override
  String get currenciesTabDirectory => 'Directory';

  @override
  String get currenciesFeaturedPairs => 'Featured Pairs';

  @override
  String get currenciesChartModeHistory => 'Historical Trajectory';

  @override
  String get currenciesChartModeSimulated => 'Simulated 1s Tick';

  @override
  String get currenciesSimulatedBadge => 'Simulated 1s Tick (Anchored to Spot)';

  @override
  String get currenciesSimulatedTooltip =>
      'Client-side micro-tick simulation anchored to the live mid-market spot rate (not an exchange orderbook).';

  @override
  String get currenciesSimulatedTrendCaption => 'Simulated Trend';

  @override
  String get currenciesChartWave => 'Wave';

  @override
  String get currenciesChartCandles => 'Candles';

  @override
  String get currenciesChartBar => 'Bar';

  @override
  String get currenciesChartLine => 'Line';

  @override
  String get currenciesPause => 'Pause';

  @override
  String get currenciesResume => 'Resume';

  @override
  String get currenciesSimulatedTrades => 'Simulated Trades';

  @override
  String get currenciesSpreadFooter => 'Simulated Spread: 0.04%';

  @override
  String get currenciesConverterTitle => 'Live Currency Converter';

  @override
  String get currenciesYouSend => 'You Send';

  @override
  String get currenciesYouReceive => 'You Receive';

  @override
  String get currenciesSwap => 'Swap';

  @override
  String get currenciesMidMarketRate => 'Mid-market rate';

  @override
  String get currenciesPortfolioImpactTitle => 'Business Portfolio Impact';

  @override
  String get currenciesPortfolioReadOnlyHint =>
      'Portfolio balance valuation is unavailable while workspace is read-only.';

  @override
  String get currenciesRiskAmountLabel => 'Foreign Invoice Amount';

  @override
  String get currenciesRiskCurrencyLabel => 'Billing Currency';

  @override
  String get currenciesRiskTermsLabel => 'Payment Terms';

  @override
  String currenciesRiskNetDays(int days) {
    return 'Net $days Days';
  }

  @override
  String get currenciesRiskSpotCardTitle => 'Today\'s Spot Valuation';

  @override
  String get currenciesRiskScenariosTitle => 'FX Sensitivity Scenarios';

  @override
  String get currenciesRiskSpotLabel => 'Spot';

  @override
  String get currenciesAlertsLocalBanner =>
      'Device-Local Alerts (Evaluated on Refresh)';

  @override
  String get currenciesAlertsTriggeredTitle => 'Target Rate Triggered';

  @override
  String get currenciesAlertsNewBtn => 'New Alert';

  @override
  String get currenciesAlertsPairLabel => 'Currency Pair';

  @override
  String get currenciesAlertsConditionLabel => 'Condition';

  @override
  String get currenciesAlertsAbove => 'Rises above (≥)';

  @override
  String get currenciesAlertsBelow => 'Drops below (≤)';

  @override
  String get currenciesAlertsTargetRate => 'Target Rate';

  @override
  String get currenciesAlertsSaveBtn => 'Save Alert';

  @override
  String get currenciesAlertsInvalidRate => 'Enter a positive target rate.';

  @override
  String get currenciesAlertsEmptyTitle => 'No target rate alerts created yet';

  @override
  String get currenciesAlertsEmptyDesc =>
      'Create a local target-rate alert to get notified when rates refresh.';

  @override
  String currenciesAlertsAwayPct(String pct) {
    return '$pct% away';
  }

  @override
  String get currenciesDirectorySearchHint => 'Search currency or code...';

  @override
  String currenciesDirectoryEmpty(String query) {
    return 'No currencies match \"$query\"';
  }

  @override
  String get currenciesDirectoryConvertBtn => 'Convert';

  @override
  String get migrationTitle => 'Change Business Base Currency';

  @override
  String get migrationSubtitle =>
      'Applies to future transactions with live FX preview';

  @override
  String get migrationTargetLabel => 'Target Base Currency';

  @override
  String get migrationFetchingPreview =>
      'Fetching real-time market exchange rate...';

  @override
  String get migrationLiveMarketRate => 'Live Market Rate';

  @override
  String get migrationCurrentBalance => 'Current Net Balance';

  @override
  String get migrationProjectedBalance => 'Projected Equivalent';

  @override
  String get migrationPreservedLabel => 'Historical Transactions Preserved';

  @override
  String migrationPreservedCount(int count) {
    return '$count transaction(s)';
  }

  @override
  String get migrationImmutabilityTitle =>
      'Historical Financial Immutability Enforced';

  @override
  String migrationImmutabilityBody(String newCurrency, int count) {
    return 'Updating your business base currency to $newCurrency applies to future transactions only. All $count existing historical transaction(s) preserve their original currency and locked FX snapshots.';
  }

  @override
  String get migrationConfirmBtn => 'Confirm Currency Change';

  @override
  String get migrationUpdating => 'Updating...';

  @override
  String get migrationPermissionNotice =>
      'Only workspace Owners or Admins on an editable workspace can change base currency.';

  @override
  String migrationSuccessToast(String newCurrency) {
    return 'Base currency updated to $newCurrency. Historical records preserved.';
  }

  @override
  String get reportsTitle => 'Financial Reports';

  @override
  String get reportsSubtitle =>
      'Analyze P&L statements, cash flow velocity, and period comparisons.';

  @override
  String reportsMonthlyQuota(int used, int limit) {
    return 'Monthly Exports: $used / $limit';
  }

  @override
  String get reportsMonthlyUnlimited => 'Monthly Exports: Unlimited';

  @override
  String get reportsExplainBtn => 'Explain Report';

  @override
  String get reportsExportCsvBtn => 'Export P&L CSV';

  @override
  String get reportsExportPdfBtn => 'Export P&L PDF';

  @override
  String get reportsArabicPdfWarning =>
      'Server PDF exports use Latin fonts cleanly; use Export P&L CSV (UTF-8 BOM) for full Arabic text support.';

  @override
  String get reportsTabPnl => 'Profit & Loss';

  @override
  String get reportsTabCashFlow => 'Cash Flow';

  @override
  String get reportsTabComparison => 'Comparison';

  @override
  String get reportsPeriodThisMonth => 'This Month';

  @override
  String get reportsPeriodLastMonth => 'Last Month';

  @override
  String get reportsPeriodThisQuarter => 'This Quarter';

  @override
  String get reportsPeriodThisYear => 'This Year';

  @override
  String get reportsPeriodLastYear => 'Last Year';

  @override
  String get reportsPeriodCustom => 'Custom Range';

  @override
  String get reportsPrimaryPeriod => 'Primary Period';

  @override
  String get reportsCompareAgainst => 'Compare Against';

  @override
  String get reportsIdenticalPeriodsHint => 'Comparing identical periods.';

  @override
  String get reportsGatedTitle => 'Advanced Report Requires Upgrade';

  @override
  String get reportsGatedBtn => 'Upgrade Plan Now';

  @override
  String get reportsPnlRevenue => 'Total Revenue';

  @override
  String get reportsPnlExpenses => 'Total Expenses';

  @override
  String get reportsPnlNetIncome => 'Net Operating Income';

  @override
  String get reportsPnlMargin => 'Net Profit Margin';

  @override
  String get reportsPnlCashReceived => 'Cash received';

  @override
  String get reportsPnlCashSpent => 'Cash spent';

  @override
  String get reportsPnlPositiveMargin => 'Positive margin';

  @override
  String get reportsPnlDeficit => 'Operating deficit';

  @override
  String get reportsPnlRevByCategory => 'Revenue by Category';

  @override
  String get reportsPnlExpByCategory => 'Expenses by Category';

  @override
  String get reportsPnlNoIncome => 'No income recorded for this period.';

  @override
  String get reportsPnlNoExpenses => 'No expenses recorded for this period.';

  @override
  String get reportsCfInflow => 'Total Cash Inflow';

  @override
  String get reportsCfOutflow => 'Total Cash Outflow';

  @override
  String get reportsCfNetChange => 'Net Cash Change';

  @override
  String get reportsCfTrendTitle =>
      '6-Month Cash Flow Trend (Trailing 6 Months)';

  @override
  String get reportsCfTrendEmpty =>
      'No cash flow activity in the last 6 months.';

  @override
  String get reportsCompRevGrowth => 'Revenue Growth';

  @override
  String get reportsCompExpChange => 'Expense Change';

  @override
  String get reportsCompNetChange => 'Net Income Change';

  @override
  String get reportsSelectDateRange => 'Select Date Range';

  @override
  String get aiTitle => 'AFAB Copilot';

  @override
  String get aiLoading => 'Loading AFAB Copilot...';

  @override
  String get aiSubtitle =>
      'Private local intelligence grounded in your business ledger.';

  @override
  String get aiBadge => 'Hybrid RAG';

  @override
  String get aiHeroBadge => '100% Private Local Intelligence';

  @override
  String get aiHeroTitleStart => 'Financial clarity for ';

  @override
  String get aiHeroTitleHighlight => 'every decision.';

  @override
  String get aiCapPrivate => 'On-device Ollama privacy';

  @override
  String get aiCapMath => 'Verified BigDecimal tools';

  @override
  String get aiCapMultilingual => 'EN · AR · FR · Tunisian Derja';

  @override
  String get aiAttachLabel => 'Attach';

  @override
  String get aiListeningLabel => 'Listening';

  @override
  String get aiNewChat => 'New Chat';

  @override
  String get aiHistoryTitle => 'Conversations';

  @override
  String get aiSearchConversations => 'Search conversations...';

  @override
  String get aiGroupToday => 'Today';

  @override
  String get aiGroupYesterday => 'Yesterday';

  @override
  String get aiGroupWeek => 'Previous 7 days';

  @override
  String get aiGroupEarlier => 'Earlier';

  @override
  String get aiToggleSidebar => 'Toggle history sidebar';

  @override
  String get aiNoConversations =>
      'No saved conversations yet for this business.';

  @override
  String get aiDeleteConversation => 'Delete conversation';

  @override
  String get aiDeleteConvConfirmTitle => 'Delete conversation?';

  @override
  String aiDeleteConvConfirmDesc(String title) {
    return 'Remove \"$title\" from conversation history? This cannot be undone.';
  }

  @override
  String get aiMemoryButton => 'Business Memory';

  @override
  String get aiSyncIndexButton => 'Sync Index';

  @override
  String get aiSyncing => 'Syncing...';

  @override
  String aiSyncSuccess(int indexed, int embeddings) {
    return 'RAG index synced ($indexed updated, $embeddings embedded).';
  }

  @override
  String get aiSyncError => 'Failed to sync RAG index.';

  @override
  String get aiModelReady => 'Model Ready';

  @override
  String get aiModelOffline => 'Local Ollama Offline';

  @override
  String get aiModelMissing => 'Pull Model Required';

  @override
  String get aiOfflineTitle => 'Local AI Runtime Offline';

  @override
  String get aiOfflineDescription =>
      'AFAB Copilot runs 100% privately via your local Ollama server. Start Ollama and ensure both models are installed:';

  @override
  String get aiTokensLabel => 'AI Tokens';

  @override
  String get aiQueriesLabel => 'Queries';

  @override
  String get aiRemaining => 'remaining';

  @override
  String get aiUnlimited => 'Unlimited';

  @override
  String get aiUpgradeCta => 'Upgrade Plan';

  @override
  String get aiQuotaExhaustedTitle => 'Monthly AI Allowance Reached';

  @override
  String get aiQuotaExhaustedDesc =>
      'You have reached your current plan\'s monthly AI token or query allowance.';

  @override
  String aiQuotaRatio(String used, String limit) {
    return '$used / $limit';
  }

  @override
  String get aiWelcomeTitle => 'Financial clarity for every decision';

  @override
  String get aiWelcomeSubtitle =>
      'Private local AI CFO grounded in your real ledger, invoices, receipts & files.';

  @override
  String get aiPlaceholder =>
      'Ask your AI CFO, drop a receipt, or write in EN / FR / AR / Derja...';

  @override
  String get aiComposerFooter =>
      '100% local Gemma 4 · Attach images, PDF, Excel or CSV';

  @override
  String get aiComposerLanguages => 'EN · AR · FR · Derja';

  @override
  String get aiScrollToBottom => 'Jump to latest message';

  @override
  String get aiFollowUpsLabel => 'Suggested follow-ups';

  @override
  String get aiYou => 'You';

  @override
  String get aiCopilotName => 'AFAB Copilot';

  @override
  String get aiCopy => 'Copy';

  @override
  String get aiCopied => 'Copied';

  @override
  String get aiRegenerate => 'Regenerate';

  @override
  String aiSourcesCount(int count) {
    return '$count verified';
  }

  @override
  String get aiSend => 'Send';

  @override
  String get aiStop => 'Stop';

  @override
  String get aiThinking => 'Analyzing verified financial tools...';

  @override
  String get aiStreamingLabel => 'Live response';

  @override
  String get aiToolRunning => 'Running tool';

  @override
  String get aiToolDone => 'Verified';

  @override
  String aiElapsedSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String get aiPhaseMemory => 'Recalling Business Memory & semantic context...';

  @override
  String get aiPhaseLedger =>
      'Inspecting ledger & selecting verified finance tools...';

  @override
  String get aiPhaseSynthesis => 'Synthesizing executive financial insight...';

  @override
  String get aiPhaseWarmingModel =>
      'Warming up local Gemma 4 model on GPU (first turn takes ~10–15s)...';

  @override
  String get aiLiveTitle => 'Live AI Model Availability';

  @override
  String get aiLiveRealtimeBadge => 'Live';

  @override
  String get aiLiveBackendLabel => 'AFAB Backend API';

  @override
  String get aiLiveOllamaLabel => 'Local Ollama Runtime';

  @override
  String get aiLiveChatModelLabel => 'Chat Model';

  @override
  String get aiLiveEmbedModelLabel => 'Embedding Model';

  @override
  String get aiLiveConnected => 'Connected';

  @override
  String get aiLiveReconnecting => 'Reconnecting...';

  @override
  String get aiLiveOnline => 'Online';

  @override
  String get aiLiveOffline => 'Offline';

  @override
  String get aiLiveHotInGpu => 'Hot in GPU';

  @override
  String get aiLiveHotShort => 'Hot GPU';

  @override
  String get aiLiveColdShort => 'Cold';

  @override
  String get aiLiveReadyShort => 'Ready';

  @override
  String get aiLiveBusy => 'Generating...';

  @override
  String get aiLiveMissing => 'Not Pulled';

  @override
  String get aiLiveBackendOffline => 'Backend Offline';

  @override
  String get aiLiveChecking => 'Checking...';

  @override
  String get aiLiveCheckNow => 'Check Now';

  @override
  String get aiLiveLastChecked => 'Checked';

  @override
  String get aiToolBusinessSummary => 'Auditing P&L summary';

  @override
  String get aiToolComparePeriods => 'Comparing date periods';

  @override
  String get aiToolCategoryBreakdown => 'Breaking down categories';

  @override
  String get aiToolSearchTransactions => 'Searching ledger transactions';

  @override
  String get aiToolInvoicesOverview => 'Inspecting receivables & invoices';

  @override
  String get aiToolCustomersOverview => 'Analyzing customer revenue';

  @override
  String get aiToolBudgetsStatus => 'Checking budget utilization';

  @override
  String get aiToolRecurringCommitments => 'Reviewing recurring commitments';

  @override
  String get aiToolDataCoverage => 'Verifying data domain coverage';

  @override
  String get aiToolCashflowForecast =>
      'Running deterministic cashflow simulation';

  @override
  String get aiToolFinancialPulse => 'Scanning financial anomalies & pulse';

  @override
  String get aiToolProposeTransaction => 'Preparing transaction draft card';

  @override
  String get aiToolProposeInvoice => 'Preparing invoice draft card';

  @override
  String get aiToolProposeBudget => 'Preparing budget draft card';

  @override
  String get aiToolProposeReminder => 'Drafting grounded payment reminder';

  @override
  String get aiToolProposeMemory => 'Preparing Business Memory rule';

  @override
  String get aiToolFallback => 'Executing verified finance check';

  @override
  String get aiFastMode => 'Fast';

  @override
  String get aiDeepMode => 'Deep';

  @override
  String get aiDeepModeBadge => 'Deep Analysis';

  @override
  String get aiDeepThinkingLive => 'Reasoning step-by-step...';

  @override
  String get aiReasoningTrace => 'Copilot Reasoning';

  @override
  String get aiMorningBriefButton => 'Morning CFO Brief';

  @override
  String get aiMorningBriefPrompt =>
      'Run get_financial_pulse and get_business_summary to give me a crisp Morning CFO Brief covering today\'s net cashflow, any spending spikes, duplicate risks, budget burn-rate alerts, missing receipts, and overdue invoices.';

  @override
  String get aiDrawerTitle => 'AFAB Copilot';

  @override
  String get aiDrawerSubtitle => 'Quick financial analysis, drafts & files';

  @override
  String get aiDrawerEmptyTitle => 'Ask AFAB Copilot anything';

  @override
  String get aiDrawerEmptyDesc =>
      'Snap a receipt photo or attach a PDF/Excel/CSV file, dictate with your mic, or ask for forecasts, draft invoices, or payment reminders.';

  @override
  String get aiOpenWorkspace => 'Full View';

  @override
  String get aiLangEn => 'EN';

  @override
  String get aiLangFr => 'FR';

  @override
  String get aiLangArMsa => 'AR';

  @override
  String get aiLangDerjaScript => 'دارجة';

  @override
  String get aiLangDerjaArabizi => 'Derja';

  @override
  String get aiAttachTitle => 'Attach receipt image or document';

  @override
  String get aiAttachCamera => 'Take Receipt Photo';

  @override
  String get aiAttachGallery => 'Photo Library';

  @override
  String get aiAttachDocument => 'Document (PDF, XLSX, CSV, TXT, JSON)';

  @override
  String get aiAttachMaxThree => 'Maximum 3 attachments per message.';

  @override
  String get aiAttachSupportedHint =>
      'JPG, PNG, WEBP, PDF, XLSX, CSV, TXT, JSON (≤ 10 MB)';

  @override
  String get aiAttachUploadFailed => 'Failed to upload attachment.';

  @override
  String get aiVoiceStart => 'Start voice dictation';

  @override
  String get aiVoiceStop => 'Stop recording';

  @override
  String get aiVoiceSwitchLang => 'Cycle dictation language (EN / FR / TN)';

  @override
  String get aiVoicePermissionDenied =>
      'Microphone access denied. Enable microphone permissions to dictate.';

  @override
  String get aiVoiceUnavailable =>
      'Speech recognition unavailable on this device.';

  @override
  String get aiVoiceError => 'Voice recognition interrupted. Please try again.';

  @override
  String get aiDraftPendingReview => 'Review & Approve';

  @override
  String get aiDraftReviewHint =>
      'Nothing has been saved yet. Edit fields below and tap Approve & Save.';

  @override
  String get aiDraftSavedBadge => 'Saved';

  @override
  String get aiDraftDismissedBadge => 'Dismissed';

  @override
  String get aiDraftViewRecord => 'View Record';

  @override
  String get aiDraftApproveSave => 'Approve & Save';

  @override
  String get aiDraftDismiss => 'Dismiss';

  @override
  String get aiDraftSaving => 'Saving...';

  @override
  String get aiDraftApprovedToast => 'Record approved and saved!';

  @override
  String get aiDraftApproveFailed => 'Failed to save approved draft.';

  @override
  String get aiDraftDismissFailed => 'Failed to dismiss draft.';

  @override
  String get aiDraftInvalidAmount => 'Please enter a valid positive amount.';

  @override
  String get aiDraftReceiptLinked => 'Receipt attached from chat';

  @override
  String get aiDraftReceiptWillSave =>
      'Will be archived into Receipts & indexed on save.';

  @override
  String get aiDraftType => 'Type';

  @override
  String get aiDraftAmount => 'Amount';

  @override
  String get aiDraftCurrency => 'Currency';

  @override
  String get aiDraftDescription => 'Description';

  @override
  String get aiDraftDate => 'Date';

  @override
  String get aiDraftCategory => 'Category';

  @override
  String get aiDraftPaymentMethod => 'Payment Method';

  @override
  String get aiDraftNotes => 'Notes';

  @override
  String get aiDraftCustomer => 'Customer';

  @override
  String get aiDraftIssueDate => 'Issue Date';

  @override
  String get aiDraftDueDate => 'Due Date';

  @override
  String get aiDraftTotal => 'Total';

  @override
  String get aiDraftIssueImmediately => 'Issue immediately (mark UNPAID)';

  @override
  String get aiDraftBudgetName => 'Budget Name';

  @override
  String get aiDraftPeriod => 'Period';

  @override
  String get aiDraftAlertPct => 'Alert %';

  @override
  String get aiReminderCopy => 'Copy Message';

  @override
  String get aiReminderCopied => 'Copied';

  @override
  String get aiReminderOpenEmail => 'Open Email';

  @override
  String get aiReminderOpenWhatsapp => 'Open WhatsApp';

  @override
  String get aiReminderSubject => 'Subject';

  @override
  String get aiMemoryProposalHeading => 'Save to Business Memory?';

  @override
  String get aiMemoryProposalIgnore => 'Ignore';

  @override
  String get aiMemoryProposalRemember => 'Approve & Remember';

  @override
  String get aiMemoryProposalSaved => 'Saved to Business Memory';

  @override
  String get aiMemoryProposalSaveFailed => 'Could not save Business Memory.';

  @override
  String get aiEvidenceTitle => 'Verified Sources & Evidence';

  @override
  String get aiCoveragePartial =>
      'Ledger & Invoices Grounded (Bank balances & supplier AP not tracked yet)';

  @override
  String get aiCoverageRag => 'Grounded in Business Memory & Indexed Records';

  @override
  String aiTokensUsedBadge(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get aiPulseMonthNet => 'Month Net';

  @override
  String get aiPulseOverdue => 'Overdue';

  @override
  String get aiPulseAlerts => 'Alerts';

  @override
  String get aiPulseAllClear => 'All clear';

  @override
  String get aiPulseHealthy => 'Healthy';

  @override
  String get aiPromptPnlTag => 'P&L Performance';

  @override
  String get aiPromptPnlTitle => 'Monthly Profit & Loss';

  @override
  String get aiPromptPnlShortDesc =>
      'Compare revenue, expenses & margin vs last month';

  @override
  String get aiPromptPnlText =>
      'Give me a crisp executive breakdown of my revenue, expenses, and net profit this month compared to last month.';

  @override
  String get aiPromptForecastTitle => '90-Day Cashflow Forecast';

  @override
  String get aiPromptForecastShortDesc =>
      'Project runway & simulate hiring or late payments';

  @override
  String get aiPromptForecastText =>
      'Run a deterministic 90-day cashflow forecast using my recent averages, recurring commitments, and unpaid invoices, and show a projection chart.';

  @override
  String get aiPromptScanTitle => 'Scan Receipt or Import File';

  @override
  String get aiPromptScanShortDesc =>
      'Upload a receipt photo, PDF, Excel or CSV to inspect';

  @override
  String get aiPromptScanBadge => 'Upload';

  @override
  String get aiPromptInvoicesTitle => 'Overdue Invoices & Cash';

  @override
  String get aiPromptInvoicesText =>
      'Which customer invoices are currently unpaid or overdue, and what is the total outstanding balance?';

  @override
  String get aiPromptBudgetsTitle => 'Budget Health Check';

  @override
  String get aiPromptBudgetsText =>
      'Check all my active budgets right now and highlight any approaching or exceeding their limit.';

  @override
  String get aiPromptDerjaTitle => 'Derja / Multilingual Check';

  @override
  String get aiPromptDerjaShortDesc =>
      'Ask in English, French, Arabic or Tunisian Derja';

  @override
  String get aiPromptDerjaText =>
      'Kadeh sraft hal chhar w chniya akther masarif?';

  @override
  String get aiPromptQuickCaptureChip => 'Log an expense by chat';

  @override
  String get aiPromptQuickCapturePrefill => 'Log expense: ';

  @override
  String get aiMemoryTitle => 'Business Memory';

  @override
  String get aiMemorySubtitle =>
      'Teach AFAB recurring supplier patterns, seasonal context, and categorization rules scoped strictly to this business.';

  @override
  String get aiMemoryAddTitle => 'Add New Memory';

  @override
  String get aiMemoryEditTitle => 'Edit Memory';

  @override
  String get aiMemoryTitleLabel => 'Short Title';

  @override
  String get aiMemoryTitlePlaceholder => 'e.g. High sales season before Eid';

  @override
  String get aiMemoryTypeLabel => 'Memory Type';

  @override
  String get aiMemoryStatusLabel => 'Lifecycle Status';

  @override
  String get aiMemoryContentLabel => 'Business Context / Fact';

  @override
  String get aiMemoryContentPlaceholder =>
      'e.g. Supplier STEG bills electricity every two months; classify as Utilities.';

  @override
  String get aiMemorySaveButton => 'Save & Vectorize';

  @override
  String get aiMemorySaveChanges => 'Save Changes';

  @override
  String get aiMemorySaving => 'Saving...';

  @override
  String get aiMemoryEmpty =>
      'No business memories added yet. Add facts or supplier habits so Copilot remembers why behind the numbers.';

  @override
  String get aiMemoryFilteredEmpty => 'No memories in this status filter.';

  @override
  String get aiMemoryVectorReady => 'Vectorized';

  @override
  String get aiMemoryLexicalOnly => 'Keyword Indexed';

  @override
  String get aiMemoryApprove => 'Approve';

  @override
  String get aiMemoryDelete => 'Delete';

  @override
  String get aiMemoryDeleteConfirmTitle => 'Delete this memory?';

  @override
  String aiMemoryDeleteConfirmDesc(String title) {
    return 'Copilot will stop using \"$title\" for future answers.';
  }

  @override
  String get aiMemoryFilterAll => 'All';

  @override
  String get aiMemoryFilterProposed => 'Proposed';

  @override
  String get aiMemoryFilterApproved => 'Approved';

  @override
  String get aiMemoryFilterExpired => 'Expired';

  @override
  String get aiMemoryTypeBusinessProfile => 'Business Profile';

  @override
  String get aiMemoryTypeTransactionContext => 'Transaction Context';

  @override
  String get aiMemoryTypeSupplierPattern => 'Supplier Pattern';

  @override
  String get aiMemoryTypeCategorizationPreference => 'Category Rule';

  @override
  String get aiMemoryTypeDecisionHistory => 'Decision History';

  @override
  String get aiMemoryTypeOperationalConstraint => 'Constraint';

  @override
  String get aiIncompleteStreamError =>
      'Copilot stream ended unexpectedly before completing. Please try again.';

  @override
  String get aiAlreadyRespondingToast =>
      'Copilot is already responding. Tap Stop first if you want to cancel.';

  @override
  String get aiDismissError => 'Dismiss';

  @override
  String get plansPageTitle => 'Plans & Subscription';

  @override
  String get plansHeaderManage => 'Manage Subscription & Plans';

  @override
  String plansActiveBusinesses(int count, int limit) {
    return 'Active Businesses: $count / $limit';
  }

  @override
  String get plansActiveBusinessesHint =>
      'Additional businesses stay safely locked until you upgrade or swap.';

  @override
  String plansCurrentPlanLabel(String name) {
    return 'Current Plan: $name';
  }

  @override
  String get plansIntervalMonthly => 'Monthly Billing';

  @override
  String get plansIntervalYearly => 'Yearly Billing';

  @override
  String get plansStatusTrialing => 'Trialing';

  @override
  String get plansStatusActive => 'Active';

  @override
  String get plansStatusPastDue => 'Past Due';

  @override
  String get plansStatusCanceled => 'Canceled';

  @override
  String plansTrialCountdown(int days, String date) {
    return '7-Day Plus Trial: $days day(s) remaining (expires $date)';
  }

  @override
  String plansRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String plansEndsOn(String date) {
    return 'Paid access ends on $date';
  }

  @override
  String plansScheduledDowngradeBadge(String plan) {
    return 'Scheduled: $plan';
  }

  @override
  String get plansScheduledCancelBadge => 'Canceling at period end';

  @override
  String get plansUpgradeToPro => 'Upgrade to Pro';

  @override
  String get plansHideOptions => 'Hide Plan Options';

  @override
  String get plansChangePlan => 'Change / Downgrade Plan';

  @override
  String get plansKeepResume => 'Keep / Resume Subscription';

  @override
  String get plansCancelScheduledDowngrade => 'Cancel Scheduled Downgrade';

  @override
  String get plansManageBilling => 'Manage Billing & Payment Methods';

  @override
  String get plansCancelTrial => 'Cancel Free Trial';

  @override
  String get plansCancelSubscription => 'Cancel Subscription';

  @override
  String get plansAiMeterTitle => 'Monthly AFAB Copilot Allowance';

  @override
  String plansAiMeterSummary(
    String tokensUsed,
    String tokensLimit,
    String queriesUsed,
    String queriesLimit,
  ) {
    return '$tokensUsed / $tokensLimit tokens · $queriesUsed / $queriesLimit queries';
  }

  @override
  String plansPendingChangeDesc(String date) {
    return 'You keep full current entitlements until $date.';
  }

  @override
  String get plansConfigureFutureBusinesses => 'Configure Future Businesses';

  @override
  String plansGracePeriodTitle(int hours) {
    return 'Payment Failed — 3-Day Grace Period (${hours}h remaining)';
  }

  @override
  String get plansGracePeriodDesc =>
      'Update your payment method in Stripe Billing Portal before paid workspaces lock.';

  @override
  String get plansUpdatePaymentMethod => 'Update Payment Method';

  @override
  String get plansOwnedWorkspacesTitle => 'Owned Workspace Allocation';

  @override
  String get plansChangeEditableBusinesses => 'Change Editable Businesses';

  @override
  String get plansPrimaryBadge => 'Primary';

  @override
  String get plansCurrentBadge => 'Current';

  @override
  String get plansStatusUnlocked => 'Active';

  @override
  String get plansStatusLocked => 'Locked';

  @override
  String get plansBillingToggleMonthly => 'Monthly';

  @override
  String get plansBillingToggleYearly => 'Yearly';

  @override
  String get plansSave20Badge => 'Save 20%';

  @override
  String get plansTrialBannerTitle => 'Start with a 7-day free trial of Plus';

  @override
  String get plansTrialBannerDesc =>
      'Explore multi-business tracking, unlimited reports, and 150K Copilot tokens risk-free.';

  @override
  String get plansMostPopularTrial => 'Most Popular · 7-Day Trial';

  @override
  String get plansVipBadge => 'VIP';

  @override
  String get plansPerMonth => '/ month';

  @override
  String get plansBilledAnnually => 'billed annually';

  @override
  String get plansCurrentPlanBtn => 'Current Plan';

  @override
  String get plansStartTrialBtn => 'Start 7-Day Free Trial';

  @override
  String plansUpgradeToBtn(String plan) {
    return 'Upgrade to $plan';
  }

  @override
  String plansDowngradeToBtn(String plan) {
    return 'Downgrade to $plan';
  }

  @override
  String get plansCompareTitle => 'Compare Plans';

  @override
  String get plansHistorySubTitle => 'Subscription Change History';

  @override
  String get plansHistoryPayTitle => 'Payment & Invoice History';

  @override
  String get plansNoPaymentsYet => 'No invoice payments recorded yet.';

  @override
  String get plansNoSubHistory => 'No subscription changes recorded yet.';

  @override
  String get plansViewInvoice => 'Invoice';

  @override
  String get plansCheckoutCanceled =>
      'Checkout was canceled. No charges were made.';

  @override
  String get plansCheckoutVerifying => 'Verifying your Stripe subscription...';

  @override
  String plansCheckoutVerified(String plan) {
    return 'Subscription updated to $plan!';
  }

  @override
  String plansDirectUpgradeSuccess(String plan) {
    return 'Upgraded directly to $plan!';
  }

  @override
  String get plansResumedSuccess =>
      'Subscription resumed. Scheduled change canceled.';

  @override
  String plansImmediateDowngradeSuccess(String plan) {
    return 'Plan switched immediately to $plan.';
  }

  @override
  String plansScheduledDowngradeSuccess(String plan) {
    return 'Downgrade to $plan scheduled for period end.';
  }

  @override
  String get plansBillingNotConfigured =>
      'Billing service is not configured in this environment.';

  @override
  String get plansLoading => 'Loading subscription details...';

  @override
  String get plansTierFreeSub => 'Starter Ledger';

  @override
  String get plansTierFreeDesc =>
      'Essential bookkeeping for solo founders getting organized.';

  @override
  String get plansTierPlusSub => 'Growing Businesses';

  @override
  String get plansTierPlusDesc =>
      'Full financial automation, PDF/Excel reports, and 3 unlocked workspaces.';

  @override
  String get plansTierProSub => 'Multi-Entity CFO Suite';

  @override
  String get plansTierProDesc =>
      'Maximum scale with 5 active businesses, unlimited exports, and custom reporting.';

  @override
  String get plansFeaturesHeader => 'What\'s included:';

  @override
  String allocationTitleDowngrade(String plan) {
    return 'Select Editable Businesses for $plan';
  }

  @override
  String allocationTitlePending(String plan) {
    return 'Update Scheduled $plan Allocation';
  }

  @override
  String get allocationTitleManage => 'Manage Editable Business Allocation';

  @override
  String allocationSubtitle(int max) {
    return 'Choose up to $max business(es) to stay Active (Unlocked). Remaining businesses keep all records safely stored in Read-Only mode.';
  }

  @override
  String allocationSelectedCounter(int count, int max) {
    return 'Selected $count / $max';
  }

  @override
  String get allocationCurrentUnlocked => 'Current: Active (Unlocked)';

  @override
  String get allocationCurrentLocked => 'Current: Locked (Data Saved)';

  @override
  String get allocationOutcomeActive => 'Will remain Active (Unlocked):';

  @override
  String get allocationOutcomeLocked =>
      'Will be Locked (all data safely vaulted):';

  @override
  String allocationExactError(int count) {
    return 'Please select exactly $count business(es) to continue.';
  }

  @override
  String allocationSubmitDowngrade(String plan) {
    return 'Confirm Downgrade to $plan';
  }

  @override
  String get allocationSubmitSave => 'Save Business Allocation';

  @override
  String get allocationUpdatedSuccess =>
      'Business workspace allocation updated.';

  @override
  String cancelSubTrialTitle(String plan) {
    return 'Cancel Your $plan 7-Day Free Trial?';
  }

  @override
  String cancelSubPaidTitle(String plan) {
    return 'Cancel Your $plan Subscription?';
  }

  @override
  String get cancelSubSubtitle =>
      'Please review when your access ends and how your businesses will be preserved.';

  @override
  String get cancelSubEndAccessLabel => 'When paid access ends';

  @override
  String cancelSubEndAccessDesc(String plan, String date) {
    return 'Keep full $plan access until $date.';
  }

  @override
  String get cancelSubFuturePayLabel => 'Future payments & billing';

  @override
  String get cancelSubTrialNoCharge =>
      'No payment will be collected when your trial ends.';

  @override
  String get cancelSubPaidNoRenew =>
      'Will not renew and no additional charges will be collected.';

  @override
  String get cancelSubBizSafeLabel => 'What happens to your businesses';

  @override
  String get cancelSubBizSafeDesc =>
      'Zero data is deleted. 1 business remains active; additional businesses are locked with all financial data safely stored until you upgrade or swap.';

  @override
  String cancelSubSelectOne(int total) {
    return 'Select the 1 business to keep Editable on Free (1 of $total):';
  }

  @override
  String get cancelSubRemainsActive => 'Remains Active';

  @override
  String get cancelSubBecomesLocked => 'Becomes Locked';

  @override
  String get cancelSubKeepBtn => 'Keep Subscription';

  @override
  String get cancelSubConfirmBtn => 'Confirm Cancellation';

  @override
  String get cancelSubScheduledSuccess =>
      'Cancellation scheduled for end of billing period.';

  @override
  String get settingsHubSubtitle =>
      'Manage your account, workspace configuration, security, and preferences.';

  @override
  String get settingsGroupAccountWorkspace => 'Account & Workspace';

  @override
  String get settingsGroupSecurityPrefs => 'Security & Preferences';

  @override
  String get settingsGroupDataConnections => 'Data & Connections';

  @override
  String get settingsTabGeneral => 'General';

  @override
  String get settingsTabGeneralSub =>
      'Business basics, regional formats, profile';

  @override
  String get settingsTabBusinessProfile => 'Business Profile';

  @override
  String get settingsTabBusinessProfileSub =>
      'Company details, Tax ID (MF), address';

  @override
  String get settingsTabSubscription => 'Subscription & Billing';

  @override
  String get settingsTabSubscriptionSub =>
      'Plan limits, Stripe billing & workspaces';

  @override
  String get settingsTabUsersPermissions => 'Users & Permissions';

  @override
  String get settingsTabUsersPermissionsSub =>
      'Team roles & active workspace members';

  @override
  String get settingsTabSecurity => 'Security & 2FA';

  @override
  String get settingsTabSecuritySub =>
      'Password, TOTP 2FA, sessions & biometrics';

  @override
  String get settingsTabAppearance => 'Appearance & Theme';

  @override
  String get settingsTabAppearanceSub =>
      'Theme mood, accent colors, fonts & density';

  @override
  String get settingsTabSignature => 'Wet Signature Vault';

  @override
  String get settingsTabSignatureSub =>
      'Signatory stamps for invoices & exports';

  @override
  String get settingsTabLanguage => 'Language';

  @override
  String get settingsTabLanguageSub =>
      'English / العربية & RTL layout direction';

  @override
  String get settingsTabNotifications => 'Notifications';

  @override
  String get settingsTabNotificationsSub => 'Email & push alert preferences';

  @override
  String get settingsTabDataExport => 'Data & Export';

  @override
  String get settingsTabDataExportSub =>
      'Excel (.xlsx), Arabic PDF & P&L archives';

  @override
  String get settingsTabIntegrations => 'Integrations';

  @override
  String get settingsTabIntegrationsSub =>
      'Bank feeds, webhooks & external connectors';

  @override
  String get settingsBadgeSoon => 'Soon';

  @override
  String get settingsBadgeLocal => 'Device-Local';

  @override
  String get settingsBadge2faOn => '2FA On';

  @override
  String get settingsBadge2faOff => '2FA Off';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsReadOnlyBanner =>
      'This workspace is in Read-Only mode. Business fields are locked, while personal account settings remain editable.';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out of AFAB?';

  @override
  String get settingsSignOutConfirmDesc =>
      'Your session on this device will end and local access tokens will be cleared.';

  @override
  String get settingsAppVersion => 'AFAB Mobile v1.0.0';

  @override
  String get generalSettingsTitle => 'General Settings';

  @override
  String get generalSettingsUnsavedBadge => 'Unsaved changes';

  @override
  String get generalSettingsMemberNotice =>
      'Only workspace Owners and Admins can modify business settings. Personal preferences below remain editable.';

  @override
  String get generalSettingsAccountCard => 'Account Profile';

  @override
  String get generalSettingsBusinessCard => 'Business Settings';

  @override
  String get generalSettingsRegionalCard => 'Regional Formats';

  @override
  String get generalSettingsPrefsCard => 'Preferences';

  @override
  String get generalSettingsOtherCard => 'Other Settings';

  @override
  String get generalSettingsBizName => 'Business Name';

  @override
  String get generalSettingsBizEmail => 'Business Email';

  @override
  String get generalSettingsCurrency => 'Base Currency';

  @override
  String get generalSettingsLiveFx => 'Live FX Engine';

  @override
  String get generalSettingsTimezone => 'Timezone';

  @override
  String get generalSettingsFiscalStart => 'Fiscal Year Start';

  @override
  String get generalSettingsAccountingCycle => 'Active Accounting Cycle';

  @override
  String get generalSettingsDateFormat => 'Date Format';

  @override
  String get generalSettingsNumberFormat => 'Number Format';

  @override
  String get generalSettingsPrefAi => 'Enable AI Insights';

  @override
  String get generalSettingsPrefAiSub =>
      'Show CFO Copilot pulse recommendations on your dashboard';

  @override
  String get generalSettingsPrefCompact => 'Compact Mode';

  @override
  String get generalSettingsPrefCompactSub =>
      'Use denser spacing across tables, lists, and form inputs';

  @override
  String get generalSettingsPrefAutoCat => 'Auto-categorize Transactions';

  @override
  String get generalSettingsPrefAutoCatSub =>
      'Suggest categories automatically using transaction descriptions';

  @override
  String get generalSettingsPrefTips => 'Show Tips & Tutorials';

  @override
  String get generalSettingsPrefTipsSub =>
      'Display helpful onboarding hints across modules';

  @override
  String get generalSettingsExportData => 'Export My Data';

  @override
  String get generalSettingsExportDataSub =>
      'Download a complete GDPR JSON snapshot of your account & ledgers';

  @override
  String generalSettingsExportComplete(
    int bizCount,
    int txCount,
    int sessCount,
  ) {
    return 'Exported $bizCount workspace(s), $txCount transactions & $sessCount session(s).';
  }

  @override
  String get generalSettingsDeleteAccount => 'Delete Account';

  @override
  String get generalSettingsDeleteAccountSub =>
      'Anonymize personal profile and revoke all access sessions';

  @override
  String get generalSettingsSaveChanges => 'Save Changes';

  @override
  String get generalSettingsSavedToast => 'Settings saved successfully.';

  @override
  String generalSettingsPartialSaveError(String msg) {
    return 'Some changes could not be saved: $msg';
  }

  @override
  String get generalSettingsDiscardTitle => 'Discard unsaved changes?';

  @override
  String get generalSettingsDiscardDesc =>
      'You have unsaved edits in Settings. Discard them and leave?';

  @override
  String get generalSettingsDiscardBtn => 'Discard';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileUploadPhoto => 'Upload Photo';

  @override
  String get editProfileRemovePhoto => 'Remove';

  @override
  String get editProfilePresetAvatars => 'Preset Avatars';

  @override
  String get editProfileFirstName => 'First Name';

  @override
  String get editProfileLastName => 'Last Name';

  @override
  String get editProfilePhone => 'Phone Number';

  @override
  String get editProfileEmailReadOnly => 'Email (Read-only)';

  @override
  String get editProfileVerified => 'Verified';

  @override
  String get editProfileSave => 'Save Profile';

  @override
  String get editProfileSaved => 'Profile updated.';

  @override
  String get editProfileInvalidPhoto => 'Could not process selected photo.';

  @override
  String deleteAccountTitle(String name) {
    return 'Delete $name';
  }

  @override
  String deleteAccountStepOf(int step) {
    return '$step / 3';
  }

  @override
  String get deleteAccountExportBtn => 'Export My Data First (.json)';

  @override
  String deleteAccountExportDone(int txCount, int bizCount) {
    return 'Account backup ready ($txCount transactions, $bizCount workspaces).';
  }

  @override
  String get deleteAccountShareAgain => 'Share / Save Again';

  @override
  String get deleteAccountContinueBtn => 'Continue to Delete Account';

  @override
  String get deleteAccountSkipExportBtn =>
      'Skip Export — I want to delete this account';

  @override
  String get deleteAccountWarningBanner =>
      'Unexpected bad things will happen if you don\'t read this!';

  @override
  String deleteAccountConsequence1(String name, String email) {
    return 'Personal identity ($name, $email) will be permanently deactivated and anonymized into a tombstone record.';
  }

  @override
  String get deleteAccountConsequence2 =>
      'All active device sessions, 2FA keys, and team memberships will be revoked immediately, and any active subscription canceled best-effort.';

  @override
  String get deleteAccountConsequence3 =>
      'Existing business financial ledgers and audit trails are preserved safely — owned active businesses must be archived or transferred first.';

  @override
  String get deleteAccountIrreversible =>
      'This action is permanent and cannot be undone.';

  @override
  String get deleteAccountReadConfirmBtn =>
      'I have read and understand these effects';

  @override
  String get deleteAccountPreflightError =>
      'Unable to verify blocking workspaces right now.';

  @override
  String get deleteAccountBlockingTitle =>
      'Resolve Active Owned Workspaces First';

  @override
  String deleteAccountMembersBadge(int count) {
    return '$count member(s)';
  }

  @override
  String get deleteAccountReadOnlyDeadlock =>
      'This workspace is currently Read-Only after a plan downgrade and cannot be archived or transferred while locked. Reallocate an active slot or upgrade your plan first.';

  @override
  String get deleteAccountManageAllocBtn => 'Manage Allocations';

  @override
  String get deleteAccountArchiveBizBtn => 'Archive Business';

  @override
  String deleteAccountArchiveConfirmTitle(String name) {
    return 'Archive \"$name\"?';
  }

  @override
  String get deleteAccountArchiveConfirmDesc =>
      'Archiving removes this workspace from active use so your account deletion can proceed.';

  @override
  String get deleteAccountTransferBtn => 'Transfer Ownership';

  @override
  String deleteAccountTransferTitle(String name) {
    return 'Transfer Ownership of $name';
  }

  @override
  String deleteAccountTransferWarning(String name) {
    return 'You will become an Admin and permanently lose Owner privileges for $name.';
  }

  @override
  String get deleteAccountNoEligibleMembers =>
      'No other active members available to receive ownership.';

  @override
  String deleteAccountPhrasePrompt(String phrase) {
    return 'To confirm, type \"$phrase\" below:';
  }

  @override
  String get deleteAccountFinalBtn => 'Delete this account';

  @override
  String get deleteAccountSuccessToast =>
      'Your account has been deactivated and anonymized.';

  @override
  String get businessProfileTitle => 'Business Profile';

  @override
  String get businessProfileSummaryCard => 'Workspace Summary';

  @override
  String get businessProfileLogoCard => 'Brand Logo';

  @override
  String get businessProfileLogoUrl => 'Logo URL (HTTPS)';

  @override
  String get businessProfileUseMonogram => 'Use Monogram Avatar';

  @override
  String get businessProfileLogoHelp =>
      'Enter an HTTPS image URL up to 500 characters (base64 data URIs are not accepted).';

  @override
  String get businessProfileLogoInvalid =>
      'Logo URL must be a valid http(s) link up to 500 characters.';

  @override
  String get businessProfileInfoCard => 'Company Details';

  @override
  String get businessProfileIndustry => 'Industry';

  @override
  String get businessProfileWebsite => 'Website';

  @override
  String get businessProfileTaxId => 'Fiscal Matricule / Tax ID (MF)';

  @override
  String get businessProfileTaxIdHelp =>
      'Displayed on invoices and certified financial exports.';

  @override
  String get businessProfileAddress => 'Street Address';

  @override
  String get businessProfileCity => 'City';

  @override
  String get businessProfileState => 'State / Region';

  @override
  String get businessProfilePostal => 'Postal Code';

  @override
  String get businessProfileCountry => 'Country';

  @override
  String get businessProfileDesc => 'Business Description (Optional)';

  @override
  String get businessProfileMemberSince => 'Member Since';

  @override
  String get businessProfileLocation => 'Location';

  @override
  String get businessProfileSavedToast => 'Business profile updated.';

  @override
  String get securityTitle => 'Security & 2FA';

  @override
  String get securityOverviewSecure => 'Your account is protected with 2FA';

  @override
  String get securityOverviewRecommend => 'Action recommended: Enable 2FA';

  @override
  String get securityTwoFactorLabel => 'Two-Factor Auth';

  @override
  String get securityPasswordLabel => 'Password';

  @override
  String securityPasswordChanged(String date) {
    return 'Changed $date';
  }

  @override
  String get securityPasswordStrong => 'Configured';

  @override
  String securityActiveSessionsCount(int count) {
    return '$count Active Session(s)';
  }

  @override
  String get securityChangePasswordBtn => 'Change Password';

  @override
  String get securityEnable2faBtn => 'Enable 2FA';

  @override
  String get securityManage2faBtn => 'Manage 2FA';

  @override
  String get securityBiometricTitle => 'Biometric App Lock';

  @override
  String get securityBiometricSub =>
      'Require Face ID or Fingerprint to unlock AFAB';

  @override
  String get securityBiometricUnavailable =>
      'Biometric authentication is not set up on this device.';

  @override
  String get securityBiometricPrompt => 'Authenticate to unlock AFAB';

  @override
  String get securityUnlockBtn => 'Unlock with Biometrics';

  @override
  String get securityCurrentPwd => 'Current Password';

  @override
  String get securityNewPwd => 'New Password';

  @override
  String get securityConfirmPwd => 'Confirm New Password';

  @override
  String get securityChangePwdWarning =>
      'You will be signed out across all devices and asked to sign in again with your new password.';

  @override
  String get securityChangePwdSuccess =>
      'Password updated. Please sign in with your new password.';

  @override
  String get securitySetup2faTitle => 'Set Up Two-Factor Authentication';

  @override
  String get security2faStep1Desc =>
      'Scan this QR code in Google Authenticator, Authy, or 1Password, or copy the setup key:';

  @override
  String get securityCopySecret => 'Copy Setup Key';

  @override
  String get security2faStep2Desc =>
      'Enter the 6-digit verification code from your authenticator app:';

  @override
  String get security2faVerifyEnable => 'Verify & Enable 2FA';

  @override
  String get security2faBackupTitle => 'Save Your Recovery Codes';

  @override
  String get security2faBackupDesc =>
      'Store these 8 single-use backup codes in a safe place if you ever lose your device.';

  @override
  String get securityCopyAllCodes => 'Copy All Codes';

  @override
  String get securityShareTxt => 'Save / Share (.txt)';

  @override
  String get securityManage2faTitle => 'Manage Two-Factor Authentication';

  @override
  String get securityRegenerateCodes => 'Regenerate Backup Codes';

  @override
  String get securityDisable2faTitle => 'Disable Two-Factor Authentication';

  @override
  String get securityDisable2faDesc =>
      'Enter your current password to remove 2FA protection from this account.';

  @override
  String get securityDisable2faBtn => 'Disable 2FA';

  @override
  String get securitySessionsTitle => 'Active Sessions';

  @override
  String get securityLogOutAllBtn => 'Log Out All Sessions';

  @override
  String get securitySessionCaveatNote =>
      'Note: Revoking all sessions also signs out this device immediately.';

  @override
  String get securityLogOutAllTitle => 'Log out all active sessions?';

  @override
  String get securityLogOutAllDesc =>
      'All active sessions—including this device—will be signed out immediately.';

  @override
  String get securityRevokeSessionConfirm => 'Revoke access for this session?';

  @override
  String get securityNoSessions => 'No active sessions found.';

  @override
  String get securityTipsTitle => 'Security Best Practices';

  @override
  String get securityTip1Title => 'Use a strong unique password';

  @override
  String get securityTip1Desc =>
      'Combine uppercase, lowercase, numbers, and symbols (at least 8 characters).';

  @override
  String get securityTip2Title => 'Keep Two-Factor Authentication active';

  @override
  String get securityTip2Desc =>
      'Protects against credential theft even if your password is exposed.';

  @override
  String get securityTip3Title => 'Review active sessions monthly';

  @override
  String get securityTip3Desc =>
      'Revoke unrecognized browsers or old devices promptly.';

  @override
  String get securityTip4Title => 'Store recovery codes offline';

  @override
  String get securityTip4Desc =>
      'Keep backup codes separate from your authenticator phone.';

  @override
  String get appearanceTitle => 'Appearance & Theme';

  @override
  String get appearanceDeviceLocalNote =>
      'Visual theme, colors, fonts, and surfaces apply live on this device; Compact Mode also syncs to your AFAB account.';

  @override
  String get appearanceLivePreviewJump => 'Live Preview';

  @override
  String get appearanceResetBtn => 'Reset';

  @override
  String get appearanceSaveBtn => 'Save Preferences';

  @override
  String get appearanceSavedToast => 'Appearance preferences saved.';

  @override
  String get appearanceSavedLocalOffline =>
      'Saved on this device; cloud compact-mode sync will retry when online.';

  @override
  String get appearanceThemeModeTitle => 'Theme Mode';

  @override
  String get appearanceModeLight => 'Light';

  @override
  String get appearanceModeDark => 'Dark';

  @override
  String get appearanceModeSystem => 'System';

  @override
  String get appearanceDarkSurfaceTitle => 'Dark Surface Mood';

  @override
  String get appearanceSurfaceMidnight => 'Midnight Navy';

  @override
  String get appearanceSurfaceOled => 'OLED Pure Black';

  @override
  String get appearanceSurfaceSlate => 'Deep Slate';

  @override
  String get appearanceSurfaceCharcoal => 'Charcoal Eclipse';

  @override
  String get appearanceAccentTitle => 'Brand Accent Color';

  @override
  String get appearanceCustomHex => 'Custom Hex (#RRGGBB)';

  @override
  String get appearanceLowContrastWarn => 'Low contrast with white button text';

  @override
  String get appearanceTypographyTitle => 'Typography & Font Family';

  @override
  String get appearanceFontSizeTitle => 'Font Size Scale';

  @override
  String get appearanceRadiusTitle => 'Corner Rounding';

  @override
  String get appearanceDensityEffectsTitle => 'Density & Visual Effects';

  @override
  String get appearanceDensityComfortable => 'Comfortable';

  @override
  String get appearanceDensityCompact => 'Compact';

  @override
  String get appearanceEnableGlow => 'Ambient Neon Glow';

  @override
  String get appearanceSmoothTransitions => 'Smooth Theme Transitions';

  @override
  String get appearanceLivePreviewTitle => 'Real-Time Live Preview';

  @override
  String get signatureTitle => 'Wet Signature Vault';

  @override
  String signatureSavedCount(int count) {
    return '$count Saved';
  }

  @override
  String get signatureDeviceLocalNotice =>
      'Stored locally on this device for your active business. Signatures do not sync across devices or AFAB cloud servers.';

  @override
  String get signatureVaultTitle => 'Saved Signatures Vault';

  @override
  String get signatureEmptyTitle => 'No signatures saved yet';

  @override
  String get signatureEmptyDesc =>
      'Draw on the pad or upload a photo of a handwritten signature to stamp PDFs & exports.';

  @override
  String get signatureActiveBadge => 'Active & In Use';

  @override
  String get signatureSetActive => 'Set as Active';

  @override
  String signatureEditingBanner(String label) {
    return 'Editing: $label';
  }

  @override
  String get signatureTabDraw => 'Draw Pad';

  @override
  String get signatureTabUpload => 'Upload Image';

  @override
  String get signatureInkBlack => 'Ink Black';

  @override
  String get signatureInkBlue => 'Royal Blue';

  @override
  String get signatureResetPad => 'Reset Pad';

  @override
  String get signatureUseDrawing => 'Use This Drawing';

  @override
  String get signatureTakePhoto => 'Take Photo';

  @override
  String get signatureChooseFile => 'Choose Image';

  @override
  String get signatureTransparentBg =>
      'Auto-remove paper background (Transparent ink)';

  @override
  String get signatureLabelField => 'Signature Label';

  @override
  String get signatureSignatoryName => 'Full Signatory Name';

  @override
  String get signatureSignatoryTitle => 'Signatory Title / Position';

  @override
  String get signatureSetDefaultCheck =>
      'Set this signature as active immediately';

  @override
  String get signatureAutoApplySwitch =>
      'Automatically stamp active signature onto Invoices & Exports';

  @override
  String get signatureSaveVaultBtn => 'Save Signature to Vault';

  @override
  String get signatureUpdateVaultBtn => 'Update Signature';

  @override
  String get signaturePreviewTitle => 'Certified Document Preview';

  @override
  String get signatureCertifiedStamp => 'CERTIFIED';

  @override
  String signatureDeleteConfirm(String label) {
    return 'Delete signature \"$label\"?';
  }

  @override
  String get signatureTooLarge => 'Image file is too large (max 5 MB).';

  @override
  String get signatureSavedToast => 'Signature saved to local vault.';

  @override
  String get dataExportTitle => 'Data & Export';

  @override
  String dataExportTruncationBanner(int loaded, int total) {
    return 'Showing $loaded of $total total records for export pagination (max 1,000 per dataset). Narrow the period filter or export full JSON from General Settings.';
  }

  @override
  String get dataExportPeriodLabel => 'Period';

  @override
  String get dataExportCurrencyLabel => 'Display Currency';

  @override
  String get dataExportCurrencyNote =>
      'Amounts reflect original ledger currencies without FX conversion.';

  @override
  String get dataExportCountTx => 'Period Transactions';

  @override
  String get dataExportCountCustomers => 'Clients Directory';

  @override
  String get dataExportCountInvoices => 'Period Invoices';

  @override
  String get dataExportCountNetFlow => 'Net Flow (Period)';

  @override
  String get dataExportMasterBadge => 'Complete Business Archive';

  @override
  String get dataExportMasterDesc =>
      'Export KPIs, transactions, customers, and invoices together with Arabic UTF-8 support.';

  @override
  String get dataExportAllExcel => 'Export Excel (.xlsx)';

  @override
  String get dataExportAllPdf => 'Export PDF (.pdf)';

  @override
  String get dataExportPrintPreview => 'Preview / Share PDF';

  @override
  String get dataExportModularTx => 'Transactions & Cash Flow';

  @override
  String get dataExportModularCustomers => 'Customer CRM Registry';

  @override
  String get dataExportModularInvoices => 'Invoices & Billing Register';

  @override
  String get dataExportModularPnl => 'Financial Performance (P&L)';

  @override
  String get dataExportBackendCsv => 'Backend CSV';

  @override
  String get dataExportBackendPdf => 'Official PDF';

  @override
  String get dataExportComplianceFooter =>
      'Client Excel & Cairo-font PDF archives support full Arabic RTL & UTF-8 text.';

  @override
  String get dataExportSheetTitle => 'Confirm Export Scope';

  @override
  String get dataExportFiscalMatricule => 'Fiscal Matricule / Tax ID (MF)';

  @override
  String get dataExportBusinessPurpose => 'Activity / Purpose';

  @override
  String get dataExportOfficialAddress => 'Official Business Address';

  @override
  String get dataExportIncludeLogo => 'Include Business Logo Details';

  @override
  String get dataExportIncludeSig => 'Include Active Wet Signature';

  @override
  String get dataExportGenerateShare => 'Generate & Share';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSystemTitle => 'System Default';

  @override
  String get languageSystemSub =>
      'Follow your device operating system language (falls back to English)';

  @override
  String get languageEnglishSub =>
      'Left-to-Right (LTR) · Gregorian Calendar · Western Digits (0-9)';

  @override
  String get languageArabicSub =>
      'Right-to-Left (RTL) · Gregorian Calendar · Western Digits (0-9)';

  @override
  String get languagePreviewTitle => 'Live Directionality & Format Preview';

  @override
  String languagePreviewDir(String dir) {
    return 'Direction: $dir';
  }

  @override
  String get languageCopilotNote =>
      'App interface language is independent of AI Copilot\'s 5 response languages (English, French, Arabic MSA, Derja, Arabizi), which you can select inside Copilot.';

  @override
  String get languageUpdatedToast => 'Interface language updated.';

  @override
  String get comingSoonBadge => 'Coming Soon';

  @override
  String get comingSoonBackBtn => 'Back to Settings';

  @override
  String get comingSoonUsersDesc =>
      'Team member invitations, role assignment, and fine-grained permissions are in development for an upcoming release.';

  @override
  String get comingSoonMembersTitle => 'Current Workspace Members (Read-Only)';

  @override
  String get comingSoonOnlyYou =>
      'Only you are currently an active member of this workspace.';

  @override
  String get comingSoonNotificationsDesc =>
      'Granular email digest schedules and push alert rules will be configurable here soon.';

  @override
  String get comingSoonOpenNotifCenter => 'View In-App Notifications';

  @override
  String get comingSoonIntegrationsDesc =>
      'Direct bank feeds, payment gateways, and automated webhooks will be available here in a future release.';
}
