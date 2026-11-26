import 'dart:convert';
import 'dart:io';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/plans/domain/plans_providers.dart';
import 'package:afab_mobile/features/plans/presentation/widgets/business_allocation_sheet.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:afab_mobile/features/settings/domain/biometric_lock_service.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Screen `SET-10`: 3-Step Account Deletion Flow (JSON backup, accurate EN/AR
/// tombstone disclosure, preflight blocking resolution + `"delete <email>"`).
class AccountDeletionFlowScreen extends ConsumerStatefulWidget {
  const AccountDeletionFlowScreen({super.key});

  @override
  ConsumerState<AccountDeletionFlowScreen> createState() =>
      _AccountDeletionFlowScreenState();
}

class _AccountDeletionFlowScreenState
    extends ConsumerState<AccountDeletionFlowScreen> {
  int _step = 1;
  bool _exporting = false;
  ({int businesses, int transactions, String filePath})? _exportDone;

  AccountDeletionPreflightDto? _preflight;
  bool _loadingPreflight = false;
  String? _preflightError;
  String? _resolvingBizId;

  final _confirmCtrl = TextEditingController();
  String? _deleteFieldError;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreflight());
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreflight() async {
    setState(() {
      _loadingPreflight = true;
      _preflightError = null;
    });
    try {
      final res =
          await ref.read(settingsRepositoryProvider).getDeletionPreflight();
      if (!mounted) return;
      setState(() {
        _preflight = res;
        _loadingPreflight = false;
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _preflightError = e.message;
        _loadingPreflight = false;
      });
    }
  }

  Future<void> _exportJson() async {
    if (_exporting) return;
    setState(() => _exporting = true);
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
      if (mounted) {
        setState(() {
          _exportDone = (
            businesses: (summary['businessesCount'] as num?)?.toInt() ?? 0,
            transactions: (summary['transactionsCount'] as num?)?.toInt() ?? 0,
            filePath: file.path,
          );
        });
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) AfabToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _archiveBlockingBusiness(BlockingBusinessDto b) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountArchiveConfirmTitle(b.businessName)),
        content: Text(l10n.deleteAccountArchiveConfirmDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAccountArchiveBizBtn),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resolvingBizId = b.businessId);
    try {
      await ref.read(businessRepositoryProvider).archiveBusiness(b.businessId);
      ref.invalidate(businessListProvider);
      await _loadPreflight();
    } on BusinessReadOnlyFailure {
      if (mounted) {
        AfabToast.showError(context, l10n.deleteAccountReadOnlyDeadlock);
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _resolvingBizId = null);
    }
  }

  Future<void> _openTransferOwnership(
    BlockingBusinessDto b,
    String currentUserId,
  ) async {
    final transferred = await showAfabBottomSheet<bool>(
      context: context,
      title: context.l10n.deleteAccountTransferTitle(b.businessName),
      builder: (ctx) => _OwnershipTransferSheet(
        businessId: b.businessId,
        businessName: b.businessName,
        currentUserId: currentUserId,
      ),
    );
    if (transferred == true && mounted) {
      ref.invalidate(businessListProvider);
      await _loadPreflight();
    }
  }

  Future<void> _openManageAllocations() async {
    try {
      final alloc = await ref.read(businessAllocationProvider.future);
      if (!mounted) return;
      if (alloc != null && alloc.businesses.isNotEmpty) {
        final ok = await showBusinessAllocationSheet(
          context,
          mode: BusinessAllocationMode.manage,
          businesses: alloc.businesses,
          maxAllowed: alloc.editableLimit,
        );
        if (ok == true && mounted) {
          await _loadPreflight();
        }
        return;
      }
    } catch (_) {}
    if (mounted) context.go('/plans');
  }

  Future<void> _submitFinalDeletion() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null || _deleting) return;
    final expected = 'delete ${user.email}'.toLowerCase();
    if (_confirmCtrl.text.trim().toLowerCase() != expected) return;

    setState(() {
      _deleting = true;
      _deleteFieldError = null;
    });
    try {
      await ref
          .read(settingsRepositoryProvider)
          .deleteMyAccount(_confirmCtrl.text.trim());
      await ref.read(biometricLockServiceProvider).clearFlag();
      await ref.read(authNotifierProvider.notifier).forceLocalLogout();
      if (mounted) {
        AfabToast.showSuccess(context, context.l10n.deleteAccountSuccessToast);
        context.go('/login');
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      if (e.statusCode == 409) {
        await _loadPreflight();
        if (mounted) AfabToast.showError(context, e.message);
      } else if (e.code.toUpperCase() == 'DELETE_CONFIRMATION_INVALID') {
        setState(() => _deleteFieldError = e.message);
      } else {
        AfabToast.showError(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final user = ref.watch(authNotifierProvider).user;
    final businesses = ref.watch(businessListProvider).value ?? const [];
    final editabilityMap = {for (final b in businesses) b.id: !b.isReadOnly};

    final email = user?.email ?? '';
    final fullName = user?.fullName ?? 'Account';
    final expectedPhrase = 'delete $email';
    final isPhraseMatch = _confirmCtrl.text.trim().toLowerCase() ==
        expectedPhrase.toLowerCase();

    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identity Summary Card
              if (user != null) ...[
                AfabInsetPanel(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                colors.primary.withValues(alpha: 0.14),
                            child: Text(
                              user.initials,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            end: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: colors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.shieldAlert,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AfabStatusBadge(
                        label: user.planTier.toUpperCase(),
                        variant: AfabBadgeVariant.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_step == 1) ...[
                AfabCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.generalSettingsExportData,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.generalSettingsExportDataSub,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      AfabButton(
                        label: l10n.deleteAccountExportBtn,
                        icon: LucideIcons.download,
                        variant: AfabButtonVariant.soft,
                        expand: true,
                        isLoading: _exporting,
                        onPressed: _exporting ? null : _exportJson,
                      ),
                      if (_exportDone != null) ...[
                        const SizedBox(height: 12),
                        AfabInsetPanel(
                          borderColor: colors.success.withValues(alpha: 0.4),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.deleteAccountExportDone(
                                  _exportDone!.transactions,
                                  _exportDone!.businesses,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.success),
                              ),
                              const SizedBox(height: 6),
                              TextButton.icon(
                                onPressed: () => SharePlus.instance.share(
                                  ShareParams(
                                    files: [
                                      XFile(
                                        _exportDone!.filePath,
                                        mimeType: 'application/json',
                                      ),
                                    ],
                                  ),
                                ),
                                icon: const Icon(LucideIcons.share2, size: 15),
                                label: Text(l10n.deleteAccountShareAgain),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      AfabButton(
                        label: _exportDone != null
                            ? l10n.deleteAccountContinueBtn
                            : l10n.deleteAccountSkipExportBtn,
                        variant: AfabButtonVariant.primary,
                        expand: true,
                        onPressed: () => setState(() => _step = 2),
                      ),
                    ],
                  ),
                ),
              ] else if (_step == 2) ...[
                AfabCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.triangleAlert,
                              size: 18,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.deleteAccountWarningBanner,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: colors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Bullet(
                        text: l10n.deleteAccountConsequence1(fullName, email),
                      ),
                      const SizedBox(height: 10),
                      _Bullet(text: l10n.deleteAccountConsequence2),
                      const SizedBox(height: 10),
                      _Bullet(text: l10n.deleteAccountConsequence3),
                      const SizedBox(height: 14),
                      Text(
                        l10n.deleteAccountIrreversible,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.danger,
                            ),
                      ),
                      const SizedBox(height: 18),
                      AfabButton(
                        label: l10n.deleteAccountReadConfirmBtn,
                        variant: AfabButtonVariant.primary,
                        expand: true,
                        onPressed: () => setState(() => _step = 3),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (_loadingPreflight)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: AfabLoader(size: 44)),
                  )
                else if (_preflightError != null || _preflight == null)
                  AfabInsetPanel(
                    borderColor: colors.danger.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _preflightError ?? l10n.deleteAccountPreflightError,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadPreflight,
                          child: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  )
                else if (!_preflight!.canDelete &&
                    _preflight!.blockingBusinesses.isNotEmpty) ...[
                  AfabCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.deleteAccountBlockingTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (_preflight!.guidance.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _preflight!.guidance,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        for (final b in _preflight!.blockingBusinesses) ...[
                          _BlockingBusinessTile(
                            blocking: b,
                            isEditable: editabilityMap[b.businessId] ?? true,
                            busy: _resolvingBizId == b.businessId,
                            onArchive: () => _archiveBlockingBusiness(b),
                            onTransfer: () => _openTransferOwnership(
                              b,
                              user?.id ?? '',
                            ),
                            onManageAlloc: _openManageAllocations,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                AfabCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.deleteAccountPhrasePrompt(expectedPhrase),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          controller: _confirmCtrl,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: expectedPhrase,
                            errorText: _deleteFieldError,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _confirmCtrl.text.isEmpty
                                    ? colors.inputBorder
                                    : (isPhraseMatch
                                        ? colors.success
                                        : colors.danger),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        hint: l10n.deleteAccountIrreversible,
                        child: AfabButton(
                          label: l10n.deleteAccountFinalBtn,
                          variant: AfabButtonVariant.danger,
                          expand: true,
                          isLoading: _deleting,
                          onPressed: (!_deleting &&
                                  isPhraseMatch &&
                                  (_preflight?.canDelete ?? false))
                              ? _submitFinalDeletion
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final bar = AppBar(
      leading: _step > 1 && !_deleting
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _step -= 1),
            )
          : null,
      title: Text(l10n.deleteAccountTitle(fullName)),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Center(
            child: AfabStatusBadge(
              label: l10n.deleteAccountStepOf(_step),
              variant: AfabBadgeVariant.neutral,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );

    final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
    if (isTablet) {
      return Scaffold(
        appBar: bar,
        body: body,
      );
    }

    return PopScope(
      canPop: !_deleting,
      child: Scaffold(
        appBar: bar,
        body: body,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _BlockingBusinessTile extends StatelessWidget {
  const _BlockingBusinessTile({
    required this.blocking,
    required this.isEditable,
    required this.busy,
    required this.onArchive,
    required this.onTransfer,
    required this.onManageAlloc,
  });

  final BlockingBusinessDto blocking;
  final bool isEditable;
  final bool busy;
  final VoidCallback onArchive;
  final VoidCallback onTransfer;
  final VoidCallback onManageAlloc;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      borderColor:
          isEditable ? colors.border : colors.warning.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                blocking.businessName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              AfabStatusBadge(
                label: l10n.deleteAccountMembersBadge(
                  blocking.activeMemberCount,
                ),
                variant: AfabBadgeVariant.neutral,
              ),
              if (!isEditable)
                AfabStatusBadge(
                  label: l10n.plansStatusLocked,
                  variant: AfabBadgeVariant.warning,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isEditable) ...[
            Text(
              l10n.deleteAccountReadOnlyDeadlock,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.warning),
            ),
            const SizedBox(height: 8),
            AfabButton(
              label: l10n.deleteAccountManageAllocBtn,
              icon: LucideIcons.slidersHorizontal,
              variant: AfabButtonVariant.secondary,
              compact: true,
              onPressed: onManageAlloc,
            ),
          ] else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (blocking.hasOtherActiveMembers)
                  AfabButton(
                    label: l10n.deleteAccountTransferBtn,
                    icon: LucideIcons.userCheck,
                    variant: AfabButtonVariant.primary,
                    compact: true,
                    onPressed: busy ? null : onTransfer,
                  ),
                AfabButton(
                  label: l10n.deleteAccountArchiveBizBtn,
                  icon: LucideIcons.archive,
                  variant: AfabButtonVariant.danger,
                  compact: true,
                  isLoading: busy,
                  onPressed: busy ? null : onArchive,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OwnershipTransferSheet extends ConsumerStatefulWidget {
  const _OwnershipTransferSheet({
    required this.businessId,
    required this.businessName,
    required this.currentUserId,
  });

  final String businessId;
  final String businessName;
  final String currentUserId;

  @override
  ConsumerState<_OwnershipTransferSheet> createState() =>
      _OwnershipTransferSheetState();
}

class _OwnershipTransferSheetState
    extends ConsumerState<_OwnershipTransferSheet> {
  List<BusinessMemberDto>? _members;
  String? _error;
  String? _selectedUserId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _error = null);
    try {
      final list = await ref
          .read(businessRepositoryProvider)
          .listMembers(widget.businessId);
      final eligible =
          list.where((m) => m.userId != widget.currentUserId).toList();
      if (!mounted) return;
      setState(() {
        _members = eligible;
        if (eligible.isNotEmpty) _selectedUserId = eligible.first.userId;
      });
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _confirmTransfer() async {
    if (_selectedUserId == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .transferOwnership(widget.businessId, _selectedUserId!);
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!),
          const SizedBox(height: 12),
          AfabButton(
            label: l10n.commonRetry,
            compact: true,
            onPressed: _loadMembers,
          ),
        ],
      );
    }

    if (_members == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: AfabLoader(size: 40)),
      );
    }

    if (_members!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(l10n.deleteAccountNoEligibleMembers),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AfabInsetPanel(
          borderColor: colors.warning.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(12),
          child: Text(
            l10n.deleteAccountTransferWarning(widget.businessName),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        for (final m in _members!)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _selectedUserId == m.userId
                  ? colors.primary.withValues(alpha: 0.1)
                  : colors.surfaceInset,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedUserId == m.userId
                      ? colors.primary
                      : colors.border,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _selectedUserId = m.userId),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _selectedUserId == m.userId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _selectedUserId == m.userId
                            ? colors.primary
                            : colors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.fullName,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                m.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AfabStatusBadge(
                        label: m.role,
                        variant: AfabBadgeVariant.neutral,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        AfabButton(
          label: l10n.deleteAccountTransferBtn,
          variant: AfabButtonVariant.primary,
          expand: true,
          isLoading: _submitting,
          onPressed: (_selectedUserId != null && !_submitting)
              ? _confirmTransfer
              : null,
        ),
      ],
    );
  }
}
