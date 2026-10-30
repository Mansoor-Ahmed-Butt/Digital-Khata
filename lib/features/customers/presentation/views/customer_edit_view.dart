import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/money_widgets.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/customer.dart';
import '../controllers/customer_form_controller.dart';

/// Add / edit customer (5.5).
class CustomerEditView extends GetView<CustomerFormController> {
  const CustomerEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text((controller.isEdit ? 'edit_customer' : 'add_customer').tr)),
      body: Obx(() {
        switch (controller.status.value) {
          case UiStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case UiStatus.error:
          case UiStatus.empty:
            return ErrorRetry(messageKey: 'err_not_found', onRetry: controller.load);
          case UiStatus.data:
            return _CustomerForm(initial: controller.initial);
        }
      }),
    );
  }
}

class _CustomerForm extends StatefulWidget {
  const _CustomerForm({required this.initial});

  final Customer? initial;

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _opening;
  late final TextEditingController _limit;
  late final TextEditingController _notes;
  final CustomerFormController _c = Get.find<CustomerFormController>();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _phone = TextEditingController(text: i?.phone ?? '');
    _address = TextEditingController(text: i?.address ?? '');
    _opening = TextEditingController(
        text: i == null || i.openingBalance == 0 ? '' : Money.format(i.openingBalance).replaceAll(',', ''));
    _limit = TextEditingController(
        text: i?.creditLimit == null ? '' : Money.format(i!.creditLimit!).replaceAll(',', ''));
    _notes = TextEditingController(text: i?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _opening.dispose();
    _limit.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _c.save(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
      openingBalance: _opening.text,
      creditLimit: _limit.text,
      notes: _notes.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Obx(() => TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: 'customer_name'.tr,
                    errorText: _c.nameError.value,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                )),
            const SizedBox(height: 8),
            Obx(() => TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr,
                    hintText: '03XXXXXXXXX',
                    errorText: _c.phoneError.value,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                )),
            const SizedBox(height: 16),
            TextField(
              controller: _address,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'address'.tr,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => MoneyField(
                  controller: _opening,
                  label: 'opening_balance'.tr,
                  allowNegative: true,
                  errorText: _c.balanceError.value,
                )),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('opening_balance_hint'.tr, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            Obx(() => MoneyField(
                  controller: _limit,
                  label: 'credit_limit'.tr,
                  errorText: _c.limitError.value,
                )),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'notes'.tr,
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => PrimaryButton(
                  label: 'save'.tr,
                  loading: _c.saving.value,
                  onPressed: _submit,
                )),
          ],
        ),
      ),
    );
  }
}
