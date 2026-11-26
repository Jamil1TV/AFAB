import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    final initial = await connectivity.checkConnectivity();
    yield !initial.contains(ConnectivityResult.none);
    await for (final results in connectivity.onConnectivityChanged) {
      yield !results.contains(ConnectivityResult.none);
    }
  } catch (_) {
    // Graceful fallback in headless test environments without platform channels.
    yield true;
  }
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStreamProvider).value ?? true;
});
