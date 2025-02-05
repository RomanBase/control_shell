void timestampDuration(String msg, DateTime start) {
  final duration = DateTime.now().difference(start);

  num microseconds = duration.inMicroseconds;

  final h = microseconds ~/ Duration.microsecondsPerHour;
  microseconds = microseconds.remainder(Duration.microsecondsPerHour);

  final m = microseconds ~/ Duration.microsecondsPerMinute;
  microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

  final s = microseconds ~/ Duration.microsecondsPerSecond;
  microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

  final ms = microseconds ~/ Duration.microsecondsPerMillisecond;

  print('$msg [${h > 0 ? '${h}h ' : ''}${m > 0 ? '${m}m ' : ''}${s > 0 ? '${s}s ' : ''}${ms}ms]');
}
