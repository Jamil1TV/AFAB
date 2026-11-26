import 'dart:async';

import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/receipts/data/receipt_dto.dart';
import 'package:afab_mobile/features/receipts/data/receipt_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionReceiptsNotifier extends AsyncNotifier<List<ReceiptDto>> {
  TransactionReceiptsNotifier(this.transactionId);

  final String transactionId;

  @override
  Future<List<ReceiptDto>> build() async {
    ref.watch(activeBusinessIdProvider);
    return ref
        .read(receiptRepositoryProvider)
        .listForTransaction(transactionId);
  }

  void prependReceipt(ReceiptDto receipt) {
    final current = state.value ?? const [];
    state = AsyncValue.data([receipt, ...current]);
  }

  Future<void> deleteReceipt(String receiptId) async {
    await ref.read(receiptRepositoryProvider).deleteReceipt(receiptId);
    final current = state.value ?? const [];
    state = AsyncValue.data(
      current.where((r) => r.id != receiptId).toList(),
    );
  }
}

final transactionReceiptsProvider = AsyncNotifierProvider.autoDispose
    .family<TransactionReceiptsNotifier, List<ReceiptDto>, String>(
  TransactionReceiptsNotifier.new,
);

final receiptContentProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, receiptId) async {
  return ref.read(receiptRepositoryProvider).downloadContent(receiptId);
});

@immutable
class ReceiptUploadState {
  const ReceiptUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.cancelToken,
  });

  final bool isUploading;
  final double progress;
  final CancelToken? cancelToken;
}

class ReceiptUploadController extends Notifier<ReceiptUploadState> {
  ReceiptUploadController(this.transactionId);

  final String transactionId;

  @override
  ReceiptUploadState build() => const ReceiptUploadState();

  Future<ReceiptDto?> upload({
    required String filePath,
    required String filename,
    required String detectedMime,
  }) async {
    final cancelToken = CancelToken();
    state = ReceiptUploadState(
      isUploading: true,
      progress: 0.05,
      cancelToken: cancelToken,
    );
    try {
      final created = await ref.read(receiptRepositoryProvider).uploadReceipt(
            transactionId: transactionId,
            filePath: filePath,
            filename: filename,
            detectedMime: detectedMime,
            cancelToken: cancelToken,
            onSendProgress: (sent, total) {
              if (total > 0) {
                state = ReceiptUploadState(
                  isUploading: true,
                  progress: (sent / total).clamp(0.05, 1.0),
                  cancelToken: cancelToken,
                );
              }
            },
          );
      ref
          .read(transactionReceiptsProvider(transactionId).notifier)
          .prependReceipt(created);
      state = const ReceiptUploadState();
      return created;
    } catch (_) {
      state = const ReceiptUploadState();
      rethrow;
    }
  }

  void cancelUpload() {
    state.cancelToken?.cancel('Cancelled by user');
    state = const ReceiptUploadState();
  }
}

final receiptUploadControllerProvider = NotifierProvider.autoDispose
    .family<ReceiptUploadController, ReceiptUploadState, String>(
  ReceiptUploadController.new,
);
