import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../controllers/statement_controller.dart';

/// Statement preview and share (FR-08). Owns its controller instance so the
/// Reports tab keeps its own state.
class StatementView extends StatefulWidget {
  const StatementView({super.key});

  @override
  State<StatementView> createState() => _StatementViewState();
}

class _StatementViewState extends State<StatementView> {
  static const String _tag = 'statement_route';
  late final StatementController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put<StatementController>(StatementController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<StatementController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('statement'.tr)),
      body: Obx(() {
        switch (_c.status.value) {
          case UiStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case UiStatus.error:
          case UiStatus.empty:
            return ErrorRetry(messageKey: 'err_statement_failed', onRetry: _c.buildStatement);
          case UiStatus.data:
            final bytes = _c.pdfBytes.value;
            if (bytes == null) return ErrorRetry(messageKey: 'err_statement_failed', onRetry: _c.buildStatement);
            return Column(
              children: <Widget>[
                Expanded(
                  child: PdfPreview(
                    build: (format) async => bytes,
                    useActions: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    onError: (context, error) => ErrorRetry(messageKey: 'err_statement_failed'),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Obx(() => PrimaryButton(
                          label: 'share'.tr,
                          icon: Icons.share_outlined,
                          loading: _c.sharing.value,
                          onPressed: _c.share,
                        )),
                  ),
                ),
              ],
            );
        }
      }),
    );
  }
}
