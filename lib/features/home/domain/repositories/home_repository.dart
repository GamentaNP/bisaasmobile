import '../entities/dashboard_data.dart';

// ignore: one_member_abstracts — repository pattern per Clean Arch, will grow
abstract class HomeRepository {
  Future<DashboardData> getDashboardData();
}
