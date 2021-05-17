import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifier {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Notifier() {
    // タイムゾーンを初期化
    tz.initializeTimeZones();
    var tokyo = tz.getLocation('Asia/Tokyo');
    tz.setLocalLocation(tokyo);
  }

  /// タイマー終了を知らせるローカル通知をスケジュールする
  int scheduleLocalNotification(Duration duration) {
    print('notification scheduled.');
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: AndroidInitializationSettings('app_icon'), iOS: IOSInitializationSettings()), // app_icon.pngを配置
    );
    int notificationId = DateTime.now().hashCode;
    flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Time is over',
        'Let\'s study again!!',
        tz.TZDateTime.now(tz.local).add(duration),
        NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name', 'your channel description',
                importance: Importance.max, priority: Priority.high),
            iOS: IOSNotificationDetails()),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    return notificationId;
  }

  // スケジュールされたローカル通知をキャンセルする
  void cancelScheduledLocalNotification(int notificationId) {
    if (notificationId == null) return;
    flutterLocalNotificationsPlugin.cancel(notificationId);
  }
}
