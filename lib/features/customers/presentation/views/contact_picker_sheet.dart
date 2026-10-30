import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/buttons.dart';
import '../../domain/contact_candidate.dart';

export '../../domain/contact_candidate.dart';

/// Multi-select list of phone contacts with search. Returns the chosen ones.
class ContactPickerSheet extends StatefulWidget {
  const ContactPickerSheet({super.key, required this.candidates});

  final List<ContactCandidate> candidates;

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  final Set<int> _selected = <int>{};
  String _query = '';

  List<int> get _visibleIndexes {
    final q = _query.trim().toLowerCase();
    final result = <int>[];
    for (var i = 0; i < widget.candidates.length; i++) {
      final c = widget.candidates[i];
      if (q.isEmpty || c.name.toLowerCase().contains(q) || (c.phone ?? '').contains(q)) {
        result.add(i);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final indexes = _visibleIndexes;
    final height = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('import_contacts'.tr, style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'cancel'.tr,
                  onPressed: () => Get.back<List<ContactCandidate>>(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: indexes.length,
              itemBuilder: (context, position) {
                final index = indexes[position];
                final c = widget.candidates[index];
                final checked = _selected.contains(index);
                return CheckboxListTile(
                  value: checked,
                  title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: c.phone == null ? null : Text(c.phone!, textDirection: TextDirection.ltr),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(index);
                    } else {
                      _selected.remove(index);
                    }
                  }),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'import_selected'.trParams(<String, String>{'n': '${_selected.length}'}),
                onPressed: _selected.isEmpty
                    ? null
                    : () => Get.back<List<ContactCandidate>>(
                          result: (_selected.toList()..sort())
                              .map((i) => widget.candidates[i])
                              .toList(),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
