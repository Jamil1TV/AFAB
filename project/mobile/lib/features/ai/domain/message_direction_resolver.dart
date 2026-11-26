import 'dart:typed_data';

import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Determines per-message BiDi text direction independently of app UI locale.
abstract final class MessageDirectionResolver {
  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _letterRegex = RegExp(r'[A-Za-z\u0600-\u06FF]');

  static TextDirection resolveForMessage(
    String text, {
    String? responseLanguage,
  }) {
    final lang = responseLanguage?.toUpperCase();
    if (lang == 'AR_MSA' || lang == 'AR_DERJA_SCRIPT') {
      return TextDirection.rtl;
    }
    if (lang == 'EN' || lang == 'FR' || lang == 'AR_DERJA_ARABIZI') {
      return TextDirection.ltr;
    }
    final letters = _letterRegex.allMatches(text).length;
    if (letters == 0) return TextDirection.ltr;
    final arabicCount = _arabicRegex.allMatches(text).length;
    return (arabicCount / letters) >= 0.30
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  static TextDirection resolveForComposer(String text, String uiLocale) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return uiLocale.toLowerCase().startsWith('ar')
          ? TextDirection.rtl
          : TextDirection.ltr;
    }
    return resolveForMessage(trimmed);
  }
}

/// Validates AI Copilot attachments against backend rules (`AiAttachmentService`).
abstract final class AiAttachmentValidator {
  static const int maxFilesPerTurn = 3;
  static const int maxBytes = 10 * 1024 * 1024; // 10 MB

  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
    'xlsx',
    'csv',
    'txt',
    'json',
    'md',
  };

  static const Set<String> _textExtensions = {'csv', 'txt', 'json', 'md'};

  static String? validate({
    required Uint8List bytes,
    required String filename,
    int currentlyStagedCount = 0,
  }) {
    if (currentlyStagedCount >= maxFilesPerTurn) {
      return 'Maximum $maxFilesPerTurn attachments per turn.';
    }
    if (bytes.isEmpty) {
      return 'Selected file is empty.';
    }
    if (bytes.length > maxBytes) {
      return 'File exceeds the 10 MB limit.';
    }
    final dotIdx = filename.lastIndexOf('.');
    final ext =
        dotIdx >= 0 ? filename.substring(dotIdx + 1).toLowerCase() : '';
    if (!allowedExtensions.contains(ext)) {
      return 'Unsupported file type ".$ext".';
    }
    if (_textExtensions.contains(ext)) {
      final sampleLen = bytes.length < 4096 ? bytes.length : 4096;
      for (var i = 0; i < sampleLen; i++) {
        if (bytes[i] == 0x00) {
          return 'Invalid text encoding (binary NUL bytes detected).';
        }
      }
    }
    return null;
  }

  static String guessContentType(String filename) {
    final dotIdx = filename.lastIndexOf('.');
    final ext =
        dotIdx >= 0 ? filename.substring(dotIdx + 1).toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'csv' => 'text/csv',
      'txt' => 'text/plain',
      'json' => 'application/json',
      'md' => 'text/markdown',
      _ => 'application/octet-stream',
    };
  }
}

enum ConversationDateBucket { today, yesterday, week, earlier }

ConversationDateBucket classifyConversationDate(
  DateTime? timestamp, {
  DateTime? now,
}) {
  if (timestamp == null) return ConversationDateBucket.earlier;
  final refNow = now ?? DateTime.now();
  final local = timestamp.toLocal();
  final todayStart = DateTime(refNow.year, refNow.month, refNow.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final weekStart = todayStart.subtract(const Duration(days: 7));

  if (!local.isBefore(todayStart)) return ConversationDateBucket.today;
  if (!local.isBefore(yesterdayStart)) return ConversationDateBucket.yesterday;
  if (!local.isBefore(weekStart)) return ConversationDateBucket.week;
  return ConversationDateBucket.earlier;
}

/// Maps backend evidence/created-entity web paths to native GoRouter destinations.
String mapWebHrefToMobileRoute(String? href) {
  final raw = (href ?? '').trim();
  if (raw.isEmpty) return '/dashboard';
  final path = raw.split('?').first.replaceFirst(RegExp(r'^/(en|ar)(?=/)'), '');

  if (path.startsWith('/dashboard/transactions')) return '/transactions';
  if (path.startsWith('/dashboard/invoices')) return '/invoices';
  if (path.startsWith('/dashboard/customers')) return '/customers';
  if (path.startsWith('/dashboard/budgets')) return '/budgets';
  if (path.startsWith('/dashboard/recurring')) return '/recurring';
  if (path.startsWith('/dashboard/expenses')) return '/expenses';
  if (path.startsWith('/dashboard/revenue')) return '/revenue';
  if (path.startsWith('/dashboard/calendar')) return '/calendar';
  if (path.startsWith('/dashboard/currencies')) return '/currencies';
  if (path.startsWith('/dashboard/reports')) return '/reports';
  if (path.startsWith('/dashboard/settings/subscription')) return '/plans';
  if (path.startsWith('/dashboard/ai')) return '/copilot/memory';
  if (path == '/dashboard' || path == '/') return '/dashboard';
  if (path.startsWith('/transactions') ||
      path.startsWith('/invoices') ||
      path.startsWith('/customers') ||
      path.startsWith('/budgets') ||
      path.startsWith('/recurring') ||
      path.startsWith('/expenses') ||
      path.startsWith('/revenue') ||
      path.startsWith('/calendar') ||
      path.startsWith('/currencies') ||
      path.startsWith('/reports') ||
      path.startsWith('/plans')) {
    return path;
  }
  return '/dashboard';
}

String localizedToolLabel(AppLocalizations l10n, String toolName) {
  return switch (toolName) {
    'get_business_summary' => l10n.aiToolBusinessSummary,
    'compare_periods' => l10n.aiToolComparePeriods,
    'get_category_breakdown' => l10n.aiToolCategoryBreakdown,
    'search_transactions' => l10n.aiToolSearchTransactions,
    'get_invoices_overview' => l10n.aiToolInvoicesOverview,
    'get_customers_overview' => l10n.aiToolCustomersOverview,
    'get_budgets_status' => l10n.aiToolBudgetsStatus,
    'get_recurring_commitments' => l10n.aiToolRecurringCommitments,
    'get_data_coverage' => l10n.aiToolDataCoverage,
    'simulate_cashflow_forecast' => l10n.aiToolCashflowForecast,
    'get_financial_pulse' => l10n.aiToolFinancialPulse,
    'propose_transaction_draft' => l10n.aiToolProposeTransaction,
    'propose_invoice_draft' => l10n.aiToolProposeInvoice,
    'propose_budget_draft' => l10n.aiToolProposeBudget,
    'propose_payment_reminder' => l10n.aiToolProposeReminder,
    'propose_business_memory' => l10n.aiToolProposeMemory,
    _ => l10n.aiToolFallback,
  };
}

String localizedAiLanguageLabel(AppLocalizations l10n, String? code) {
  return switch ((code ?? '').toUpperCase()) {
    'EN' => l10n.aiLangEn,
    'FR' => l10n.aiLangFr,
    'AR_MSA' => l10n.aiLangArMsa,
    'AR_DERJA_SCRIPT' => l10n.aiLangDerjaScript,
    'AR_DERJA_ARABIZI' => l10n.aiLangDerjaArabizi,
    _ => '',
  };
}
