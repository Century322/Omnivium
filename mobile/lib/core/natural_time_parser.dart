class ParsedTime {
  final DateTime? absoluteTime;
  final Duration? relativeDuration;
  final bool isRecurring;
  final Duration? recurringInterval;
  final String rawText;

  const ParsedTime({
    this.absoluteTime,
    this.relativeDuration,
    this.isRecurring = false,
    this.recurringInterval,
    required this.rawText,
  });

  DateTime? get triggerTime {
    if (absoluteTime != null) return absoluteTime;
    if (relativeDuration != null) return DateTime.now().add(relativeDuration!);
    return null;
  }

  bool get isValid => absoluteTime != null || relativeDuration != null;
}

class NaturalTimeParser {
  static ParsedTime parse(String input) {
    final lower = input.trim().toLowerCase();

    final relative = _parseRelative(lower);
    if (relative != null) return relative;

    final absolute = _parseAbsolute(lower);
    if (absolute != null) return absolute;

    final recurring = _parseRecurring(lower);
    if (recurring != null) return recurring;

    return ParsedTime(rawText: input);
  }

  static ParsedTime? _parseRelative(String input) {
    final now = DateTime.now();

    final minutesMatch = RegExp(r'(\d+)\s*分[钟]?后').firstMatch(input);
    if (minutesMatch != null) {
      final mins = int.parse(minutesMatch.group(1)!);
      return ParsedTime(
        relativeDuration: Duration(minutes: mins),
        rawText: input,
      );
    }

    final hoursMatch = RegExp(r'(\d+)\s*小时后').firstMatch(input);
    if (hoursMatch != null) {
      final hrs = int.parse(hoursMatch.group(1)!);
      return ParsedTime(
        relativeDuration: Duration(hours: hrs),
        rawText: input,
      );
    }

    final daysMatch = RegExp(r'(\d+)\s*天[以]?后').firstMatch(input);
    if (daysMatch != null) {
      final d = int.parse(daysMatch.group(1)!);
      return ParsedTime(
        relativeDuration: Duration(days: d),
        rawText: input,
      );
    }

    if (input.contains('半小时后') || input.contains('30分钟后')) {
      return ParsedTime(relativeDuration: const Duration(minutes: 30), rawText: input);
    }
    if (input.contains('一小时后') || input.contains('1小时后') || input.contains('1hr后')) {
      return ParsedTime(relativeDuration: const Duration(hours: 1), rawText: input);
    }

    final minAfter = RegExp(r'(\d+)\s*min(?:ute)?s?\s*(?:later|after)?', caseSensitive: false).firstMatch(input);
    if (minAfter != null) {
      return ParsedTime(relativeDuration: Duration(minutes: int.parse(minAfter.group(1)!)), rawText: input);
    }
    final hrAfter = RegExp(r'(\d+)\s*h(?:ou)?rs?\s*(?:later|after)?', caseSensitive: false).firstMatch(input);
    if (hrAfter != null) {
      return ParsedTime(relativeDuration: Duration(hours: int.parse(hrAfter.group(1)!)), rawText: input);
    }
    final dayAfter = RegExp(r'(\d+)\s*days?\s*(?:later|after)?', caseSensitive: false).firstMatch(input);
    if (dayAfter != null) {
      return ParsedTime(relativeDuration: Duration(days: int.parse(dayAfter.group(1)!)), rawText: input);
    }

    if (input.contains('明天')) {
      return ParsedTime(relativeDuration: const Duration(days: 1), rawText: input);
    }
    if (input.contains('后天')) {
      return ParsedTime(relativeDuration: const Duration(days: 2), rawText: input);
    }
    if (input.contains('下周')) {
      return ParsedTime(relativeDuration: const Duration(days: 7), rawText: input);
    }

    return null;
  }

  static ParsedTime? _parseAbsolute(String input) {
    final timeOnly = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(input);
    if (timeOnly != null) {
      final hour = int.parse(timeOnly.group(1)!);
      final minute = int.parse(timeOnly.group(2)!);
      var target = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
      if (target.isBefore(DateTime.now())) {
        target = target.add(const Duration(days: 1));
      }
      return ParsedTime(absoluteTime: target, rawText: input);
    }

    final amPm = RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false).firstMatch(input);
    if (amPm != null) {
      var hour = int.parse(amPm.group(1)!);
      final isPm = amPm.group(2)!.toLowerCase() == 'pm';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      var target = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, 0);
      if (target.isBefore(DateTime.now())) {
        target = target.add(const Duration(days: 1));
      }
      return ParsedTime(absoluteTime: target, rawText: input);
    }

    final chineseTime = RegExp(r'(上午|下午|晚上|早上|凌晨)(\d{1,2})[点时](\d{1,2})?分?').firstMatch(input);
    if (chineseTime != null) {
      var hour = int.parse(chineseTime.group(2)!);
      final minute = chineseTime.group(3) != null ? int.parse(chineseTime.group(3)!) : 0;
      final period = chineseTime.group(1)!;
      if ((period == '下午' || period == '晚上') && hour < 12) hour += 12;
      if (period == '凌晨' && hour == 12) hour = 0;
      var target = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
      if (target.isBefore(DateTime.now())) {
        target = target.add(const Duration(days: 1));
      }
      return ParsedTime(absoluteTime: target, rawText: input);
    }

    return null;
  }

  static ParsedTime? _parseRecurring(String input) {
    final everyMin = RegExp(r'每(\d+)\s*分[钟]?').firstMatch(input);
    if (everyMin != null) {
      return ParsedTime(
        relativeDuration: Duration(minutes: int.parse(everyMin.group(1)!)),
        isRecurring: true,
        recurringInterval: Duration(minutes: int.parse(everyMin.group(1)!)),
        rawText: input,
      );
    }
    final everyHour = RegExp(r'每(\d+)\s*小时').firstMatch(input);
    if (everyHour != null) {
      return ParsedTime(
        relativeDuration: Duration(hours: int.parse(everyHour.group(1)!)),
        isRecurring: true,
        recurringInterval: Duration(hours: int.parse(everyHour.group(1)!)),
        rawText: input,
      );
    }
    if (input.contains('每天') || input.contains('每日')) {
      return ParsedTime(
        relativeDuration: const Duration(days: 1),
        isRecurring: true,
        recurringInterval: const Duration(days: 1),
        rawText: input,
      );
    }
    final everyNMin = RegExp(r'every\s+(\d+)\s+min', caseSensitive: false).firstMatch(input);
    if (everyNMin != null) {
      return ParsedTime(
        relativeDuration: Duration(minutes: int.parse(everyNMin.group(1)!)),
        isRecurring: true,
        recurringInterval: Duration(minutes: int.parse(everyNMin.group(1)!)),
        rawText: input,
      );
    }
    return null;
  }
}
