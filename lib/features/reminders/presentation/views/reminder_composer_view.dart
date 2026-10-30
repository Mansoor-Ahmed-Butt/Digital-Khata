import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/khata_colors.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/reminder.dart';
import '../controllers/reminder_controller.dart';

/// Reminder composer (5.8).
class ReminderComposerView extends GetView<ReminderController> {
  const ReminderComposerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('send_reminder'.tr)),
      body: Obx(() {
        switch (controller.status.value) {
          case UiStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case UiStatus.error:
          case UiStatus.empty:
            return ErrorRetry(messageKey: 'err_not_found', onRetry: controller.load);
          case UiStatus.data:
            return const _Composer();
        }
      }),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final ReminderController _c = Get.find<ReminderController>();
  late final TextEditingController _text = TextEditingController(text: _c.message.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('message'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 8,
              onChanged: (v) => _c.message.value = v,
              decoration: InputDecoration(
                fillColor: context.khata.primaryTint,
                helperText: 'reminder_edit_hint'.tr,
              ),
            ),
            const SizedBox(height: 16),
            Text('template'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final key in ReminderController.templates)
                      ChoiceChip(
                        label: Text(('${key}_name').tr),
                        selected: _c.template.value == key,
                        onSelected: (_) => _text.text = _c.selectTemplate(key),
                      ),
                  ],
                )),
            const SizedBox(height: 16),
            Text('channel'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() => SegmentedButton<ReminderChannel>(
                  segments: <ButtonSegment<ReminderChannel>>[
                    ButtonSegment<ReminderChannel>(
                        value: ReminderChannel.whatsapp,
                        icon: const Icon(Icons.chat_outlined),
                        label: Text('whatsapp'.tr)),
                    ButtonSegment<ReminderChannel>(
                        value: ReminderChannel.sms,
                        icon: const Icon(Icons.sms_outlined),
                        label: Text('sms'.tr)),
                  ],
                  selected: <ReminderChannel>{_c.channel.value},
                  onSelectionChanged: (s) => _c.channel.value = s.first,
                )),
            const SizedBox(height: 24),
            Obx(() => PrimaryButton(
                  label: 'send'.tr,
                  icon: Icons.send,
                  loading: _c.sending.value,
                  onPressed: () => _c.send(_text.text),
                )),
          ],
        ),
      ),
    );
  }
}
