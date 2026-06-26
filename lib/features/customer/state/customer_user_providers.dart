import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/auth/models/user_model.dart';
import 'package:festivo/features/auth/services/auth_service.dart';

final userByIdProvider =
    FutureProvider.autoDispose.family<UserModel?, String>((ref, uid) {
  if (uid.isEmpty) return Future.value(null);
  return AuthService.instance.getUserById(uid);
});

final customerFirstNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'User';
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final name = doc.data()?['name'] as String?;
    if (name == null || name.trim().isEmpty) return 'User';
    return name.trim().split(' ').first;
  } catch (_) {
    return 'User';
  }
});

