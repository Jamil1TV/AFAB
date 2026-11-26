import 'dart:convert';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConfirmedExportConfig {
  const ConfirmedExportConfig({
    required this.period,
    required this.currency,
    required this.branding,
    this.customStart,
    this.customEnd,
  });

  final String period;
  final String currency;
  final ExportBrandingOverrides branding;
  final DateTime? customStart;
  final DateTime? customEnd;
}

Future<ConfirmedExportConfig?> showExportPeriodSheet(
  BuildContext context, {
  required String initialPeriod,
  required String initialCurrency,
  DateTime? initialCustomStart,
  DateTime? initialCustomEnd,
}) {
  return showAfabBottomSheet<ConfirmedExportConfig>(
    context: context,
    title: context.l10n.dataExportSheetTitle,
    builder: (_) => _ExportPeriodSheetBody(
      initialPeriod: initialPeriod,
      initialCurrency: initialCurrency,
      initialCustomStart: initialCustomStart,
      initialCustomEnd: initialCustomEnd,
    ),
  );
}

class _ExportPeriodSheetBody extends ConsumerStatefulWidget {
  const _ExportPeriodSheetBody({
    required this.initialPeriod,
    required this.initialCurrency,
    this.initialCustomStart,
    this.initialCustomEnd,
  });

  final String initialPeriod;
  final String initialCurrency;
  final DateTime? initialCustomStart;
  final DateTime? initialCustomEnd;

  @override
  ConsumerState<_ExportPeriodSheetBody> createState() =>
      _ExportPeriodSheetBodyState();
}

class _ExportPeriodSheetBodyState
    extends ConsumerState<_ExportPeriodSheetBody> {
  final _mfCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  late String _period;
  late String _currency;
  bool _includeLogo = true;
  bool _includeSignature = true;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _currency = widget.initialCurrency;
    final biz = ref.read(activeBusinessProvider);
    final bizId = biz?.id ?? '';
    _mfCtrl.text = biz?.taxId ?? '';
    _purposeCtrl.text = biz?.description ?? '';
    _addressCtrl.text = [
      biz?.addressLine,
      biz?.city,
      biz?.country,
    ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

    if (bizId.isNotEmpty) {
      final raw = ref.read(prefsStoreProvider).getExportBrandingJson(bizId);
      if (raw != null && raw.isNotEmpty) {
        try {
          final parsed = ExportBrandingOverrides.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          );
          if (parsed.fiscalMatricule.isNotEmpty) {
            _mfCtrl.text = parsed.fiscalMatricule;
          }
          if (parsed.businessPurpose.isNotEmpty) {
            _purposeCtrl.text = parsed.businessPurpose;
          }
          if (parsed.officialAddress.isNotEmpty) {
            _addressCtrl.text = parsed.officialAddress;
          }
          _includeLogo = parsed.includeLogo;
          _includeSignature = parsed.includeSignature;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _mfCtrl.dispose();
    _purposeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final branding = ExportBrandingOverrides(
      fiscalMatricule: _mfCtrl.text.trim(),
      businessPurpose: _purposeCtrl.text.trim(),
      officialAddress: _addressCtrl.text.trim(),
      includeLogo: _includeLogo,
      includeSignature: _includeSignature,
    );
    final bizId = ref.read(activeBusinessProvider)?.id ?? '';
    if (bizId.isNotEmpty) {
      await ref
          .read(prefsStoreProvider)
          .setExportBrandingJson(bizId, branding.encode());
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      ConfirmedExportConfig(
        period: _period,
        currency: _currency,
        branding: branding,
        customStart: widget.initialCustomStart,
        customEnd: widget.initialCustomEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _mfCtrl,
              decoration: InputDecoration(
                labelText: l10n.dataExportFiscalMatricule,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeCtrl,
            decoration: InputDecoration(
              labelText: l10n.dataExportBusinessPurpose,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: l10n.dataExportOfficialAddress,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _includeLogo,
            onChanged: (v) => setState(() => _includeLogo = v),
            title: Text(
              l10n.dataExportIncludeLogo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Divider(height: 1, color: colors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _includeSignature,
            onChanged: (v) => setState(() => _includeSignature = v),
            title: Text(
              l10n.dataExportIncludeSig,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 14),
          AfabButton(
            label: l10n.dataExportGenerateShare,
            icon: LucideIcons.share2,
            variant: AfabButtonVariant.primary,
            expand: true,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
