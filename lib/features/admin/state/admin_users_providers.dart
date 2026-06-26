import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/services/auth_service.dart';

final adminUsersProvider = StreamProvider.autoDispose((ref) {
  return AuthService.instance.watchManageableUsers();
});
