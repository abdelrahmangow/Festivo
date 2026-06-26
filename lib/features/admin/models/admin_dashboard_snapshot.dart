import 'activity_model.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalVenues;
  final int pendingVenues;
  final int totalBookings;
  final int platformRevenue;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalVenues,
    required this.pendingVenues,
    required this.totalBookings,
    required this.platformRevenue,
  });
}

class AdminDashboardSnapshot {
  final AdminDashboardStats stats;
  final List<ActivityModel> activities;

  const AdminDashboardSnapshot({
    required this.stats,
    required this.activities,
  });
}
