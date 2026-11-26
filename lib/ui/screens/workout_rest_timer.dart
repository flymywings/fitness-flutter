/// Deadline-based countdown. A missed tick does not extend the rest interval.
class WorkoutRestTimer {
  static const maxSeconds = 90;

  DateTime? _deadline;

  static int limit(int seconds) => seconds.clamp(0, maxSeconds);

  void start(DateTime now, int seconds) {
    _deadline = now.add(Duration(seconds: limit(seconds)));
  }

  int secondsRemaining(DateTime now) {
    final microseconds = _remaining(now).inMicroseconds;
    return limit((microseconds / Duration.microsecondsPerSecond).ceil());
  }

  Duration? untilNextSecond(DateTime now) {
    final remaining = _remaining(now);
    if (remaining <= Duration.zero) return null;
    final fraction = remaining.inMicroseconds % Duration.microsecondsPerSecond;
    return fraction == 0
        ? const Duration(seconds: 1)
        : Duration(microseconds: fraction);
  }

  Duration _remaining(DateTime now) =>
      _deadline?.difference(now) ?? Duration.zero;

  void adjust(DateTime now, int seconds) {
    final deadline = _deadline;
    final origin = deadline != null && deadline.isAfter(now) ? deadline : now;
    final adjusted = origin.add(Duration(seconds: seconds));
    final maximum = now.add(const Duration(seconds: maxSeconds));
    _deadline = adjusted.isAfter(maximum) ? maximum : adjusted;
  }

  void skip() => _deadline = null;
}
