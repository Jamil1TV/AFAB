import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Directory resolver overridable in unit/widget tests to avoid platform channels.
typedef SignatureStorageDirResolver = Future<Directory> Function();

final signatureStorageDirProvider =
    Provider<SignatureStorageDirResolver>((ref) {
  return getApplicationDocumentsDirectory;
});

class SignatureVaultNotifier extends Notifier<SignatureRegistry> {
  SignatureVaultNotifier(this.businessId);

  final String businessId;

  String get _scopeKey => businessId.isEmpty ? 'default' : businessId;

  @override
  SignatureRegistry build() {
    final raw =
        ref.read(prefsStoreProvider).getSignatureRegistryJson(_scopeKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return SignatureRegistry.fromJson(decoded);
        }
        if (decoded is Map) {
          return SignatureRegistry.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return const SignatureRegistry();
  }

  Future<void> _persist(SignatureRegistry next) async {
    state = next;
    await ref
        .read(prefsStoreProvider)
        .setSignatureRegistryJson(_scopeKey, next.encode());
  }

  Future<Directory> _sigDir() async {
    final root = await ref.read(signatureStorageDirProvider)();
    final dir = Directory('${root.path}/signatures/$_scopeKey');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<SignatureItem> saveSignature({
    String? editingId,
    required Uint8List pngBytes,
    required String label,
    required String signatoryName,
    required String signatoryTitle,
    required bool makeActive,
  }) async {
    final now = DateTime.now();
    final id = (editingId != null && editingId.isNotEmpty)
        ? editingId
        : 'sig_${now.microsecondsSinceEpoch}';
    final dir = await _sigDir();
    final file = File('${dir.path}/$id.png');
    file.writeAsBytesSync(pngBytes);

    final existingIdx =
        state.signatures.indexWhere((s) => s.id == editingId);
    final createdAt = existingIdx >= 0
        ? state.signatures[existingIdx].createdAt
        : now;

    final updatedItem = SignatureItem(
      id: id,
      label: label.trim().isEmpty ? 'Authorized Signature' : label.trim(),
      filePath: file.path,
      signatoryName: signatoryName.trim(),
      signatoryTitle: signatoryTitle.trim().isEmpty
          ? 'Authorized Signatory'
          : signatoryTitle.trim(),
      isDefault: makeActive || state.signatures.isEmpty,
      createdAt: createdAt,
      updatedAt: now,
    );

    final nextList = List<SignatureItem>.from(state.signatures);
    if (existingIdx >= 0) {
      nextList[existingIdx] = updatedItem;
    } else {
      nextList.add(updatedItem);
    }

    final targetActiveId = (makeActive ||
            state.activeId == null ||
            state.signatures.isEmpty)
        ? id
        : state.activeId;

    final normalized = nextList
        .map((s) => s.copyWith(isDefault: s.id == targetActiveId))
        .toList();

    await _persist(
      state.copyWith(activeId: targetActiveId, signatures: normalized),
    );
    return updatedItem;
  }

  Future<void> setActive(String id) async {
    final normalized = state.signatures
        .map((s) => s.copyWith(isDefault: s.id == id))
        .toList();
    await _persist(state.copyWith(activeId: id, signatures: normalized));
  }

  Future<void> setAutoApply(bool autoApply) async {
    await _persist(state.copyWith(autoApply: autoApply));
  }

  Future<void> deleteSignature(String id) async {
    final target = state.signatures.where((s) => s.id == id).firstOrNull;
    if (target != null && target.filePath.isNotEmpty) {
      try {
        final f = File(target.filePath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }

    final remaining = state.signatures.where((s) => s.id != id).toList();
    String? nextActiveId = state.activeId == id ? null : state.activeId;
    if (nextActiveId == null && remaining.isNotEmpty) {
      nextActiveId = remaining.first.id;
    }
    final normalized = remaining
        .map((s) => s.copyWith(isDefault: s.id == nextActiveId))
        .toList();

    await _persist(
      state.copyWith(
        activeId: nextActiveId,
        clearActiveId: nextActiveId == null,
        signatures: normalized,
      ),
    );
  }

  Future<Uint8List?> readActiveBytes() async {
    final active = state.activeSignature;
    if (active == null || !state.autoApply || active.filePath.isEmpty) {
      return null;
    }
    try {
      final f = File(active.filePath);
      if (f.existsSync()) return await f.readAsBytes();
    } catch (_) {}
    return null;
  }
}

final signatureVaultProvider = NotifierProvider.family<SignatureVaultNotifier,
    SignatureRegistry, String>(
  SignatureVaultNotifier.new,
);
