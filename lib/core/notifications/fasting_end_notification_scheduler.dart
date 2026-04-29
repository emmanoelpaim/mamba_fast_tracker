import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FastingEndNotificationScheduler {
  FastingEndNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _scheduledEndNotificationId = 91001;
  static const _startNotificationId = 91002;
  static const _endedNotificationId = 91003;

  static Future<void> ensureLocalTimeZone() async {
    tz_data.initializeTimeZones();
    final zoneId = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(zoneId));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );
  }

  Future<void> requestRuntimePermissions() async {
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> notifyFastingStarted() async {
    const androidChannelId = 'fasting_start';
    final android = AndroidNotificationDetails(
      androidChannelId,
      'Jejum',
      channelDescription: 'Alerta ao iniciar jejum',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      _startNotificationId,
      'Jejum iniciado',
      'Seu período de jejum começou.',
      NotificationDetails(android: android, iOS: ios),
    );
  }

  Future<void> notifyFastingEnded() async {
    const androidChannelId = 'fasting_end';
    final android = AndroidNotificationDetails(
      androidChannelId,
      'Jejum',
      channelDescription: 'Alerta ao concluir jejum',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      _endedNotificationId,
      'Jejum encerrado',
      'Seu jejum foi encerrado.',
      NotificationDetails(android: android, iOS: ios),
    );
  }

  Future<void> syncSchedule(FastingState state) async {
    await _plugin.cancel(_scheduledEndNotificationId);
    if (state.session.status != FastingSessionStatus.running) return;
    final remaining = state.remaining;
    if (remaining <= Duration.zero) return;
    final when = tz.TZDateTime.now(tz.local).add(remaining);
    const androidChannelId = 'fasting_end';
    final android = AndroidNotificationDetails(
      androidChannelId,
      'Jejum',
      channelDescription: 'Alerta ao concluir jejum',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.zonedSchedule(
      _scheduledEndNotificationId,
      'Jejum',
      'Tempo de jejum concluído',
      when,
      NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel() async {
    await _plugin.cancel(_scheduledEndNotificationId);
  }
}
