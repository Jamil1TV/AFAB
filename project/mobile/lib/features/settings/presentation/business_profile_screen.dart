import 'package:afab_mobile/core/config/business_constants.dart';
import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/domain/settings_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `SET-03`: Business Profile (omits fake Document Uploads & fixes Cancel + 500-char logo URL).
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();

  String _industry = 'technology';
  String _country = 'US';

  BusinessDto? _baseline;
  String? _seededId;
  String? _logoError;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    _descCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  void _seedIfNeeded(BusinessDto? biz) {
    if (biz == null || _seededId == biz.id) return;
    _seededId = biz.id;
    _applyBaseline(biz);
  }

  String _resolveIndustry(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'technology';
    final low = raw.trim().toLowerCase();
    for (final opt in BusinessConstants.industries) {
      if (opt.id == low ||
          opt.nameEn.toLowerCase() == low ||
          opt.nameAr == raw.trim()) {
        return opt.id;
      }
    }
    if (low.contains('software') || low.contains('tech')) return 'technology';
    return 'other';
  }

  String _resolveCountry(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'US';
    final up = raw.trim().toUpperCase();
    for (final c in BusinessConstants.countries) {
      if (c.code == up || c.nameEn.toUpperCase() == up || c.nameAr == raw) {
        return c.code;
      }
    }
    return 'US';
  }

  void _applyBaseline(BusinessDto biz) {
    _baseline = biz;
    _nameCtrl.text = biz.name;
    _emailCtrl.text = biz.businessEmail ?? '';
    _phoneCtrl.text = biz.phoneNumber ?? '';
    _websiteCtrl.text = biz.website ?? '';
    _taxIdCtrl.text = biz.taxId ?? '';
    _addressCtrl.text = biz.addressLine ?? '';
    _cityCtrl.text = biz.city ?? '';
    _stateCtrl.text = biz.state ?? '';
    _postalCtrl.text = biz.postalCode ?? '';
    _descCtrl.text = biz.description ?? '';
    _logoUrlCtrl.text = biz.logoUrl ?? '';
    _industry = _resolveIndustry(biz.industry);
    _country = _resolveCountry(biz.country);
    _logoError = null;
  }

  bool get _isDirty {
    final b = _baseline;
    if (b == null) return false;
    return _nameCtrl.text.trim() != b.name.trim() ||
        _emailCtrl.text.trim() != (b.businessEmail ?? '').trim() ||
        _phoneCtrl.text.trim() != (b.phoneNumber ?? '').trim() ||
        _websiteCtrl.text.trim() != (b.website ?? '').trim() ||
        _taxIdCtrl.text.trim() != (b.taxId ?? '').trim() ||
        _addressCtrl.text.trim() != (b.addressLine ?? '').trim() ||
        _cityCtrl.text.trim() != (b.city ?? '').trim() ||
        _stateCtrl.text.trim() != (b.state ?? '').trim() ||
        _postalCtrl.text.trim() != (b.postalCode ?? '').trim() ||
        _descCtrl.text.trim() != (b.description ?? '').trim() ||
        _logoUrlCtrl.text.trim() != (b.logoUrl ?? '').trim() ||
        _industry != _resolveIndustry(b.industry) ||
        _country != _resolveCountry(b.country);
  }

  bool _canEdit(BusinessDto? biz) {
    if (biz == null || biz.isReadOnly) return false;
    final role = biz.userRole.toUpperCase();
    return role == 'OWNER' || role == 'ADMIN';
  }

  bool _validateLogoUrl() {
    final raw = _logoUrlCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _logoError = null);
      return true;
    }
    if (raw.startsWith('data:') ||
        raw.length > 500 ||
        (!raw.startsWith('http://') && !raw.startsWith('https://'))) {
      setState(() => _logoError = context.l10n.businessProfileLogoInvalid);
      return false;
    }
    setState(() => _logoError = null);
    return true;
  }

  Future<void> _save() async {
    final biz = _baseline;
    if (biz == null || !_canEdit(biz) || _saving) return;
    if (!_validateLogoUrl()) return;

    setState(() => _saving = true);
    try {
      final updated =
          await ref.read(businessRepositoryProvider).updateBusiness(biz.id, {
        'name': _nameCtrl.text.trim(),
        'country': _country,
        'industry': _industry,
        'businessEmail': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'taxId': _taxIdCtrl.text.trim(),
        'addressLine': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'postalCode': _postalCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'logoUrl': _logoUrlCtrl.text.trim(),
      });

      // Cache per-business metadata locally for offline export headers.
      final prefs = ref.read(prefsStoreProvider);
      await prefs.setExportBrandingJson(
        biz.id,
        ExportBrandingOverrides(
          fiscalMatricule: updated.taxId ?? _taxIdCtrl.text.trim(),
          businessPurpose: updated.description ?? _descCtrl.text.trim(),
          officialAddress: [
            updated.addressLine,
            updated.city,
            updated.country,
          ].where((e) => e != null && e.trim().isNotEmpty).join(', '),
        ).encode(),
      );

      ref.invalidate(businessListProvider);
      await invalidateAfterBusinessSettingsUpdate(ref);

      if (!mounted) return;
      setState(() {
        _saving = false;
        _applyBaseline(updated);
      });
      AfabToast.showSuccess(context, context.l10n.businessProfileSavedToast);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AfabToast.showError(context, e.message);
      }
    }
  }

  Widget _logoPreview(AfabColors colors, BusinessDto? biz) {
    final raw = _logoUrlCtrl.text.trim();
    final initials = (biz?.name.isNotEmpty == true)
        ? biz!.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : 'AF';

    final fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'AF' : initials,
        style: TextStyle(
          color: colors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (raw.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: raw,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => fallback,
        ),
      );
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    _seedIfNeeded(biz);

    final canEdit = _canEdit(biz);
    final dirty = _isDirty;

    final formCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canEdit) ...[
          AfabInsetPanel(
            borderColor: colors.warning.withValues(alpha: 0.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lock, size: 17, color: colors.warning),
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

        // Logo URL Card
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.businessProfileLogoCard,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logoPreview(colors, biz),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextField(
                            controller: _logoUrlCtrl,
                            enabled: canEdit,
                            maxLength: 500,
                            onChanged: (_) => setState(() => _logoError = null),
                            decoration: InputDecoration(
                              labelText: l10n.businessProfileLogoUrl,
                              errorText: _logoError,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            AfabButton(
                              label: l10n.businessProfileUseMonogram,
                              icon: LucideIcons.sparkles,
                              variant: AfabButtonVariant.secondary,
                              compact: true,
                              onPressed: canEdit
                                  ? () {
                                      final seed = Uri.encodeComponent(
                                        _nameCtrl.text.trim().isEmpty
                                            ? 'AFAB'
                                            : _nameCtrl.text.trim(),
                                      );
                                      setState(() {
                                        _logoUrlCtrl.text =
                                            'https://api.dicebear.com/7.x/initials/png?seed=$seed';
                                        _logoError = null;
                                      });
                                    }
                                  : null,
                            ),
                            if (_logoUrlCtrl.text.isNotEmpty && canEdit)
                              AfabButton(
                                label: l10n.editProfileRemovePhoto,
                                variant: AfabButtonVariant.ghost,
                                compact: true,
                                onPressed: () => setState(() {
                                  _logoUrlCtrl.clear();
                                  _logoError = null;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.businessProfileLogoHelp,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Business Information Card
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.businessProfileInfoCard,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameCtrl,
                enabled: canEdit,
                maxLength: 255,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.generalSettingsBizName,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _industry,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.businessProfileIndustry,
                ),
                items: [
                  for (final ind in BusinessConstants.industries)
                    DropdownMenuItem(
                      value: ind.id,
                      child: Text(ind.label(locale)),
                    ),
                ],
                onChanged: canEdit
                    ? (v) {
                        if (v != null) setState(() => _industry = v);
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _emailCtrl,
                  enabled: canEdit,
                  maxLength: 255,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.generalSettingsBizEmail,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _phoneCtrl,
                  enabled: canEdit,
                  maxLength: 50,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.editProfilePhone,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _websiteCtrl,
                  enabled: canEdit,
                  maxLength: 255,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.businessProfileWebsite,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _taxIdCtrl,
                  enabled: canEdit,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.businessProfileTaxId,
                    helperText: l10n.businessProfileTaxIdHelp,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                enabled: canEdit,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.businessProfileAddress,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      enabled: canEdit,
                      maxLength: 100,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.businessProfileCity,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stateCtrl,
                      enabled: canEdit,
                      maxLength: 100,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.businessProfileState,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _postalCtrl,
                        enabled: canEdit,
                        maxLength: 20,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.businessProfilePostal,
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _country,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.businessProfileCountry,
                      ),
                      items: [
                        for (final c in BusinessConstants.countries)
                          DropdownMenuItem(
                            value: c.code,
                            child: Text(
                              c.label(locale),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: canEdit
                          ? (v) {
                              if (v != null) setState(() => _country = v);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                enabled: canEdit,
                maxLines: 3,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.businessProfileDesc,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final summaryCard = AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _logoPreview(colors, biz),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameCtrl.text.trim().isEmpty
                          ? (biz?.name ?? 'AFAB')
                          : _nameCtrl.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      BusinessConstants.industries
                              .where((i) => i.id == _industry)
                              .firstOrNull
                              ?.label(locale) ??
                          _industry,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 10),
          _MetaRow(
            label: l10n.businessProfileMemberSince,
            value: biz?.createdAt != null ? '${biz!.createdAt!.year}' : '—',
          ),
          const SizedBox(height: 8),
          _MetaRow(
            label: l10n.businessProfileLocation,
            value: [
              if (_cityCtrl.text.trim().isNotEmpty) _cityCtrl.text.trim(),
              BusinessConstants.localizedCountry(_country, locale),
            ].join(', '),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            label: l10n.generalSettingsTimezone,
            value: biz?.timezone ?? 'UTC',
          ),
        ],
      ),
    );

    final mainBody = Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: c.maxWidth >= 840
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: formCard),
                              const SizedBox(width: 16),
                              Expanded(child: summaryCard),
                            ],
                          )
                        : Column(
                            children: [
                              summaryCard,
                              const SizedBox(height: 16),
                              formCard,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        if (canEdit && dirty)
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
                      onPressed: _saving || _baseline == null
                          ? null
                          : () => setState(() => _applyBaseline(_baseline!)),
                    ),
                    AfabButton(
                      label: l10n.generalSettingsSaveChanges,
                      icon: LucideIcons.check,
                      variant: AfabButtonVariant.primary,
                      compact: true,
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.embedded) return mainBody;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessProfileTitle),
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
      body: mainBody,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
