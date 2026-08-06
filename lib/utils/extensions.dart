/// String extensions for common operations
extension StringExtension on String {
  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Get first N characters
  String take(int count) {
    if (length <= count) return this;
    return substring(0, count);
  }

  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if valid email
  bool get isEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if valid URL
  bool get isUrl {
    return RegExp(r'^https?:\/\/').hasMatch(this);
  }

  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

/// DateTime extensions for formatting
extension DateTimeExtension on DateTime {
  /// Format as relative time (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  /// Format as short date (e.g., "Jan 15")
  String get shortDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month - 1]} $day';
  }

  /// Check if today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

/// List extensions
extension ListExtension<T> on List<T> {
  /// Safe element access
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}
