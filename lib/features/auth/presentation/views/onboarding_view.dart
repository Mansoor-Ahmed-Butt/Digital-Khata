import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/khata_card.dart';
import '../../../../app/theme/khata_colors.dart';
import '../controllers/onboarding_controller.dart';
import 'splash_lock_view.dart';

/// Onboarding (5.2): choose a language and enter the shop name.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final TextEditingController _shop = TextEditingController();
  late final OnboardingController _controller = Get.find<OnboardingController>();

  @override
  void dispose() {
    _shop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: <Widget>[
          const BrandHeader(compact: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('choose_language'.tr, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Obx(
                    () => Row(
                      children: <Widget>[
                        Expanded(
                          child: _LanguageCard(
                            label: 'English',
                            selected: _controller.language.value == 'en',
                            onTap: () => _controller.selectLanguage('en'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LanguageCard(
                            label: 'language_urdu'.tr,
                            selected: _controller.language.value == 'ur',
                            onTap: () => _controller.selectLanguage('ur'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => TextField(
                      controller: _shop,
                      textInputAction: TextInputAction.done,
                      maxLength: 60,
                      onSubmitted: (v) => _controller.submit(v),
                      decoration: InputDecoration(
                        labelText: 'shop_name'.tr,
                        hintText: 'enter_shop_name'.tr,
                        errorText: _controller.shopError.value,
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => PrimaryButton(
                      label: 'continue'.tr,
                      loading: _controller.saving.value,
                      onPressed: () => _controller.submit(_shop.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.khata;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: KhataCard(
        onTap: onTap,
        color: selected ? colors.primaryTint : null,
        borderColor: selected ? theme.colorScheme.primary : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected && theme.brightness == Brightness.light
                        ? colors.primaryDark
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
