import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/khata_colors.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/buttons.dart';
import '../../domain/ledger_transaction.dart';
import '../controllers/add_transaction_controller.dart';

/// Add transaction (5.7).
class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final TextEditingController _note = TextEditingController();
  final AddTransactionController _c = Get.find<AddTransactionController>();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.date.value.isAfter(now.add(const Duration(days: 1))) ? now : _c.date.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day + 1),
    );
    if (picked != null) _c.setDate(picked);
  }

  void _photoSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('take_photo'.tr),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _c.pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('choose_gallery'.tr),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _c.pickPhoto(ImageSource.gallery);
              },
            ),
            Obx(() => _c.photoPath.value == null
                ? const SizedBox.shrink()
                : ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text('remove_photo'.tr),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _c.photoPath.value = null;
                    },
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.khata;
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text(_c.customer.value?.name ?? 'add_transaction'.tr))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Obx(() => SegmentedButton<TxnType>(
                    segments: <ButtonSegment<TxnType>>[
                      ButtonSegment<TxnType>(
                          value: TxnType.credit,
                          icon: const Icon(Icons.remove),
                          label: Text('credit'.tr)),
                      ButtonSegment<TxnType>(
                          value: TxnType.payment,
                          icon: const Icon(Icons.add),
                          label: Text('payment'.tr)),
                    ],
                    selected: <TxnType>{_c.type.value},
                    onSelectionChanged: (s) => _c.type.value = s.first,
                  )),
              const SizedBox(height: 16),
              Obx(() {
                final isCredit = _c.type.value == TxnType.credit;
                final error = _c.amountError.value;
                return Column(
                  children: <Widget>[
                    Text('amount_rs'.tr, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Semantics(
                      liveRegion: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _c.displayAmount,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.displaySmall
                              ?.copyWith(color: isCredit ? colors.danger : colors.success),
                        ),
                      ),
                    ),
                    if (error != null)
                      Text(error, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                );
              }),
              const SizedBox(height: 8),
              _Keypad(onKey: _c.onKey, onBackspace: _c.onBackspace),
              const SizedBox(height: 16),
              Obx(() => OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(AppDates.full(_c.date.value)),
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'note'.tr,
                  hintText: 'enter_note'.tr,
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final path = _c.photoPath.value;
                return Row(
                  children: <Widget>[
                    Semantics(
                      button: true,
                      label: 'attach_photo'.tr,
                      child: InkWell(
                        onTap: _photoSheet,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.outline, width: 1.5),
                          ),
                          child: _c.pickingPhoto.value
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.photo_camera_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (path != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined)),
                      )
                    else
                      Expanded(child: Text('attach_photo'.tr)),
                  ],
                );
              }),
              const SizedBox(height: 24),
              Obx(() => PrimaryButton(
                    label: 'save'.tr,
                    loading: _c.saving.value,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _c.save(_note.text);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, required this.onBackspace});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, String label, VoidCallback onTap) => Expanded(
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: 56, child: Center(child: child)),
            ),
          ),
        );
    Widget digit(String d) => key(
        Text(d, style: Theme.of(context).textTheme.titleLarge), d, () => onKey(d));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: <Widget>[
          Row(children: <Widget>[digit('1'), digit('2'), digit('3')]),
          Row(children: <Widget>[digit('4'), digit('5'), digit('6')]),
          Row(children: <Widget>[digit('7'), digit('8'), digit('9')]),
          Row(children: <Widget>[
            digit('.'),
            digit('0'),
            key(const Icon(Icons.backspace_outlined), 'a11y_backspace'.tr, onBackspace),
          ]),
        ],
      ),
    );
  }
}
