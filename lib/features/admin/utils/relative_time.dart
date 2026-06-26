String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    final days = diff.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  }
  if (diff.inDays < 30) {
    final weeks = diff.inDays ~/ 7;
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  }
  if (diff.inDays < 365) {
    final months = diff.inDays ~/ 30;
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
  final years = diff.inDays ~/ 365;
  return '$years ${years == 1 ? 'year' : 'years'} ago';
}

String formatEgpAmount(int amount) {
  final negative = amount < 0;
  final value = amount.abs();
  final formatted = _withThousandsSeparator(value);
  return negative ? '-$formatted EGP' : '$formatted EGP';
}

String _withThousandsSeparator(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
}
