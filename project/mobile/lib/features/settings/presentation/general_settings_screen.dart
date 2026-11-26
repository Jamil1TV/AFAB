import 'dart:convert';
import 'dart:io';

import 'package:afab_mobile/core/config/business_constants.dart';
import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/currencies/presentation/widgets/currency_migration_sheet.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:afab_mobile/features/settings/domain/settings_providers.dart';
import 'package:afab_mobile/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Screen `SET-02`: General Settings (Profile, Business Basics, Formats, Preferences, Export, Delete).
class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  final _bizNameCtrl = TextEditingController();
  final _bizEmailCtrl = TextEditingController();

  String _baseCurrency = 'USD';
  String _timezone = 'UTC';
  int _fiscalMonth = 1;
  String _dateFormat = 'YYYY-MM-DD';
  String _numberFormat = 'US';

  bool _enableAiInsights = true;
  bool _compactMode = false;
  bool _autoCategorize = true;
  bool _showTips = true;

  String? _seededKey;
  BusinessDto? _baselineBiz;
  UserProfile? _baselineUser;
  bool _saving = false;
  bool _exportingJson = false;
  String? _exportSummary;

  static const _dateFormats = [
    'YYYY-MM-DD',
    'MM/DD/YYYY',
    'DD/MM/YYYY',
    'DD-MM-YYYY',
    'MMM DD, YYYY',
    'DD MMM YYYY',
    'YYYY/MM/DD',
  ];

  static const _numberFormats = ['US', 'EU', 'SI', 'DOT', 'RAW'];

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _bizEmailCtrl.dispose();
    super.dispose();
  }

  void _seedFrom(BusinessDto? biz, UserProfile? user) {
    final key = '${biz?.id ?? 'none'}:${user?.id ?? 'none'}';
    if (_seededKey == key) return;
    _seededKey = key;
    _applyBaseline(biz, user);
  }

  void _applyBaseline(BusinessDto? biz, UserProfile? user) {
    _baselineBiz = biz;
    _baselineUser = user;
    _bizNameCtrl.text = biz?.name ?? '';
    _bizEmailCtrl.text = biz?.businessEmail ?? '';
    _baseCurrency = (biz?.currency ?? 'USD').toUpperCase();
    _timezone = (biz?.timezone?.isNotEmpty == true) ? biz!.timezone! : 'UTC';
    _fiscalMonth = (biz?.fiscalYearStartMonth ?? 1).clamp(1, 12);
    _dateFormat =
        (biz?.dateFormat?.isNotEmpty == true) ? biz!.dateFormat! : 'YYYY-MM-DD';
    _numberFormat =
        (biz?.numberFormat?.isNotEmpty == true) ? biz!.numberFormat! : 'US';

    _enableAiInsights = user?.enableAiInsights ?? true;
    _compactMode = user?.compactMode ?? false;
    _autoCategorize = user?.autoCategorizeTransactions ?? true;
    _showTips = user?.showTips ?? true;
  }

  bool get _isDirty {
    final b = _baselineBiz;
    final u = _baselineUser;
    final bizDirty = b != null &&
        (_bizNameCtrl.text.trim() != b.name.trim() ||
            _bizEmailCtrl.text.trim() != (b.businessEmail ?? '').trim() ||
            _timezone != ((b.timezone?.isNotEmpty == true) ? b.timezone! : 'UTC') ||
            _fiscalMonth != (b.fiscalYearStartMonth ?? 1) ||
            _dateFormat !=
                ((b.dateFormat?.isNotEmpty == true)
                    ? b.dateFormat!
                    : 'YYYY-MM-DD') ||
            _numberFormat !=
                ((b.numberFormat?.isNotEmpty == true) ? b.numberFormat! : 'US'));
    final userDirty = u != null &&
        (_enableAiInsights != u.enableAiInsights ||
            _compactMode != u.compactMode ||
            _autoCategorize != u.autoCategorizeTransactions ||
            _showTips != u.showTips);
    return bizDirty || userDirty;
  }

  bool _canEditBusiness(BusinessDto? biz) {
    if (biz == null || biz.isReadOnly) return false;
    final role = biz.userRole.toUpperCase();
    return role == 'OWNER' || role == 'ADMIN';
  }

  Future<void> _saveChanges() async {
    final l10n = context.l10n;
    final biz = _baselineBiz;
    final canEditBiz = _canEditBusiness(biz);
    setState(() => _saving = true);

    String? partialErr;
    BusinessDto? nextBiz = biz;
    UserProfile? nextUser = _baselineUser;

    if (canEditBiz && biz != null) {
      try {
        nextBiz = await ref.read(businessRepositoryProvider).updateBusiness(
          biz.id,
          {
            'name': _bizNameCtrl.text.trim(),
            'businessEmail': _bizEmailCtrl.text.trim(),
            'timezone': _timezone,
            'fiscalYearStartMonth': _fiscalMonth,
            'dateFormat': _dateFormat,
            'numberFormat': _numberFormat,
          },
        );
        final prefs = ref.read(prefsStoreProvider);
        await prefs.setNumberFormat(_numberFormat);
        await prefs.setDateFormat(_dateFormat);
        ref.invalidate(businessListProvider);
        await invalidateAfterBusinessSettingsUpdate(ref);
      } on AppFailure catch (e) {
        partialErr = e.message;
      }
    }

    try {
      nextUser = await ref.read(settingsRepositoryProvider).updateProfile({
        'enableAiInsights': _enableAiInsights,
        'compactMode': _compactMode,
        'autoCategorizeTransactions': _autoCategorize,
        'showTips': _showTips,
      });
      await ref.read(authNotifierProvider.notifier).updateCachedUser(nextUser);
    } on AppFailure catch (e) {
      partialErr = partialErr == null ? e.message : '$partialErr · ${e.message}';
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _baselineBiz = nextBiz;
      _baselineUser = nextUser;
    });

    if (partialErr != null) {
      AfabToast.showError(
        context,
        l10n.generalSettingsPartialSaveError(partialErr),
      );
    } else {
      AfabToast.showSuccess(context, l10n.generalSettingsSavedToast);
    }
  }

  Future<void> _exportJson() async {
    if (_exportingJson) return;
    setState(() => _exportingJson = true);
    try {
      final data = await ref.read(settingsRepositoryProvider).exportUserData();
      final dir = await getTemporaryDirectory();
      final today = AfabDateFormatter.formatDateTime(DateTime.now());
      final file = File('${dir.path}/afab-account-export-$today.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );

      final summary =
          (data['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
      final bizCount = (summary['businessesCount'] as num?)?.toInt() ?? 0;
      final txCount = (summary['transactionsCount'] as num?)?.toInt() ?? 0;
      final sessCount = (summary['activeSessionsCount'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _exportSummary = context.l10n.generalSettingsExportComplete(
            bizCount,
            txCount,
            sessCount,
          );
        });
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) AfabToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _exportingJson = false);
    }
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_isDirty) return true;
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.generalSettingsDiscardTitle),
        content: Text(l10n.generalSettingsDiscardDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.generalSettingsDiscardBtn),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  List<(String qLabel, String span)> _buildQuarters(String locale) {
    final months = BusinessConstants.months;
    String name(int zeroBased) => months[zeroBased % 12].label(locale);
    final start = _fiscalMonth - 1;
    return [
      ('Q1', '${name(start)} – ${name(start + 2)}'),
      ('Q2', '${name(start + 3)} – ${name(start + 5)}'),
      ('Q3', '${name(start + 6)} – ${name(start + 8)}'),
      ('Q4', '${name(start + 9)} – ${name(start + 11)}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    final user = ref.watch(authNotifierProvider).user;

    _seedFrom(biz, user);
    final canEditBiz = _canEditBusiness(biz);
    final dirty = _isDirty;

    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (dirty && widget.embedded) ...[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AfabStatusBadge(
                          label: l10n.generalSettingsUnsavedBadge,
                          variant: AfabBadgeVariant.warning,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (!canEditBiz) ...[
                      AfabInsetPanel(
                        borderColor: colors.warning.withValues(alpha: 0.4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.lock,
                              size: 17,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (biz?.isReadOnly ?? false)
                                    ? l10n.settingsReadOnlyBanner
                                    : l10n.generalSettingsMemberNotice,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 1. Account Profile Card
                    if (user != null) ...[
                      _AccountSummaryCard(
                        user: user,
                        onEdit: () async {
                          final updated = await showEditProfileSheet(
                            context,
                            profile: user,
                          );
                          if (updated != null && mounted) {
                            setState(() {
                              _baselineUser = updated;
                              _compactMode = updated.compactMode;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Business Settings Card
                    AfabCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.generalSettingsBusinessCard,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _bizNameCtrl,
                            enabled: canEditBiz,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.generalSettingsBizName,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextField(
                              controller: _bizEmailCtrl,
                              enabled: canEditBiz,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: l10n.generalSettingsBizEmail,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: canEditBiz
                                ? () async {
                                    final res = await showCurrencyMigrationSheet(
                                      context,
                                    );
                                    if (res != null && mounted) {
                                      setState(() {
                                        _baseCurrency = res.newCurrency;
                                      });
                                    }
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.generalSettingsCurrency,
                                suffixIcon: const Icon(
                                  LucideIcons.arrowRightLeft,
                                  size: 16,
                                ),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _baseCurrency,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  AfabStatusBadge(
                                    label: l10n.generalSettingsLiveFx,
                                    variant: AfabBadgeVariant.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: BusinessConstants.timezones
                                    .any((t) => t.id == _timezone)
                                ? _timezone
                                : 'UTC',
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.generalSettingsTimezone,
                            ),
                            items: [
                              for (final tz in BusinessConstants.timezones)
                                DropdownMenuItem(
                                  value: tz.id,
                                  child: Text(
                                    tz.label(locale),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: canEditBiz
                                ? (v) {
                                    if (v != null) {
                                      setState(() => _timezone = v);
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _fiscalMonth,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.generalSettingsFiscalStart,
                            ),
                            items: [
                              for (var m = 1; m <= 12; m++)
                                DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    BusinessConstants.localizedMonth(m, locale),
                                  ),
                                ),
                            ],
                            onChanged: canEditBiz
                                ? (v) {
                                    if (v != null) {
                                      setState(() => _fiscalMonth = v);
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 12),
                          AfabInsetPanel(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.generalSettingsAccountingCycle,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final quarters = _buildQuarters(locale);
                                    final tileW = (c.maxWidth - 8) / 2;
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final q in quarters)
                                          SizedBox(
                                            width: tileW,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: colors.surface,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: colors.border,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    q.$1,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: colors.primary,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    q.$2,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Regional Formats Card
                    AfabCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.generalSettingsRegionalCard,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _dateFormats.contains(_dateFormat)
                                ? _dateFormat
                                : 'YYYY-MM-DD',
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.generalSettingsDateFormat,
                            ),
                            items: [
                              for (final fmt in _dateFormats)
                                DropdownMenuItem(
                                  value: fmt,
                                  child: Text(fmt),
                                ),
                            ],
                            onChanged: canEditBiz
                                ? (v) {
                                    if (v != null) {
                                      setState(() => _dateFormat = v);
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              AfabDateFormatter.formatDateTime(
                                DateTime(2026, 10, 24),
                                dateFormat: _dateFormat,
                                locale: locale,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _numberFormats.contains(_numberFormat)
                                ? _numberFormat
                                : 'US',
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.generalSettingsNumberFormat,
                            ),
                            items: [
                              for (final fmt in _numberFormats)
                                DropdownMenuItem(
                                  value: fmt,
                                  child: Text(fmt),
                                ),
                            ],
                            onChanged: canEditBiz
                                ? (v) {
                                    if (v != null) {
                                      setState(() => _numberFormat = v);
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              MoneyFormatter.formatDecimal(
                                Decimal.parse('1234567.89'),
                                currency: _baseCurrency,
                                numberFormat: _numberFormat,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Preferences Card (Always Editable User Prefs)
                    AfabCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.generalSettingsPrefsCard,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _enableAiInsights,
                            onChanged: (v) =>
                                setState(() => _enableAiInsights = v),
                            title: Text(l10n.generalSettingsPrefAi),
                            subtitle: Text(l10n.generalSettingsPrefAiSub),
                          ),
                          Divider(height: 1, color: colors.border),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _compactMode,
                            onChanged: (v) => setState(() => _compactMode = v),
                            title: Text(l10n.generalSettingsPrefCompact),
                            subtitle: Text(l10n.generalSettingsPrefCompactSub),
                          ),
                          Divider(height: 1, color: colors.border),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _autoCategorize,
                            onChanged: (v) =>
                                setState(() => _autoCategorize = v),
                            title: Text(l10n.generalSettingsPrefAutoCat),
                            subtitle: Text(l10n.generalSettingsPrefAutoCatSub),
                          ),
                          Divider(height: 1, color: colors.border),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _showTips,
                            onChanged: (v) => setState(() => _showTips = v),
                            title: Text(l10n.generalSettingsPrefTips),
                            subtitle: Text(l10n.generalSettingsPrefTipsSub),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Other Settings: Export Data + Delete Account
                    AfabCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.generalSettingsOtherCard,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              LucideIcons.download,
                              color: colors.primary,
                            ),
                            title: Text(l10n.generalSettingsExportData),
                            subtitle: Text(l10n.generalSettingsExportDataSub),
                            trailing: _exportingJson
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(LucideIcons.share2, size: 18),
                            onTap: _exportingJson ? null : _exportJson,
                          ),
                          if (_exportSummary != null) ...[
                            AfabInsetPanel(
                              padding: const EdgeInsets.all(10),
                              borderColor:
                                  colors.success.withValues(alpha: 0.35),
                              child: Text(
                                _exportSummary!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.success),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Divider(height: 1, color: colors.border),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              LucideIcons.trash2,
                              color: colors.danger,
                            ),
                            title: Text(
                              l10n.generalSettingsDeleteAccount,
                              style: TextStyle(
                                color: colors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              l10n.generalSettingsDeleteAccountSub,
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: colors.danger,
                            ),
                            onTap: () =>
                                context.push('/settings/delete-account'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Sticky Bottom Save Bar when Dirty
        if (dirty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    AfabButton(
                      label: l10n.commonCancel,
                      icon: LucideIcons.rotateCcw,
                      variant: AfabButtonVariant.secondary,
                      compact: true,
                      onPressed: _saving
                          ? null
                          : () => setState(
                                () => _applyBaseline(_baselineBiz, _baselineUser),
                              ),
                    ),
                    AfabButton(
                      label: l10n.generalSettingsSaveChanges,
                      icon: LucideIcons.check,
                      variant: AfabButtonVariant.primary,
                      compact: true,
                      isLoading: _saving,
                      onPressed: _saving ? null : _saveChanges,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.embedded) return content;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscardIfDirty();
        if (discard && context.mounted) {
          setState(() => _applyBaseline(_baselineBiz, _baselineUser));
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.generalSettingsTitle),
          actions: [
            if (dirty)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Center(
                  child: AfabStatusBadge(
                    label: l10n.generalSettingsUnsavedBadge,
                    variant: AfabBadgeVariant.warning,
                  ),
                ),
              ),
          ],
        ),
        body: content,
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({
    required this.user,
    required this.onEdit,
  });

  final UserProfile user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UserAvatar(user: user, size: 56, colors: colors),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (user.phoneNumber != null &&
                        user.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          user.phoneNumber!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AfabButton(
            label: l10n.settingsEditProfile,
            icon: LucideIcons.pencil,
            variant: AfabButtonVariant.secondary,
            compact: true,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.size,
    required this.colors,
  });

  final UserProfile user;
  final double size;
  final AfabColors colors;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    if (url != null && url.startsWith('data:image/')) {
      final comma = url.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(url.substring(comma + 1));
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {}
      }
    }
    if (url != null && url.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primary.withValues(alpha: 0.14),
      child: Text(
        user.initials,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
