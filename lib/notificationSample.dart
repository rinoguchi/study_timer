import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  await setup();
  runApp(MaterialApp(home: NotificationSamplePage()));
}

Future<void> setup() async {
  tz.initializeTimeZones();
  var tokyo = tz.getLocation('Asia/Tokyo');
  tz.setLocalLocation(tokyo);
}

class NotificationSamplePage extends StatelessWidget {
  // インスタンス生成
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// ローカル通知をスケジュールする
  void _scheduleLocalNotification() async {
    // 初期化
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
          android: AndroidInitializationSettings('app_icon'), // app_icon.pngを配置
          iOS: IOSInitializationSettings()),
    );
    // スケジュール設定する
    int id = (new math.Random()).nextInt(10);
    flutterLocalNotificationsPlugin.zonedSchedule(
        id, // id
        'Local Notification Title $id', // title
        'Local Notification Body $id', // body
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // 5秒後設定
        NotificationDetails(
            android: AndroidNotificationDetails('my_channel_id', 'my_channel_name', 'my_channel_description',
                importance: Importance.max, priority: Priority.high),
            iOS: IOSNotificationDetails()),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: FloatingActionButton(
      onPressed: _scheduleLocalNotification, // ボタンを押したら通知をスケジュールする
      child: Text("Notify"),
    )));
  }
}
