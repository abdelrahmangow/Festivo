import 'package:flutter_riverpod/legacy.dart';

/// App-wide dark mode toggle used by shared widgets/colors.
final isDarkProvider = StateProvider<bool>((_) => false);
