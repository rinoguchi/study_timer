import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  _setupTimeZone();
  runApp(TimerApp());
}

// タイムゾーンを設定する
Future<void> _setupTimeZone() async {
  tz.initializeTimeZones();
  var tokyo = tz.getLocation('Asia/Tokyo');
  tz.setLocalLocation(tokyo);
}

/// タイマーアプリ
class TimerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life cycle Event Sample Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TimerPage(title: 'Life cycle Event Sample Timer'),
    );
  }
}

/// タイマーページ
class TimerPage extends StatefulWidget {
  TimerPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _TimerPageState createState() => _TimerPageState();
}

/// タイマーページの状態を管理するクラス
class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer _timer; // タイマーオブジェクト
  DateTime _time = DateTime.utc(0, 0, 0).add(Duration(seconds: 10)); // タイマーで管理している時間。10秒をカウントダウンする設定
  bool _isTimerPaused = false; // バックグラウンドに遷移した際にタイマーがもともと起動中で、停止したかどうか
  DateTime _pausedTime; // バックグラウンドに遷移した時間
  int _notificationId; // 通知ID

  /// 初期化処理
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// ライフサイクルが変更された際に呼び出される関数をoverrideして、変更を検知
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // バックグラウンドに遷移した時
      setState(_handleOnPaused);
    } else if (state == AppLifecycleState.resumed) {
      // フォアグラウンドに復帰した時
      setState(_handleOnResumed);
    }
  }

  /// アプリがバックグラウンドに遷移した際のハンドラ
  void _handleOnPaused() {
    if (_timer.isActive) {
      _isTimerPaused = true;
      _timer.cancel(); // タイマーを停止する
    }
    _pausedTime = DateTime.now(); // バックグラウンドに遷移した時間を記録
    _notificationId = _scheduleLocalNotification(_time.difference(DateTime.utc(0, 0, 0))); // ローカル通知をスケジュール登録。詳細割愛
  }

  /// アプリがフォアグラウンドに復帰した際のハンドラ
  void _handleOnResumed() {
    if (_isTimerPaused == null) return; // タイマーが動いてなければ何もしない
    Duration backgroundDuration = DateTime.now().difference(_pausedTime); // バックグラウンドでの経過時間
    // バックグラウンドでの経過時間が終了予定を超えていた場合（この場合は通知実行済みのはず）
    if (_time.difference(DateTime.utc(0, 0, 0)).compareTo(backgroundDuration) < 0) {
      _time = DateTime.utc(0, 0, 0); // 時間をリセットする
    } else {
      _time = _time.add(-backgroundDuration); // バックグラウンド経過時間分時間を進める
      _startTimer(); // タイマーを再開する
    }
    if (_notificationId != null) flutterLocalNotificationsPlugin.cancel(_notificationId); // 通知をキャンセル
    _isTimerPaused = false; // リセット
    _notificationId = null; // リセット
    _pausedTime = null;
  }

  // タイマーを開始する
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _time = _time.add(Duration(seconds: -1));
        _handleTimeIsOver();
      });
    }); // 1秒ずつ時間を減らす
  }

  // 時間がゼロになったらタイマーを止める
  void _handleTimeIsOver() {
    if (_timer != null && _timer.isActive && _time != null && _time == DateTime.utc(0, 0, 0)) {
      _timer.cancel();
    }
  }

  /// タイマー終了をローカル通知
  int _scheduleLocalNotification(Duration duration) {
    print('notification scheduled.');
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: AndroidInitializationSettings('app_icon'), iOS: IOSInitializationSettings()), // app_icon.pngを配置
    );
    int notificationId = DateTime.now().hashCode;
    flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Time is over',
        '',
        tz.TZDateTime.now(tz.local).add(duration),
        NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name', 'your channel description',
                importance: Importance.max, priority: Priority.high),
            iOS: IOSNotificationDetails()),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    return notificationId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        DateFormat.Hms().format(_time),
        style: Theme.of(context).textTheme.headline2,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              if (_timer != null && _timer.isActive) _timer.cancel();
            },
            child: Text("Stop"),
          ),
          FloatingActionButton(
            onPressed: _startTimer,
            child: Text("Start"),
          ),
        ],
      )
    ]));
  }
}
