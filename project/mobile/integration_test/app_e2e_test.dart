import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/integration/e2e_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Device Integration E2E: Auth + 2FA + Multi-Module Shell + 404 + Maintenance + Session Expiry',
    (tester) async {
      await runAllAfabE2eJourneys(tester);
    },
  );
}
