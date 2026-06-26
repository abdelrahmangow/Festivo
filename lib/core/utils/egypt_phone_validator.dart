const kEgyptPrefixes = ['010', '011', '012', '015'];

/// Returns null when valid, or an error message when invalid.
String? validateEgyptPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Phone number is required';

  String local;
  if (digits.length == 13 && digits.startsWith('20')) {
    local = '0${digits.substring(2)}';
  } else {
    local = digits;
  }

  if (local.length != 11) return 'Must be exactly 11 digits';
  if (!kEgyptPrefixes.any((p) => local.startsWith(p))) {
    return 'Must start with 010, 011, 012, or 015';
  }
  return null;
}

String formatEgyptPhoneForStorage(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) return '+20${digits.substring(1)}';
  if (digits.length == 13 && digits.startsWith('20')) {
    return '+$digits';
  }
  return raw.trim();
}
