import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

void main() {
  testWidgets(
    'Phase 7 Full E2E Journeys: Splash -> Login -> 2FA -> Dashboard -> Tabs -> 404 -> Maintenance -> Session Expiry',
    (tester) async {
      await runAllAfabE2eJourneys(tester);
    },
  );
}
