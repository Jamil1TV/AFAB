import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AFAB'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'AI Finance Assistant for Business'**
  String get appTagline;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonRetry;

  /// No description provided for @commonReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get commonReload;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get commonNoData;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get commonComingSoon;

  /// No description provided for @commonComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'This section will be implemented in an upcoming milestone.'**
  String get commonComingSoonDesc;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get commonLocked;

  /// No description provided for @commonReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-Only'**
  String get commonReadOnly;

  /// No description provided for @commonOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some actions require an active internet connection.'**
  String get commonOfflineBanner;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameAr.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageNameAr;

  /// No description provided for @languageSwitchShort.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get languageSwitchShort;

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get periodMonthly;

  /// No description provided for @periodYearly.
  ///
  /// In en, this message translates to:
  /// **'YEARLY'**
  String get periodYearly;

  /// No description provided for @periodVsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get periodVsLastWeek;

  /// No description provided for @periodVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get periodVsLastMonth;

  /// No description provided for @periodVsLastYear.
  ///
  /// In en, this message translates to:
  /// **'vs last year'**
  String get periodVsLastYear;

  /// No description provided for @authLoginTab.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLoginTab;

  /// No description provided for @authSignupTab.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignupTab;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please enter your details.'**
  String get authLoginSubtitle;

  /// No description provided for @authSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of business owners today.'**
  String get authSignupSubtitle;

  /// No description provided for @authFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get authFirstName;

  /// No description provided for @authFirstNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Jane'**
  String get authFirstNamePlaceholder;

  /// No description provided for @authLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get authLastName;

  /// No description provided for @authLastNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Doe'**
  String get authLastNamePlaceholder;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmail;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailPlaceholder;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordPlaceholder;

  /// No description provided for @authPasswordCreatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get authPasswordCreatePlaceholder;

  /// No description provided for @authBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get authBusinessName;

  /// No description provided for @authBusinessNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Acme Corp'**
  String get authBusinessNamePlaceholder;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLoginButton;

  /// No description provided for @authSignupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignupButton;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember for 30 days'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHasAccount;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String authVerifyEmailSubtitle(String email);

  /// No description provided for @authVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get authVerifyButton;

  /// No description provided for @authDidntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get authDidntReceiveCode;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get authResendCode;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authResendIn(int seconds);

  /// No description provided for @authCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent! Check your inbox.'**
  String get authCodeResent;

  /// No description provided for @authVerifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get authVerifySuccess;

  /// No description provided for @authVerifyCodeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 6-digit code.'**
  String get authVerifyCodeIncomplete;

  /// No description provided for @authNoEmailFound.
  ///
  /// In en, this message translates to:
  /// **'Session invalid. Please sign up or log in again.'**
  String get authNoEmailFound;

  /// No description provided for @authUseDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out and use another account'**
  String get authUseDifferentAccount;

  /// No description provided for @authDevOtpNotice.
  ///
  /// In en, this message translates to:
  /// **'Development verification code: {code}'**
  String authDevOtpNotice(String code);

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get authFieldRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authPasswordMinLength;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authResetEmailSent;

  /// No description provided for @authResetEmailSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}'**
  String authResetEmailSentSubtitle(String email);

  /// No description provided for @authHaveResetToken.
  ///
  /// In en, this message translates to:
  /// **'Already have a reset token?'**
  String get authHaveResetToken;

  /// No description provided for @authEnterTokenManually.
  ///
  /// In en, this message translates to:
  /// **'Enter token manually'**
  String get authEnterTokenManually;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authBackToLogin;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your new password must meet all requirements below.'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authResetPasswordValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating your reset link...'**
  String get authResetPasswordValidating;

  /// No description provided for @authResetTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset Token'**
  String get authResetTokenLabel;

  /// No description provided for @authResetTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your password reset token'**
  String get authResetTokenHint;

  /// No description provided for @authValidateTokenButton.
  ///
  /// In en, this message translates to:
  /// **'Validate Token'**
  String get authValidateTokenButton;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get authNewPassword;

  /// No description provided for @authNewPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get authNewPasswordPlaceholder;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get authConfirmPasswordPlaceholder;

  /// No description provided for @authResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetButton;

  /// No description provided for @authResetPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet all requirements.'**
  String get authResetPasswordWeak;

  /// No description provided for @authResetPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authResetPasswordMismatch;

  /// No description provided for @authPasswordResetSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset!'**
  String get authPasswordResetSuccessTitle;

  /// No description provided for @authPasswordResetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully. You can now sign in.'**
  String get authPasswordResetSuccessMessage;

  /// No description provided for @authTokenExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Link expired'**
  String get authTokenExpiredTitle;

  /// No description provided for @authTokenExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This password reset link has expired. Please request a new one.'**
  String get authTokenExpiredMessage;

  /// No description provided for @authTokenInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get authTokenInvalidTitle;

  /// No description provided for @authTokenInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has already been used.'**
  String get authTokenInvalidMessage;

  /// No description provided for @authRequestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request a new link'**
  String get authRequestNewLink;

  /// No description provided for @authPwStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get authPwStrengthLabel;

  /// No description provided for @authPwStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get authPwStrengthWeak;

  /// No description provided for @authPwStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get authPwStrengthFair;

  /// No description provided for @authPwStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get authPwStrengthGood;

  /// No description provided for @authPwStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get authPwStrengthStrong;

  /// No description provided for @authPwStrengthVeryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very Strong'**
  String get authPwStrengthVeryStrong;

  /// No description provided for @authPwReqLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPwReqLength;

  /// No description provided for @authPwReqUppercase.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get authPwReqUppercase;

  /// No description provided for @authPwReqLowercase.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get authPwReqLowercase;

  /// No description provided for @authPwReqNumber.
  ///
  /// In en, this message translates to:
  /// **'One number'**
  String get authPwReqNumber;

  /// No description provided for @authPwReqSpecial.
  ///
  /// In en, this message translates to:
  /// **'One special character'**
  String get authPwReqSpecial;

  /// No description provided for @authTwoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get authTwoFactorTitle;

  /// No description provided for @authTwoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app to complete sign-in.'**
  String get authTwoFactorSubtitle;

  /// No description provided for @authTwoFactorVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get authTwoFactorVerifyButton;

  /// No description provided for @authTwoFactorEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Authentication Code'**
  String get authTwoFactorEnterCode;

  /// No description provided for @authUseBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Use emergency backup recovery code'**
  String get authUseBackupCode;

  /// No description provided for @authUseTotpCode.
  ///
  /// In en, this message translates to:
  /// **'Use 6-digit authenticator code'**
  String get authUseTotpCode;

  /// No description provided for @authBackupCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup Recovery Code'**
  String get authBackupCodeLabel;

  /// No description provided for @authBackupCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABCD-1234'**
  String get authBackupCodePlaceholder;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Your account is not active.'**
  String get authErrorAccountDisabled;

  /// No description provided for @authErrorAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Your account has been temporarily locked due to failed attempts.'**
  String get authErrorAccountLocked;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorNetworkFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Please check your connection and try again.'**
  String get authErrorNetworkFailure;

  /// No description provided for @authErrorServerFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get authErrorServerFailure;

  /// No description provided for @authErrorInvalid2FaCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid authentication code or backup recovery code.'**
  String get authErrorInvalid2FaCode;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get authErrorSessionExpired;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3'**
  String onboardingStep(int step);

  /// No description provided for @onboardingStep1Tab.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get onboardingStep1Tab;

  /// No description provided for @onboardingStep2Tab.
  ///
  /// In en, this message translates to:
  /// **'Financial Setup'**
  String get onboardingStep2Tab;

  /// No description provided for @onboardingStep3Tab.
  ///
  /// In en, this message translates to:
  /// **'Review & Complete'**
  String get onboardingStep3Tab;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us tailor financial reports and AI insights for you.'**
  String get onboardingStep1Subtitle;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Configure your financial preferences'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your accounting currency, timezone, and fiscal calendar.'**
  String get onboardingStep2Subtitle;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set to launch!'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your business configuration below.'**
  String get onboardingStep3Subtitle;

  /// No description provided for @onboardingCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country of Operation'**
  String get onboardingCountryLabel;

  /// No description provided for @onboardingIndustryLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get onboardingIndustryLabel;

  /// No description provided for @onboardingBusinessTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entity Type'**
  String get onboardingBusinessTypeLabel;

  /// No description provided for @onboardingCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Currency'**
  String get onboardingCurrencyLabel;

  /// No description provided for @onboardingTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get onboardingTimezoneLabel;

  /// No description provided for @onboardingFiscalYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Fiscal Year Starts In'**
  String get onboardingFiscalYearLabel;

  /// No description provided for @onboardingSummaryCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get onboardingSummaryCountry;

  /// No description provided for @onboardingSummaryIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get onboardingSummaryIndustry;

  /// No description provided for @onboardingSummaryBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Entity Type'**
  String get onboardingSummaryBusinessType;

  /// No description provided for @onboardingSummaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get onboardingSummaryCurrency;

  /// No description provided for @onboardingSummaryTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get onboardingSummaryTimezone;

  /// No description provided for @onboardingSummaryFiscalYear.
  ///
  /// In en, this message translates to:
  /// **'Fiscal Year Starts'**
  String get onboardingSummaryFiscalYear;

  /// No description provided for @onboardingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get onboardingSearchHint;

  /// No description provided for @onboardingLaunchDashboard.
  ///
  /// In en, this message translates to:
  /// **'Launch Dashboard'**
  String get onboardingLaunchDashboard;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'AI Finance Assistant for Business'**
  String get splashTagline;

  /// No description provided for @splashRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring your secure workspace...'**
  String get splashRestoring;

  /// No description provided for @splashOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Issue'**
  String get splashOfflineTitle;

  /// No description provided for @splashOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach AFAB servers to verify your session.'**
  String get splashOfflineSubtitle;

  /// No description provided for @splashContinueToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get splashContinueToLogin;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @navCopilot.
  ///
  /// In en, this message translates to:
  /// **'Copilot'**
  String get navCopilot;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get navRevenue;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

  /// No description provided for @navRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get navRecurring;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies & FX'**
  String get navCurrencies;

  /// No description provided for @navAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get navAiAssistant;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans & Billing'**
  String get navPlans;

  /// No description provided for @navNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get navNewBadge;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get navLogout;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning, {name}'**
  String dashboardGoodMorning(String name);

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon, {name}'**
  String dashboardGoodAfternoon(String name);

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening, {name}'**
  String dashboardGoodEvening(String name);

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening with your business today.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get dashboardTotalRevenue;

  /// No description provided for @dashboardTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get dashboardTotalExpenses;

  /// No description provided for @dashboardNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get dashboardNetProfit;

  /// No description provided for @dashboardCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get dashboardCashFlow;

  /// No description provided for @dashboardRevenueChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue & Expenses'**
  String get dashboardRevenueChartTitle;

  /// No description provided for @dashboardRevenueChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trailing 6-month cash flow performance'**
  String get dashboardRevenueChartSubtitle;

  /// No description provided for @dashboardRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get dashboardRevenueLabel;

  /// No description provided for @dashboardExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardExpensesLabel;

  /// No description provided for @dashboardAwaitingData.
  ///
  /// In en, this message translates to:
  /// **'Awaiting activity'**
  String get dashboardAwaitingData;

  /// No description provided for @dashboardExpenseCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get dashboardExpenseCategoriesTitle;

  /// No description provided for @dashboardExpenseCategoriesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dashboardExpenseCategoriesTotal;

  /// No description provided for @dashboardExpenseCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expense breakdown recorded for this period yet.'**
  String get dashboardExpenseCategoriesEmpty;

  /// No description provided for @dashboardAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant Insights'**
  String get dashboardAiTitle;

  /// No description provided for @dashboardAiLivePulse.
  ///
  /// In en, this message translates to:
  /// **'Live Pulse'**
  String get dashboardAiLivePulse;

  /// No description provided for @dashboardAiAskBtn.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Assistant'**
  String get dashboardAiAskBtn;

  /// No description provided for @dashboardAiInvestigate.
  ///
  /// In en, this message translates to:
  /// **'Investigate in Copilot'**
  String get dashboardAiInvestigate;

  /// No description provided for @dashboardAiAwaitingActivity.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Financial Activity'**
  String get dashboardAiAwaitingActivity;

  /// No description provided for @dashboardAiAwaitingActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Record transactions or invoices to unlock live financial pulse alerts.'**
  String get dashboardAiAwaitingActivityDesc;

  /// No description provided for @dashboardRecentTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get dashboardRecentTransactionsTitle;

  /// No description provided for @dashboardRecentTransactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yet.'**
  String get dashboardRecentTransactionsEmpty;

  /// No description provided for @dashboardBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Progress'**
  String get dashboardBudgetsTitle;

  /// No description provided for @dashboardBudgetsSubtitleActive.
  ///
  /// In en, this message translates to:
  /// **'{active} active • {over} over budget • {approaching} approaching'**
  String dashboardBudgetsSubtitleActive(int active, int over, int approaching);

  /// No description provided for @dashboardBudgetsSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set monthly or category spending caps to track business costs.'**
  String get dashboardBudgetsSubtitleEmpty;

  /// No description provided for @dashboardBudgetsManageLink.
  ///
  /// In en, this message translates to:
  /// **'Manage Budgets'**
  String get dashboardBudgetsManageLink;

  /// No description provided for @dashboardBudgetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active budgets for the current period.'**
  String get dashboardBudgetsEmpty;

  /// No description provided for @dashboardBudgetsOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by'**
  String get dashboardBudgetsOverBy;

  /// No description provided for @dashboardBudgetsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get dashboardBudgetsRemaining;

  /// No description provided for @dashboardBudgetsOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get dashboardBudgetsOverLabel;

  /// No description provided for @dashboardBudgetsApproachingLabel.
  ///
  /// In en, this message translates to:
  /// **'Approaching'**
  String get dashboardBudgetsApproachingLabel;

  /// No description provided for @dashboardBudgetsOnTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get dashboardBudgetsOnTrackLabel;

  /// No description provided for @dashboardRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get dashboardRemindersTitle;

  /// No description provided for @dashboardRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No urgent budget or invoice reminders.'**
  String get dashboardRemindersEmpty;

  /// No description provided for @dashboardCustomersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Customers'**
  String get dashboardCustomersTitle;

  /// No description provided for @dashboardCustomersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No paid customer activity recorded yet.'**
  String get dashboardCustomersEmpty;

  /// No description provided for @dashboardCustomersInRevenue.
  ///
  /// In en, this message translates to:
  /// **'in revenue'**
  String get dashboardCustomersInRevenue;

  /// No description provided for @dashboardUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Supercharge your financial insights'**
  String get dashboardUpgradeTitle;

  /// No description provided for @dashboardUpgradeDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock expanded AI Copilot quotas, multi-business workspaces, and custom financial reports.'**
  String get dashboardUpgradeDesc;

  /// No description provided for @dashboardUpgradeBtn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get dashboardUpgradeBtn;

  /// No description provided for @dashboardUpgradeProCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get dashboardUpgradeProCta;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your financial dashboard.'**
  String get dashboardLoadError;

  /// No description provided for @businessSwitcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get businessSwitcherTitle;

  /// No description provided for @businessSwitcherCapacity.
  ///
  /// In en, this message translates to:
  /// **'{editable} / {limit} active'**
  String businessSwitcherCapacity(int editable, int limit);

  /// No description provided for @businessSwitcherAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add Business'**
  String get businessSwitcherAddNew;

  /// No description provided for @businessSwitcherCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Business'**
  String get businessSwitcherCreateTitle;

  /// No description provided for @businessSwitcherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessSwitcherNameLabel;

  /// No description provided for @businessSwitcherNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Northwind Studio'**
  String get businessSwitcherNamePlaceholder;

  /// No description provided for @businessSwitcherCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get businessSwitcherCurrencyLabel;

  /// No description provided for @businessSwitcherCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Workspace'**
  String get businessSwitcherCreateBtn;

  /// No description provided for @businessSwitcherCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Workspace created and activated.'**
  String get businessSwitcherCreateSuccess;

  /// No description provided for @businessSwitcherSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String businessSwitcherSwitched(String name);

  /// No description provided for @businessSwitcherLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace Locked (Read-Only)'**
  String get businessSwitcherLockedTitle;

  /// No description provided for @businessSwitcherLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your current plan allows fewer active workspaces. Data for {name} is safely preserved, but edits and switching require swapping active workspaces or upgrading your plan.'**
  String businessSwitcherLockedDesc(String name);

  /// No description provided for @businessSwitcherLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace Limit Reached'**
  String get businessSwitcherLimitTitle;

  /// No description provided for @businessSwitcherLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'Your plan allows up to {limit} active owned business workspaces. Upgrade to Plus or Pro to unlock more workspaces.'**
  String businessSwitcherLimitDesc(int limit);

  /// No description provided for @businessSwitcherManagePlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans & Allocations'**
  String get businessSwitcherManagePlans;

  /// No description provided for @businessRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get businessRoleOwner;

  /// No description provided for @businessRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get businessRoleAdmin;

  /// No description provided for @businessRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get businessRoleMember;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'New billing, workspace, and account alerts will appear here.'**
  String get notificationsEmptyDesc;

  /// No description provided for @bannerPastDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Past Due — {hours}h Grace Remaining'**
  String bannerPastDueTitle(int hours);

  /// No description provided for @bannerPastDueDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your payment method to keep Plus/Pro features and workspaces active.'**
  String get bannerPastDueDesc;

  /// No description provided for @bannerAllocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace Allocation Required'**
  String get bannerAllocationTitle;

  /// No description provided for @bannerAllocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Select which businesses remain active under your current plan limit.'**
  String get bannerAllocationDesc;

  /// No description provided for @bannerManageAction.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get bannerManageAction;

  /// No description provided for @moreHubSectionOperations.
  ///
  /// In en, this message translates to:
  /// **'Money & Operations'**
  String get moreHubSectionOperations;

  /// No description provided for @moreHubSectionIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Financial Intelligence'**
  String get moreHubSectionIntelligence;

  /// No description provided for @moreHubSectionWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace & Preferences'**
  String get moreHubSectionWorkspace;

  /// No description provided for @moreHubPreferences.
  ///
  /// In en, this message translates to:
  /// **'Quick Preferences'**
  String get moreHubPreferences;

  /// No description provided for @moreHubThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get moreHubThemeMode;

  /// No description provided for @moreHubLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get moreHubLanguage;

  /// No description provided for @moreHubAskCopilotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ask AFAB Copilot'**
  String get moreHubAskCopilotTooltip;

  /// No description provided for @planLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Limit Reached'**
  String get planLimitTitle;

  /// No description provided for @planLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your monthly {feature} limit ({used}/{limit}). Upgrade to {plan} to continue.'**
  String planLimitMessage(String feature, int used, int limit, String plan);

  /// No description provided for @planReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace is Read-Only'**
  String get planReadOnlyTitle;

  /// No description provided for @planReadOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is currently read-only under your active subscription allocation.'**
  String planReadOnlyMessage(String name);

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re Under Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'AFAB services are temporarily unavailable while we complete scheduled updates. Your financial records remain safe.'**
  String get maintenanceDesc;

  /// No description provided for @maintenanceCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Server Health'**
  String get maintenanceCheckStatus;

  /// No description provided for @maintenanceStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Backend Online'**
  String get maintenanceStatusOnline;

  /// No description provided for @maintenanceStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Backend Unreachable'**
  String get maintenanceStatusOffline;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get notFoundTitle;

  /// No description provided for @notFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'The screen you requested doesn\'t exist or was moved.'**
  String get notFoundDesc;

  /// No description provided for @notFoundGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get notFoundGoHome;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericDesc.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while rendering this view.'**
  String get errorGenericDesc;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @periodAllTime.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get periodAllTime;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @commonExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get commonExportCsv;

  /// No description provided for @commonDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get commonDiscardTitle;

  /// No description provided for @commonDiscardDesc.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave without saving?'**
  String get commonDiscardDesc;

  /// No description provided for @commonDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscardConfirm;

  /// No description provided for @commonKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get commonKeepEditing;

  /// No description provided for @commonReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This workspace is in read-only vault mode. Editing and deletions are disabled.'**
  String get commonReadOnlyNotice;

  /// No description provided for @commonCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopiedToClipboard;

  /// No description provided for @txTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get txTitle;

  /// No description provided for @txSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, filter, split, and reconcile your business cash ledger.'**
  String get txSubtitle;

  /// No description provided for @txAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get txAddButton;

  /// No description provided for @txSplitButton.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txSplitButton;

  /// No description provided for @txManageCategoriesButton.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get txManageCategoriesButton;

  /// No description provided for @txAllTimeLedgerCaption.
  ///
  /// In en, this message translates to:
  /// **'All-time ledger totals'**
  String get txAllTimeLedgerCaption;

  /// No description provided for @txFilteredResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} matching'**
  String txFilteredResultsCount(int count);

  /// No description provided for @txKpiInflow.
  ///
  /// In en, this message translates to:
  /// **'Total Inflow'**
  String get txKpiInflow;

  /// No description provided for @txKpiOutflow.
  ///
  /// In en, this message translates to:
  /// **'Total Outflow'**
  String get txKpiOutflow;

  /// No description provided for @txKpiNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get txKpiNetBalance;

  /// No description provided for @txKpiCount.
  ///
  /// In en, this message translates to:
  /// **'Total Records'**
  String get txKpiCount;

  /// No description provided for @txQuickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Magic Quick-Add'**
  String get txQuickAddTitle;

  /// No description provided for @txQuickAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Paid \$120 to Figma yesterday via card'**
  String get txQuickAddHint;

  /// No description provided for @txQuickAddSubmit.
  ///
  /// In en, this message translates to:
  /// **'Quick Log'**
  String get txQuickAddSubmit;

  /// No description provided for @txQuickAddParsedAs.
  ///
  /// In en, this message translates to:
  /// **'Parsed preview'**
  String get txQuickAddParsedAs;

  /// No description provided for @txQuickAddNoAmount.
  ///
  /// In en, this message translates to:
  /// **'Include an amount (e.g. \$45.50 or 120 TND) to quick-add.'**
  String get txQuickAddNoAmount;

  /// No description provided for @txQuickAddSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction logged via Quick-Add.'**
  String get txQuickAddSuccess;

  /// No description provided for @txSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description...'**
  String get txSearchHint;

  /// No description provided for @txFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get txFiltersTitle;

  /// No description provided for @txFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get txFilterReset;

  /// No description provided for @txFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get txFilterApply;

  /// No description provided for @txFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get txFilterType;

  /// No description provided for @txFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get txFilterCategory;

  /// No description provided for @txFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get txFilterStatus;

  /// No description provided for @txFilterPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get txFilterPaymentMethod;

  /// No description provided for @txFilterTaxDeductibleOnly.
  ///
  /// In en, this message translates to:
  /// **'Tax Write-offs Only'**
  String get txFilterTaxDeductibleOnly;

  /// No description provided for @txFilterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get txFilterDateRange;

  /// No description provided for @txFilterStartDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get txFilterStartDate;

  /// No description provided for @txFilterEndDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get txFilterEndDate;

  /// No description provided for @txTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txTypeIncome;

  /// No description provided for @txTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txTypeExpense;

  /// No description provided for @txStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get txStatusCompleted;

  /// No description provided for @txStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get txStatusPending;

  /// No description provided for @txStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get txStatusCancelled;

  /// No description provided for @txMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get txMethodBankTransfer;

  /// No description provided for @txMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get txMethodCard;

  /// No description provided for @txMethodCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get txMethodCreditCard;

  /// No description provided for @txMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get txMethodCash;

  /// No description provided for @txMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get txMethodOther;

  /// No description provided for @txSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txSortDate;

  /// No description provided for @txSortAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txSortAmount;

  /// No description provided for @txPageSummary.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String txPageSummary(int page, int total);

  /// No description provided for @txPageOnlySortHint.
  ///
  /// In en, this message translates to:
  /// **'Sorting applies to the currently loaded page.'**
  String get txPageOnlySortHint;

  /// No description provided for @txShowingRange.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}–{end} of {total} results'**
  String txShowingRange(int start, int end, int total);

  /// No description provided for @txEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get txEmptyTitle;

  /// No description provided for @txEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search filters or record a new transaction.'**
  String get txEmptyDesc;

  /// No description provided for @txEmptyDetailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a transaction to inspect FX rates, splits, and private receipts.'**
  String get txEmptyDetailPrompt;

  /// No description provided for @txBadgeTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get txBadgeTax;

  /// No description provided for @txBadgeSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txBadgeSplit;

  /// No description provided for @txBadgeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate?'**
  String get txBadgeDuplicate;

  /// No description provided for @txBadgePriceHike.
  ///
  /// In en, this message translates to:
  /// **'+{pct}% spike'**
  String txBadgePriceHike(String pct);

  /// No description provided for @txActionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get txActionDuplicate;

  /// No description provided for @txDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get txDeleteConfirmTitle;

  /// No description provided for @txDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{description}\" ({amount}) and any split child allocations.'**
  String txDeleteConfirmDesc(String description, String amount);

  /// No description provided for @txDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted.'**
  String get txDeletedToast;

  /// No description provided for @txCsvExportChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Transactions CSV'**
  String get txCsvExportChoiceTitle;

  /// No description provided for @txCsvExportCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Export current page ({count} rows)'**
  String txCsvExportCurrentPage(int count);

  /// No description provided for @txCsvExportUpTo100.
  ///
  /// In en, this message translates to:
  /// **'Export up to 100 matching rows'**
  String get txCsvExportUpTo100;

  /// No description provided for @txDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get txDetailsTitle;

  /// No description provided for @txDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Transaction unavailable in this workspace'**
  String get txDetailsUnavailable;

  /// No description provided for @txDetailsUnavailableDesc.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted or belongs to another business.'**
  String get txDetailsUnavailableDesc;

  /// No description provided for @txDetailsBackToLedger.
  ///
  /// In en, this message translates to:
  /// **'Back to Ledger'**
  String get txDetailsBackToLedger;

  /// No description provided for @txDetailsOriginalFx.
  ///
  /// In en, this message translates to:
  /// **'Original: {origAmount} @ {rate} {origCurr}/{baseCurr}'**
  String txDetailsOriginalFx(
    String origAmount,
    String rate,
    String origCurr,
    String baseCurr,
  );

  /// No description provided for @txDetailsDuplicateAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Potential Duplicate Charge'**
  String get txDetailsDuplicateAlertTitle;

  /// No description provided for @txDetailsDuplicateAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Another active transaction with the same amount and description was found within 48 hours.'**
  String get txDetailsDuplicateAlertDesc;

  /// No description provided for @txDetailsPriceHikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Increase Detected (+{pct}%)'**
  String txDetailsPriceHikeTitle(String pct);

  /// No description provided for @txDetailsPriceHikeDesc.
  ///
  /// In en, this message translates to:
  /// **'This expense is noticeably higher than the previous charge with the same description.'**
  String get txDetailsPriceHikeDesc;

  /// No description provided for @txDetailsFxSnapshot.
  ///
  /// In en, this message translates to:
  /// **'FX Snapshot'**
  String get txDetailsFxSnapshot;

  /// No description provided for @txDetailsLegacyFx.
  ///
  /// In en, this message translates to:
  /// **'Legacy ({currency})'**
  String txDetailsLegacyFx(String currency);

  /// No description provided for @txDetailsTaxRate.
  ///
  /// In en, this message translates to:
  /// **'VAT / Tax Rate'**
  String get txDetailsTaxRate;

  /// No description provided for @txDetailsSplitSection.
  ///
  /// In en, this message translates to:
  /// **'Split Allocation'**
  String get txDetailsSplitSection;

  /// No description provided for @txDetailsChildSplitBanner.
  ///
  /// In en, this message translates to:
  /// **'Part of a multi-category split transaction'**
  String get txDetailsChildSplitBanner;

  /// No description provided for @txDetailsViewParent.
  ///
  /// In en, this message translates to:
  /// **'View Parent'**
  String get txDetailsViewParent;

  /// No description provided for @txDetailsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get txDetailsNotes;

  /// No description provided for @txDetailsAuditId.
  ///
  /// In en, this message translates to:
  /// **'Reference ID'**
  String get txDetailsAuditId;

  /// No description provided for @txDetailsUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get txDetailsUncategorized;

  /// No description provided for @txFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get txFormAddTitle;

  /// No description provided for @txFormDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Transaction'**
  String get txFormDuplicateTitle;

  /// No description provided for @txFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get txFormEditTitle;

  /// No description provided for @txFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get txFormDescriptionLabel;

  /// No description provided for @txFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Vendor, client, or memo'**
  String get txFormDescriptionHint;

  /// No description provided for @txFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txFormAmountLabel;

  /// No description provided for @txFormCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get txFormCurrencyLabel;

  /// No description provided for @txFormCustomRateToggle.
  ///
  /// In en, this message translates to:
  /// **'Custom FX Rate (Optional)'**
  String get txFormCustomRateToggle;

  /// No description provided for @txFormCustomRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate to {base}'**
  String txFormCustomRateLabel(String base);

  /// No description provided for @txFormFxOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Live FX quote unavailable offline — enter custom rate or submit online.'**
  String get txFormFxOfflineHint;

  /// No description provided for @txFormFxLockedNotice.
  ///
  /// In en, this message translates to:
  /// **'Historical currency and exchange rate are locked on existing transactions.'**
  String get txFormFxLockedNotice;

  /// No description provided for @txFormSplitEditNotice.
  ///
  /// In en, this message translates to:
  /// **'Note: Editing a split parent updates its metadata/total without modifying existing split lines.'**
  String get txFormSplitEditNotice;

  /// No description provided for @txFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get txFormDateLabel;

  /// No description provided for @txFormNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get txFormNotesLabel;

  /// No description provided for @txFormTaxSwitch.
  ///
  /// In en, this message translates to:
  /// **'Tax Deductible Business Expense'**
  String get txFormTaxSwitch;

  /// No description provided for @txFormTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT / Tax %'**
  String get txFormTaxRateLabel;

  /// No description provided for @txFormTaxRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a tax rate between 0 and 100.'**
  String get txFormTaxRateInvalid;

  /// No description provided for @txFormAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount (minimum 0.0001).'**
  String get txFormAmountInvalid;

  /// No description provided for @txFormSubmitCreate.
  ///
  /// In en, this message translates to:
  /// **'Record Transaction'**
  String get txFormSubmitCreate;

  /// No description provided for @txFormSubmitEdit.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get txFormSubmitEdit;

  /// No description provided for @txFormSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved.'**
  String get txFormSavedToast;

  /// No description provided for @txSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split Transaction'**
  String get txSplitTitle;

  /// No description provided for @txSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allocate a single payment across multiple categories'**
  String get txSplitSubtitle;

  /// No description provided for @txSplitVendorLabel.
  ///
  /// In en, this message translates to:
  /// **'Master Description / Vendor'**
  String get txSplitVendorLabel;

  /// No description provided for @txSplitTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get txSplitTotalAmount;

  /// No description provided for @txSplitLinesHeader.
  ///
  /// In en, this message translates to:
  /// **'Split Lines ({count})'**
  String txSplitLinesHeader(int count);

  /// No description provided for @txSplitAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add Line'**
  String get txSplitAddLine;

  /// No description provided for @txSplitLineMemoHint.
  ///
  /// In en, this message translates to:
  /// **'Line memo (optional)'**
  String get txSplitLineMemoHint;

  /// No description provided for @txSplitFillRemaining.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get txSplitFillRemaining;

  /// No description provided for @txSplitAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get txSplitAllocated;

  /// No description provided for @txSplitRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get txSplitRemaining;

  /// No description provided for @txSplitBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced ({zero})'**
  String txSplitBalanced(String zero);

  /// No description provided for @txSplitMinLinesError.
  ///
  /// In en, this message translates to:
  /// **'A split transaction requires at least 2 lines.'**
  String get txSplitMinLinesError;

  /// No description provided for @txSplitUnbalancedError.
  ///
  /// In en, this message translates to:
  /// **'Split lines must equal the parent total exactly.'**
  String get txSplitUnbalancedError;

  /// No description provided for @txSplitConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Split Transaction'**
  String get txSplitConfirmBtn;

  /// No description provided for @txCatTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get txCatTitle;

  /// No description provided for @txCatExpenseTab.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get txCatExpenseTab;

  /// No description provided for @txCatIncomeTab.
  ///
  /// In en, this message translates to:
  /// **'Income Categories'**
  String get txCatIncomeTab;

  /// No description provided for @txCatNewBtn.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get txCatNewBtn;

  /// No description provided for @txCatEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get txCatEditTitle;

  /// No description provided for @txCatNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get txCatNameLabel;

  /// No description provided for @txCatNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cloud Hosting'**
  String get txCatNameHint;

  /// No description provided for @txCatColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get txCatColorLabel;

  /// No description provided for @txCatIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get txCatIconLabel;

  /// No description provided for @txCatSystemBadge.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get txCatSystemBadge;

  /// No description provided for @txCatCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get txCatCustomBadge;

  /// No description provided for @txCatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete category \"{name}\"? This cannot be undone.'**
  String txCatDeleteConfirm(String name);

  /// No description provided for @txCatCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Category created.'**
  String get txCatCreatedToast;

  /// No description provided for @txCatUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Category updated.'**
  String get txCatUpdatedToast;

  /// No description provided for @txCatDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Category deleted.'**
  String get txCatDeletedToast;

  /// No description provided for @txCatDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists.'**
  String get txCatDuplicateError;

  /// No description provided for @txCatInUseWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Cannot delete: used by 1 transaction.} other{Cannot delete: used by {count} transactions.}}'**
  String txCatInUseWithCount(int count);

  /// No description provided for @txCatInUseGeneric.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete category while transactions reference it.'**
  String get txCatInUseGeneric;

  /// No description provided for @receiptsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts ({count})'**
  String receiptsSectionTitle(int count);

  /// No description provided for @receiptsAttachBtn.
  ///
  /// In en, this message translates to:
  /// **'Attach Receipt'**
  String get receiptsAttachBtn;

  /// No description provided for @receiptsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'No receipts attached. Upload PDF, PNG, JPEG, or WEBP (max 10 MB).'**
  String get receiptsEmptyDesc;

  /// No description provided for @receiptsSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach Private Receipt'**
  String get receiptsSourceTitle;

  /// No description provided for @receiptsSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: PDF, JPEG, PNG, WEBP up to 10 MB'**
  String get receiptsSourceSubtitle;

  /// No description provided for @receiptsTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get receiptsTakePhoto;

  /// No description provided for @receiptsChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photo Library'**
  String get receiptsChooseGallery;

  /// No description provided for @receiptsBrowseFile.
  ///
  /// In en, this message translates to:
  /// **'Browse PDF or Document'**
  String get receiptsBrowseFile;

  /// No description provided for @receiptsUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading receipt...'**
  String get receiptsUploading;

  /// No description provided for @receiptsUploadedToast.
  ///
  /// In en, this message translates to:
  /// **'Receipt uploaded securely.'**
  String get receiptsUploadedToast;

  /// No description provided for @receiptsDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Receipt deleted.'**
  String get receiptsDeletedToast;

  /// No description provided for @receiptsTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Receipt file exceeds the 10 MB maximum limit.'**
  String get receiptsTooLarge;

  /// No description provided for @receiptsInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file. Only PDF, JPEG, PNG, and WEBP receipts are accepted.'**
  String get receiptsInvalidType;

  /// No description provided for @receiptsEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'Selected receipt file is empty.'**
  String get receiptsEmptyFile;

  /// No description provided for @receiptsViewerLoading.
  ///
  /// In en, this message translates to:
  /// **'Decrypting private receipt...'**
  String get receiptsViewerLoading;

  /// No description provided for @receiptsShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get receiptsShareAction;

  /// No description provided for @receiptsCopyLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Copy Presigned URL'**
  String get receiptsCopyLinkAction;

  /// No description provided for @receiptsPresignedNotice.
  ///
  /// In en, this message translates to:
  /// **'Temporary link copied (expires in {seconds}s).'**
  String receiptsPresignedNotice(int seconds);

  /// No description provided for @receiptsPdfReady.
  ///
  /// In en, this message translates to:
  /// **'Private PDF Receipt Ready'**
  String get receiptsPdfReady;

  /// No description provided for @receiptsPdfHint.
  ///
  /// In en, this message translates to:
  /// **'Open with your OS share sheet or external viewer.'**
  String get receiptsPdfHint;

  /// No description provided for @receiptsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete receipt?'**
  String get receiptsDeleteConfirmTitle;

  /// No description provided for @receiptsDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes \"{filename}\" from encrypted private storage.'**
  String receiptsDeleteConfirmDesc(String filename);

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @expensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visual analysis of business spend and operating costs.'**
  String get expensesSubtitle;

  /// No description provided for @expensesCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'New Expense'**
  String get expensesCreateBtn;

  /// No description provided for @expensesKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get expensesKpiTotal;

  /// No description provided for @expensesKpiAvgDay.
  ///
  /// In en, this message translates to:
  /// **'Avg per Day'**
  String get expensesKpiAvgDay;

  /// No description provided for @expensesKpiHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest Expense'**
  String get expensesKpiHighest;

  /// No description provided for @expensesKpiCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get expensesKpiCategories;

  /// No description provided for @expensesKpiRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get expensesKpiRecurring;

  /// No description provided for @expensesOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get expensesOverviewTitle;

  /// No description provided for @expensesNoChartData.
  ///
  /// In en, this message translates to:
  /// **'No completed expenses in this period.'**
  String get expensesNoChartData;

  /// No description provided for @expensesDonutTitle.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get expensesDonutTitle;

  /// No description provided for @expensesTotalSpend.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SPEND'**
  String get expensesTotalSpend;

  /// No description provided for @expensesTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Spending Categories'**
  String get expensesTopCategories;

  /// No description provided for @expensesRecurringCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Subscriptions'**
  String get expensesRecurringCardTitle;

  /// No description provided for @expensesRecurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense schedules are managed on the Recurring page.'**
  String get expensesRecurringEmpty;

  /// No description provided for @expensesManageRecurring.
  ///
  /// In en, this message translates to:
  /// **'Manage Recurring Rules'**
  String get expensesManageRecurring;

  /// No description provided for @expensesListHeader.
  ///
  /// In en, this message translates to:
  /// **'All Expense Entries'**
  String get expensesListHeader;

  /// No description provided for @revenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueTitle;

  /// No description provided for @revenueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track cash inflow velocity and top income streams.'**
  String get revenueSubtitle;

  /// No description provided for @revenueCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'New Revenue'**
  String get revenueCreateBtn;

  /// No description provided for @revenueKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get revenueKpiTotal;

  /// No description provided for @revenueKpiAvgDay.
  ///
  /// In en, this message translates to:
  /// **'Avg per Day'**
  String get revenueKpiAvgDay;

  /// No description provided for @revenueKpiHighestDay.
  ///
  /// In en, this message translates to:
  /// **'Highest Revenue Day'**
  String get revenueKpiHighestDay;

  /// No description provided for @revenueKpiCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed Income'**
  String get revenueKpiCompletedCount;

  /// No description provided for @revenueKpiCompletedSub.
  ///
  /// In en, this message translates to:
  /// **'Completed income entries'**
  String get revenueKpiCompletedSub;

  /// No description provided for @revenueOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue Overview'**
  String get revenueOverviewTitle;

  /// No description provided for @revenueNoChartData.
  ///
  /// In en, this message translates to:
  /// **'No completed income in this period.'**
  String get revenueNoChartData;

  /// No description provided for @revenueBySourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Source'**
  String get revenueBySourceTitle;

  /// No description provided for @revenueGrossNetTitle.
  ///
  /// In en, this message translates to:
  /// **'Gross vs Net Revenue'**
  String get revenueGrossNetTitle;

  /// No description provided for @revenueGrossLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross Revenue'**
  String get revenueGrossLabel;

  /// No description provided for @revenueDiscountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get revenueDiscountsLabel;

  /// No description provided for @revenueRefundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get revenueRefundsLabel;

  /// No description provided for @revenueNetLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Revenue'**
  String get revenueNetLabel;

  /// No description provided for @revenueCashBasisNote.
  ///
  /// In en, this message translates to:
  /// **'Discounts & refunds are not tracked separately on cash-basis entries.'**
  String get revenueCashBasisNote;

  /// No description provided for @revenueTopProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Products & Streams'**
  String get revenueTopProductsTitle;

  /// No description provided for @revenueTopProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Product-level attribution uses invoice line items.'**
  String get revenueTopProductsEmpty;

  /// No description provided for @revenueViewInvoices.
  ///
  /// In en, this message translates to:
  /// **'View Invoices'**
  String get revenueViewInvoices;

  /// No description provided for @revenueListHeader.
  ///
  /// In en, this message translates to:
  /// **'All Income Entries'**
  String get revenueListHeader;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage client relationships, invoices, and billed revenue.'**
  String get customersSubtitle;

  /// No description provided for @customersAddBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customersAddBtn;

  /// No description provided for @customersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get customersEditTitle;

  /// No description provided for @customersAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get customersAddTitle;

  /// No description provided for @customersPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get customersPeriodToday;

  /// No description provided for @customersPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get customersPeriodWeek;

  /// No description provided for @customersPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get customersPeriodMonth;

  /// No description provided for @customersPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get customersPeriodYear;

  /// No description provided for @customersKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get customersKpiTotal;

  /// No description provided for @customersKpiTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get customersKpiTotalRevenue;

  /// No description provided for @customersKpiAvgRevenue.
  ///
  /// In en, this message translates to:
  /// **'Avg / Customer'**
  String get customersKpiAvgRevenue;

  /// No description provided for @customersKpiRepeatRate.
  ///
  /// In en, this message translates to:
  /// **'Repeat Rate'**
  String get customersKpiRepeatRate;

  /// No description provided for @customersNewPeriod.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String customersNewPeriod(int count);

  /// No description provided for @customersOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Segments'**
  String get customersOverviewTitle;

  /// No description provided for @customersStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersStatusActive;

  /// No description provided for @customersStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customersStatusInactive;

  /// No description provided for @customersStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get customersStatusNew;

  /// No description provided for @customersTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Customers'**
  String get customersTopTitle;

  /// No description provided for @customersActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get customersActivityTitle;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, code, email, phone...'**
  String get customersSearchHint;

  /// No description provided for @customersGroupAll.
  ///
  /// In en, this message translates to:
  /// **'All Groups'**
  String get customersGroupAll;

  /// No description provided for @customersGroupStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get customersGroupStandard;

  /// No description provided for @customersGroupVip.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get customersGroupVip;

  /// No description provided for @customersGroupWholesale.
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get customersGroupWholesale;

  /// No description provided for @customersGroupEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get customersGroupEnterprise;

  /// No description provided for @customersGroupPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get customersGroupPartner;

  /// No description provided for @customersStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get customersStatusAll;

  /// No description provided for @customersSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get customersSortNewest;

  /// No description provided for @customersSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customersSortName;

  /// No description provided for @customersSortRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get customersSortRevenue;

  /// No description provided for @customersSortOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get customersSortOrders;

  /// No description provided for @customersFieldName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get customersFieldName;

  /// No description provided for @customersFieldCompany.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get customersFieldCompany;

  /// No description provided for @customersFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customersFieldEmail;

  /// No description provided for @customersFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customersFieldPhone;

  /// No description provided for @customersFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Customer Code'**
  String get customersFieldCode;

  /// No description provided for @customersFieldCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated if blank'**
  String get customersFieldCodeHint;

  /// No description provided for @customersFieldGroup.
  ///
  /// In en, this message translates to:
  /// **'Customer Group'**
  String get customersFieldGroup;

  /// No description provided for @customersFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get customersFieldStatus;

  /// No description provided for @customersFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customersFieldAddress;

  /// No description provided for @customersFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get customersFieldNotes;

  /// No description provided for @customersCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Customer created.'**
  String get customersCreatedToast;

  /// No description provided for @customersUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Customer updated.'**
  String get customersUpdatedToast;

  /// No description provided for @customersArchivedToast.
  ///
  /// In en, this message translates to:
  /// **'Customer archived.'**
  String get customersArchivedToast;

  /// No description provided for @customersArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive customer?'**
  String get customersArchiveTitle;

  /// No description provided for @customersArchiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Archive \"{name}\"? Historical invoices and ledger entries remain preserved.'**
  String customersArchiveDesc(String name);

  /// No description provided for @customersArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get customersArchiveAction;

  /// No description provided for @customersCallAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get customersCallAction;

  /// No description provided for @customersEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customersEmailAction;

  /// No description provided for @customersDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customersDetailsTitle;

  /// No description provided for @customersDetailsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a customer to view their profile, balances, and order history.'**
  String get customersDetailsPrompt;

  /// No description provided for @customersKpiInvoiced.
  ///
  /// In en, this message translates to:
  /// **'Invoiced'**
  String get customersKpiInvoiced;

  /// No description provided for @customersKpiOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get customersKpiOutstanding;

  /// No description provided for @customersKpiOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get customersKpiOrdersCount;

  /// No description provided for @customersContactCard.
  ///
  /// In en, this message translates to:
  /// **'Contact & Address'**
  String get customersContactCard;

  /// No description provided for @customersOrdersHistory.
  ///
  /// In en, this message translates to:
  /// **'Orders & Invoices'**
  String get customersOrdersHistory;

  /// No description provided for @customersAddOrderBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Order'**
  String get customersAddOrderBtn;

  /// No description provided for @customersOrdersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders or invoices recorded for this customer yet.'**
  String get customersOrdersEmpty;

  /// No description provided for @customersOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String customersOrdersCount(int count);

  /// No description provided for @customersOrderModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Customer Order'**
  String get customersOrderModalTitle;

  /// No description provided for @customersOrderDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Order / Invoice Description *'**
  String get customersOrderDescLabel;

  /// No description provided for @customersOrderAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount ({currency}) *'**
  String customersOrderAmountLabel(String currency);

  /// No description provided for @customersOrderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get customersOrderDateLabel;

  /// No description provided for @customersOrderInitialStatus.
  ///
  /// In en, this message translates to:
  /// **'Initial Status'**
  String get customersOrderInitialStatus;

  /// No description provided for @customersOrderPaidHelper.
  ///
  /// In en, this message translates to:
  /// **'Issues invoice and records a linked income payment transaction.'**
  String get customersOrderPaidHelper;

  /// No description provided for @customersOrderUnpaidHelper.
  ///
  /// In en, this message translates to:
  /// **'Issues invoice as Unpaid awaiting customer settlement.'**
  String get customersOrderUnpaidHelper;

  /// No description provided for @customersOrderDraftHelper.
  ///
  /// In en, this message translates to:
  /// **'Saves invoice as Draft for later editing.'**
  String get customersOrderDraftHelper;

  /// No description provided for @customersOrderCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Order invoice created successfully.'**
  String get customersOrderCreatedToast;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer or adjust your search and segment filters.'**
  String get customersEmptyDesc;

  /// No description provided for @customersPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get customersPickerTitle;

  /// No description provided for @customersPickerWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in / No Customer'**
  String get customersPickerWalkIn;

  /// No description provided for @customersPickerWalkInDesc.
  ///
  /// In en, this message translates to:
  /// **'Create invoice without linking a customer profile'**
  String get customersPickerWalkInDesc;

  /// No description provided for @invoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoicesTitle;

  /// No description provided for @invoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create drafts, issue bills, track balances, and record payments.'**
  String get invoicesSubtitle;

  /// No description provided for @invoicesCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get invoicesCreateBtn;

  /// No description provided for @invoicesKpiTotalInvoiced.
  ///
  /// In en, this message translates to:
  /// **'Total Invoiced'**
  String get invoicesKpiTotalInvoiced;

  /// No description provided for @invoicesKpiPaid.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get invoicesKpiPaid;

  /// No description provided for @invoicesKpiPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Balance'**
  String get invoicesKpiPending;

  /// No description provided for @invoicesKpiOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoicesKpiOverdue;

  /// No description provided for @invoicesStatusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Status Breakdown'**
  String get invoicesStatusBreakdown;

  /// No description provided for @invoicesUpcomingDue.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Due'**
  String get invoicesUpcomingDue;

  /// No description provided for @invoicesUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No unpaid invoices coming due soon.'**
  String get invoicesUpcomingEmpty;

  /// No description provided for @invoicesDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String invoicesDueDateLabel(String date);

  /// No description provided for @invoicesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search invoice # or customer...'**
  String get invoicesSearchHint;

  /// No description provided for @invoicesStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get invoicesStatusDraft;

  /// No description provided for @invoicesStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get invoicesStatusSent;

  /// No description provided for @invoicesStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get invoicesStatusUnpaid;

  /// No description provided for @invoicesStatusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get invoicesStatusPartiallyPaid;

  /// No description provided for @invoicesStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoicesStatusPaid;

  /// No description provided for @invoicesStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoicesStatusOverdue;

  /// No description provided for @invoicesStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invoicesStatusCancelled;

  /// No description provided for @invoicesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get invoicesEmptyTitle;

  /// No description provided for @invoicesEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a draft invoice or adjust your status filter.'**
  String get invoicesEmptyDesc;

  /// No description provided for @invoicesDetailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select an invoice to view line items, payment history, and export PDF.'**
  String get invoicesDetailPrompt;

  /// No description provided for @invoicesDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoicesDetailTitle;

  /// No description provided for @invoicesOverdueBanner.
  ///
  /// In en, this message translates to:
  /// **'This invoice is past its due date. Follow up or record a payment.'**
  String get invoicesOverdueBanner;

  /// No description provided for @invoicesIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get invoicesIssueDate;

  /// No description provided for @invoicesDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get invoicesDueDate;

  /// No description provided for @invoicesCustomerSection.
  ///
  /// In en, this message translates to:
  /// **'Billed To'**
  String get invoicesCustomerSection;

  /// No description provided for @invoicesWalkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get invoicesWalkInCustomer;

  /// No description provided for @invoicesLineItems.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get invoicesLineItems;

  /// No description provided for @invoicesQtyPrice.
  ///
  /// In en, this message translates to:
  /// **'Qty {qty} × {price}'**
  String invoicesQtyPrice(String qty, String price);

  /// No description provided for @invoicesTaxRateBadge.
  ///
  /// In en, this message translates to:
  /// **'Tax {rate}%'**
  String invoicesTaxRateBadge(String rate);

  /// No description provided for @invoicesSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoicesSubtotal;

  /// No description provided for @invoicesTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get invoicesTax;

  /// No description provided for @invoicesDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get invoicesDiscount;

  /// No description provided for @invoicesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get invoicesTotal;

  /// No description provided for @invoicesPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoicesPaidAmount;

  /// No description provided for @invoicesOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get invoicesOutstanding;

  /// No description provided for @invoicesPaymentsHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get invoicesPaymentsHistory;

  /// No description provided for @invoicesPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded against this invoice yet.'**
  String get invoicesPaymentsEmpty;

  /// No description provided for @invoicesLinkedTx.
  ///
  /// In en, this message translates to:
  /// **'Income Tx'**
  String get invoicesLinkedTx;

  /// No description provided for @invoicesEditDraftBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit Draft'**
  String get invoicesEditDraftBtn;

  /// No description provided for @invoicesMarkSentBtn.
  ///
  /// In en, this message translates to:
  /// **'Mark as Sent'**
  String get invoicesMarkSentBtn;

  /// No description provided for @invoicesIssueUnpaidBtn.
  ///
  /// In en, this message translates to:
  /// **'Issue as Unpaid'**
  String get invoicesIssueUnpaidBtn;

  /// No description provided for @invoicesRecordPaymentBtn.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get invoicesRecordPaymentBtn;

  /// No description provided for @invoicesCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invoice'**
  String get invoicesCancelBtn;

  /// No description provided for @invoicesExportPdfBtn.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get invoicesExportPdfBtn;

  /// No description provided for @invoicesAiReminderBtn.
  ///
  /// In en, this message translates to:
  /// **'AI Reminder'**
  String get invoicesAiReminderBtn;

  /// No description provided for @invoicesIssuedSentToast.
  ///
  /// In en, this message translates to:
  /// **'Invoice marked as Sent.'**
  String get invoicesIssuedSentToast;

  /// No description provided for @invoicesIssuedUnpaidToast.
  ///
  /// In en, this message translates to:
  /// **'Invoice issued as Unpaid.'**
  String get invoicesIssuedUnpaidToast;

  /// No description provided for @invoicesCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice?'**
  String get invoicesCancelConfirmTitle;

  /// No description provided for @invoicesCancelConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Cancel {number}? Cancelled invoices cannot receive payments.'**
  String invoicesCancelConfirmDesc(String number);

  /// No description provided for @invoicesCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Invoice cancelled.'**
  String get invoicesCancelledToast;

  /// No description provided for @invoicesFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice (Draft)'**
  String get invoicesFormCreateTitle;

  /// No description provided for @invoicesFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Draft {number}'**
  String invoicesFormEditTitle(String number);

  /// No description provided for @invoicesFormOnlyDraftError.
  ///
  /// In en, this message translates to:
  /// **'Only DRAFT invoices can be edited.'**
  String get invoicesFormOnlyDraftError;

  /// No description provided for @invoicesFormCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer (Optional)'**
  String get invoicesFormCustomerLabel;

  /// No description provided for @invoicesFormCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Currency'**
  String get invoicesFormCurrencyLabel;

  /// No description provided for @invoicesFormAddLineBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Line'**
  String get invoicesFormAddLineBtn;

  /// No description provided for @invoicesFormItemDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Description *'**
  String get invoicesFormItemDescLabel;

  /// No description provided for @invoicesFormQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty *'**
  String get invoicesFormQtyLabel;

  /// No description provided for @invoicesFormUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price *'**
  String get invoicesFormUnitPriceLabel;

  /// No description provided for @invoicesFormTaxPctLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax %'**
  String get invoicesFormTaxPctLabel;

  /// No description provided for @invoicesFormDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get invoicesFormDiscountLabel;

  /// No description provided for @invoicesFormNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Payment terms, bank details, or reference notes...'**
  String get invoicesFormNotesHint;

  /// No description provided for @invoicesFormSaveDraftBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Draft Invoice'**
  String get invoicesFormSaveDraftBtn;

  /// No description provided for @invoicesFormUpdateDraftBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Draft'**
  String get invoicesFormUpdateDraftBtn;

  /// No description provided for @invoicesFormDiscountExceedsError.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot exceed subtotal plus tax.'**
  String get invoicesFormDiscountExceedsError;

  /// No description provided for @invoicesFormSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number} saved.'**
  String invoicesFormSavedToast(String number);

  /// No description provided for @paymentSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get paymentSheetTitle;

  /// No description provided for @paymentRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{number} · Remaining: {amount}'**
  String paymentRemainingLabel(String number, String amount);

  /// No description provided for @paymentLedgerNotice.
  ///
  /// In en, this message translates to:
  /// **'Recording this payment automatically creates a 1:1 COMPLETED Income transaction in your ledger and updates the invoice balance.'**
  String get paymentLedgerNotice;

  /// No description provided for @paymentFullBalanceChip.
  ///
  /// In en, this message translates to:
  /// **'Full Balance'**
  String get paymentFullBalanceChip;

  /// No description provided for @paymentHalfChip.
  ///
  /// In en, this message translates to:
  /// **'50%'**
  String get paymentHalfChip;

  /// No description provided for @paymentAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Supports full or partial payment up to {max}.'**
  String paymentAmountHelper(String max);

  /// No description provided for @paymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Date *'**
  String get paymentDateLabel;

  /// No description provided for @paymentFxLabel.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate (1 {from} = ? {to})'**
  String paymentFxLabel(String from, String to);

  /// No description provided for @paymentFxHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional manual FX rate for the linked {base} income transaction. Leave blank for live spot rate.'**
  String paymentFxHelper(String base);

  /// No description provided for @paymentReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get paymentReferenceLabel;

  /// No description provided for @paymentReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Wire transfer # or receipt reference'**
  String get paymentReferenceHint;

  /// No description provided for @paymentConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get paymentConfirmBtn;

  /// No description provided for @paymentRetrySameBtn.
  ///
  /// In en, this message translates to:
  /// **'Retry Same Payment'**
  String get paymentRetrySameBtn;

  /// No description provided for @paymentOverBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed outstanding balance.'**
  String get paymentOverBalanceError;

  /// No description provided for @paymentRateInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate must be at least 0.000001.'**
  String get paymentRateInvalidError;

  /// No description provided for @paymentSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded and income transaction created.'**
  String get paymentSuccessToast;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor expense limits with real-time ledger alerts.'**
  String get budgetsSubtitle;

  /// No description provided for @budgetsNewBtn.
  ///
  /// In en, this message translates to:
  /// **'New Budget'**
  String get budgetsNewBtn;

  /// No description provided for @budgetsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budgetsEditTitle;

  /// No description provided for @budgetsFilterActiveOnly.
  ///
  /// In en, this message translates to:
  /// **'Active Only'**
  String get budgetsFilterActiveOnly;

  /// No description provided for @budgetsFilterIncludeArchived.
  ///
  /// In en, this message translates to:
  /// **'Include Archived'**
  String get budgetsFilterIncludeArchived;

  /// No description provided for @budgetsKpiActive.
  ///
  /// In en, this message translates to:
  /// **'Active Budgets'**
  String get budgetsKpiActive;

  /// No description provided for @budgetsKpiSpent.
  ///
  /// In en, this message translates to:
  /// **'Actual Spending'**
  String get budgetsKpiSpent;

  /// No description provided for @budgetsKpiApproaching.
  ///
  /// In en, this message translates to:
  /// **'Approaching Limit'**
  String get budgetsKpiApproaching;

  /// No description provided for @budgetsKpiOver.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get budgetsKpiOver;

  /// No description provided for @budgetsTotalLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Limit: {amount}'**
  String budgetsTotalLimitHint(String amount);

  /// No description provided for @budgetsAggregationTip.
  ///
  /// In en, this message translates to:
  /// **'Totals sum all active budgets; overall and category budgets may count the same expenses.'**
  String get budgetsAggregationTip;

  /// No description provided for @budgetsAllBusinessExpenses.
  ///
  /// In en, this message translates to:
  /// **'All Business Expenses'**
  String get budgetsAllBusinessExpenses;

  /// No description provided for @budgetsPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetsPeriodMonthly;

  /// No description provided for @budgetsPeriodQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get budgetsPeriodQuarterly;

  /// No description provided for @budgetsPeriodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetsPeriodYearly;

  /// No description provided for @budgetsPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get budgetsPeriodCustom;

  /// No description provided for @budgetsAlertOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get budgetsAlertOnTrack;

  /// No description provided for @budgetsAlertApproaching.
  ///
  /// In en, this message translates to:
  /// **'Approaching'**
  String get budgetsAlertApproaching;

  /// No description provided for @budgetsAlertOver.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get budgetsAlertOver;

  /// No description provided for @budgetsStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get budgetsStatusArchived;

  /// No description provided for @budgetsAlertAt.
  ///
  /// In en, this message translates to:
  /// **'Alert at {pct}%'**
  String budgetsAlertAt(int pct);

  /// No description provided for @budgetsAskCopilot.
  ///
  /// In en, this message translates to:
  /// **'Ask Copilot'**
  String get budgetsAskCopilot;

  /// No description provided for @budgetsArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive budget?'**
  String get budgetsArchiveConfirmTitle;

  /// No description provided for @budgetsArchiveConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Archive \"{name}\"? Archived budgets stop tracking active alerts while preserving historical records.'**
  String budgetsArchiveConfirmDesc(String name);

  /// No description provided for @budgetsArchivedToast.
  ///
  /// In en, this message translates to:
  /// **'Budget archived.'**
  String get budgetsArchivedToast;

  /// No description provided for @budgetsSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Budget saved.'**
  String get budgetsSavedToast;

  /// No description provided for @budgetsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budgets configured'**
  String get budgetsEmptyTitle;

  /// No description provided for @budgetsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create an overall or category expense budget to get automatic spending alerts.'**
  String get budgetsEmptyDesc;

  /// No description provided for @budgetsCreateFirstBtn.
  ///
  /// In en, this message translates to:
  /// **'Create First Budget'**
  String get budgetsCreateFirstBtn;

  /// No description provided for @budgetsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Budget Name *'**
  String get budgetsFieldName;

  /// No description provided for @budgetsFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monthly Marketing Budget'**
  String get budgetsFieldNameHint;

  /// No description provided for @budgetsFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Spending Limit ({currency}) *'**
  String budgetsFieldAmount(String currency);

  /// No description provided for @budgetsFieldThreshold.
  ///
  /// In en, this message translates to:
  /// **'Alert Threshold (%)'**
  String get budgetsFieldThreshold;

  /// No description provided for @budgetsFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense Category'**
  String get budgetsFieldCategory;

  /// No description provided for @budgetsFieldPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period Type *'**
  String get budgetsFieldPeriod;

  /// No description provided for @budgetsAutoDateHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to auto-calculate current period'**
  String get budgetsAutoDateHint;

  /// No description provided for @budgetsCustomDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Start date and end date are required for custom budgets.'**
  String get budgetsCustomDatesRequired;

  /// No description provided for @budgetsEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after start date.'**
  String get budgetsEndBeforeStart;

  /// No description provided for @budgetsThresholdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a threshold between 1 and 100.'**
  String get budgetsThresholdInvalid;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Schedules'**
  String get recurringTitle;

  /// No description provided for @recurringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automate repeating income and operating expenses.'**
  String get recurringSubtitle;

  /// No description provided for @recurringNewBtn.
  ///
  /// In en, this message translates to:
  /// **'New Schedule'**
  String get recurringNewBtn;

  /// No description provided for @recurringEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get recurringEditTitle;

  /// No description provided for @recurringFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringFilterActive;

  /// No description provided for @recurringFilterPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringFilterPaused;

  /// No description provided for @recurringFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringFreqWeekly;

  /// No description provided for @recurringFreqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringFreqMonthly;

  /// No description provided for @recurringFreqQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get recurringFreqQuarterly;

  /// No description provided for @recurringFreqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringFreqYearly;

  /// No description provided for @recurringNextRun.
  ///
  /// In en, this message translates to:
  /// **'Next run: {date}'**
  String recurringNextRun(String date);

  /// No description provided for @recurringLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last run: {date}'**
  String recurringLastRun(String date);

  /// No description provided for @recurringEndDate.
  ///
  /// In en, this message translates to:
  /// **'Ends: {date}'**
  String recurringEndDate(String date);

  /// No description provided for @recurringRunDueBtn.
  ///
  /// In en, this message translates to:
  /// **'Run Due'**
  String get recurringRunDueBtn;

  /// No description provided for @recurringPauseBtn.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPauseBtn;

  /// No description provided for @recurringResumeBtn.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResumeBtn;

  /// No description provided for @recurringGeneratedToast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Generated 1 due transaction.} other{Generated {count} due transactions.}}'**
  String recurringGeneratedToast(int count);

  /// No description provided for @recurringNoneDueToast.
  ///
  /// In en, this message translates to:
  /// **'No occurrences are currently due for this schedule.'**
  String get recurringNoneDueToast;

  /// No description provided for @recurringPausedToast.
  ///
  /// In en, this message translates to:
  /// **'Schedule paused.'**
  String get recurringPausedToast;

  /// No description provided for @recurringResumedToast.
  ///
  /// In en, this message translates to:
  /// **'Schedule resumed.'**
  String get recurringResumedToast;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete or deactivate schedule?'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'If \"{name}\" has already generated transactions, it will be deactivated (paused) to preserve ledger history. If it has never run, it will be permanently deleted.'**
  String recurringDeleteDesc(String name);

  /// No description provided for @recurringDeactivatedToast.
  ///
  /// In en, this message translates to:
  /// **'Schedule deactivated to preserve ledger history.'**
  String get recurringDeactivatedToast;

  /// No description provided for @recurringDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Schedule permanently deleted.'**
  String get recurringDeletedToast;

  /// No description provided for @recurringSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Recurring schedule saved.'**
  String get recurringSavedToast;

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring schedules'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create an automated rule for rent, payroll, SaaS subscriptions, or retainers.'**
  String get recurringEmptyDesc;

  /// No description provided for @recurringCreateFirstBtn.
  ///
  /// In en, this message translates to:
  /// **'Create First Schedule'**
  String get recurringCreateFirstBtn;

  /// No description provided for @recurringFieldFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurringFieldFrequency;

  /// No description provided for @recurringFieldEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get recurringFieldEndDate;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect daily inflows, outflows, and scheduled financial events.'**
  String get calendarSubtitle;

  /// No description provided for @calendarTodayBtn.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarTodayBtn;

  /// No description provided for @calendarKpiInflow.
  ///
  /// In en, this message translates to:
  /// **'Monthly Inflow'**
  String get calendarKpiInflow;

  /// No description provided for @calendarKpiOutflow.
  ///
  /// In en, this message translates to:
  /// **'Monthly Outflow'**
  String get calendarKpiOutflow;

  /// No description provided for @calendarKpiPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Items'**
  String get calendarKpiPending;

  /// No description provided for @calendarKpiEntries.
  ///
  /// In en, this message translates to:
  /// **'Recorded Entries'**
  String get calendarKpiEntries;

  /// No description provided for @calendarAwaitingSettlement.
  ///
  /// In en, this message translates to:
  /// **'Awaiting settlement'**
  String get calendarAwaitingSettlement;

  /// No description provided for @calendarOverlayTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get calendarOverlayTransactions;

  /// No description provided for @calendarOverlayInvoicesDue.
  ///
  /// In en, this message translates to:
  /// **'Invoices Due'**
  String get calendarOverlayInvoicesDue;

  /// No description provided for @calendarOverlayRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring Runs'**
  String get calendarOverlayRecurring;

  /// No description provided for @calendarOverlayNotice.
  ///
  /// In en, this message translates to:
  /// **'Calendar overlays combine settled ledger entries with open invoice due dates and scheduled recurring rules.'**
  String get calendarOverlayNotice;

  /// No description provided for @calendarSelectedDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected Date Activity'**
  String get calendarSelectedDateTitle;

  /// No description provided for @calendarEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 entries} =1{1 entry} other{{count} entries}}'**
  String calendarEntriesCount(int count);

  /// No description provided for @calendarNoActivityDate.
  ///
  /// In en, this message translates to:
  /// **'No transactions or events on this date.'**
  String get calendarNoActivityDate;

  /// No description provided for @calendarTruncatedNotice.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 1,000 entries for this month.'**
  String get calendarTruncatedNotice;

  /// No description provided for @currenciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Currencies & FX Markets'**
  String get currenciesTitle;

  /// No description provided for @currenciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live mid-market rates, multi-currency impact, and risk tools.'**
  String get currenciesSubtitle;

  /// No description provided for @currenciesLiveActive.
  ///
  /// In en, this message translates to:
  /// **'Live Rates Active'**
  String get currenciesLiveActive;

  /// No description provided for @currenciesFeedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Feed Unavailable'**
  String get currenciesFeedUnavailable;

  /// No description provided for @currenciesViewPrefix.
  ///
  /// In en, this message translates to:
  /// **'View:'**
  String get currenciesViewPrefix;

  /// No description provided for @currenciesBasePrefix.
  ///
  /// In en, this message translates to:
  /// **'Base: {code}'**
  String currenciesBasePrefix(String code);

  /// No description provided for @currenciesRegionAll.
  ///
  /// In en, this message translates to:
  /// **'All Pairs'**
  String get currenciesRegionAll;

  /// No description provided for @currenciesRegionMajors.
  ///
  /// In en, this message translates to:
  /// **'Majors'**
  String get currenciesRegionMajors;

  /// No description provided for @currenciesRegionMena.
  ///
  /// In en, this message translates to:
  /// **'MENA / Gulf'**
  String get currenciesRegionMena;

  /// No description provided for @currenciesRegionAsia.
  ///
  /// In en, this message translates to:
  /// **'Asia-Pac'**
  String get currenciesRegionAsia;

  /// No description provided for @currenciesTabMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get currenciesTabMarkets;

  /// No description provided for @currenciesTabSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated Tick'**
  String get currenciesTabSimulated;

  /// No description provided for @currenciesTabRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk Simulator'**
  String get currenciesTabRisk;

  /// No description provided for @currenciesTabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Local Alerts'**
  String get currenciesTabAlerts;

  /// No description provided for @currenciesTabDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get currenciesTabDirectory;

  /// No description provided for @currenciesFeaturedPairs.
  ///
  /// In en, this message translates to:
  /// **'Featured Pairs'**
  String get currenciesFeaturedPairs;

  /// No description provided for @currenciesChartModeHistory.
  ///
  /// In en, this message translates to:
  /// **'Historical Trajectory'**
  String get currenciesChartModeHistory;

  /// No description provided for @currenciesChartModeSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated 1s Tick'**
  String get currenciesChartModeSimulated;

  /// No description provided for @currenciesSimulatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Simulated 1s Tick (Anchored to Spot)'**
  String get currenciesSimulatedBadge;

  /// No description provided for @currenciesSimulatedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Client-side micro-tick simulation anchored to the live mid-market spot rate (not an exchange orderbook).'**
  String get currenciesSimulatedTooltip;

  /// No description provided for @currenciesSimulatedTrendCaption.
  ///
  /// In en, this message translates to:
  /// **'Simulated Trend'**
  String get currenciesSimulatedTrendCaption;

  /// No description provided for @currenciesChartWave.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get currenciesChartWave;

  /// No description provided for @currenciesChartCandles.
  ///
  /// In en, this message translates to:
  /// **'Candles'**
  String get currenciesChartCandles;

  /// No description provided for @currenciesChartBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get currenciesChartBar;

  /// No description provided for @currenciesChartLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get currenciesChartLine;

  /// No description provided for @currenciesPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get currenciesPause;

  /// No description provided for @currenciesResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get currenciesResume;

  /// No description provided for @currenciesSimulatedTrades.
  ///
  /// In en, this message translates to:
  /// **'Simulated Trades'**
  String get currenciesSimulatedTrades;

  /// No description provided for @currenciesSpreadFooter.
  ///
  /// In en, this message translates to:
  /// **'Simulated Spread: 0.04%'**
  String get currenciesSpreadFooter;

  /// No description provided for @currenciesConverterTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Currency Converter'**
  String get currenciesConverterTitle;

  /// No description provided for @currenciesYouSend.
  ///
  /// In en, this message translates to:
  /// **'You Send'**
  String get currenciesYouSend;

  /// No description provided for @currenciesYouReceive.
  ///
  /// In en, this message translates to:
  /// **'You Receive'**
  String get currenciesYouReceive;

  /// No description provided for @currenciesSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get currenciesSwap;

  /// No description provided for @currenciesMidMarketRate.
  ///
  /// In en, this message translates to:
  /// **'Mid-market rate'**
  String get currenciesMidMarketRate;

  /// No description provided for @currenciesPortfolioImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Portfolio Impact'**
  String get currenciesPortfolioImpactTitle;

  /// No description provided for @currenciesPortfolioReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Portfolio balance valuation is unavailable while workspace is read-only.'**
  String get currenciesPortfolioReadOnlyHint;

  /// No description provided for @currenciesRiskAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Foreign Invoice Amount'**
  String get currenciesRiskAmountLabel;

  /// No description provided for @currenciesRiskCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing Currency'**
  String get currenciesRiskCurrencyLabel;

  /// No description provided for @currenciesRiskTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get currenciesRiskTermsLabel;

  /// No description provided for @currenciesRiskNetDays.
  ///
  /// In en, this message translates to:
  /// **'Net {days} Days'**
  String currenciesRiskNetDays(int days);

  /// No description provided for @currenciesRiskSpotCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Spot Valuation'**
  String get currenciesRiskSpotCardTitle;

  /// No description provided for @currenciesRiskScenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'FX Sensitivity Scenarios'**
  String get currenciesRiskScenariosTitle;

  /// No description provided for @currenciesRiskSpotLabel.
  ///
  /// In en, this message translates to:
  /// **'Spot'**
  String get currenciesRiskSpotLabel;

  /// No description provided for @currenciesAlertsLocalBanner.
  ///
  /// In en, this message translates to:
  /// **'Device-Local Alerts (Evaluated on Refresh)'**
  String get currenciesAlertsLocalBanner;

  /// No description provided for @currenciesAlertsTriggeredTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Rate Triggered'**
  String get currenciesAlertsTriggeredTitle;

  /// No description provided for @currenciesAlertsNewBtn.
  ///
  /// In en, this message translates to:
  /// **'New Alert'**
  String get currenciesAlertsNewBtn;

  /// No description provided for @currenciesAlertsPairLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency Pair'**
  String get currenciesAlertsPairLabel;

  /// No description provided for @currenciesAlertsConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get currenciesAlertsConditionLabel;

  /// No description provided for @currenciesAlertsAbove.
  ///
  /// In en, this message translates to:
  /// **'Rises above (≥)'**
  String get currenciesAlertsAbove;

  /// No description provided for @currenciesAlertsBelow.
  ///
  /// In en, this message translates to:
  /// **'Drops below (≤)'**
  String get currenciesAlertsBelow;

  /// No description provided for @currenciesAlertsTargetRate.
  ///
  /// In en, this message translates to:
  /// **'Target Rate'**
  String get currenciesAlertsTargetRate;

  /// No description provided for @currenciesAlertsSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Alert'**
  String get currenciesAlertsSaveBtn;

  /// No description provided for @currenciesAlertsInvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive target rate.'**
  String get currenciesAlertsInvalidRate;

  /// No description provided for @currenciesAlertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No target rate alerts created yet'**
  String get currenciesAlertsEmptyTitle;

  /// No description provided for @currenciesAlertsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a local target-rate alert to get notified when rates refresh.'**
  String get currenciesAlertsEmptyDesc;

  /// No description provided for @currenciesAlertsAwayPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% away'**
  String currenciesAlertsAwayPct(String pct);

  /// No description provided for @currenciesDirectorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search currency or code...'**
  String get currenciesDirectorySearchHint;

  /// No description provided for @currenciesDirectoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No currencies match \"{query}\"'**
  String currenciesDirectoryEmpty(String query);

  /// No description provided for @currenciesDirectoryConvertBtn.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get currenciesDirectoryConvertBtn;

  /// No description provided for @migrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Business Base Currency'**
  String get migrationTitle;

  /// No description provided for @migrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to future transactions with live FX preview'**
  String get migrationSubtitle;

  /// No description provided for @migrationTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Base Currency'**
  String get migrationTargetLabel;

  /// No description provided for @migrationFetchingPreview.
  ///
  /// In en, this message translates to:
  /// **'Fetching real-time market exchange rate...'**
  String get migrationFetchingPreview;

  /// No description provided for @migrationLiveMarketRate.
  ///
  /// In en, this message translates to:
  /// **'Live Market Rate'**
  String get migrationLiveMarketRate;

  /// No description provided for @migrationCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Net Balance'**
  String get migrationCurrentBalance;

  /// No description provided for @migrationProjectedBalance.
  ///
  /// In en, this message translates to:
  /// **'Projected Equivalent'**
  String get migrationProjectedBalance;

  /// No description provided for @migrationPreservedLabel.
  ///
  /// In en, this message translates to:
  /// **'Historical Transactions Preserved'**
  String get migrationPreservedLabel;

  /// No description provided for @migrationPreservedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transaction(s)'**
  String migrationPreservedCount(int count);

  /// No description provided for @migrationImmutabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Historical Financial Immutability Enforced'**
  String get migrationImmutabilityTitle;

  /// No description provided for @migrationImmutabilityBody.
  ///
  /// In en, this message translates to:
  /// **'Updating your business base currency to {newCurrency} applies to future transactions only. All {count} existing historical transaction(s) preserve their original currency and locked FX snapshots.'**
  String migrationImmutabilityBody(String newCurrency, int count);

  /// No description provided for @migrationConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Currency Change'**
  String get migrationConfirmBtn;

  /// No description provided for @migrationUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get migrationUpdating;

  /// No description provided for @migrationPermissionNotice.
  ///
  /// In en, this message translates to:
  /// **'Only workspace Owners or Admins on an editable workspace can change base currency.'**
  String get migrationPermissionNotice;

  /// No description provided for @migrationSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Base currency updated to {newCurrency}. Historical records preserved.'**
  String migrationSuccessToast(String newCurrency);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Reports'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze P&L statements, cash flow velocity, and period comparisons.'**
  String get reportsSubtitle;

  /// No description provided for @reportsMonthlyQuota.
  ///
  /// In en, this message translates to:
  /// **'Monthly Exports: {used} / {limit}'**
  String reportsMonthlyQuota(int used, int limit);

  /// No description provided for @reportsMonthlyUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Monthly Exports: Unlimited'**
  String get reportsMonthlyUnlimited;

  /// No description provided for @reportsExplainBtn.
  ///
  /// In en, this message translates to:
  /// **'Explain Report'**
  String get reportsExplainBtn;

  /// No description provided for @reportsExportCsvBtn.
  ///
  /// In en, this message translates to:
  /// **'Export P&L CSV'**
  String get reportsExportCsvBtn;

  /// No description provided for @reportsExportPdfBtn.
  ///
  /// In en, this message translates to:
  /// **'Export P&L PDF'**
  String get reportsExportPdfBtn;

  /// No description provided for @reportsArabicPdfWarning.
  ///
  /// In en, this message translates to:
  /// **'Server PDF exports use Latin fonts cleanly; use Export P&L CSV (UTF-8 BOM) for full Arabic text support.'**
  String get reportsArabicPdfWarning;

  /// No description provided for @reportsTabPnl.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get reportsTabPnl;

  /// No description provided for @reportsTabCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get reportsTabCashFlow;

  /// No description provided for @reportsTabComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get reportsTabComparison;

  /// No description provided for @reportsPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reportsPeriodThisMonth;

  /// No description provided for @reportsPeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get reportsPeriodLastMonth;

  /// No description provided for @reportsPeriodThisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get reportsPeriodThisQuarter;

  /// No description provided for @reportsPeriodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get reportsPeriodThisYear;

  /// No description provided for @reportsPeriodLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get reportsPeriodLastYear;

  /// No description provided for @reportsPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get reportsPeriodCustom;

  /// No description provided for @reportsPrimaryPeriod.
  ///
  /// In en, this message translates to:
  /// **'Primary Period'**
  String get reportsPrimaryPeriod;

  /// No description provided for @reportsCompareAgainst.
  ///
  /// In en, this message translates to:
  /// **'Compare Against'**
  String get reportsCompareAgainst;

  /// No description provided for @reportsIdenticalPeriodsHint.
  ///
  /// In en, this message translates to:
  /// **'Comparing identical periods.'**
  String get reportsIdenticalPeriodsHint;

  /// No description provided for @reportsGatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Report Requires Upgrade'**
  String get reportsGatedTitle;

  /// No description provided for @reportsGatedBtn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan Now'**
  String get reportsGatedBtn;

  /// No description provided for @reportsPnlRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get reportsPnlRevenue;

  /// No description provided for @reportsPnlExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get reportsPnlExpenses;

  /// No description provided for @reportsPnlNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Net Operating Income'**
  String get reportsPnlNetIncome;

  /// No description provided for @reportsPnlMargin.
  ///
  /// In en, this message translates to:
  /// **'Net Profit Margin'**
  String get reportsPnlMargin;

  /// No description provided for @reportsPnlCashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get reportsPnlCashReceived;

  /// No description provided for @reportsPnlCashSpent.
  ///
  /// In en, this message translates to:
  /// **'Cash spent'**
  String get reportsPnlCashSpent;

  /// No description provided for @reportsPnlPositiveMargin.
  ///
  /// In en, this message translates to:
  /// **'Positive margin'**
  String get reportsPnlPositiveMargin;

  /// No description provided for @reportsPnlDeficit.
  ///
  /// In en, this message translates to:
  /// **'Operating deficit'**
  String get reportsPnlDeficit;

  /// No description provided for @reportsPnlRevByCategory.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Category'**
  String get reportsPnlRevByCategory;

  /// No description provided for @reportsPnlExpByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Category'**
  String get reportsPnlExpByCategory;

  /// No description provided for @reportsPnlNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income recorded for this period.'**
  String get reportsPnlNoIncome;

  /// No description provided for @reportsPnlNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded for this period.'**
  String get reportsPnlNoExpenses;

  /// No description provided for @reportsCfInflow.
  ///
  /// In en, this message translates to:
  /// **'Total Cash Inflow'**
  String get reportsCfInflow;

  /// No description provided for @reportsCfOutflow.
  ///
  /// In en, this message translates to:
  /// **'Total Cash Outflow'**
  String get reportsCfOutflow;

  /// No description provided for @reportsCfNetChange.
  ///
  /// In en, this message translates to:
  /// **'Net Cash Change'**
  String get reportsCfNetChange;

  /// No description provided for @reportsCfTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'6-Month Cash Flow Trend (Trailing 6 Months)'**
  String get reportsCfTrendTitle;

  /// No description provided for @reportsCfTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cash flow activity in the last 6 months.'**
  String get reportsCfTrendEmpty;

  /// No description provided for @reportsCompRevGrowth.
  ///
  /// In en, this message translates to:
  /// **'Revenue Growth'**
  String get reportsCompRevGrowth;

  /// No description provided for @reportsCompExpChange.
  ///
  /// In en, this message translates to:
  /// **'Expense Change'**
  String get reportsCompExpChange;

  /// No description provided for @reportsCompNetChange.
  ///
  /// In en, this message translates to:
  /// **'Net Income Change'**
  String get reportsCompNetChange;

  /// No description provided for @reportsSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get reportsSelectDateRange;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'AFAB Copilot'**
  String get aiTitle;

  /// No description provided for @aiLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading AFAB Copilot...'**
  String get aiLoading;

  /// No description provided for @aiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private local intelligence grounded in your business ledger.'**
  String get aiSubtitle;

  /// No description provided for @aiBadge.
  ///
  /// In en, this message translates to:
  /// **'Hybrid RAG'**
  String get aiBadge;

  /// No description provided for @aiHeroBadge.
  ///
  /// In en, this message translates to:
  /// **'100% Private Local Intelligence'**
  String get aiHeroBadge;

  /// No description provided for @aiHeroTitleStart.
  ///
  /// In en, this message translates to:
  /// **'Financial clarity for '**
  String get aiHeroTitleStart;

  /// No description provided for @aiHeroTitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'every decision.'**
  String get aiHeroTitleHighlight;

  /// No description provided for @aiCapPrivate.
  ///
  /// In en, this message translates to:
  /// **'On-device Ollama privacy'**
  String get aiCapPrivate;

  /// No description provided for @aiCapMath.
  ///
  /// In en, this message translates to:
  /// **'Verified BigDecimal tools'**
  String get aiCapMath;

  /// No description provided for @aiCapMultilingual.
  ///
  /// In en, this message translates to:
  /// **'EN · AR · FR · Tunisian Derja'**
  String get aiCapMultilingual;

  /// No description provided for @aiAttachLabel.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get aiAttachLabel;

  /// No description provided for @aiListeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get aiListeningLabel;

  /// No description provided for @aiNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get aiNewChat;

  /// No description provided for @aiHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get aiHistoryTitle;

  /// No description provided for @aiSearchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get aiSearchConversations;

  /// No description provided for @aiGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get aiGroupToday;

  /// No description provided for @aiGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get aiGroupYesterday;

  /// No description provided for @aiGroupWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous 7 days'**
  String get aiGroupWeek;

  /// No description provided for @aiGroupEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get aiGroupEarlier;

  /// No description provided for @aiToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle history sidebar'**
  String get aiToggleSidebar;

  /// No description provided for @aiNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet for this business.'**
  String get aiNoConversations;

  /// No description provided for @aiDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get aiDeleteConversation;

  /// No description provided for @aiDeleteConvConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get aiDeleteConvConfirmTitle;

  /// No description provided for @aiDeleteConvConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from conversation history? This cannot be undone.'**
  String aiDeleteConvConfirmDesc(String title);

  /// No description provided for @aiMemoryButton.
  ///
  /// In en, this message translates to:
  /// **'Business Memory'**
  String get aiMemoryButton;

  /// No description provided for @aiSyncIndexButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Index'**
  String get aiSyncIndexButton;

  /// No description provided for @aiSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get aiSyncing;

  /// No description provided for @aiSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'RAG index synced ({indexed} updated, {embeddings} embedded).'**
  String aiSyncSuccess(int indexed, int embeddings);

  /// No description provided for @aiSyncError.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync RAG index.'**
  String get aiSyncError;

  /// No description provided for @aiModelReady.
  ///
  /// In en, this message translates to:
  /// **'Model Ready'**
  String get aiModelReady;

  /// No description provided for @aiModelOffline.
  ///
  /// In en, this message translates to:
  /// **'Local Ollama Offline'**
  String get aiModelOffline;

  /// No description provided for @aiModelMissing.
  ///
  /// In en, this message translates to:
  /// **'Pull Model Required'**
  String get aiModelMissing;

  /// No description provided for @aiOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Local AI Runtime Offline'**
  String get aiOfflineTitle;

  /// No description provided for @aiOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'AFAB Copilot runs 100% privately via your local Ollama server. Start Ollama and ensure both models are installed:'**
  String get aiOfflineDescription;

  /// No description provided for @aiTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Tokens'**
  String get aiTokensLabel;

  /// No description provided for @aiQueriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Queries'**
  String get aiQueriesLabel;

  /// No description provided for @aiRemaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get aiRemaining;

  /// No description provided for @aiUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get aiUnlimited;

  /// No description provided for @aiUpgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get aiUpgradeCta;

  /// No description provided for @aiQuotaExhaustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly AI Allowance Reached'**
  String get aiQuotaExhaustedTitle;

  /// No description provided for @aiQuotaExhaustedDesc.
  ///
  /// In en, this message translates to:
  /// **'You have reached your current plan\'s monthly AI token or query allowance.'**
  String get aiQuotaExhaustedDesc;

  /// No description provided for @aiQuotaRatio.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit}'**
  String aiQuotaRatio(String used, String limit);

  /// No description provided for @aiWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial clarity for every decision'**
  String get aiWelcomeTitle;

  /// No description provided for @aiWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private local AI CFO grounded in your real ledger, invoices, receipts & files.'**
  String get aiWelcomeSubtitle;

  /// No description provided for @aiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask your AI CFO, drop a receipt, or write in EN / FR / AR / Derja...'**
  String get aiPlaceholder;

  /// No description provided for @aiComposerFooter.
  ///
  /// In en, this message translates to:
  /// **'100% local Gemma 4 · Attach images, PDF, Excel or CSV'**
  String get aiComposerFooter;

  /// No description provided for @aiComposerLanguages.
  ///
  /// In en, this message translates to:
  /// **'EN · AR · FR · Derja'**
  String get aiComposerLanguages;

  /// No description provided for @aiScrollToBottom.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest message'**
  String get aiScrollToBottom;

  /// No description provided for @aiFollowUpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested follow-ups'**
  String get aiFollowUpsLabel;

  /// No description provided for @aiYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get aiYou;

  /// No description provided for @aiCopilotName.
  ///
  /// In en, this message translates to:
  /// **'AFAB Copilot'**
  String get aiCopilotName;

  /// No description provided for @aiCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiCopy;

  /// No description provided for @aiCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiCopied;

  /// No description provided for @aiRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiRegenerate;

  /// No description provided for @aiSourcesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verified'**
  String aiSourcesCount(int count);

  /// No description provided for @aiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiSend;

  /// No description provided for @aiStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get aiStop;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Analyzing verified financial tools...'**
  String get aiThinking;

  /// No description provided for @aiStreamingLabel.
  ///
  /// In en, this message translates to:
  /// **'Live response'**
  String get aiStreamingLabel;

  /// No description provided for @aiToolRunning.
  ///
  /// In en, this message translates to:
  /// **'Running tool'**
  String get aiToolRunning;

  /// No description provided for @aiToolDone.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get aiToolDone;

  /// No description provided for @aiElapsedSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String aiElapsedSeconds(String seconds);

  /// No description provided for @aiPhaseMemory.
  ///
  /// In en, this message translates to:
  /// **'Recalling Business Memory & semantic context...'**
  String get aiPhaseMemory;

  /// No description provided for @aiPhaseLedger.
  ///
  /// In en, this message translates to:
  /// **'Inspecting ledger & selecting verified finance tools...'**
  String get aiPhaseLedger;

  /// No description provided for @aiPhaseSynthesis.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing executive financial insight...'**
  String get aiPhaseSynthesis;

  /// No description provided for @aiPhaseWarmingModel.
  ///
  /// In en, this message translates to:
  /// **'Warming up local Gemma 4 model on GPU (first turn takes ~10–15s)...'**
  String get aiPhaseWarmingModel;

  /// No description provided for @aiLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live AI Model Availability'**
  String get aiLiveTitle;

  /// No description provided for @aiLiveRealtimeBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get aiLiveRealtimeBadge;

  /// No description provided for @aiLiveBackendLabel.
  ///
  /// In en, this message translates to:
  /// **'AFAB Backend API'**
  String get aiLiveBackendLabel;

  /// No description provided for @aiLiveOllamaLabel.
  ///
  /// In en, this message translates to:
  /// **'Local Ollama Runtime'**
  String get aiLiveOllamaLabel;

  /// No description provided for @aiLiveChatModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat Model'**
  String get aiLiveChatModelLabel;

  /// No description provided for @aiLiveEmbedModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Embedding Model'**
  String get aiLiveEmbedModelLabel;

  /// No description provided for @aiLiveConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get aiLiveConnected;

  /// No description provided for @aiLiveReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get aiLiveReconnecting;

  /// No description provided for @aiLiveOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get aiLiveOnline;

  /// No description provided for @aiLiveOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get aiLiveOffline;

  /// No description provided for @aiLiveHotInGpu.
  ///
  /// In en, this message translates to:
  /// **'Hot in GPU'**
  String get aiLiveHotInGpu;

  /// No description provided for @aiLiveHotShort.
  ///
  /// In en, this message translates to:
  /// **'Hot GPU'**
  String get aiLiveHotShort;

  /// No description provided for @aiLiveColdShort.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get aiLiveColdShort;

  /// No description provided for @aiLiveReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get aiLiveReadyShort;

  /// No description provided for @aiLiveBusy.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get aiLiveBusy;

  /// No description provided for @aiLiveMissing.
  ///
  /// In en, this message translates to:
  /// **'Not Pulled'**
  String get aiLiveMissing;

  /// No description provided for @aiLiveBackendOffline.
  ///
  /// In en, this message translates to:
  /// **'Backend Offline'**
  String get aiLiveBackendOffline;

  /// No description provided for @aiLiveChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get aiLiveChecking;

  /// No description provided for @aiLiveCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check Now'**
  String get aiLiveCheckNow;

  /// No description provided for @aiLiveLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get aiLiveLastChecked;

  /// No description provided for @aiToolBusinessSummary.
  ///
  /// In en, this message translates to:
  /// **'Auditing P&L summary'**
  String get aiToolBusinessSummary;

  /// No description provided for @aiToolComparePeriods.
  ///
  /// In en, this message translates to:
  /// **'Comparing date periods'**
  String get aiToolComparePeriods;

  /// No description provided for @aiToolCategoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breaking down categories'**
  String get aiToolCategoryBreakdown;

  /// No description provided for @aiToolSearchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Searching ledger transactions'**
  String get aiToolSearchTransactions;

  /// No description provided for @aiToolInvoicesOverview.
  ///
  /// In en, this message translates to:
  /// **'Inspecting receivables & invoices'**
  String get aiToolInvoicesOverview;

  /// No description provided for @aiToolCustomersOverview.
  ///
  /// In en, this message translates to:
  /// **'Analyzing customer revenue'**
  String get aiToolCustomersOverview;

  /// No description provided for @aiToolBudgetsStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking budget utilization'**
  String get aiToolBudgetsStatus;

  /// No description provided for @aiToolRecurringCommitments.
  ///
  /// In en, this message translates to:
  /// **'Reviewing recurring commitments'**
  String get aiToolRecurringCommitments;

  /// No description provided for @aiToolDataCoverage.
  ///
  /// In en, this message translates to:
  /// **'Verifying data domain coverage'**
  String get aiToolDataCoverage;

  /// No description provided for @aiToolCashflowForecast.
  ///
  /// In en, this message translates to:
  /// **'Running deterministic cashflow simulation'**
  String get aiToolCashflowForecast;

  /// No description provided for @aiToolFinancialPulse.
  ///
  /// In en, this message translates to:
  /// **'Scanning financial anomalies & pulse'**
  String get aiToolFinancialPulse;

  /// No description provided for @aiToolProposeTransaction.
  ///
  /// In en, this message translates to:
  /// **'Preparing transaction draft card'**
  String get aiToolProposeTransaction;

  /// No description provided for @aiToolProposeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Preparing invoice draft card'**
  String get aiToolProposeInvoice;

  /// No description provided for @aiToolProposeBudget.
  ///
  /// In en, this message translates to:
  /// **'Preparing budget draft card'**
  String get aiToolProposeBudget;

  /// No description provided for @aiToolProposeReminder.
  ///
  /// In en, this message translates to:
  /// **'Drafting grounded payment reminder'**
  String get aiToolProposeReminder;

  /// No description provided for @aiToolProposeMemory.
  ///
  /// In en, this message translates to:
  /// **'Preparing Business Memory rule'**
  String get aiToolProposeMemory;

  /// No description provided for @aiToolFallback.
  ///
  /// In en, this message translates to:
  /// **'Executing verified finance check'**
  String get aiToolFallback;

  /// No description provided for @aiFastMode.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get aiFastMode;

  /// No description provided for @aiDeepMode.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get aiDeepMode;

  /// No description provided for @aiDeepModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Deep Analysis'**
  String get aiDeepModeBadge;

  /// No description provided for @aiDeepThinkingLive.
  ///
  /// In en, this message translates to:
  /// **'Reasoning step-by-step...'**
  String get aiDeepThinkingLive;

  /// No description provided for @aiReasoningTrace.
  ///
  /// In en, this message translates to:
  /// **'Copilot Reasoning'**
  String get aiReasoningTrace;

  /// No description provided for @aiMorningBriefButton.
  ///
  /// In en, this message translates to:
  /// **'Morning CFO Brief'**
  String get aiMorningBriefButton;

  /// No description provided for @aiMorningBriefPrompt.
  ///
  /// In en, this message translates to:
  /// **'Run get_financial_pulse and get_business_summary to give me a crisp Morning CFO Brief covering today\'s net cashflow, any spending spikes, duplicate risks, budget burn-rate alerts, missing receipts, and overdue invoices.'**
  String get aiMorningBriefPrompt;

  /// No description provided for @aiDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'AFAB Copilot'**
  String get aiDrawerTitle;

  /// No description provided for @aiDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick financial analysis, drafts & files'**
  String get aiDrawerSubtitle;

  /// No description provided for @aiDrawerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask AFAB Copilot anything'**
  String get aiDrawerEmptyTitle;

  /// No description provided for @aiDrawerEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Snap a receipt photo or attach a PDF/Excel/CSV file, dictate with your mic, or ask for forecasts, draft invoices, or payment reminders.'**
  String get aiDrawerEmptyDesc;

  /// No description provided for @aiOpenWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Full View'**
  String get aiOpenWorkspace;

  /// No description provided for @aiLangEn.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get aiLangEn;

  /// No description provided for @aiLangFr.
  ///
  /// In en, this message translates to:
  /// **'FR'**
  String get aiLangFr;

  /// No description provided for @aiLangArMsa.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get aiLangArMsa;

  /// No description provided for @aiLangDerjaScript.
  ///
  /// In en, this message translates to:
  /// **'دارجة'**
  String get aiLangDerjaScript;

  /// No description provided for @aiLangDerjaArabizi.
  ///
  /// In en, this message translates to:
  /// **'Derja'**
  String get aiLangDerjaArabizi;

  /// No description provided for @aiAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach receipt image or document'**
  String get aiAttachTitle;

  /// No description provided for @aiAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Receipt Photo'**
  String get aiAttachCamera;

  /// No description provided for @aiAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get aiAttachGallery;

  /// No description provided for @aiAttachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document (PDF, XLSX, CSV, TXT, JSON)'**
  String get aiAttachDocument;

  /// No description provided for @aiAttachMaxThree.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 attachments per message.'**
  String get aiAttachMaxThree;

  /// No description provided for @aiAttachSupportedHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, WEBP, PDF, XLSX, CSV, TXT, JSON (≤ 10 MB)'**
  String get aiAttachSupportedHint;

  /// No description provided for @aiAttachUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload attachment.'**
  String get aiAttachUploadFailed;

  /// No description provided for @aiVoiceStart.
  ///
  /// In en, this message translates to:
  /// **'Start voice dictation'**
  String get aiVoiceStart;

  /// No description provided for @aiVoiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get aiVoiceStop;

  /// No description provided for @aiVoiceSwitchLang.
  ///
  /// In en, this message translates to:
  /// **'Cycle dictation language (EN / FR / TN)'**
  String get aiVoiceSwitchLang;

  /// No description provided for @aiVoicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access denied. Enable microphone permissions to dictate.'**
  String get aiVoicePermissionDenied;

  /// No description provided for @aiVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition unavailable on this device.'**
  String get aiVoiceUnavailable;

  /// No description provided for @aiVoiceError.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition interrupted. Please try again.'**
  String get aiVoiceError;

  /// No description provided for @aiDraftPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Review & Approve'**
  String get aiDraftPendingReview;

  /// No description provided for @aiDraftReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been saved yet. Edit fields below and tap Approve & Save.'**
  String get aiDraftReviewHint;

  /// No description provided for @aiDraftSavedBadge.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get aiDraftSavedBadge;

  /// No description provided for @aiDraftDismissedBadge.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get aiDraftDismissedBadge;

  /// No description provided for @aiDraftViewRecord.
  ///
  /// In en, this message translates to:
  /// **'View Record'**
  String get aiDraftViewRecord;

  /// No description provided for @aiDraftApproveSave.
  ///
  /// In en, this message translates to:
  /// **'Approve & Save'**
  String get aiDraftApproveSave;

  /// No description provided for @aiDraftDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get aiDraftDismiss;

  /// No description provided for @aiDraftSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get aiDraftSaving;

  /// No description provided for @aiDraftApprovedToast.
  ///
  /// In en, this message translates to:
  /// **'Record approved and saved!'**
  String get aiDraftApprovedToast;

  /// No description provided for @aiDraftApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save approved draft.'**
  String get aiDraftApproveFailed;

  /// No description provided for @aiDraftDismissFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to dismiss draft.'**
  String get aiDraftDismissFailed;

  /// No description provided for @aiDraftInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive amount.'**
  String get aiDraftInvalidAmount;

  /// No description provided for @aiDraftReceiptLinked.
  ///
  /// In en, this message translates to:
  /// **'Receipt attached from chat'**
  String get aiDraftReceiptLinked;

  /// No description provided for @aiDraftReceiptWillSave.
  ///
  /// In en, this message translates to:
  /// **'Will be archived into Receipts & indexed on save.'**
  String get aiDraftReceiptWillSave;

  /// No description provided for @aiDraftType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get aiDraftType;

  /// No description provided for @aiDraftAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get aiDraftAmount;

  /// No description provided for @aiDraftCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get aiDraftCurrency;

  /// No description provided for @aiDraftDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get aiDraftDescription;

  /// No description provided for @aiDraftDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get aiDraftDate;

  /// No description provided for @aiDraftCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get aiDraftCategory;

  /// No description provided for @aiDraftPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get aiDraftPaymentMethod;

  /// No description provided for @aiDraftNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get aiDraftNotes;

  /// No description provided for @aiDraftCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get aiDraftCustomer;

  /// No description provided for @aiDraftIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get aiDraftIssueDate;

  /// No description provided for @aiDraftDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get aiDraftDueDate;

  /// No description provided for @aiDraftTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get aiDraftTotal;

  /// No description provided for @aiDraftIssueImmediately.
  ///
  /// In en, this message translates to:
  /// **'Issue immediately (mark UNPAID)'**
  String get aiDraftIssueImmediately;

  /// No description provided for @aiDraftBudgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get aiDraftBudgetName;

  /// No description provided for @aiDraftPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get aiDraftPeriod;

  /// No description provided for @aiDraftAlertPct.
  ///
  /// In en, this message translates to:
  /// **'Alert %'**
  String get aiDraftAlertPct;

  /// No description provided for @aiReminderCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get aiReminderCopy;

  /// No description provided for @aiReminderCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiReminderCopied;

  /// No description provided for @aiReminderOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Open Email'**
  String get aiReminderOpenEmail;

  /// No description provided for @aiReminderOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get aiReminderOpenWhatsapp;

  /// No description provided for @aiReminderSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get aiReminderSubject;

  /// No description provided for @aiMemoryProposalHeading.
  ///
  /// In en, this message translates to:
  /// **'Save to Business Memory?'**
  String get aiMemoryProposalHeading;

  /// No description provided for @aiMemoryProposalIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get aiMemoryProposalIgnore;

  /// No description provided for @aiMemoryProposalRemember.
  ///
  /// In en, this message translates to:
  /// **'Approve & Remember'**
  String get aiMemoryProposalRemember;

  /// No description provided for @aiMemoryProposalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to Business Memory'**
  String get aiMemoryProposalSaved;

  /// No description provided for @aiMemoryProposalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save Business Memory.'**
  String get aiMemoryProposalSaveFailed;

  /// No description provided for @aiEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Sources & Evidence'**
  String get aiEvidenceTitle;

  /// No description provided for @aiCoveragePartial.
  ///
  /// In en, this message translates to:
  /// **'Ledger & Invoices Grounded (Bank balances & supplier AP not tracked yet)'**
  String get aiCoveragePartial;

  /// No description provided for @aiCoverageRag.
  ///
  /// In en, this message translates to:
  /// **'Grounded in Business Memory & Indexed Records'**
  String get aiCoverageRag;

  /// No description provided for @aiTokensUsedBadge.
  ///
  /// In en, this message translates to:
  /// **'{tokens} tokens'**
  String aiTokensUsedBadge(String tokens);

  /// No description provided for @aiPulseMonthNet.
  ///
  /// In en, this message translates to:
  /// **'Month Net'**
  String get aiPulseMonthNet;

  /// No description provided for @aiPulseOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get aiPulseOverdue;

  /// No description provided for @aiPulseAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get aiPulseAlerts;

  /// No description provided for @aiPulseAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get aiPulseAllClear;

  /// No description provided for @aiPulseHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get aiPulseHealthy;

  /// No description provided for @aiPromptPnlTag.
  ///
  /// In en, this message translates to:
  /// **'P&L Performance'**
  String get aiPromptPnlTag;

  /// No description provided for @aiPromptPnlTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Profit & Loss'**
  String get aiPromptPnlTitle;

  /// No description provided for @aiPromptPnlShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare revenue, expenses & margin vs last month'**
  String get aiPromptPnlShortDesc;

  /// No description provided for @aiPromptPnlText.
  ///
  /// In en, this message translates to:
  /// **'Give me a crisp executive breakdown of my revenue, expenses, and net profit this month compared to last month.'**
  String get aiPromptPnlText;

  /// No description provided for @aiPromptForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'90-Day Cashflow Forecast'**
  String get aiPromptForecastTitle;

  /// No description provided for @aiPromptForecastShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Project runway & simulate hiring or late payments'**
  String get aiPromptForecastShortDesc;

  /// No description provided for @aiPromptForecastText.
  ///
  /// In en, this message translates to:
  /// **'Run a deterministic 90-day cashflow forecast using my recent averages, recurring commitments, and unpaid invoices, and show a projection chart.'**
  String get aiPromptForecastText;

  /// No description provided for @aiPromptScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt or Import File'**
  String get aiPromptScanTitle;

  /// No description provided for @aiPromptScanShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload a receipt photo, PDF, Excel or CSV to inspect'**
  String get aiPromptScanShortDesc;

  /// No description provided for @aiPromptScanBadge.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get aiPromptScanBadge;

  /// No description provided for @aiPromptInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue Invoices & Cash'**
  String get aiPromptInvoicesTitle;

  /// No description provided for @aiPromptInvoicesText.
  ///
  /// In en, this message translates to:
  /// **'Which customer invoices are currently unpaid or overdue, and what is the total outstanding balance?'**
  String get aiPromptInvoicesText;

  /// No description provided for @aiPromptBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Health Check'**
  String get aiPromptBudgetsTitle;

  /// No description provided for @aiPromptBudgetsText.
  ///
  /// In en, this message translates to:
  /// **'Check all my active budgets right now and highlight any approaching or exceeding their limit.'**
  String get aiPromptBudgetsText;

  /// No description provided for @aiPromptDerjaTitle.
  ///
  /// In en, this message translates to:
  /// **'Derja / Multilingual Check'**
  String get aiPromptDerjaTitle;

  /// No description provided for @aiPromptDerjaShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask in English, French, Arabic or Tunisian Derja'**
  String get aiPromptDerjaShortDesc;

  /// No description provided for @aiPromptDerjaText.
  ///
  /// In en, this message translates to:
  /// **'Kadeh sraft hal chhar w chniya akther masarif?'**
  String get aiPromptDerjaText;

  /// No description provided for @aiPromptQuickCaptureChip.
  ///
  /// In en, this message translates to:
  /// **'Log an expense by chat'**
  String get aiPromptQuickCaptureChip;

  /// No description provided for @aiPromptQuickCapturePrefill.
  ///
  /// In en, this message translates to:
  /// **'Log expense: '**
  String get aiPromptQuickCapturePrefill;

  /// No description provided for @aiMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Memory'**
  String get aiMemoryTitle;

  /// No description provided for @aiMemorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Teach AFAB recurring supplier patterns, seasonal context, and categorization rules scoped strictly to this business.'**
  String get aiMemorySubtitle;

  /// No description provided for @aiMemoryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Memory'**
  String get aiMemoryAddTitle;

  /// No description provided for @aiMemoryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
  String get aiMemoryEditTitle;

  /// No description provided for @aiMemoryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Short Title'**
  String get aiMemoryTitleLabel;

  /// No description provided for @aiMemoryTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. High sales season before Eid'**
  String get aiMemoryTitlePlaceholder;

  /// No description provided for @aiMemoryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory Type'**
  String get aiMemoryTypeLabel;

  /// No description provided for @aiMemoryStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle Status'**
  String get aiMemoryStatusLabel;

  /// No description provided for @aiMemoryContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Context / Fact'**
  String get aiMemoryContentLabel;

  /// No description provided for @aiMemoryContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Supplier STEG bills electricity every two months; classify as Utilities.'**
  String get aiMemoryContentPlaceholder;

  /// No description provided for @aiMemorySaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save & Vectorize'**
  String get aiMemorySaveButton;

  /// No description provided for @aiMemorySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get aiMemorySaveChanges;

  /// No description provided for @aiMemorySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get aiMemorySaving;

  /// No description provided for @aiMemoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No business memories added yet. Add facts or supplier habits so Copilot remembers why behind the numbers.'**
  String get aiMemoryEmpty;

  /// No description provided for @aiMemoryFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memories in this status filter.'**
  String get aiMemoryFilteredEmpty;

  /// No description provided for @aiMemoryVectorReady.
  ///
  /// In en, this message translates to:
  /// **'Vectorized'**
  String get aiMemoryVectorReady;

  /// No description provided for @aiMemoryLexicalOnly.
  ///
  /// In en, this message translates to:
  /// **'Keyword Indexed'**
  String get aiMemoryLexicalOnly;

  /// No description provided for @aiMemoryApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get aiMemoryApprove;

  /// No description provided for @aiMemoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get aiMemoryDelete;

  /// No description provided for @aiMemoryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this memory?'**
  String get aiMemoryDeleteConfirmTitle;

  /// No description provided for @aiMemoryDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Copilot will stop using \"{title}\" for future answers.'**
  String aiMemoryDeleteConfirmDesc(String title);

  /// No description provided for @aiMemoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get aiMemoryFilterAll;

  /// No description provided for @aiMemoryFilterProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get aiMemoryFilterProposed;

  /// No description provided for @aiMemoryFilterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get aiMemoryFilterApproved;

  /// No description provided for @aiMemoryFilterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get aiMemoryFilterExpired;

  /// No description provided for @aiMemoryTypeBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get aiMemoryTypeBusinessProfile;

  /// No description provided for @aiMemoryTypeTransactionContext.
  ///
  /// In en, this message translates to:
  /// **'Transaction Context'**
  String get aiMemoryTypeTransactionContext;

  /// No description provided for @aiMemoryTypeSupplierPattern.
  ///
  /// In en, this message translates to:
  /// **'Supplier Pattern'**
  String get aiMemoryTypeSupplierPattern;

  /// No description provided for @aiMemoryTypeCategorizationPreference.
  ///
  /// In en, this message translates to:
  /// **'Category Rule'**
  String get aiMemoryTypeCategorizationPreference;

  /// No description provided for @aiMemoryTypeDecisionHistory.
  ///
  /// In en, this message translates to:
  /// **'Decision History'**
  String get aiMemoryTypeDecisionHistory;

  /// No description provided for @aiMemoryTypeOperationalConstraint.
  ///
  /// In en, this message translates to:
  /// **'Constraint'**
  String get aiMemoryTypeOperationalConstraint;

  /// No description provided for @aiIncompleteStreamError.
  ///
  /// In en, this message translates to:
  /// **'Copilot stream ended unexpectedly before completing. Please try again.'**
  String get aiIncompleteStreamError;

  /// No description provided for @aiAlreadyRespondingToast.
  ///
  /// In en, this message translates to:
  /// **'Copilot is already responding. Tap Stop first if you want to cancel.'**
  String get aiAlreadyRespondingToast;

  /// No description provided for @aiDismissError.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get aiDismissError;

  /// No description provided for @plansPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans & Subscription'**
  String get plansPageTitle;

  /// No description provided for @plansHeaderManage.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription & Plans'**
  String get plansHeaderManage;

  /// No description provided for @plansActiveBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Active Businesses: {count} / {limit}'**
  String plansActiveBusinesses(int count, int limit);

  /// No description provided for @plansActiveBusinessesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional businesses stay safely locked until you upgrade or swap.'**
  String get plansActiveBusinessesHint;

  /// No description provided for @plansCurrentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Plan: {name}'**
  String plansCurrentPlanLabel(String name);

  /// No description provided for @plansIntervalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Billing'**
  String get plansIntervalMonthly;

  /// No description provided for @plansIntervalYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly Billing'**
  String get plansIntervalYearly;

  /// No description provided for @plansStatusTrialing.
  ///
  /// In en, this message translates to:
  /// **'Trialing'**
  String get plansStatusTrialing;

  /// No description provided for @plansStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get plansStatusActive;

  /// No description provided for @plansStatusPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past Due'**
  String get plansStatusPastDue;

  /// No description provided for @plansStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get plansStatusCanceled;

  /// No description provided for @plansTrialCountdown.
  ///
  /// In en, this message translates to:
  /// **'7-Day Plus Trial: {days} day(s) remaining (expires {date})'**
  String plansTrialCountdown(int days, String date);

  /// No description provided for @plansRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String plansRenewsOn(String date);

  /// No description provided for @plansEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Paid access ends on {date}'**
  String plansEndsOn(String date);

  /// No description provided for @plansScheduledDowngradeBadge.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {plan}'**
  String plansScheduledDowngradeBadge(String plan);

  /// No description provided for @plansScheduledCancelBadge.
  ///
  /// In en, this message translates to:
  /// **'Canceling at period end'**
  String get plansScheduledCancelBadge;

  /// No description provided for @plansUpgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get plansUpgradeToPro;

  /// No description provided for @plansHideOptions.
  ///
  /// In en, this message translates to:
  /// **'Hide Plan Options'**
  String get plansHideOptions;

  /// No description provided for @plansChangePlan.
  ///
  /// In en, this message translates to:
  /// **'Change / Downgrade Plan'**
  String get plansChangePlan;

  /// No description provided for @plansKeepResume.
  ///
  /// In en, this message translates to:
  /// **'Keep / Resume Subscription'**
  String get plansKeepResume;

  /// No description provided for @plansCancelScheduledDowngrade.
  ///
  /// In en, this message translates to:
  /// **'Cancel Scheduled Downgrade'**
  String get plansCancelScheduledDowngrade;

  /// No description provided for @plansManageBilling.
  ///
  /// In en, this message translates to:
  /// **'Manage Billing & Payment Methods'**
  String get plansManageBilling;

  /// No description provided for @plansCancelTrial.
  ///
  /// In en, this message translates to:
  /// **'Cancel Free Trial'**
  String get plansCancelTrial;

  /// No description provided for @plansCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get plansCancelSubscription;

  /// No description provided for @plansAiMeterTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly AFAB Copilot Allowance'**
  String get plansAiMeterTitle;

  /// No description provided for @plansAiMeterSummary.
  ///
  /// In en, this message translates to:
  /// **'{tokensUsed} / {tokensLimit} tokens · {queriesUsed} / {queriesLimit} queries'**
  String plansAiMeterSummary(
    String tokensUsed,
    String tokensLimit,
    String queriesUsed,
    String queriesLimit,
  );

  /// No description provided for @plansPendingChangeDesc.
  ///
  /// In en, this message translates to:
  /// **'You keep full current entitlements until {date}.'**
  String plansPendingChangeDesc(String date);

  /// No description provided for @plansConfigureFutureBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Configure Future Businesses'**
  String get plansConfigureFutureBusinesses;

  /// No description provided for @plansGracePeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed — 3-Day Grace Period ({hours}h remaining)'**
  String plansGracePeriodTitle(int hours);

  /// No description provided for @plansGracePeriodDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your payment method in Stripe Billing Portal before paid workspaces lock.'**
  String get plansGracePeriodDesc;

  /// No description provided for @plansUpdatePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Update Payment Method'**
  String get plansUpdatePaymentMethod;

  /// No description provided for @plansOwnedWorkspacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Owned Workspace Allocation'**
  String get plansOwnedWorkspacesTitle;

  /// No description provided for @plansChangeEditableBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Change Editable Businesses'**
  String get plansChangeEditableBusinesses;

  /// No description provided for @plansPrimaryBadge.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get plansPrimaryBadge;

  /// No description provided for @plansCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get plansCurrentBadge;

  /// No description provided for @plansStatusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get plansStatusUnlocked;

  /// No description provided for @plansStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get plansStatusLocked;

  /// No description provided for @plansBillingToggleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get plansBillingToggleMonthly;

  /// No description provided for @plansBillingToggleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get plansBillingToggleYearly;

  /// No description provided for @plansSave20Badge.
  ///
  /// In en, this message translates to:
  /// **'Save 20%'**
  String get plansSave20Badge;

  /// No description provided for @plansTrialBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a 7-day free trial of Plus'**
  String get plansTrialBannerTitle;

  /// No description provided for @plansTrialBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore multi-business tracking, unlimited reports, and 150K Copilot tokens risk-free.'**
  String get plansTrialBannerDesc;

  /// No description provided for @plansMostPopularTrial.
  ///
  /// In en, this message translates to:
  /// **'Most Popular · 7-Day Trial'**
  String get plansMostPopularTrial;

  /// No description provided for @plansVipBadge.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get plansVipBadge;

  /// No description provided for @plansPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get plansPerMonth;

  /// No description provided for @plansBilledAnnually.
  ///
  /// In en, this message translates to:
  /// **'billed annually'**
  String get plansBilledAnnually;

  /// No description provided for @plansCurrentPlanBtn.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get plansCurrentPlanBtn;

  /// No description provided for @plansStartTrialBtn.
  ///
  /// In en, this message translates to:
  /// **'Start 7-Day Free Trial'**
  String get plansStartTrialBtn;

  /// No description provided for @plansUpgradeToBtn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {plan}'**
  String plansUpgradeToBtn(String plan);

  /// No description provided for @plansDowngradeToBtn.
  ///
  /// In en, this message translates to:
  /// **'Downgrade to {plan}'**
  String plansDowngradeToBtn(String plan);

  /// No description provided for @plansCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare Plans'**
  String get plansCompareTitle;

  /// No description provided for @plansHistorySubTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Change History'**
  String get plansHistorySubTitle;

  /// No description provided for @plansHistoryPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment & Invoice History'**
  String get plansHistoryPayTitle;

  /// No description provided for @plansNoPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No invoice payments recorded yet.'**
  String get plansNoPaymentsYet;

  /// No description provided for @plansNoSubHistory.
  ///
  /// In en, this message translates to:
  /// **'No subscription changes recorded yet.'**
  String get plansNoSubHistory;

  /// No description provided for @plansViewInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get plansViewInvoice;

  /// No description provided for @plansCheckoutCanceled.
  ///
  /// In en, this message translates to:
  /// **'Checkout was canceled. No charges were made.'**
  String get plansCheckoutCanceled;

  /// No description provided for @plansCheckoutVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your Stripe subscription...'**
  String get plansCheckoutVerifying;

  /// No description provided for @plansCheckoutVerified.
  ///
  /// In en, this message translates to:
  /// **'Subscription updated to {plan}!'**
  String plansCheckoutVerified(String plan);

  /// No description provided for @plansDirectUpgradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upgraded directly to {plan}!'**
  String plansDirectUpgradeSuccess(String plan);

  /// No description provided for @plansResumedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subscription resumed. Scheduled change canceled.'**
  String get plansResumedSuccess;

  /// No description provided for @plansImmediateDowngradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan switched immediately to {plan}.'**
  String plansImmediateDowngradeSuccess(String plan);

  /// No description provided for @plansScheduledDowngradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Downgrade to {plan} scheduled for period end.'**
  String plansScheduledDowngradeSuccess(String plan);

  /// No description provided for @plansBillingNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Billing service is not configured in this environment.'**
  String get plansBillingNotConfigured;

  /// No description provided for @plansLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading subscription details...'**
  String get plansLoading;

  /// No description provided for @plansTierFreeSub.
  ///
  /// In en, this message translates to:
  /// **'Starter Ledger'**
  String get plansTierFreeSub;

  /// No description provided for @plansTierFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Essential bookkeeping for solo founders getting organized.'**
  String get plansTierFreeDesc;

  /// No description provided for @plansTierPlusSub.
  ///
  /// In en, this message translates to:
  /// **'Growing Businesses'**
  String get plansTierPlusSub;

  /// No description provided for @plansTierPlusDesc.
  ///
  /// In en, this message translates to:
  /// **'Full financial automation, PDF/Excel reports, and 3 unlocked workspaces.'**
  String get plansTierPlusDesc;

  /// No description provided for @plansTierProSub.
  ///
  /// In en, this message translates to:
  /// **'Multi-Entity CFO Suite'**
  String get plansTierProSub;

  /// No description provided for @plansTierProDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum scale with 5 active businesses, unlimited exports, and custom reporting.'**
  String get plansTierProDesc;

  /// No description provided for @plansFeaturesHeader.
  ///
  /// In en, this message translates to:
  /// **'What\'s included:'**
  String get plansFeaturesHeader;

  /// No description provided for @allocationTitleDowngrade.
  ///
  /// In en, this message translates to:
  /// **'Select Editable Businesses for {plan}'**
  String allocationTitleDowngrade(String plan);

  /// No description provided for @allocationTitlePending.
  ///
  /// In en, this message translates to:
  /// **'Update Scheduled {plan} Allocation'**
  String allocationTitlePending(String plan);

  /// No description provided for @allocationTitleManage.
  ///
  /// In en, this message translates to:
  /// **'Manage Editable Business Allocation'**
  String get allocationTitleManage;

  /// No description provided for @allocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {max} business(es) to stay Active (Unlocked). Remaining businesses keep all records safely stored in Read-Only mode.'**
  String allocationSubtitle(int max);

  /// No description provided for @allocationSelectedCounter.
  ///
  /// In en, this message translates to:
  /// **'Selected {count} / {max}'**
  String allocationSelectedCounter(int count, int max);

  /// No description provided for @allocationCurrentUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Current: Active (Unlocked)'**
  String get allocationCurrentUnlocked;

  /// No description provided for @allocationCurrentLocked.
  ///
  /// In en, this message translates to:
  /// **'Current: Locked (Data Saved)'**
  String get allocationCurrentLocked;

  /// No description provided for @allocationOutcomeActive.
  ///
  /// In en, this message translates to:
  /// **'Will remain Active (Unlocked):'**
  String get allocationOutcomeActive;

  /// No description provided for @allocationOutcomeLocked.
  ///
  /// In en, this message translates to:
  /// **'Will be Locked (all data safely vaulted):'**
  String get allocationOutcomeLocked;

  /// No description provided for @allocationExactError.
  ///
  /// In en, this message translates to:
  /// **'Please select exactly {count} business(es) to continue.'**
  String allocationExactError(int count);

  /// No description provided for @allocationSubmitDowngrade.
  ///
  /// In en, this message translates to:
  /// **'Confirm Downgrade to {plan}'**
  String allocationSubmitDowngrade(String plan);

  /// No description provided for @allocationSubmitSave.
  ///
  /// In en, this message translates to:
  /// **'Save Business Allocation'**
  String get allocationSubmitSave;

  /// No description provided for @allocationUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Business workspace allocation updated.'**
  String get allocationUpdatedSuccess;

  /// No description provided for @cancelSubTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Your {plan} 7-Day Free Trial?'**
  String cancelSubTrialTitle(String plan);

  /// No description provided for @cancelSubPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Your {plan} Subscription?'**
  String cancelSubPaidTitle(String plan);

  /// No description provided for @cancelSubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review when your access ends and how your businesses will be preserved.'**
  String get cancelSubSubtitle;

  /// No description provided for @cancelSubEndAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'When paid access ends'**
  String get cancelSubEndAccessLabel;

  /// No description provided for @cancelSubEndAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep full {plan} access until {date}.'**
  String cancelSubEndAccessDesc(String plan, String date);

  /// No description provided for @cancelSubFuturePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Future payments & billing'**
  String get cancelSubFuturePayLabel;

  /// No description provided for @cancelSubTrialNoCharge.
  ///
  /// In en, this message translates to:
  /// **'No payment will be collected when your trial ends.'**
  String get cancelSubTrialNoCharge;

  /// No description provided for @cancelSubPaidNoRenew.
  ///
  /// In en, this message translates to:
  /// **'Will not renew and no additional charges will be collected.'**
  String get cancelSubPaidNoRenew;

  /// No description provided for @cancelSubBizSafeLabel.
  ///
  /// In en, this message translates to:
  /// **'What happens to your businesses'**
  String get cancelSubBizSafeLabel;

  /// No description provided for @cancelSubBizSafeDesc.
  ///
  /// In en, this message translates to:
  /// **'Zero data is deleted. 1 business remains active; additional businesses are locked with all financial data safely stored until you upgrade or swap.'**
  String get cancelSubBizSafeDesc;

  /// No description provided for @cancelSubSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Select the 1 business to keep Editable on Free (1 of {total}):'**
  String cancelSubSelectOne(int total);

  /// No description provided for @cancelSubRemainsActive.
  ///
  /// In en, this message translates to:
  /// **'Remains Active'**
  String get cancelSubRemainsActive;

  /// No description provided for @cancelSubBecomesLocked.
  ///
  /// In en, this message translates to:
  /// **'Becomes Locked'**
  String get cancelSubBecomesLocked;

  /// No description provided for @cancelSubKeepBtn.
  ///
  /// In en, this message translates to:
  /// **'Keep Subscription'**
  String get cancelSubKeepBtn;

  /// No description provided for @cancelSubConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get cancelSubConfirmBtn;

  /// No description provided for @cancelSubScheduledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cancellation scheduled for end of billing period.'**
  String get cancelSubScheduledSuccess;

  /// No description provided for @settingsHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account, workspace configuration, security, and preferences.'**
  String get settingsHubSubtitle;

  /// No description provided for @settingsGroupAccountWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Account & Workspace'**
  String get settingsGroupAccountWorkspace;

  /// No description provided for @settingsGroupSecurityPrefs.
  ///
  /// In en, this message translates to:
  /// **'Security & Preferences'**
  String get settingsGroupSecurityPrefs;

  /// No description provided for @settingsGroupDataConnections.
  ///
  /// In en, this message translates to:
  /// **'Data & Connections'**
  String get settingsGroupDataConnections;

  /// No description provided for @settingsTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsTabGeneral;

  /// No description provided for @settingsTabGeneralSub.
  ///
  /// In en, this message translates to:
  /// **'Business basics, regional formats, profile'**
  String get settingsTabGeneralSub;

  /// No description provided for @settingsTabBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get settingsTabBusinessProfile;

  /// No description provided for @settingsTabBusinessProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Company details, Tax ID (MF), address'**
  String get settingsTabBusinessProfileSub;

  /// No description provided for @settingsTabSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Billing'**
  String get settingsTabSubscription;

  /// No description provided for @settingsTabSubscriptionSub.
  ///
  /// In en, this message translates to:
  /// **'Plan limits, Stripe billing & workspaces'**
  String get settingsTabSubscriptionSub;

  /// No description provided for @settingsTabUsersPermissions.
  ///
  /// In en, this message translates to:
  /// **'Users & Permissions'**
  String get settingsTabUsersPermissions;

  /// No description provided for @settingsTabUsersPermissionsSub.
  ///
  /// In en, this message translates to:
  /// **'Team roles & active workspace members'**
  String get settingsTabUsersPermissionsSub;

  /// No description provided for @settingsTabSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & 2FA'**
  String get settingsTabSecurity;

  /// No description provided for @settingsTabSecuritySub.
  ///
  /// In en, this message translates to:
  /// **'Password, TOTP 2FA, sessions & biometrics'**
  String get settingsTabSecuritySub;

  /// No description provided for @settingsTabAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get settingsTabAppearance;

  /// No description provided for @settingsTabAppearanceSub.
  ///
  /// In en, this message translates to:
  /// **'Theme mood, accent colors, fonts & density'**
  String get settingsTabAppearanceSub;

  /// No description provided for @settingsTabSignature.
  ///
  /// In en, this message translates to:
  /// **'Wet Signature Vault'**
  String get settingsTabSignature;

  /// No description provided for @settingsTabSignatureSub.
  ///
  /// In en, this message translates to:
  /// **'Signatory stamps for invoices & exports'**
  String get settingsTabSignatureSub;

  /// No description provided for @settingsTabLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsTabLanguage;

  /// No description provided for @settingsTabLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'English / العربية & RTL layout direction'**
  String get settingsTabLanguageSub;

  /// No description provided for @settingsTabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsTabNotifications;

  /// No description provided for @settingsTabNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Email & push alert preferences'**
  String get settingsTabNotificationsSub;

  /// No description provided for @settingsTabDataExport.
  ///
  /// In en, this message translates to:
  /// **'Data & Export'**
  String get settingsTabDataExport;

  /// No description provided for @settingsTabDataExportSub.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx), Arabic PDF & P&L archives'**
  String get settingsTabDataExportSub;

  /// No description provided for @settingsTabIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsTabIntegrations;

  /// No description provided for @settingsTabIntegrationsSub.
  ///
  /// In en, this message translates to:
  /// **'Bank feeds, webhooks & external connectors'**
  String get settingsTabIntegrationsSub;

  /// No description provided for @settingsBadgeSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get settingsBadgeSoon;

  /// No description provided for @settingsBadgeLocal.
  ///
  /// In en, this message translates to:
  /// **'Device-Local'**
  String get settingsBadgeLocal;

  /// No description provided for @settingsBadge2faOn.
  ///
  /// In en, this message translates to:
  /// **'2FA On'**
  String get settingsBadge2faOn;

  /// No description provided for @settingsBadge2faOff.
  ///
  /// In en, this message translates to:
  /// **'2FA Off'**
  String get settingsBadge2faOff;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsReadOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'This workspace is in Read-Only mode. Business fields are locked, while personal account settings remain editable.'**
  String get settingsReadOnlyBanner;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of AFAB?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Your session on this device will end and local access tokens will be cleared.'**
  String get settingsSignOutConfirmDesc;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'AFAB Mobile v1.0.0'**
  String get settingsAppVersion;

  /// No description provided for @generalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettingsTitle;

  /// No description provided for @generalSettingsUnsavedBadge.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get generalSettingsUnsavedBadge;

  /// No description provided for @generalSettingsMemberNotice.
  ///
  /// In en, this message translates to:
  /// **'Only workspace Owners and Admins can modify business settings. Personal preferences below remain editable.'**
  String get generalSettingsMemberNotice;

  /// No description provided for @generalSettingsAccountCard.
  ///
  /// In en, this message translates to:
  /// **'Account Profile'**
  String get generalSettingsAccountCard;

  /// No description provided for @generalSettingsBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get generalSettingsBusinessCard;

  /// No description provided for @generalSettingsRegionalCard.
  ///
  /// In en, this message translates to:
  /// **'Regional Formats'**
  String get generalSettingsRegionalCard;

  /// No description provided for @generalSettingsPrefsCard.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get generalSettingsPrefsCard;

  /// No description provided for @generalSettingsOtherCard.
  ///
  /// In en, this message translates to:
  /// **'Other Settings'**
  String get generalSettingsOtherCard;

  /// No description provided for @generalSettingsBizName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get generalSettingsBizName;

  /// No description provided for @generalSettingsBizEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get generalSettingsBizEmail;

  /// No description provided for @generalSettingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get generalSettingsCurrency;

  /// No description provided for @generalSettingsLiveFx.
  ///
  /// In en, this message translates to:
  /// **'Live FX Engine'**
  String get generalSettingsLiveFx;

  /// No description provided for @generalSettingsTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get generalSettingsTimezone;

  /// No description provided for @generalSettingsFiscalStart.
  ///
  /// In en, this message translates to:
  /// **'Fiscal Year Start'**
  String get generalSettingsFiscalStart;

  /// No description provided for @generalSettingsAccountingCycle.
  ///
  /// In en, this message translates to:
  /// **'Active Accounting Cycle'**
  String get generalSettingsAccountingCycle;

  /// No description provided for @generalSettingsDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get generalSettingsDateFormat;

  /// No description provided for @generalSettingsNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Number Format'**
  String get generalSettingsNumberFormat;

  /// No description provided for @generalSettingsPrefAi.
  ///
  /// In en, this message translates to:
  /// **'Enable AI Insights'**
  String get generalSettingsPrefAi;

  /// No description provided for @generalSettingsPrefAiSub.
  ///
  /// In en, this message translates to:
  /// **'Show CFO Copilot pulse recommendations on your dashboard'**
  String get generalSettingsPrefAiSub;

  /// No description provided for @generalSettingsPrefCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact Mode'**
  String get generalSettingsPrefCompact;

  /// No description provided for @generalSettingsPrefCompactSub.
  ///
  /// In en, this message translates to:
  /// **'Use denser spacing across tables, lists, and form inputs'**
  String get generalSettingsPrefCompactSub;

  /// No description provided for @generalSettingsPrefAutoCat.
  ///
  /// In en, this message translates to:
  /// **'Auto-categorize Transactions'**
  String get generalSettingsPrefAutoCat;

  /// No description provided for @generalSettingsPrefAutoCatSub.
  ///
  /// In en, this message translates to:
  /// **'Suggest categories automatically using transaction descriptions'**
  String get generalSettingsPrefAutoCatSub;

  /// No description provided for @generalSettingsPrefTips.
  ///
  /// In en, this message translates to:
  /// **'Show Tips & Tutorials'**
  String get generalSettingsPrefTips;

  /// No description provided for @generalSettingsPrefTipsSub.
  ///
  /// In en, this message translates to:
  /// **'Display helpful onboarding hints across modules'**
  String get generalSettingsPrefTipsSub;

  /// No description provided for @generalSettingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get generalSettingsExportData;

  /// No description provided for @generalSettingsExportDataSub.
  ///
  /// In en, this message translates to:
  /// **'Download a complete GDPR JSON snapshot of your account & ledgers'**
  String get generalSettingsExportDataSub;

  /// No description provided for @generalSettingsExportComplete.
  ///
  /// In en, this message translates to:
  /// **'Exported {bizCount} workspace(s), {txCount} transactions & {sessCount} session(s).'**
  String generalSettingsExportComplete(
    int bizCount,
    int txCount,
    int sessCount,
  );

  /// No description provided for @generalSettingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get generalSettingsDeleteAccount;

  /// No description provided for @generalSettingsDeleteAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Anonymize personal profile and revoke all access sessions'**
  String get generalSettingsDeleteAccountSub;

  /// No description provided for @generalSettingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get generalSettingsSaveChanges;

  /// No description provided for @generalSettingsSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully.'**
  String get generalSettingsSavedToast;

  /// No description provided for @generalSettingsPartialSaveError.
  ///
  /// In en, this message translates to:
  /// **'Some changes could not be saved: {msg}'**
  String generalSettingsPartialSaveError(String msg);

  /// No description provided for @generalSettingsDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get generalSettingsDiscardTitle;

  /// No description provided for @generalSettingsDiscardDesc.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved edits in Settings. Discard them and leave?'**
  String get generalSettingsDiscardDesc;

  /// No description provided for @generalSettingsDiscardBtn.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get generalSettingsDiscardBtn;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get editProfileUploadPhoto;

  /// No description provided for @editProfileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get editProfileRemovePhoto;

  /// No description provided for @editProfilePresetAvatars.
  ///
  /// In en, this message translates to:
  /// **'Preset Avatars'**
  String get editProfilePresetAvatars;

  /// No description provided for @editProfileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get editProfileFirstName;

  /// No description provided for @editProfileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get editProfileLastName;

  /// No description provided for @editProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get editProfilePhone;

  /// No description provided for @editProfileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Email (Read-only)'**
  String get editProfileEmailReadOnly;

  /// No description provided for @editProfileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get editProfileVerified;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get editProfileSave;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get editProfileSaved;

  /// No description provided for @editProfileInvalidPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not process selected photo.'**
  String get editProfileInvalidPhoto;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteAccountTitle(String name);

  /// No description provided for @deleteAccountStepOf.
  ///
  /// In en, this message translates to:
  /// **'{step} / 3'**
  String deleteAccountStepOf(int step);

  /// No description provided for @deleteAccountExportBtn.
  ///
  /// In en, this message translates to:
  /// **'Export My Data First (.json)'**
  String get deleteAccountExportBtn;

  /// No description provided for @deleteAccountExportDone.
  ///
  /// In en, this message translates to:
  /// **'Account backup ready ({txCount} transactions, {bizCount} workspaces).'**
  String deleteAccountExportDone(int txCount, int bizCount);

  /// No description provided for @deleteAccountShareAgain.
  ///
  /// In en, this message translates to:
  /// **'Share / Save Again'**
  String get deleteAccountShareAgain;

  /// No description provided for @deleteAccountContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue to Delete Account'**
  String get deleteAccountContinueBtn;

  /// No description provided for @deleteAccountSkipExportBtn.
  ///
  /// In en, this message translates to:
  /// **'Skip Export — I want to delete this account'**
  String get deleteAccountSkipExportBtn;

  /// No description provided for @deleteAccountWarningBanner.
  ///
  /// In en, this message translates to:
  /// **'Unexpected bad things will happen if you don\'t read this!'**
  String get deleteAccountWarningBanner;

  /// No description provided for @deleteAccountConsequence1.
  ///
  /// In en, this message translates to:
  /// **'Personal identity ({name}, {email}) will be permanently deactivated and anonymized into a tombstone record.'**
  String deleteAccountConsequence1(String name, String email);

  /// No description provided for @deleteAccountConsequence2.
  ///
  /// In en, this message translates to:
  /// **'All active device sessions, 2FA keys, and team memberships will be revoked immediately, and any active subscription canceled best-effort.'**
  String get deleteAccountConsequence2;

  /// No description provided for @deleteAccountConsequence3.
  ///
  /// In en, this message translates to:
  /// **'Existing business financial ledgers and audit trails are preserved safely — owned active businesses must be archived or transferred first.'**
  String get deleteAccountConsequence3;

  /// No description provided for @deleteAccountIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone.'**
  String get deleteAccountIrreversible;

  /// No description provided for @deleteAccountReadConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'I have read and understand these effects'**
  String get deleteAccountReadConfirmBtn;

  /// No description provided for @deleteAccountPreflightError.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify blocking workspaces right now.'**
  String get deleteAccountPreflightError;

  /// No description provided for @deleteAccountBlockingTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve Active Owned Workspaces First'**
  String get deleteAccountBlockingTitle;

  /// No description provided for @deleteAccountMembersBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} member(s)'**
  String deleteAccountMembersBadge(int count);

  /// No description provided for @deleteAccountReadOnlyDeadlock.
  ///
  /// In en, this message translates to:
  /// **'This workspace is currently Read-Only after a plan downgrade and cannot be archived or transferred while locked. Reallocate an active slot or upgrade your plan first.'**
  String get deleteAccountReadOnlyDeadlock;

  /// No description provided for @deleteAccountManageAllocBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage Allocations'**
  String get deleteAccountManageAllocBtn;

  /// No description provided for @deleteAccountArchiveBizBtn.
  ///
  /// In en, this message translates to:
  /// **'Archive Business'**
  String get deleteAccountArchiveBizBtn;

  /// No description provided for @deleteAccountArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive \"{name}\"?'**
  String deleteAccountArchiveConfirmTitle(String name);

  /// No description provided for @deleteAccountArchiveConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Archiving removes this workspace from active use so your account deletion can proceed.'**
  String get deleteAccountArchiveConfirmDesc;

  /// No description provided for @deleteAccountTransferBtn.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get deleteAccountTransferBtn;

  /// No description provided for @deleteAccountTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership of {name}'**
  String deleteAccountTransferTitle(String name);

  /// No description provided for @deleteAccountTransferWarning.
  ///
  /// In en, this message translates to:
  /// **'You will become an Admin and permanently lose Owner privileges for {name}.'**
  String deleteAccountTransferWarning(String name);

  /// No description provided for @deleteAccountNoEligibleMembers.
  ///
  /// In en, this message translates to:
  /// **'No other active members available to receive ownership.'**
  String get deleteAccountNoEligibleMembers;

  /// No description provided for @deleteAccountPhrasePrompt.
  ///
  /// In en, this message translates to:
  /// **'To confirm, type \"{phrase}\" below:'**
  String deleteAccountPhrasePrompt(String phrase);

  /// No description provided for @deleteAccountFinalBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete this account'**
  String get deleteAccountFinalBtn;

  /// No description provided for @deleteAccountSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated and anonymized.'**
  String get deleteAccountSuccessToast;

  /// No description provided for @businessProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfileTitle;

  /// No description provided for @businessProfileSummaryCard.
  ///
  /// In en, this message translates to:
  /// **'Workspace Summary'**
  String get businessProfileSummaryCard;

  /// No description provided for @businessProfileLogoCard.
  ///
  /// In en, this message translates to:
  /// **'Brand Logo'**
  String get businessProfileLogoCard;

  /// No description provided for @businessProfileLogoUrl.
  ///
  /// In en, this message translates to:
  /// **'Logo URL (HTTPS)'**
  String get businessProfileLogoUrl;

  /// No description provided for @businessProfileUseMonogram.
  ///
  /// In en, this message translates to:
  /// **'Use Monogram Avatar'**
  String get businessProfileUseMonogram;

  /// No description provided for @businessProfileLogoHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter an HTTPS image URL up to 500 characters (base64 data URIs are not accepted).'**
  String get businessProfileLogoHelp;

  /// No description provided for @businessProfileLogoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Logo URL must be a valid http(s) link up to 500 characters.'**
  String get businessProfileLogoInvalid;

  /// No description provided for @businessProfileInfoCard.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get businessProfileInfoCard;

  /// No description provided for @businessProfileIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get businessProfileIndustry;

  /// No description provided for @businessProfileWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get businessProfileWebsite;

  /// No description provided for @businessProfileTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get businessProfileTaxId;

  /// No description provided for @businessProfileTaxIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Your official Tax ID printed on invoices, Excel exports, and PDF reports.'**
  String get businessProfileTaxIdHelp;

  /// No description provided for @businessProfileAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get businessProfileAddress;

  /// No description provided for @businessProfileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get businessProfileCity;

  /// No description provided for @businessProfileState.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get businessProfileState;

  /// No description provided for @businessProfilePostal.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get businessProfilePostal;

  /// No description provided for @businessProfileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get businessProfileCountry;

  /// No description provided for @businessProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Business Description (Optional)'**
  String get businessProfileDesc;

  /// No description provided for @businessProfileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get businessProfileMemberSince;

  /// No description provided for @businessProfileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get businessProfileLocation;

  /// No description provided for @businessProfileSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Business profile updated.'**
  String get businessProfileSavedToast;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & 2FA'**
  String get securityTitle;

  /// No description provided for @securityOverviewSecure.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with 2FA'**
  String get securityOverviewSecure;

  /// No description provided for @securityOverviewRecommend.
  ///
  /// In en, this message translates to:
  /// **'Action recommended: Enable 2FA'**
  String get securityOverviewRecommend;

  /// No description provided for @securityTwoFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Auth'**
  String get securityTwoFactorLabel;

  /// No description provided for @securityPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get securityPasswordLabel;

  /// No description provided for @securityPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed {date}'**
  String securityPasswordChanged(String date);

  /// No description provided for @securityPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get securityPasswordStrong;

  /// No description provided for @securityActiveSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Active Session(s)'**
  String securityActiveSessionsCount(int count);

  /// No description provided for @securityChangePasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get securityChangePasswordBtn;

  /// No description provided for @securityEnable2faBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get securityEnable2faBtn;

  /// No description provided for @securityManage2faBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage 2FA'**
  String get securityManage2faBtn;

  /// No description provided for @securityBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric App Lock'**
  String get securityBiometricTitle;

  /// No description provided for @securityBiometricSub.
  ///
  /// In en, this message translates to:
  /// **'Require Face ID or Fingerprint to unlock AFAB'**
  String get securityBiometricSub;

  /// No description provided for @securityBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not set up on this device.'**
  String get securityBiometricUnavailable;

  /// No description provided for @securityBiometricPrompt.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock AFAB'**
  String get securityBiometricPrompt;

  /// No description provided for @securityUnlockBtn.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometrics'**
  String get securityUnlockBtn;

  /// No description provided for @securityCurrentPwd.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get securityCurrentPwd;

  /// No description provided for @securityNewPwd.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get securityNewPwd;

  /// No description provided for @securityConfirmPwd.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get securityConfirmPwd;

  /// No description provided for @securityChangePwdWarning.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out across all devices and asked to sign in again with your new password.'**
  String get securityChangePwdWarning;

  /// No description provided for @securityChangePwdSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please sign in with your new password.'**
  String get securityChangePwdSuccess;

  /// No description provided for @securitySetup2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Two-Factor Authentication'**
  String get securitySetup2faTitle;

  /// No description provided for @security2faStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code in Google Authenticator, Authy, or 1Password, or copy the setup key:'**
  String get security2faStep1Desc;

  /// No description provided for @securityCopySecret.
  ///
  /// In en, this message translates to:
  /// **'Copy Setup Key'**
  String get securityCopySecret;

  /// No description provided for @security2faStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code from your authenticator app:'**
  String get security2faStep2Desc;

  /// No description provided for @security2faVerifyEnable.
  ///
  /// In en, this message translates to:
  /// **'Verify & Enable 2FA'**
  String get security2faVerifyEnable;

  /// No description provided for @security2faBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Your Recovery Codes'**
  String get security2faBackupTitle;

  /// No description provided for @security2faBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Store these 8 single-use backup codes in a safe place if you ever lose your device.'**
  String get security2faBackupDesc;

  /// No description provided for @securityCopyAllCodes.
  ///
  /// In en, this message translates to:
  /// **'Copy All Codes'**
  String get securityCopyAllCodes;

  /// No description provided for @securityShareTxt.
  ///
  /// In en, this message translates to:
  /// **'Save / Share (.txt)'**
  String get securityShareTxt;

  /// No description provided for @securityManage2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Two-Factor Authentication'**
  String get securityManage2faTitle;

  /// No description provided for @securityRegenerateCodes.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Backup Codes'**
  String get securityRegenerateCodes;

  /// No description provided for @securityDisable2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Two-Factor Authentication'**
  String get securityDisable2faTitle;

  /// No description provided for @securityDisable2faDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to remove 2FA protection from this account.'**
  String get securityDisable2faDesc;

  /// No description provided for @securityDisable2faBtn.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get securityDisable2faBtn;

  /// No description provided for @securitySessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get securitySessionsTitle;

  /// No description provided for @securityLogOutAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Log Out All Sessions'**
  String get securityLogOutAllBtn;

  /// No description provided for @securitySessionCaveatNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Revoking all sessions also signs out this device immediately.'**
  String get securitySessionCaveatNote;

  /// No description provided for @securityLogOutAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out all active sessions?'**
  String get securityLogOutAllTitle;

  /// No description provided for @securityLogOutAllDesc.
  ///
  /// In en, this message translates to:
  /// **'All active sessions—including this device—will be signed out immediately.'**
  String get securityLogOutAllDesc;

  /// No description provided for @securityRevokeSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke access for this session?'**
  String get securityRevokeSessionConfirm;

  /// No description provided for @securityNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No active sessions found.'**
  String get securityNoSessions;

  /// No description provided for @securityTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Best Practices'**
  String get securityTipsTitle;

  /// No description provided for @securityTip1Title.
  ///
  /// In en, this message translates to:
  /// **'Use a strong unique password'**
  String get securityTip1Title;

  /// No description provided for @securityTip1Desc.
  ///
  /// In en, this message translates to:
  /// **'Combine uppercase, lowercase, numbers, and symbols (at least 8 characters).'**
  String get securityTip1Desc;

  /// No description provided for @securityTip2Title.
  ///
  /// In en, this message translates to:
  /// **'Keep Two-Factor Authentication active'**
  String get securityTip2Title;

  /// No description provided for @securityTip2Desc.
  ///
  /// In en, this message translates to:
  /// **'Protects against credential theft even if your password is exposed.'**
  String get securityTip2Desc;

  /// No description provided for @securityTip3Title.
  ///
  /// In en, this message translates to:
  /// **'Review active sessions monthly'**
  String get securityTip3Title;

  /// No description provided for @securityTip3Desc.
  ///
  /// In en, this message translates to:
  /// **'Revoke unrecognized browsers or old devices promptly.'**
  String get securityTip3Desc;

  /// No description provided for @securityTip4Title.
  ///
  /// In en, this message translates to:
  /// **'Store recovery codes offline'**
  String get securityTip4Title;

  /// No description provided for @securityTip4Desc.
  ///
  /// In en, this message translates to:
  /// **'Keep backup codes separate from your authenticator phone.'**
  String get securityTip4Desc;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get appearanceTitle;

  /// No description provided for @appearanceDeviceLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Visual theme, colors, fonts, and surfaces apply live on this device; Compact Mode also syncs to your AFAB account.'**
  String get appearanceDeviceLocalNote;

  /// No description provided for @appearanceLivePreviewJump.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get appearanceLivePreviewJump;

  /// No description provided for @appearanceResetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get appearanceResetBtn;

  /// No description provided for @appearanceSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get appearanceSaveBtn;

  /// No description provided for @appearanceSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Appearance preferences saved.'**
  String get appearanceSavedToast;

  /// No description provided for @appearanceSavedLocalOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device; cloud compact-mode sync will retry when online.'**
  String get appearanceSavedLocalOffline;

  /// No description provided for @appearanceThemeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get appearanceThemeModeTitle;

  /// No description provided for @appearanceModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceModeLight;

  /// No description provided for @appearanceModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceModeDark;

  /// No description provided for @appearanceModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceModeSystem;

  /// No description provided for @appearanceDarkSurfaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Surface Mood'**
  String get appearanceDarkSurfaceTitle;

  /// No description provided for @appearanceSurfaceMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight Navy'**
  String get appearanceSurfaceMidnight;

  /// No description provided for @appearanceSurfaceOled.
  ///
  /// In en, this message translates to:
  /// **'OLED Pure Black'**
  String get appearanceSurfaceOled;

  /// No description provided for @appearanceSurfaceSlate.
  ///
  /// In en, this message translates to:
  /// **'Deep Slate'**
  String get appearanceSurfaceSlate;

  /// No description provided for @appearanceSurfaceCharcoal.
  ///
  /// In en, this message translates to:
  /// **'Charcoal Eclipse'**
  String get appearanceSurfaceCharcoal;

  /// No description provided for @appearanceAccentTitle.
  ///
  /// In en, this message translates to:
  /// **'Brand Accent Color'**
  String get appearanceAccentTitle;

  /// No description provided for @appearanceCustomHex.
  ///
  /// In en, this message translates to:
  /// **'Custom Hex (#RRGGBB)'**
  String get appearanceCustomHex;

  /// No description provided for @appearanceLowContrastWarn.
  ///
  /// In en, this message translates to:
  /// **'Low contrast with white button text'**
  String get appearanceLowContrastWarn;

  /// No description provided for @appearanceTypographyTitle.
  ///
  /// In en, this message translates to:
  /// **'Typography & Font Family'**
  String get appearanceTypographyTitle;

  /// No description provided for @appearanceFontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Font Size Scale'**
  String get appearanceFontSizeTitle;

  /// No description provided for @appearanceRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Corner Rounding'**
  String get appearanceRadiusTitle;

  /// No description provided for @appearanceDensityEffectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Density & Visual Effects'**
  String get appearanceDensityEffectsTitle;

  /// No description provided for @appearanceDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get appearanceDensityComfortable;

  /// No description provided for @appearanceDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get appearanceDensityCompact;

  /// No description provided for @appearanceEnableGlow.
  ///
  /// In en, this message translates to:
  /// **'Ambient Neon Glow'**
  String get appearanceEnableGlow;

  /// No description provided for @appearanceSmoothTransitions.
  ///
  /// In en, this message translates to:
  /// **'Smooth Theme Transitions'**
  String get appearanceSmoothTransitions;

  /// No description provided for @appearanceLivePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Live Preview'**
  String get appearanceLivePreviewTitle;

  /// No description provided for @signatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Wet Signature Vault'**
  String get signatureTitle;

  /// No description provided for @signatureSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Saved'**
  String signatureSavedCount(int count);

  /// No description provided for @signatureDeviceLocalNotice.
  ///
  /// In en, this message translates to:
  /// **'Stored locally on this device for your active business. Signatures do not sync across devices or AFAB cloud servers.'**
  String get signatureDeviceLocalNotice;

  /// No description provided for @signatureVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Signatures Vault'**
  String get signatureVaultTitle;

  /// No description provided for @signatureEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No signatures saved yet'**
  String get signatureEmptyTitle;

  /// No description provided for @signatureEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw on the pad or upload a photo of a handwritten signature to stamp PDFs & exports.'**
  String get signatureEmptyDesc;

  /// No description provided for @signatureActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active & In Use'**
  String get signatureActiveBadge;

  /// No description provided for @signatureSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set as Active'**
  String get signatureSetActive;

  /// No description provided for @signatureEditingBanner.
  ///
  /// In en, this message translates to:
  /// **'Editing: {label}'**
  String signatureEditingBanner(String label);

  /// No description provided for @signatureTabDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw Pad'**
  String get signatureTabDraw;

  /// No description provided for @signatureTabUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get signatureTabUpload;

  /// No description provided for @signatureInkBlack.
  ///
  /// In en, this message translates to:
  /// **'Ink Black'**
  String get signatureInkBlack;

  /// No description provided for @signatureInkBlue.
  ///
  /// In en, this message translates to:
  /// **'Royal Blue'**
  String get signatureInkBlue;

  /// No description provided for @signatureResetPad.
  ///
  /// In en, this message translates to:
  /// **'Reset Pad'**
  String get signatureResetPad;

  /// No description provided for @signatureUseDrawing.
  ///
  /// In en, this message translates to:
  /// **'Use This Drawing'**
  String get signatureUseDrawing;

  /// No description provided for @signatureTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get signatureTakePhoto;

  /// No description provided for @signatureChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get signatureChooseFile;

  /// No description provided for @signatureTransparentBg.
  ///
  /// In en, this message translates to:
  /// **'Auto-remove paper background (Transparent ink)'**
  String get signatureTransparentBg;

  /// No description provided for @signatureLabelField.
  ///
  /// In en, this message translates to:
  /// **'Signature Label'**
  String get signatureLabelField;

  /// No description provided for @signatureSignatoryName.
  ///
  /// In en, this message translates to:
  /// **'Full Signatory Name'**
  String get signatureSignatoryName;

  /// No description provided for @signatureSignatoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Signatory Title / Position'**
  String get signatureSignatoryTitle;

  /// No description provided for @signatureSetDefaultCheck.
  ///
  /// In en, this message translates to:
  /// **'Set this signature as active immediately'**
  String get signatureSetDefaultCheck;

  /// No description provided for @signatureAutoApplySwitch.
  ///
  /// In en, this message translates to:
  /// **'Automatically stamp active signature onto Invoices & Exports'**
  String get signatureAutoApplySwitch;

  /// No description provided for @signatureSaveVaultBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Signature to Vault'**
  String get signatureSaveVaultBtn;

  /// No description provided for @signatureUpdateVaultBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Signature'**
  String get signatureUpdateVaultBtn;

  /// No description provided for @signaturePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Certified Document Preview'**
  String get signaturePreviewTitle;

  /// No description provided for @signatureCertifiedStamp.
  ///
  /// In en, this message translates to:
  /// **'CERTIFIED'**
  String get signatureCertifiedStamp;

  /// No description provided for @signatureDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete signature \"{label}\"?'**
  String signatureDeleteConfirm(String label);

  /// No description provided for @signatureTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image file is too large (max 5 MB).'**
  String get signatureTooLarge;

  /// No description provided for @signatureSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Signature saved to local vault.'**
  String get signatureSavedToast;

  /// No description provided for @dataExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & Export'**
  String get dataExportTitle;

  /// No description provided for @dataExportTruncationBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing {loaded} of {total} total records for export pagination (max 1,000 per dataset). Narrow the period filter or export full JSON from General Settings.'**
  String dataExportTruncationBanner(int loaded, int total);

  /// No description provided for @dataExportPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get dataExportPeriodLabel;

  /// No description provided for @dataExportCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Currency'**
  String get dataExportCurrencyLabel;

  /// No description provided for @dataExportCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'Amounts reflect original ledger currencies without FX conversion.'**
  String get dataExportCurrencyNote;

  /// No description provided for @dataExportCountTx.
  ///
  /// In en, this message translates to:
  /// **'Period Transactions'**
  String get dataExportCountTx;

  /// No description provided for @dataExportCountCustomers.
  ///
  /// In en, this message translates to:
  /// **'Clients Directory'**
  String get dataExportCountCustomers;

  /// No description provided for @dataExportCountInvoices.
  ///
  /// In en, this message translates to:
  /// **'Period Invoices'**
  String get dataExportCountInvoices;

  /// No description provided for @dataExportCountNetFlow.
  ///
  /// In en, this message translates to:
  /// **'Net Flow (Period)'**
  String get dataExportCountNetFlow;

  /// No description provided for @dataExportMasterBadge.
  ///
  /// In en, this message translates to:
  /// **'Complete Business Archive'**
  String get dataExportMasterBadge;

  /// No description provided for @dataExportMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Export KPIs, transactions, customers, and invoices together with Arabic UTF-8 support.'**
  String get dataExportMasterDesc;

  /// No description provided for @dataExportAllExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel (.xlsx)'**
  String get dataExportAllExcel;

  /// No description provided for @dataExportAllPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF (.pdf)'**
  String get dataExportAllPdf;

  /// No description provided for @dataExportPrintPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview / Share PDF'**
  String get dataExportPrintPreview;

  /// No description provided for @dataExportModularTx.
  ///
  /// In en, this message translates to:
  /// **'Transactions & Cash Flow'**
  String get dataExportModularTx;

  /// No description provided for @dataExportModularCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customer CRM Registry'**
  String get dataExportModularCustomers;

  /// No description provided for @dataExportModularInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices & Billing Register'**
  String get dataExportModularInvoices;

  /// No description provided for @dataExportModularPnl.
  ///
  /// In en, this message translates to:
  /// **'Financial Performance (P&L)'**
  String get dataExportModularPnl;

  /// No description provided for @dataExportBackendCsv.
  ///
  /// In en, this message translates to:
  /// **'Backend CSV'**
  String get dataExportBackendCsv;

  /// No description provided for @dataExportBackendPdf.
  ///
  /// In en, this message translates to:
  /// **'Official PDF'**
  String get dataExportBackendPdf;

  /// No description provided for @dataExportComplianceFooter.
  ///
  /// In en, this message translates to:
  /// **'Client Excel & Cairo-font PDF archives support full Arabic RTL & UTF-8 text.'**
  String get dataExportComplianceFooter;

  /// No description provided for @dataExportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Export Scope'**
  String get dataExportSheetTitle;

  /// No description provided for @dataExportFiscalMatricule.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get dataExportFiscalMatricule;

  /// No description provided for @dataExportBusinessPurpose.
  ///
  /// In en, this message translates to:
  /// **'Activity / Purpose'**
  String get dataExportBusinessPurpose;

  /// No description provided for @dataExportOfficialAddress.
  ///
  /// In en, this message translates to:
  /// **'Official Business Address'**
  String get dataExportOfficialAddress;

  /// No description provided for @dataExportIncludeLogo.
  ///
  /// In en, this message translates to:
  /// **'Include Business Logo Details'**
  String get dataExportIncludeLogo;

  /// No description provided for @dataExportIncludeSig.
  ///
  /// In en, this message translates to:
  /// **'Include Active Wet Signature'**
  String get dataExportIncludeSig;

  /// No description provided for @dataExportGenerateShare.
  ///
  /// In en, this message translates to:
  /// **'Generate & Share'**
  String get dataExportGenerateShare;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// No description provided for @languageSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystemTitle;

  /// No description provided for @languageSystemSub.
  ///
  /// In en, this message translates to:
  /// **'Follow your device operating system language (falls back to English)'**
  String get languageSystemSub;

  /// No description provided for @languageEnglishSub.
  ///
  /// In en, this message translates to:
  /// **'Left-to-Right (LTR) · Gregorian Calendar · Western Digits (0-9)'**
  String get languageEnglishSub;

  /// No description provided for @languageArabicSub.
  ///
  /// In en, this message translates to:
  /// **'Right-to-Left (RTL) · Gregorian Calendar · Western Digits (0-9)'**
  String get languageArabicSub;

  /// No description provided for @languagePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Directionality & Format Preview'**
  String get languagePreviewTitle;

  /// No description provided for @languagePreviewDir.
  ///
  /// In en, this message translates to:
  /// **'Direction: {dir}'**
  String languagePreviewDir(String dir);

  /// No description provided for @languageCopilotNote.
  ///
  /// In en, this message translates to:
  /// **'App interface language is independent of AI Copilot\'s 5 response languages (English, French, Arabic MSA, Derja, Arabizi), which you can select inside Copilot.'**
  String get languageCopilotNote;

  /// No description provided for @languageUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Interface language updated.'**
  String get languageUpdatedToast;

  /// No description provided for @comingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonBadge;

  /// No description provided for @comingSoonBackBtn.
  ///
  /// In en, this message translates to:
  /// **'Back to Settings'**
  String get comingSoonBackBtn;

  /// No description provided for @comingSoonUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Team member invitations, role assignment, and fine-grained permissions are in development for an upcoming release.'**
  String get comingSoonUsersDesc;

  /// No description provided for @comingSoonMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Workspace Members (Read-Only)'**
  String get comingSoonMembersTitle;

  /// No description provided for @comingSoonOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Only you are currently an active member of this workspace.'**
  String get comingSoonOnlyYou;

  /// No description provided for @comingSoonNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Granular email digest schedules and push alert rules will be configurable here soon.'**
  String get comingSoonNotificationsDesc;

  /// No description provided for @comingSoonOpenNotifCenter.
  ///
  /// In en, this message translates to:
  /// **'View In-App Notifications'**
  String get comingSoonOpenNotifCenter;

  /// No description provided for @comingSoonIntegrationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct bank feeds, payment gateways, and automated webhooks will be available here in a future release.'**
  String get comingSoonIntegrationsDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
