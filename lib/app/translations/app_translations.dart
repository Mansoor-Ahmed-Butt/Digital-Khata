import 'package:get/get.dart';

import 'en.dart';
import 'ur.dart';

/// All user-facing text. Add a key to BOTH maps (tool/check_keys.py verifies this).
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
        'en': enStrings,
        'en_US': enStrings,
        'ur': urStrings,
        'ur_PK': urStrings,
      };
}
