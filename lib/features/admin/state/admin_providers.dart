import 'package:flutter_riverpod/legacy.dart';

import '../screens/admin_dashboard_screen.dart';

final adminTabProvider = StateProvider<AdminTab>((ref) => AdminTab.overview);
