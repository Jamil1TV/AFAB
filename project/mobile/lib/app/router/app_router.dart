import 'package:afab_mobile/app/shell/adaptive_shell.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/features/ai/presentation/ai_copilot_screen.dart';
import 'package:afab_mobile/features/ai/presentation/business_memory_screen.dart';
import 'package:afab_mobile/features/app_states/error_and_not_found_screen.dart';
import 'package:afab_mobile/features/app_states/maintenance_screen.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/auth/presentation/email_verification_screen.dart';
import 'package:afab_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:afab_mobile/features/auth/presentation/login_screen.dart';
import 'package:afab_mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:afab_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:afab_mobile/features/auth/presentation/signup_screen.dart';
import 'package:afab_mobile/features/auth/presentation/splash_screen.dart';
import 'package:afab_mobile/features/auth/presentation/two_factor_challenge_screen.dart';
import 'package:afab_mobile/features/budgets/presentation/budgets_screen.dart';
import 'package:afab_mobile/features/calendar/presentation/financial_calendar_screen.dart';
import 'package:afab_mobile/features/categories/presentation/manage_categories_screen.dart';
import 'package:afab_mobile/features/currencies/presentation/currencies_screen.dart';
import 'package:afab_mobile/features/customers/presentation/customer_details_screen.dart';
import 'package:afab_mobile/features/customers/presentation/customers_screen.dart';
import 'package:afab_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:afab_mobile/features/dashboard/presentation/more_hub_screen.dart';
import 'package:afab_mobile/features/expenses/presentation/expenses_screen.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/presentation/create_edit_invoice_screen.dart';
import 'package:afab_mobile/features/invoices/presentation/invoice_details_screen.dart';
import 'package:afab_mobile/features/invoices/presentation/invoices_screen.dart';
import 'package:afab_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:afab_mobile/features/plans/presentation/plans_and_subscription_screen.dart';
import 'package:afab_mobile/features/receipts/data/receipt_dto.dart';
import 'package:afab_mobile/features/receipts/presentation/receipt_viewer_screen.dart';
import 'package:afab_mobile/features/recurring/presentation/recurring_transactions_screen.dart';
import 'package:afab_mobile/features/reports/presentation/reports_screen.dart';
import 'package:afab_mobile/features/revenue/presentation/revenue_screen.dart';
import 'package:afab_mobile/features/settings/presentation/account_deletion_flow.dart';
import 'package:afab_mobile/features/settings/presentation/appearance_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/business_profile_screen.dart';
import 'package:afab_mobile/features/settings/presentation/data_export_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/general_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/language_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/security_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/settings_coming_soon_screen.dart';
import 'package:afab_mobile/features/settings/presentation/settings_home_screen.dart';
import 'package:afab_mobile/features/settings/presentation/signature_settings_screen.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/presentation/add_edit_transaction_screen.dart';
import 'package:afab_mobile/features/transactions/presentation/split_transaction_screen.dart';
import 'package:afab_mobile/features/transactions/presentation/transaction_details_screen.dart';
import 'package:afab_mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _RouterRefreshListenable();
  ref.listen<SessionState>(authNotifierProvider, (_, _) => listenable.refresh());
  ref.onDispose(listenable.dispose);

  const unauthAllowed = {
    '/login',
    '/signup',
    '/forgot-password',
    '/reset-password',
    '/maintenance',
  };

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    errorBuilder: (context, _) => const ErrorAndNotFoundScreen(isNotFound: true),
    redirect: (context, state) {
      final session = ref.read(authNotifierProvider);
      final path = state.uri.path;

      // Strip Web locale prefixes (/en/..., /ar/...) from deep links while preserving query params.
      if (path == '/en' || path == '/ar') {
        return state.uri.replace(path: '/dashboard').toString();
      }
      if (path.startsWith('/en/') || path.startsWith('/ar/')) {
        return state.uri.replace(path: path.substring(3)).toString();
      }

      if (path == '/maintenance') return null;

      if (session.status == SessionStatus.initial ||
          session.status == SessionStatus.restoring ||
          session.status == SessionStatus.biometricLocked ||
          session.status == SessionStatus.offlineError) {
        if (unauthAllowed.contains(path) || path == '/splash') {
          return null;
        }
        return '/splash';
      }

      if (session.status == SessionStatus.unauthenticated) {
        return unauthAllowed.contains(path) ? null : '/login';
      }

      if (session.status == SessionStatus.requiresTwoFactor) {
        if (path == '/two-factor' || unauthAllowed.contains(path)) {
          return null;
        }
        return '/two-factor';
      }

      // Authenticated
      if (session.needsEmailVerification) {
        return path == '/verify-email' ? null : '/verify-email';
      }
      if (session.needsOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      if (path == '/splash' ||
          path == '/login' ||
          path == '/signup' ||
          path == '/two-factor' ||
          path == '/verify-email' ||
          path == '/onboarding') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/two-factor',
        builder: (_, _) => const TwoFactorChallengeScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (_, _) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, _) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (_, state) => AddEditTransactionScreen(
          mode: TransactionFormMode.create,
          initialType: TransactionType.fromApi(
            state.uri.queryParameters['type'],
          ),
          initialDate: state.uri.queryParameters['date'],
          initialTransaction: state.extra is TransactionDto
              ? state.extra as TransactionDto
              : null,
        ),
      ),
      GoRoute(
        path: '/transactions/split',
        builder: (_, _) => const SplitTransactionScreen(),
      ),
      GoRoute(
        path: '/transactions/:transactionId/edit',
        builder: (_, state) => AddEditTransactionScreen(
          mode: TransactionFormMode.edit,
          transactionId: state.pathParameters['transactionId']!,
          initialTransaction: state.extra is TransactionDto
              ? state.extra as TransactionDto
              : null,
        ),
      ),
      GoRoute(
        path: '/transactions/:transactionId/duplicate',
        builder: (_, state) => AddEditTransactionScreen(
          mode: TransactionFormMode.duplicate,
          transactionId: state.pathParameters['transactionId']!,
          initialTransaction: state.extra is TransactionDto
              ? state.extra as TransactionDto
              : null,
        ),
      ),
      GoRoute(
        path: '/transactions/:transactionId/receipts/:receiptId',
        builder: (_, state) => ReceiptViewerScreen(
          transactionId: state.pathParameters['transactionId']!,
          receiptId: state.pathParameters['receiptId']!,
          initialReceipt:
              state.extra is ReceiptDto ? state.extra as ReceiptDto : null,
        ),
      ),
      GoRoute(
        path: '/transactions/:transactionId',
        builder: (_, state) => TransactionDetailsScreen(
          transactionId: state.pathParameters['transactionId']!,
          initialPreview: state.extra is TransactionDto
              ? state.extra as TransactionDto
              : null,
        ),
      ),
      GoRoute(
        path: '/customers/:customerId',
        builder: (_, state) => CustomerDetailsScreen(
          customerId: state.pathParameters['customerId']!,
        ),
      ),
      GoRoute(
        path: '/invoices/new',
        builder: (_, state) => CreateEditInvoiceScreen(
          mode: InvoiceFormMode.create,
          initialCustomerId: state.uri.queryParameters['customerId'],
        ),
      ),
      GoRoute(
        path: '/invoices/:invoiceId/edit',
        builder: (_, state) => CreateEditInvoiceScreen(
          mode: InvoiceFormMode.edit,
          invoiceId: state.pathParameters['invoiceId']!,
          initialInvoice:
              state.extra is InvoiceDto ? state.extra as InvoiceDto : null,
        ),
      ),
      GoRoute(
        path: '/invoices/:invoiceId',
        builder: (_, state) => InvoiceDetailsScreen(
          invoiceId: state.pathParameters['invoiceId']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdaptiveShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, _) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/copilot',
                builder: (_, state) => AiCopilotScreen(
                  initialPromptRequest: state.extra is CopilotPromptRequest
                      ? state.extra as CopilotPromptRequest
                      : null,
                  initialConversationId:
                      state.uri.queryParameters['conversationId'],
                ),
              ),
              GoRoute(
                path: '/copilot/memory',
                builder: (_, _) => const BusinessMemoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (_, _) => const InvoicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const MoreHubScreen(),
              ),
              GoRoute(
                path: '/expenses',
                builder: (_, _) => const ExpensesScreen(),
              ),
              GoRoute(
                path: '/revenue',
                builder: (_, _) => const RevenueScreen(),
              ),
              GoRoute(
                path: '/customers',
                builder: (_, _) => const CustomersScreen(),
              ),
              GoRoute(
                path: '/budgets',
                builder: (_, _) => const BudgetsScreen(),
              ),
              GoRoute(
                path: '/recurring',
                builder: (_, _) => const RecurringTransactionsScreen(),
              ),
              GoRoute(
                path: '/calendar',
                builder: (_, _) => const FinancialCalendarScreen(),
              ),
              GoRoute(
                path: '/currencies',
                builder: (_, _) => const CurrenciesScreen(),
              ),
              GoRoute(
                path: '/reports',
                builder: (_, _) => const ReportsScreen(),
              ),
              GoRoute(
                path: '/plans',
                builder: (_, state) => PlansAndSubscriptionScreen(
                  checkoutStatus: state.uri.queryParameters['checkout'],
                  sessionId: state.uri.queryParameters['session_id'],
                  changePlan: state.uri.queryParameters['changePlan'] == 'true',
                ),
              ),
              GoRoute(
                path: '/upgrade',
                redirect: (_, state) =>
                    state.uri.replace(path: '/plans').toString(),
              ),
              GoRoute(
                path: '/dashboard/plans',
                redirect: (_, state) =>
                    state.uri.replace(path: '/plans').toString(),
              ),
              GoRoute(
                path: '/dashboard/upgrade',
                redirect: (_, state) =>
                    state.uri.replace(path: '/plans').toString(),
              ),
              GoRoute(
                path: '/dashboard/settings/subscription',
                redirect: (_, state) =>
                    state.uri.replace(path: '/plans').toString(),
              ),
              GoRoute(
                path: '/dashboard/settings',
                redirect: (_, _) => '/settings',
              ),
              GoRoute(
                path: '/dashboard/settings/:tab',
                redirect: (_, state) =>
                    '/settings/${state.pathParameters['tab'] ?? 'general'}',
              ),
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsHomeScreen(),
              ),
              GoRoute(
                path: '/settings/subscription',
                builder: (_, state) => PlansAndSubscriptionScreen(
                  checkoutStatus: state.uri.queryParameters['checkout'],
                  sessionId: state.uri.queryParameters['session_id'],
                  changePlan: state.uri.queryParameters['changePlan'] == 'true',
                ),
              ),
              GoRoute(
                path: '/settings/general',
                builder: (_, _) => const GeneralSettingsScreen(),
              ),
              GoRoute(
                path: '/settings/business-profile',
                builder: (_, _) => const BusinessProfileScreen(),
              ),
              GoRoute(
                path: '/settings/security',
                builder: (_, _) => const SecuritySettingsScreen(),
              ),
              GoRoute(
                path: '/settings/appearance',
                builder: (_, _) => const AppearanceSettingsScreen(),
              ),
              GoRoute(
                path: '/settings/signature',
                builder: (_, _) => const SignatureSettingsScreen(),
              ),
              GoRoute(
                path: '/settings/data-export',
                builder: (_, _) => const DataExportSettingsScreen(),
              ),
              GoRoute(
                path: '/settings/language',
                builder: (_, _) => const LanguageSettingsScreen(),
              ),
              GoRoute(
                path: '/settings/users-permissions',
                builder: (_, _) => const SettingsComingSoonScreen(
                  tab: ComingSoonSettingsTab.usersPermissions,
                ),
              ),
              GoRoute(
                path: '/settings/notifications',
                builder: (_, _) => const SettingsComingSoonScreen(
                  tab: ComingSoonSettingsTab.notifications,
                ),
              ),
              GoRoute(
                path: '/settings/integrations',
                builder: (_, _) => const SettingsComingSoonScreen(
                  tab: ComingSoonSettingsTab.integrations,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings/delete-account',
        builder: (_, _) => const AccountDeletionFlowScreen(),
      ),
    ],
  );
});
