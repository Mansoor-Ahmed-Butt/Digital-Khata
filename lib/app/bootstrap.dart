import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../features/auth/data/pin_store.dart';
import '../features/settings/data/settings_store.dart';

/// Everything that must exist before the first frame.
class Boot {
  const Boot({required this.database, required this.settings, required this.pinStore});

  final AppDatabase database;
  final SettingsStore settings;
  final PinStore pinStore;
}

class Bootstrap {
  Bootstrap._();

  static Future<Boot> run() async {
    final prefs = await SharedPreferences.getInstance();
    final database = await AppDatabase.open();
    return Boot(database: database, settings: SettingsStore(prefs), pinStore: PinStore());
  }
}
