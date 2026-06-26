import 'package:flutter/material.dart';

import 'package:festivo/core/auth/account_status_guard.dart';
import 'package:festivo/core/notifications/notification_bootstrap.dart';
import 'package:festivo/features/admin/screens/admin_dashboard_screen.dart';
import 'package:festivo/features/auth/screens/account_suspended_screen.dart';
import 'package:festivo/features/auth/screens/login_screen.dart';
import 'package:festivo/features/customer/screens/customer_shell.dart';
import 'package:festivo/features/notifications/services/notification_service.dart';
import 'package:festivo/features/owner/screens/owner_shell.dart';

/// Routes the user to the correct home screen after login or splash auth resolution.
void navigateForRole(BuildContext context, String role, {String? userId}) {
  final normalized = role.toLowerCase().trim();
  final Widget destination;
  switch (normalized) {
    case 'admin':
      destination = const AdminDashboardScreen();
      break;
    case 'venue_owner':
      destination = const AccountStatusGuard(child: OwnerShell());
      break;
    default:
      destination = const AccountStatusGuard(child: CustomerShell());
      break;
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );

  final uid = userId?.trim();
  if (uid == null || uid.isEmpty) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    bootstrapNotifications(uid).then((result) {
      if (!result.success) {
        NotificationService.log(
          'Post-auth notification registration failed: ${result.error}',
        );
      }
      NotificationService.instance.processPendingActions();
    }).catchError((Object error, StackTrace stackTrace) {
      NotificationService.log(
        'Post-auth notification registration crashed: $error\n$stackTrace',
      );
    });
  });
}

void navigateToLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

void navigateToAccountSuspended(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AccountSuspendedScreen()),
    (route) => false,
  );
}
