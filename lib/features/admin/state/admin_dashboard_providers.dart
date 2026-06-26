import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_dashboard_snapshot.dart';
import '../services/admin_dashboard_service.dart';

final adminDashboardServiceProvider = Provider<AdminDashboardService>((ref) {
  return AdminDashboardService();
});

final adminDashboardProvider = StreamProvider<AdminDashboardSnapshot>((ref) {
  return ref.watch(adminDashboardServiceProvider).watchDashboard();
});
