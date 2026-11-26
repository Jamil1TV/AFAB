import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class CopilotReminderCard extends StatefulWidget {
  const CopilotReminderCard({super.key, required this.draft});

  final AiActionDraftDto draft;

  @override
  State<CopilotReminderCard> createState() => _CopilotReminderCardState();
}

class _CopilotReminderCardState extends State<CopilotReminderCard> {
  String _channel = 'email';
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _waCtrl;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final p = widget.draft.payload;
    _subjectCtrl = TextEditingController(
      text: (p['emailSubject'] ?? '').toString(),
    );
    _emailCtrl = TextEditingController(
      text: (p['emailBody'] ?? '').toString(),
    );
    _waCtrl = TextEditingController(
      text: (p['whatsappBody'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _emailCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = _channel == 'email'
        ? '${_subjectCtrl.text.trim()}\n\n${_emailCtrl.text.trim()}'
        : _waCtrl.text.trim();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    AfabToast.showSuccess(context, context.l10n.aiReminderCopied);
  }

  Future<void> _launchEmail() async {
    final email = (widget.draft.payload['customerEmail'] ?? '').toString();
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': _subjectCtrl.text,
        'body': _emailCtrl.text,
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchWhatsapp() async {
    final rawPhone = (widget.draft.payload['customerPhone'] ?? '').toString();
    final cleanPhone =
        rawPhone.replaceAll(RegExp(r'[^0-9+]'), '').replaceFirst('+', '');
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(_waCtrl.text)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabInsetPanel(
      borderColor: colors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.draft.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    widget.draft.summary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'email',
                    icon: Icon(LucideIcons.mail, size: 14),
                    label: Text('Email'),
                  ),
                  ButtonSegment(
                    value: 'whatsapp',
                    icon: Icon(LucideIcons.messageCircle, size: 14),
                    label: Text('WhatsApp'),
                  ),
                ],
                selected: {_channel},
                onSelectionChanged: (sel) {
                  setState(() => _channel = sel.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_channel == 'email') ...[
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: l10n.aiReminderSubject,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(isDense: true),
            ),
          ] else
            TextField(
              controller: _waCtrl,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(isDense: true),
            ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AfabButton(
                label: _copied ? l10n.aiReminderCopied : l10n.aiReminderCopy,
                icon: _copied ? LucideIcons.check : LucideIcons.copy,
                variant: AfabButtonVariant.secondary,
                compact: true,
                onPressed: _copy,
              ),
              if (_channel == 'email')
                AfabButton(
                  label: l10n.aiReminderOpenEmail,
                  icon: LucideIcons.mail,
                  compact: true,
                  onPressed: _launchEmail,
                )
              else
                AfabButton(
                  label: l10n.aiReminderOpenWhatsapp,
                  icon: LucideIcons.messageCircle,
                  compact: true,
                  onPressed: _launchWhatsapp,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
