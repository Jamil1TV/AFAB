import 'dart:async';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sentinel result distinguishing "dismissed" (`null`) from "Walk-in / No Customer".
class CustomerPickerSelection {
  const CustomerPickerSelection(this.customer);

  final CustomerDto? customer;
}

Future<CustomerPickerSelection?> showCustomerPickerSheet(
  BuildContext context, {
  String? selectedCustomerId,
}) {
  return showModalBottomSheet<CustomerPickerSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => _CustomerPickerBody(selectedId: selectedCustomerId),
  );
}

class _CustomerPickerBody extends ConsumerStatefulWidget {
  const _CustomerPickerBody({this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<_CustomerPickerBody> createState() =>
      _CustomerPickerBodyState();
}

class _CustomerPickerBodyState extends ConsumerState<_CustomerPickerBody> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  final List<CustomerDto> _items = [];
  int _page = 0;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 180 &&
        !_loadingMore &&
        !_loading &&
        _page + 1 < _totalPages) {
      _fetchPage(reset: false);
    }
  }

  Future<void> _fetchPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 0;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final targetPage = reset ? 0 : _page + 1;
    try {
      final result = await ref.read(customersRepositoryProvider).listCustomers(
            search: _searchCtrl.text.trim(),
            page: targetPage,
            size: 20,
          );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.content);
        _page = result.pageNumber;
        _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPage(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.customersPickerTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: colors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.customersSearchHint,
                  isDense: true,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: _loading
                  ? const Center(child: AfabLoader(size: 48))
                  : _error != null
                      ? AfabErrorState(
                          title: l10n.errorGenericTitle,
                          message: _error!,
                          retryLabel: l10n.commonRetry,
                          onRetry: () => _fetchPage(reset: true),
                        )
                      : ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length + 1 + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: colors.border),
                          itemBuilder: (ctx, index) {
                            if (index == 0) {
                              final isWalkIn = widget.selectedId == null ||
                                  widget.selectedId!.isEmpty;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colors.surfaceInset,
                                  child: Icon(
                                    LucideIcons.userX,
                                    size: 18,
                                    color: colors.textMuted,
                                  ),
                                ),
                                title: Text(l10n.customersPickerWalkIn),
                                subtitle: Text(
                                  l10n.customersPickerWalkInDesc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isWalkIn
                                    ? Icon(
                                        LucideIcons.check,
                                        color: colors.primary,
                                        size: 18,
                                      )
                                    : null,
                                onTap: () => Navigator.of(context).pop(
                                  const CustomerPickerSelection(null),
                                ),
                              );
                            }

                            final itemIdx = index - 1;
                            if (itemIdx >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: AfabLoader(size: 32)),
                              );
                            }

                            final c = _items[itemIdx];
                            final selected = widget.selectedId == c.id;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colors.secondaryBg,
                                child: Text(
                                  c.initials,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              title: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  if (c.customerCode.isNotEmpty) c.customerCode,
                                  if (c.email != null && c.email!.isNotEmpty)
                                    c.email!,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: selected
                                  ? Icon(
                                      LucideIcons.check,
                                      color: colors.primary,
                                      size: 18,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(
                                CustomerPickerSelection(c),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
