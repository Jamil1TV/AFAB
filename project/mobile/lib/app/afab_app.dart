import 'dart:async';

import 'package:afab_mobile/app/router/app_router.dart';
import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/core/theme/native_theme_sync.dart';
import 'package:afab_mobile/features/app_states/business_read_only_sheet.dart';
import 'package:afab_mobile/features/app_states/plan_limit_sheet.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AfabApp extends ConsumerStatefulWidget {
  const AfabApp({super.key});

  @override
  ConsumerState<AfabApp> createState() => _AfabAppState();
}

class _AfabAppState extends ConsumerState<AfabApp> {
  StreamSubscription<GlobalApiEvent>? _eventSub;
  bool _planLimitSheetOpen = false;
  bool _readOnlySheetOpen = false;
  bool _handlingSessionExpiry = false;

  @override
  void initState() {
    super.initState();
    _eventSub = ref.read(globalEventBusProvider).stream.listen(_onGlobalEvent);
    unawaited(
      NativeThemeSync.sync(ref.read(appearanceNotifierProvider).themeMode),
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _onGlobalEvent(GlobalApiEvent event) {
    final router = ref.read(appRouterProvider);
    final navContext = router.routerDelegate.navigatorKey.currentContext;

    switch (event) {
      case PlanLimitReachedEvent():
        if (_planLimitSheetOpen) return;
        if (navContext != null && navContext.mounted) {
          _planLimitSheetOpen = true;
          showPlanLimitSheet(navContext, event).whenComplete(() {
            _planLimitSheetOpen = false;
          });
        }
      case BusinessReadOnlyEvent():
        ref.invalidate(businessListProvider);
        ref.invalidate(dashboardSummaryProvider);
        if (_readOnlySheetOpen) return;
        if (navContext != null && navContext.mounted) {
          _readOnlySheetOpen = true;
          showBusinessReadOnlySheet(navContext, event).whenComplete(() {
            _readOnlySheetOpen = false;
          });
        }
      case SessionExpiredEvent():
        if (_handlingSessionExpiry) return;
        _handlingSessionExpiry = true;
        ref.read(authNotifierProvider.notifier).handleSessionExpired();
        if (navContext != null && navContext.mounted) {
          AfabToast.showError(
            navContext,
            AppLocalizations.of(navContext).authErrorSessionExpired,
          );
        }
      case MaintenanceDetectedEvent():
        if (router.routerDelegate.currentConfiguration.uri.path !=
            '/maintenance') {
          router.go('/maintenance');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(authNotifierProvider, (_, next) {
      if (next.status == SessionStatus.authenticated) {
        _handlingSessionExpiry = false;
      }
    });
    final router = ref.watch(appRouterProvider);
    final appearance = ref.watch(appearanceNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AFAB',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: appearance.themeMode,
      theme: AppearanceThemeBuilder.build(
        settings: appearance,
        brightness: Brightness.light,
        locale: locale,
      ),
      darkTheme: AppearanceThemeBuilder.build(
        settings: appearance,
        brightness: Brightness.dark,
        locale: locale,
      ),
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.45,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
