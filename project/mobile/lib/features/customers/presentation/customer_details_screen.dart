import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/features/customers/presentation/widgets/add_edit_customer_sheet.dart';
import 'package:afab_mobile/features/customers/presentation/widgets/add_order_sheet.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
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
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen `BIZ-02`: Standalone phone route for Customer Details & Order History.
class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.customersDetailsTitle)),
      body: CustomerDetailsPane(
        customerId: customerId,
        onArchived: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/customers');
          }
        },
      ),
    );
  }
}

/// Reusable Customer Details & Order History pane (Phone screen + Tablet right pane).
/// Fixes Web bug by ALWAYS fetching `GET /customers/{id}` for hydrated `orders[]`.
class CustomerDetailsPane extends ConsumerWidget {
  const CustomerDetailsPane({
    super.key,
    required this.customerId,
    this.onArchived,
  });

  final String customerId;
  final VoidCallback? onArchived;

  Future<void> _launchContact(
    BuildContext context,
    String scheme,
    String value,
  ) async {
    final uri = Uri(scheme: scheme, path: value.trim());
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _archiveCustomer(
    BuildContext context,
    WidgetRef ref,
    CustomerDto customer,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.customersArchiveTitle),
        content: Text(l10n.customersArchiveDesc(customer.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.customersArchiveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(customersRepositoryProvider).archiveCustomer(customer.id);
      if (!context.mounted) return;
      invalidateCustomerProviders(ref, customerId: customer.id);
      AfabToast.showSuccess(context, l10n.customersArchivedToast);
      onArchived?.call();
    } on AppFailure catch (e) {
      if (context.mounted) AfabToast.showError(context, e.message);
    }
  }

  String _methodLabel(BuildContext context, String raw) {
    final l10n = context.l10n;
    return switch (raw.toUpperCase()) {
      'BANK_TRANSFER' => l10n.txMethodBankTransfer,
      'CARD' => l10n.txMethodCard,
      'CREDIT_CARD' => l10n.txMethodCreditCard,
      'CASH' => l10n.txMethodCash,
      _ => l10n.txMethodOther,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final currency = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final detailAsync = ref.watch(customerDetailProvider(customerId));

    return detailAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AfabLoader(size: 56),
        ),
      ),
      error: (err, _) => AfabErrorState(
        title: l10n.errorGenericTitle,
        message: err.toString(),
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
      ),
      data: (customer) {
        final statusVariant = switch (customer.status.toLowerCase()) {
          'active' => AfabBadgeVariant.success,
          'new' => AfabBadgeVariant.info,
          _ => AfabBadgeVariant.neutral,
        };

        return RefreshIndicator(
          onRefresh: () => ref.refresh(customerDetailProvider(customerId).future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header Card
              AfabCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.secondaryBg,
                          child: Text(
                            customer.initials,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (customer.companyName != null &&
                                  customer.companyName!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  customer.companyName!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (customer.customerCode.isNotEmpty)
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: AfabStatusBadge(
                                        label: customer.customerCode,
                                        variant: AfabBadgeVariant.primary,
                                      ),
                                    ),
                                  AfabStatusBadge(
                                    label: customer.status,
                                    variant: statusVariant,
                                  ),
                                  AfabStatusBadge(
                                    label: customer.group,
                                    variant: AfabBadgeVariant.neutral,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (customer.phone != null &&
                            customer.phone!.trim().isNotEmpty)
                          AfabButton(
                            label: l10n.customersCallAction,
                            icon: LucideIcons.phone,
                            variant: AfabButtonVariant.secondary,
                            compact: true,
                            onPressed: () =>
                                _launchContact(context, 'tel', customer.phone!),
                          ),
                        if (customer.email != null &&
                            customer.email!.trim().isNotEmpty)
                          AfabButton(
                            label: l10n.customersEmailAction,
                            icon: LucideIcons.mail,
                            variant: AfabButtonVariant.secondary,
                            compact: true,
                            onPressed: () => _launchContact(
                              context,
                              'mailto',
                              customer.email!,
                            ),
                          ),
                        if (isEditable) ...[
                          AfabButton(
                            label: l10n.commonEdit,
                            icon: LucideIcons.pencil,
                            variant: AfabButtonVariant.soft,
                            compact: true,
                            onPressed: () => showAddEditCustomerSheet(
                              context,
                              editingCustomer: customer,
                            ),
                          ),
                          AfabButton(
                            label: l10n.customersArchiveAction,
                            icon: LucideIcons.archive,
                            variant: AfabButtonVariant.danger,
                            compact: true,
                            onPressed: () =>
                                _archiveCustomer(context, ref, customer),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4 Financial KPIs bound directly to CustomerDTO
              LayoutBuilder(
                builder: (ctx, c) {
                  final cols = c.maxWidth >= 560 ? 4 : 2;
                  final tiles = [
                    _MiniMetricTile(
                      label: l10n.customersKpiTotalRevenue,
                      value: MoneyText(
                        amount: customer.totalRevenue,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.success,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _MiniMetricTile(
                      label: l10n.customersKpiInvoiced,
                      value: MoneyText(
                        amount: customer.invoicedAmount,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _MiniMetricTile(
                      label: l10n.customersKpiOutstanding,
                      value: MoneyText(
                        amount: customer.outstandingBalance,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: customer.outstandingBalance > Decimal.zero
                                  ? colors.warning
                                  : colors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _MiniMetricTile(
                      label: l10n.customersKpiOrdersCount,
                      value: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${customer.ordersCount}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tiles.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 82,
                    ),
                    itemBuilder: (_, idx) => tiles[idx],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Contact & Notes Card
              if ((customer.email != null && customer.email!.isNotEmpty) ||
                  (customer.phone != null && customer.phone!.isNotEmpty) ||
                  (customer.address != null && customer.address!.isNotEmpty) ||
                  (customer.notes != null && customer.notes!.isNotEmpty)) ...[
                AfabCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customersContactCard,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      if (customer.email != null && customer.email!.isNotEmpty)
                        _ContactRow(
                          icon: LucideIcons.mail,
                          text: customer.email!,
                          forceLtr: true,
                        ),
                      if (customer.phone != null && customer.phone!.isNotEmpty)
                        _ContactRow(
                          icon: LucideIcons.phone,
                          text: customer.phone!,
                          forceLtr: true,
                        ),
                      if (customer.address != null &&
                          customer.address!.isNotEmpty)
                        _ContactRow(
                          icon: LucideIcons.mapPin,
                          text: customer.address!,
                        ),
                      if (customer.notes != null && customer.notes!.isNotEmpty)
                        _ContactRow(
                          icon: LucideIcons.stickyNote,
                          text: customer.notes!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Order / Invoice History
              AfabCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          l10n.customersOrdersHistory,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isEditable)
                          Wrap(
                            spacing: 8,
                            children: [
                              AfabButton(
                                label: l10n.customersAddOrderBtn,
                                icon: LucideIcons.plus,
                                variant: AfabButtonVariant.soft,
                                compact: true,
                                onPressed: () => showAddOrderSheet(
                                  context,
                                  customer: customer,
                                ),
                              ),
                              AfabButton(
                                label: l10n.invoicesCreateBtn,
                                icon: LucideIcons.filePlus,
                                variant: AfabButtonVariant.secondary,
                                compact: true,
                                onPressed: () => context.push(
                                  '/invoices/new?customerId=${customer.id}',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (customer.orders.isEmpty)
                      AfabEmptyState(
                        icon: LucideIcons.receipt,
                        title: l10n.commonNoData,
                        description: l10n.customersOrdersEmpty,
                      )
                    else
                      for (var i = 0; i < customer.orders.length; i++) ...[
                        _CustomerOrderRow(
                          order: customer.orders[i],
                          currency: currency,
                          dateFormat: dateFmt,
                          locale: locale,
                          methodLabel: customer.orders[i].paymentMethod != null
                              ? _methodLabel(
                                  context,
                                  customer.orders[i].paymentMethod!,
                                )
                              : null,
                          onTap: () =>
                              context.push('/invoices/${customer.orders[i].id}'),
                        ),
                        if (i < customer.orders.length - 1)
                          const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return AfabCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: value,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    this.forceLtr = false,
  });

  final IconData icon;
  final String text;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: forceLtr
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderRow extends StatelessWidget {
  const _CustomerOrderRow({
    required this.order,
    required this.currency,
    required this.dateFormat,
    required this.locale,
    this.methodLabel,
    required this.onTap,
  });

  final CustomerInvoiceLinkDto order;
  final String currency;
  final String dateFormat;
  final String locale;
  final String? methodLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final invoiceStatus = InvoiceStatus.fromApi(order.status);
    final label = order.invoiceNumber?.isNotEmpty == true
        ? order.invoiceNumber!
        : order.orderNumber;
    final dateStr = AfabDateFormatter.formatIsoDate(
      order.orderDate,
      dateFormat: dateFormat,
      locale: locale,
    );

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AfabStatusBadge(
                  label: invoiceStatus.localizedLabel(context),
                  variant: invoiceStatus.badgeVariant,
                ),
              ],
            ),
            if (order.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                order.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(
                  [
                    dateStr,
                    if (methodLabel != null && methodLabel!.isNotEmpty)
                      methodLabel!,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                MoneyText(
                  amount: order.amount,
                  currency: currency,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
