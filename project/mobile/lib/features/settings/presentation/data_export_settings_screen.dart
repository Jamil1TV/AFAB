import 'dart:io';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/reports/data/reports_repository.dart';
import 'package:afab_mobile/features/settings/data/export_generators.dart';
import 'package:afab_mobile/features/settings/domain/signature_vault_provider.dart';
import 'package:afab_mobile/features/settings/presentation/widgets/export_period_sheet.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Screen `SET-07`: Data & Export Center (`.xlsx`, Cairo-TTF Arabic `.pdf`,
/// paginated up to 1,000 rows in `size=100` chunks with honest truncation notice,
/// plus Backend Certified P&L CSV/PDF).
class DataExportSettingsScreen extends ConsumerWidget {
  const DataExportSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const body = DataExportSettingsBody();
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataExportTitle)),
      body: body,
    );
  }
}

class DataExportSettingsBody extends ConsumerStatefulWidget {
  const DataExportSettingsBody({super.key});

  @override
  ConsumerState<DataExportSettingsBody> createState() =>
      _DataExportSettingsBodyState();
}

class _DataExportSettingsBodyState
    extends ConsumerState<DataExportSettingsBody> {
  static const int _pageSize = 100;
  static const int _maxPages = 10; // 1,000 rows max

  bool _loading = true;
  String? _loadError;
  bool _generating = false;

  List<TransactionDto> _transactions = const [];
  List<CustomerDto> _customers = const [];
  List<InvoiceDto> _invoices = const [];
  int _totalAvailable = 0;
  int _loadedCount = 0;
  bool _isTruncated = false;

  String _period = 'this_month';
  late String _currency;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _lastBusinessId;

  static const _periodPresets = [
    'all',
    'this_month',
    'last_month',
    'this_quarter',
    'this_year',
    'last_year',
    'last_30_days',
    'last_90_days',
    'custom',
  ];

  static const _currencies = [
    'USD',
    'EUR',
    'SAR',
    'AED',
    'TND',
    'GBP',
    'CAD',
    'KWD',
  ];

  @override
  void initState() {
    super.initState();
    _currency = (ref.read(activeBusinessProvider)?.currency ?? 'USD').toUpperCase();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      final custRepo = ref.read(customersRepositoryProvider);
      final invRepo = ref.read(invoicesRepositoryProvider);

      final txs = <TransactionDto>[];
      var txTotal = 0;
      for (var p = 0; p < _maxPages; p++) {
        final page = await txRepo.getTransactions(page: p, size: _pageSize);
        txTotal = page.totalElements;
        txs.addAll(page.content);
        if (p + 1 >= page.totalPages || page.content.isEmpty) break;
      }

      final custs = <CustomerDto>[];
      var custTotal = 0;
      for (var p = 0; p < _maxPages; p++) {
        final page = await custRepo.listCustomers(page: p, size: _pageSize);
        custTotal = page.totalElements;
        custs.addAll(page.content);
        if (p + 1 >= page.totalPages || page.content.isEmpty) break;
      }

      final invs = <InvoiceDto>[];
      var invTotal = 0;
      for (var p = 0; p < _maxPages; p++) {
        final page = await invRepo.listInvoices(page: p, size: _pageSize);
        invTotal = page.totalElements;
        invs.addAll(page.content);
        if (p + 1 >= page.totalPages || page.content.isEmpty) break;
      }

      if (!mounted) return;
      final truncated = txTotal > txs.length ||
          custTotal > custs.length ||
          invTotal > invs.length;
      setState(() {
        _transactions = txs;
        _customers = custs;
        _invoices = invs;
        _totalAvailable = txTotal + custTotal + invTotal;
        _loadedCount = txs.length + custs.length + invs.length;
        _isTruncated = truncated;
        _loading = false;
      });
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  (DateTime? start, DateTime? end) _resolveRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      'all' => (null, null),
      'this_month' => (DateTime(now.year, now.month, 1), today),
      'last_month' => (
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0),
        ),
      'this_quarter' => () {
          final qStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
          return (DateTime(now.year, qStartMonth, 1), today);
        }(),
      'this_year' => (DateTime(now.year, 1, 1), today),
      'last_year' => (
          DateTime(now.year - 1, 1, 1),
          DateTime(now.year - 1, 12, 31),
        ),
      'last_30_days' => (today.subtract(const Duration(days: 30)), today),
      'last_90_days' => (today.subtract(const Duration(days: 90)), today),
      'custom' => (_customStart, _customEnd),
      _ => (null, null),
    };
  }

  bool _inRange(String isoDate, DateTime? start, DateTime? end) {
    if (start == null && end == null) return true;
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return true;
    final d = DateTime(dt.year, dt.month, dt.day);
    if (start != null && d.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    if (end != null && d.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }
    return true;
  }

  Future<void> _exportClient({
    required ExportDatasetKind kind,
    required bool isPdf,
  }) async {
    final config = await showExportPeriodSheet(
      context,
      initialPeriod: _period,
      initialCurrency: _currency,
      initialCustomStart: _customStart,
      initialCustomEnd: _customEnd,
    );
    if (config == null || !mounted) return;

    setState(() => _generating = true);
    try {
      final range = _resolveRange();
      final filteredTx = _transactions
          .where((t) => _inRange(t.transactionDate, range.$1, range.$2))
          .toList();
      final filteredInv = _invoices
          .where((i) => _inRange(i.issueDate, range.$1, range.$2))
          .toList();
      var netFlow = Decimal.zero;
      for (final tx in filteredTx) {
        netFlow += tx.type == TransactionType.income ? tx.amount : -tx.amount;
      }

      final biz = ref.read(activeBusinessProvider);
      final bizName = biz?.name ?? 'AFAB';
      final bizId = biz?.id ?? 'default';
      final locale = Localizations.localeOf(context).languageCode;
      final dir = await getTemporaryDirectory();
      final slug = '${kind.name}-${DateFormat('yyyyMMdd', 'en_US').format(DateTime.now())}';

      if (isPdf) {
        final sigBytes = config.branding.includeSignature
            ? await ref.read(signatureVaultProvider(bizId).notifier).readActiveBytes()
            : null;
        final activeSig =
            ref.read(signatureVaultProvider(bizId)).activeSignature;
        final pdfBytes = await ExportGenerators.buildPdfBytes(
          kind: kind,
          locale: locale,
          businessName: bizName,
          periodLabel: _period,
          displayCurrency: config.currency,
          branding: config.branding,
          transactions: filteredTx,
          customers: _customers,
          invoices: filteredInv,
          periodNetFlow: netFlow,
          signaturePngBytes: sigBytes,
          signatoryName: activeSig?.signatoryName,
          signatoryTitle: activeSig?.signatoryTitle,
        );
        final file = File('${dir.path}/afab-$slug.pdf');
        await file.writeAsBytes(pdfBytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
        );
      } else {
        final xlsxBytes = ExportGenerators.buildExcelBytes(
          kind: kind,
          businessName: bizName,
          displayCurrency: config.currency,
          branding: config.branding,
          transactions: filteredTx,
          customers: _customers,
          invoices: filteredInv,
          periodNetFlow: netFlow,
        );
        final file = File('${dir.path}/afab-$slug.xlsx');
        await file.writeAsBytes(xlsxBytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                file.path,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ),
            ],
          ),
        );
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) AfabToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _exportBackendPnl({required bool isPdf}) async {
    setState(() => _generating = true);
    try {
      final repo = ref.read(reportsRepositoryProvider);
      final apiPeriod = _period == 'all' ? 'this_year' : _period;
      final startStr = _period == 'custom' && _customStart != null
          ? DateFormat('yyyy-MM-dd', 'en_US').format(_customStart!)
          : null;
      final endStr = _period == 'custom' && _customEnd != null
          ? DateFormat('yyyy-MM-dd', 'en_US').format(_customEnd!)
          : null;

      final fileData = isPdf
          ? await repo.exportPdf(
              period: apiPeriod,
              startDate: startStr,
              endDate: endStr,
            )
          : await repo.exportCsv(
              period: apiPeriod,
              startDate: startStr,
              endDate: endStr,
            );
      await repo.saveAndShareExport(fileData);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);

    if (biz != null && _lastBusinessId != biz.id) {
      _lastBusinessId = biz.id;
      _currency = biz.currency.toUpperCase();
    }

    if (_loading) {
      return Center(child: AfabLoader(size: 50, label: l10n.commonLoading));
    }

    if (_loadError != null) {
      return AfabErrorState(
        title: l10n.errorGenericTitle,
        message: _loadError!,
        retryLabel: l10n.commonRetry,
        onRetry: _fetchAll,
      );
    }

    final range = _resolveRange();
    final filteredTx = _transactions
        .where((t) => _inRange(t.transactionDate, range.$1, range.$2))
        .toList();
    final filteredInv = _invoices
        .where((i) => _inRange(i.issueDate, range.$1, range.$2))
        .toList();
    var netFlow = Decimal.zero;
    for (final tx in filteredTx) {
      netFlow += tx.type == TransactionType.income ? tx.amount : -tx.amount;
    }

    final currencySet = <String>{
      ..._currencies,
      if (biz != null) biz.currency.toUpperCase(),
    }.toList();

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final kpiCols = width >= 840 ? 4 : 2;
          final modCols = width >= 720 ? 2 : 1;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isTruncated) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.triangleAlert,
                              size: 17,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.dataExportTruncationBanner(
                                  _loadedCount,
                                  _totalAvailable,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Period & Currency Controls Card
                    AfabCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _period,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.dataExportPeriodLabel,
                            ),
                            items: [
                              for (final p in _periodPresets)
                                DropdownMenuItem(value: p, child: Text(p)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _period = v);
                            },
                          ),
                          if (_period == 'custom') ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    LucideIcons.calendar,
                                    size: 15,
                                  ),
                                  label: Text(
                                    _customStart != null
                                        ? AfabDateFormatter.formatDateTime(
                                            _customStart!,
                                          )
                                        : l10n.txFilterStartDate,
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _customStart ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _customStart = picked);
                                    }
                                  },
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    LucideIcons.calendar,
                                    size: 15,
                                  ),
                                  label: Text(
                                    _customEnd != null
                                        ? AfabDateFormatter.formatDateTime(
                                            _customEnd!,
                                          )
                                        : l10n.txFilterEndDate,
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _customEnd ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _customEnd = picked);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: currencySet.contains(_currency)
                                ? _currency
                                : currencySet.first,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.dataExportCurrencyLabel,
                              helperText: l10n.dataExportCurrencyNote,
                            ),
                            items: [
                              for (final c in currencySet)
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4 Live KPI Counters
                    LayoutBuilder(
                      builder: (context, inner) {
                        const gap = 10.0;
                        final tileW =
                            (inner.maxWidth - gap * (kpiCols - 1)) / kpiCols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _ExportStatTile(
                              width: tileW,
                              label: l10n.dataExportCountTx,
                              value: '${filteredTx.length}',
                            ),
                            _ExportStatTile(
                              width: tileW,
                              label: l10n.dataExportCountCustomers,
                              value: '${_customers.length}',
                            ),
                            _ExportStatTile(
                              width: tileW,
                              label: l10n.dataExportCountInvoices,
                              value: '${filteredInv.length}',
                            ),
                            _ExportStatTile(
                              width: tileW,
                              label: l10n.dataExportCountNetFlow,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: MoneyText(
                                    amount: netFlow,
                                    currency: _currency,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Master Archive Card
                    AfabCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AfabStatusBadge(
                            label: l10n.dataExportMasterBadge,
                            variant: AfabBadgeVariant.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.dataExportMasterDesc,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              AfabButton(
                                label: l10n.dataExportAllExcel,
                                icon: LucideIcons.fileSpreadsheet,
                                variant: AfabButtonVariant.primary,
                                compact: true,
                                isLoading: _generating,
                                onPressed: _generating
                                    ? null
                                    : () => _exportClient(
                                          kind: ExportDatasetKind.master,
                                          isPdf: false,
                                        ),
                              ),
                              AfabButton(
                                label: l10n.dataExportAllPdf,
                                icon: LucideIcons.fileText,
                                variant: AfabButtonVariant.secondary,
                                compact: true,
                                onPressed: _generating
                                    ? null
                                    : () => _exportClient(
                                          kind: ExportDatasetKind.master,
                                          isPdf: true,
                                        ),
                              ),
                              AfabButton(
                                label: l10n.dataExportPrintPreview,
                                icon: LucideIcons.printer,
                                variant: AfabButtonVariant.soft,
                                compact: true,
                                onPressed: _generating
                                    ? null
                                    : () => _exportClient(
                                          kind: ExportDatasetKind.master,
                                          isPdf: true,
                                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Modular Datasets (4 Cards)
                    LayoutBuilder(
                      builder: (context, inner) {
                        const gap = 12.0;
                        final cardW = modCols == 1
                            ? inner.maxWidth
                            : (inner.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _ModularExportCard(
                              width: cardW,
                              icon: LucideIcons.arrowRightLeft,
                              title: l10n.dataExportModularTx,
                              countText: '${filteredTx.length}',
                              btn1Label: 'Excel (.xlsx)',
                              btn2Label: 'PDF (.pdf)',
                              disabled: _generating,
                              onBtn1: () => _exportClient(
                                kind: ExportDatasetKind.transactions,
                                isPdf: false,
                              ),
                              onBtn2: () => _exportClient(
                                kind: ExportDatasetKind.transactions,
                                isPdf: true,
                              ),
                            ),
                            _ModularExportCard(
                              width: cardW,
                              icon: LucideIcons.users,
                              title: l10n.dataExportModularCustomers,
                              countText: '${_customers.length}',
                              btn1Label: 'Excel (.xlsx)',
                              btn2Label: 'PDF (.pdf)',
                              disabled: _generating,
                              onBtn1: () => _exportClient(
                                kind: ExportDatasetKind.customers,
                                isPdf: false,
                              ),
                              onBtn2: () => _exportClient(
                                kind: ExportDatasetKind.customers,
                                isPdf: true,
                              ),
                            ),
                            _ModularExportCard(
                              width: cardW,
                              icon: LucideIcons.fileText,
                              title: l10n.dataExportModularInvoices,
                              countText: '${filteredInv.length}',
                              btn1Label: 'Excel (.xlsx)',
                              btn2Label: 'PDF (.pdf)',
                              disabled: _generating,
                              onBtn1: () => _exportClient(
                                kind: ExportDatasetKind.invoices,
                                isPdf: false,
                              ),
                              onBtn2: () => _exportClient(
                                kind: ExportDatasetKind.invoices,
                                isPdf: true,
                              ),
                            ),
                            _ModularExportCard(
                              width: cardW,
                              icon: LucideIcons.chartBar,
                              title: l10n.dataExportModularPnl,
                              countText: _period,
                              btn1Label: l10n.dataExportBackendCsv,
                              btn2Label: l10n.dataExportBackendPdf,
                              disabled: _generating,
                              onBtn1: () => _exportBackendPnl(isPdf: false),
                              onBtn2: () => _exportBackendPnl(isPdf: true),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    AfabInsetPanel(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            size: 16,
                            color: colors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.dataExportComplianceFooter,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExportStatTile extends StatelessWidget {
  const _ExportStatTile({
    required this.width,
    required this.label,
    this.value,
    this.child,
  });

  final double width;
  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AfabCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            child ??
                Text(
                  value ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
          ],
        ),
      ),
    );
  }
}

class _ModularExportCard extends StatelessWidget {
  const _ModularExportCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.countText,
    required this.btn1Label,
    required this.btn2Label,
    required this.disabled,
    required this.onBtn1,
    required this.onBtn2,
  });

  final double width;
  final IconData icon;
  final String title;
  final String countText;
  final String btn1Label;
  final String btn2Label;
  final bool disabled;
  final VoidCallback onBtn1;
  final VoidCallback onBtn2;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return SizedBox(
      width: width,
      child: AfabCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                AfabStatusBadge(
                  label: countText,
                  variant: AfabBadgeVariant.neutral,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton(
                  onPressed: disabled ? null : onBtn1,
                  child: Text(btn1Label),
                ),
                OutlinedButton(
                  onPressed: disabled ? null : onBtn2,
                  child: Text(btn2Label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
