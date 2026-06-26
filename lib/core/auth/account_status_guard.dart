import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/auth/screens/account_suspended_screen.dart';
import '../../features/auth/services/auth_service.dart';

/// Wraps authenticated shells and enforces account status in real time.
class AccountStatusGuard extends ConsumerStatefulWidget {
  final Widget child;

  const AccountStatusGuard({super.key, required this.child});

  @override
  ConsumerState<AccountStatusGuard> createState() => _AccountStatusGuardState();
}

class _AccountStatusGuardState extends ConsumerState<AccountStatusGuard> {
  bool _handlingSuspension = false;

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return widget.child;
    }

    final userAsync = ref.watch(accountStatusStreamProvider(uid));

    return userAsync.when(
      loading: () => widget.child,
      error: (_, __) => widget.child,
      data: (user) {
        if (user != null && user.isSuspended && !_handlingSuspension) {
          _handlingSuspension = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSuspension(context);
          });
        }
        return widget.child;
      },
    );
  }

  Future<void> _handleSuspension(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccountSuspendedScreen()),
      (route) => false,
    );
  }
}

final accountStatusStreamProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, uid) {
  return AuthService.instance.watchUser(uid);
});
