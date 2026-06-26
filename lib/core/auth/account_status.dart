import '../../features/auth/models/user_model.dart';

/// Canonical account status values stored in Firestore `users.accountStatus`.
class AccountStatus {
  AccountStatus._();

  static const active = 'active';
  static const suspended = 'suspended';

  /// Returns `true` when the account should be treated as suspended.
  static bool isSuspendedFromData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final status = (data['accountStatus'] as String?)?.toLowerCase().trim();
    if (status == suspended) return true;
    if (status == active) return false;

    // Legacy fallback for documents that only have `isActive`.
    return data['isActive'] == false;
  }

  static bool isSuspended(UserModel user) => user.isSuspended;

  static String statusLabelFromData(Map<String, dynamic>? data) =>
      isSuspendedFromData(data) ? 'Suspended' : 'Active';
}
