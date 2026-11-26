import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SettingsTabId {
  general,
  businessProfile,
  signature,
  subscription,
  usersPermissions,
  notifications,
  security,
  integrations,
  dataExport,
  appearance,
  language,
}

class SelectedSettingsTabNotifier extends Notifier<SettingsTabId> {
  @override
  SettingsTabId build() => SettingsTabId.general;

  void select(SettingsTabId tab) => state = tab;
}

final selectedSettingsTabProvider =
    NotifierProvider<SelectedSettingsTabNotifier, SettingsTabId>(
  SelectedSettingsTabNotifier.new,
);

final activeSessionsProvider = FutureProvider<List<SessionDto>>((ref) async {
  return ref.read(settingsRepositoryProvider).listSessions();
});

final businessMembersProvider =
    FutureProvider.family<List<BusinessMemberDto>, String>(
        (ref, businessId) async {
  return ref.read(businessRepositoryProvider).listMembers(businessId);
});

Future<void> invalidateAfterBusinessSettingsUpdate(WidgetRef ref) async {
  ref.invalidate(dashboardSummaryProvider);
}
