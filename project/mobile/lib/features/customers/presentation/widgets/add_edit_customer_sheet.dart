import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<CustomerDto?> showAddEditCustomerSheet(
  BuildContext context, {
  CustomerDto? editingCustomer,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<CustomerDto>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _AddEditCustomerForm(
              editingCustomer: editingCustomer,
              showDialogHeader: true,
            ),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<CustomerDto>(
    context: context,
    title: editingCustomer == null
        ? context.l10n.customersAddTitle
        : context.l10n.customersEditTitle,
    builder: (ctx) => _AddEditCustomerForm(
      editingCustomer: editingCustomer,
      showDialogHeader: false,
    ),
  );
}

class _AddEditCustomerForm extends ConsumerStatefulWidget {
  const _AddEditCustomerForm({
    this.editingCustomer,
    required this.showDialogHeader,
  });

  final CustomerDto? editingCustomer;
  final bool showDialogHeader;

  @override
  ConsumerState<_AddEditCustomerForm> createState() =>
      _AddEditCustomerFormState();
}

class _AddEditCustomerFormState extends ConsumerState<_AddEditCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  late String _group;
  late String _status;
  bool _submitting = false;
  String? _serverError;

  static const _groups = ['Standard', 'VIP', 'Wholesale', 'Enterprise', 'Partner'];
  static const _statuses = ['Active', 'Inactive', 'New'];

  @override
  void initState() {
    super.initState();
    final c = widget.editingCustomer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _companyCtrl = TextEditingController(text: c?.companyName ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _codeCtrl = TextEditingController(text: c?.customerCode ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _group = _groups.contains(c?.group) ? c!.group : 'Standard';
    _status = _statuses.contains(c?.status) ? c!.status : 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final request = CustomerMutationRequest(
      name: _nameCtrl.text,
      companyName: _companyCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      customerCode: _codeCtrl.text,
      group: _group,
      status: _status,
      address: _addressCtrl.text,
      notes: _notesCtrl.text,
    );

    try {
      final repo = ref.read(customersRepositoryProvider);
      final saved = widget.editingCustomer == null
          ? await repo.createCustomer(request)
          : await repo.updateCustomer(widget.editingCustomer!.id, request);
      if (!mounted) return;
      invalidateCustomerProviders(ref, customerId: saved.id);
      AfabToast.showSuccess(
        context,
        widget.editingCustomer == null
            ? context.l10n.customersCreatedToast
            : context.l10n.customersUpdatedToast,
      );
      Navigator.of(context).pop(saved);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    String groupLabel(String g) => switch (g) {
          'VIP' => l10n.customersGroupVip,
          'Wholesale' => l10n.customersGroupWholesale,
          'Enterprise' => l10n.customersGroupEnterprise,
          'Partner' => l10n.customersGroupPartner,
          _ => l10n.customersGroupStandard,
        };

    String statusLabel(String s) => switch (s) {
          'Inactive' => l10n.customersStatusInactive,
          'New' => l10n.customersStatusNew,
          _ => l10n.customersStatusActive,
        };

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showDialogHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.editingCustomer == null
                        ? l10n.customersAddTitle
                        : l10n.customersEditTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: colors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_serverError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                _serverError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.danger),
              ),
            ),
            const SizedBox(height: 12),
          ],
          AfabTextField(
            label: l10n.customersFieldName,
            controller: _nameCtrl,
            maxLength: 255,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null,
          ),
          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.customersFieldCompany,
            controller: _companyCtrl,
            maxLength: 255,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AfabTextField(
                  label: l10n.customersFieldEmail,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  forceLtr: true,
                  maxLength: 255,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    if (!t.contains('@') || !t.contains('.')) {
                      return l10n.authEmailInvalid;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AfabTextField(
                  label: l10n.customersFieldPhone,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  forceLtr: true,
                  maxLength: 50,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.customersFieldCode,
            hintText: l10n.customersFieldCodeHint,
            controller: _codeCtrl,
            forceLtr: true,
            maxLength: 40,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _group,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.customersFieldGroup,
                    isDense: true,
                  ),
                  items: [
                    for (final g in _groups)
                      DropdownMenuItem(value: g, child: Text(groupLabel(g))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _group = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.customersFieldStatus,
                    isDense: true,
                  ),
                  items: [
                    for (final s in _statuses)
                      DropdownMenuItem(value: s, child: Text(statusLabel(s))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.customersFieldAddress,
            controller: _addressCtrl,
            maxLength: 1000,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.customersFieldNotes,
            controller: _notesCtrl,
            maxLength: 2000,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AfabButton(
                  label: l10n.commonCancel,
                  variant: AfabButtonVariant.secondary,
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AfabButton(
                  label: l10n.commonSave,
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
