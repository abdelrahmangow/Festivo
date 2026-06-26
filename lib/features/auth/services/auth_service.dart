import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/account_status.dart';
import '../models/user_model.dart';
import '../../notifications/services/notification_service.dart';

// ─────────────────────────────────────────────
// Authentication service — wraps FirebaseAuth + Firestore user ops
// ─────────────────────────────────────────────
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user ──────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Sign in ───────────────────────────────────────────────
  /// Returns the [UserModel] on success, or throws a descriptive [Exception].
  Future<UserModel> signIn({
    required String email,
    required String password,
    required String selectedRole, // UI label e.g. 'Customer'
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('Account not found. Please create an account.');
    }

    final user = UserModel.fromMap(uid, doc.data()!);

    if (user.isSuspended) {
      await _auth.signOut();
      throw AccountSuspendedException();
    }

    // Role mismatch check
    if (user.roleLabel != selectedRole) {
      await _auth.signOut();
      throw Exception(
        "Role mismatch. You selected '$selectedRole' but your account is "
        "registered as '${user.roleLabel}'.",
      );
    }

    return user;
  }

  // ── Create account ────────────────────────────────────────
  /// Creates a Firebase Auth user and writes the Firestore document.
  /// Returns the created [UserModel].
  Future<UserModel> createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String uiRole, // 'Customer' or 'Venue Owner'
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final firestoreRole = _uiRoleToFirestore(uiRole);

    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: firestoreRole,
      accountStatus: AccountStatus.active,
      isActive: true,
    );

    // Non-fatal Firestore write
    try {
      await _db.collection('users').doc(uid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {/* handled by caller */}

    // Sign out so the user logs in explicitly
    _auth.signOut().catchError((_) {});

    return user;
  }

  // ── Password reset ────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign out ──────────────────────────────────────────────
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await NotificationService.instance.clearRegistration(uid);
    }
    await _auth.signOut();
  }

  // ── Fetch user profile ────────────────────────────────────
  Future<UserModel?> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserById(user.uid);
  }

  /// Live stream of all registered users for admin dashboards.
  Stream<List<UserModel>> watchAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Customers and venue owners shown in the admin Users tab.
  Stream<List<UserModel>> watchManageableUsers() {
    return watchAllUsers().map(
      (users) => users.where((user) => user.isCustomerOrOwner).toList(),
    );
  }

  /// Real-time stream for a single user document (account status monitoring).
  Stream<UserModel?> watchUser(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.id, snap.data()!);
    });
  }

  /// Fetches any user document by UID (e.g. venue owner contact info).
  Future<UserModel?> getUserById(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  /// Merges only the supplied fields into the user's Firestore document.
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    if (uid.isEmpty || updates.isEmpty) return;
    await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));
  }

  /// Updates account status and keeps the legacy `isActive` flag in sync.
  Future<void> updateAccountStatus({
    required String uid,
    required String accountStatus,
  }) async {
    final isActive = accountStatus == AccountStatus.active;
    await updateUserProfile(
      uid: uid,
      updates: {
        'accountStatus': accountStatus,
        'isActive': isActive,
      },
    );
  }

  Future<void> suspendUser(String uid) => updateAccountStatus(
        uid: uid,
        accountStatus: AccountStatus.suspended,
      );

  Future<void> reactivateUser(String uid) => updateAccountStatus(
        uid: uid,
        accountStatus: AccountStatus.active,
      );

  // ── Role string conversion ────────────────────────────────
  String _uiRoleToFirestore(String uiRole) {
    switch (uiRole) {
      case 'Venue Owner':
        return 'venue_owner';
      default:
        return 'customer';
    }
  }
}

/// Thrown when a suspended account attempts to sign in.
class AccountSuspendedException implements Exception {
  @override
  String toString() => 'Account suspended';
}
