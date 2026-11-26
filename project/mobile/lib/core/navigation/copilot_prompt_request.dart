import 'package:flutter/foundation.dart';

/// Carries a pre-seeded AI Copilot prompt from business operation screens
/// (`BIZ-03`, `BIZ-04`, `BIZ-07`) to `/copilot` via GoRouter `extra`.
@immutable
class CopilotPromptRequest {
  const CopilotPromptRequest({
    required this.prompt,
    this.autoSend = true,
    this.screenContext = const {},
  });

  final String prompt;
  final bool autoSend;
  final Map<String, dynamic> screenContext;
}
