import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  NotificationService._init();

  static const _moodId      = 1;
  static const _gratitudeId = 2;
  static const _sleepId     = 3;
  static const _affirmId    = 4;
  static const _welcomeId   = 5;

  static const _androidDetails = AndroidNotificationDetails(
    'mental_wellness_daily',
    'Daily Wellness Reminders',
    channelDescription: 'Gentle daily reminders to support your emotional well-being',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
    icon: '@mipmap/ic_launcher',
    styleInformation: BigTextStyleInformation(''),
  );

  static const _welcomeAndroidDetails = AndroidNotificationDetails(
    'mental_wellness_welcome',
    'Welcome Notifications',
    channelDescription: 'Warm greeting when you sign in',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
    icon: '@mipmap/ic_launcher',
    styleInformation: BigTextStyleInformation(''),
  );

  static const _details        = NotificationDetails(android: _androidDetails);
  static const _welcomeDetails = NotificationDetails(android: _welcomeAndroidDetails);

  static const _affirmations = [
    'You are allowed to take up space and be exactly who you are.',
    'Every small step forward is still progress. Be proud of yourself.',
    'You have survived every difficult day so far. You are stronger than you know.',
    'Your feelings are valid. You deserve to be heard and understood.',
    'Rest is not a reward — it is a necessity. Give yourself permission to pause.',
    'You are not behind. You are on your own timeline, and that is enough.',
    'Healing is not linear. Be gentle with yourself on the harder days.',
    'You bring something to this world that no one else can.',
  ];

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    await _rescheduleAll();
  }

  Future<void> _rescheduleAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notif_mood')      ?? true) await scheduleMoodReminder();
    if (prefs.getBool('notif_gratitude') ?? true) await scheduleGratitudeReminder();
    if (prefs.getBool('notif_sleep')     ?? true) await scheduleSleepReminder();
    if (prefs.getBool('notif_affirm')    ?? true) await scheduleAffirmationReminder();
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleDaily(int id, String title, String body, int hour, int minute) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Public schedule methods ───────────────────────────────────────────────

  Future<void> scheduleMoodReminder() => _scheduleDaily(
    _moodId,
    'Daily Mood Check-in',
    _rotatingBody([
      'A moment of reflection can shift your entire day. How are you feeling right now?',
      'Checking in with yourself is an act of self-care. Take a breath and log your mood.',
      'Your emotional patterns matter. A quick log today helps you understand yourself better.',
    ]),
    9, 0,
  );

  Future<void> scheduleGratitudeReminder() => _scheduleDaily(
    _gratitudeId,
    'Your Gratitude Journal Awaits',
    _rotatingBody([
      'Gratitude rewires the mind toward what is good. What made you smile today?',
      'Three small things you are grateful for can change the tone of your entire evening.',
      'Take two minutes to write what you appreciate today — your future self will thank you.',
    ]),
    20, 0,
  );

  Future<void> scheduleSleepReminder() => _scheduleDaily(
    _sleepId,
    'Sleep Log Reminder',
    _rotatingBody([
      'Good sleep is the foundation of emotional resilience. Log last night and set your intention for tonight.',
      'How did you sleep? Tracking your rest helps you understand your energy and mood patterns.',
      'Your sleep schedule is a form of self-respect. Take a moment to log it.',
    ]),
    22, 0,
  );

  Future<void> scheduleAffirmationReminder() => _scheduleDaily(
    _affirmId,
    'A Thought for Today',
    _rotatingBody(_affirmations),
    7, 30,
  );

  Future<void> showInstantNotification(String title, String body) async =>
      _plugin.show(0, title, body, _details);

  /// Fired immediately after a successful login — warm greeting to the user.
  Future<void> showWelcomeNotification(String username) async {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final bodies = [
      'Your wellness space is ready. Take a breath — you\'re doing great.',
      'Every day you show up for yourself is a win. Let\'s make today count.',
      'You\'ve got this. Your journey to emotional well-being continues here.',
      'Small steps, big changes. Welcome back to your safe space.',
    ];
    final body = bodies[DateTime.now().second % bodies.length];
    await _plugin.show(
      _welcomeId,
      '$greeting, $username! 👋',
      body,
      _welcomeDetails,
    );
  }

  Future<void> setEnabled(
    String key, int id, bool enabled, Future<void> Function() schedule,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
    if (enabled) {
      await schedule();
    } else {
      await _plugin.cancel(id);
    }
  }

  Future<bool> isEnabled(String key, {bool defaultVal = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultVal;
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  int get moodId      => _moodId;
  int get gratitudeId => _gratitudeId;
  int get sleepId     => _sleepId;
  int get affirmId    => _affirmId;

  String _rotatingBody(List<String> options) {
    final idx = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays % options.length;
    return options[idx];
  }
}
