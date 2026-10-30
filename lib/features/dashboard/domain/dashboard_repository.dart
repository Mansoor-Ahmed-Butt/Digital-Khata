import 'dashboard_data.dart';

abstract class DashboardRepository {
  Stream<DashboardData> watch();
}
