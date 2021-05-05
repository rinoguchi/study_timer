import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'edit.dart';

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
      title: 'Study Timer', // Webアプリとして実行した際のページタイトル
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TimerPage(title: 'Study Timer'),
    );
  }
}

/// タイマーページ
class TimerPage extends StatefulWidget {
  // 状態オブジェクトを持つステートフルWidget
  TimerPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _TimerPageState createState() => _TimerPageState();
}

/// タイマーのモード
enum TimerMode { Study, Play }

/// タイマーページの状態を管理するクラス
class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final DateFormat formatter = DateFormat('HH:mm:ss');
  final Alarm _alarm = new Alarm();

  Timer _timer;
  bool _isTimerStarted; // タイマーが実行中かどうか（PlayでもStudyでもOK）
  TimerMode _timerMode; // タイマーモード（Play or Study）

  DateTime _studyTime; // 勉強した時間
  DateTime _playTime; // 遊んだ時間
  DateTime _differenceTime; // 勉強した時間 - 遊んだ時間

  bool _isTimerPaused; // タイマー起動中にバックグラウンド遷移してタイマー停止されたかどうか
  DateTime _pausedTime; // バックグラウンドに遷移した時間
  Duration _willStopDuration; // タイマーが停止するまでの経過時間
  int _notificationId; // 通知ID

  @override
  void initState() {
    super.initState();
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  /// アプリのライフサイクルが変更された際に実行される処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(_handleOnPaused);
    } else if (state == AppLifecycleState.resumed) {
      setState(_handleOnResumed);
    }
  }

  /// アプリがバックグラウンドに遷移した際のハンドラ
  void _handleOnPaused() {
    print('app is paused.');
    if (!_isTimerStarted) return; // タイマーが起動してない時は何もしない

    _stopTimer();
    _isTimerPaused = true;
    _pausedTime = DateTime.now(); // バックグラウンドに遷移した時間を記録
    if (_timerMode == TimerMode.Play && _differenceTime.compareTo(DateTime.utc(0, 0, 0)) > 0) {
      _willStopDuration = _studyTime.difference(_playTime);
      _notificationId = _scheduleLocalNotification(_willStopDuration); //
    }
  }

  /// アプリがフォアグラウンドに復帰した際のハンドラ
  void _handleOnResumed() {
    print('app is resumed.');
    if (!_isTimerPaused) return; // タイマー起動中にバックグラウンド遷移してない場合は何もしない
    Duration backgroundDuration = DateTime.now().difference(_pausedTime);
    if (_timerMode == TimerMode.Play && _willStopDuration != null && _willStopDuration.compareTo(backgroundDuration) < 0) {
      _playTime = _playTime.add(_differenceTime.difference(DateTime.utc(0, 0, 0))); // Play時間を時間を進める
    } else {
      if (_timerMode == TimerMode.Study) {
        _studyTime = _studyTime.add(backgroundDuration);
      } else {
        _playTime = _playTime.add(backgroundDuration);
      }
      _startTimer(_timerMode);
    }
    if (_notificationId != null) flutterLocalNotificationsPlugin.cancel(_notificationId); // 通知をキャンセル
    _differenceTime = DateTime.utc(0, 0, 0).add(_studyTime.difference(_playTime));
    _isTimerPaused = false;
    _willStopDuration = null;
    _notificationId = null;
  }

  // 初期化処理
  void _initialize() {
    if (_timer != null && _timer.isActive) _timer.cancel();
    _studyTime = DateTime.utc(0, 0, 0);
    _playTime = DateTime.utc(0, 0, 0);
    _differenceTime = DateTime.utc(0, 0, 0);
    _timerMode = null;
    _isTimerStarted = false;
    _isTimerPaused = false;
  }

  /// タイマーを開始する
  void _startTimer(TimerMode timerMode) {
    // ボタン状態を即時反映
    setState(() {
      _isTimerStarted = true;
      _timerMode = timerMode;
    });

    // タイマー起動
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (Timer timer) {
        setState(() {
          if (timerMode == TimerMode.Study) {
            _studyTime = _studyTime.add(Duration(seconds: 1));
          } else {
            _playTime = _playTime.add(Duration(seconds: 1));
          }
          _differenceTime = DateTime.utc(0, 0, 0).add(_studyTime.difference(_playTime));
        });
        _handleTimeIsOver();
      },
    );
  }

  /// タイマーを停止する
  void _stopTimer() {
    setState(() {
      _isTimerStarted = false;
      _timer.cancel();
    });
  }

  /// タイマーが00:00:00になった際のハンドラー
  /// タイマー停止・アラーム開始・ダイアログ表示を行う
  /// この処理はフォアグラウンドでしか呼ばれないので、ローカル通知は行わない
  void _handleTimeIsOver() async {
    if (_differenceTime != DateTime.utc(0, 0, 0) || _timerMode == TimerMode.Study) return;
    _stopTimer();
    _alarm.start();
    _showTimeOverDialog();
  }

  /// タイマー終了通知をダイアログ表示
  void _showTimeOverDialog() {
    showDialog(
        context: context,
        barrierDismissible: false, // ダイアログの外をタップしてダイアログを閉じれないように
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Time is over.'),
            content: Text('Please stop the alarm.'),
            actions: <Widget>[
              TextButton(
                child: Text('Stop Alarm'),
                onPressed: () {
                  _alarm.stop();
                  Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                },
              ),
            ],
          );
        });
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
        'Let\'s study again!!',
        tz.TZDateTime.now(tz.local).add(duration),
        NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name', 'your channel description',
                importance: Importance.max, priority: Priority.high),
            iOS: IOSNotificationDetails()),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    return notificationId;
  }

  /// リセットダイアログを表示
  void _showResetDialog() {
    showDialog(
        context: context,
        barrierDismissible: false, // ダイアログの外をタップしてダイアログを閉じれないように
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm'),
            content: Text('Are you sure you want to reset timer ?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  setState(_initialize);
                  Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                },
              ),
            ],
          );
        });
  }

  /// 手作業で時間を変更する
  void _editTime() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPage(_studyTime, _playTime)),
    );
    if (result == null) return;
    setState(() {
      _studyTime = result['studyTime'];
      _playTime = result['playTime'];
      _differenceTime = DateTime.utc(0, 0, 0).add(_studyTime.difference(_playTime));
    });
  }

  @override
  Widget build(BuildContext context) {
    // setStateが呼ばれる度に実行される
    // flutterがこのbuild関数を最速で実行するよう最適化してるので、個別にwidget変更を反映するより、全体をまとめてbuildする方がよい
    return Scaffold(
      appBar: AppBar(
        // ステートが所属するwidget情報には`widget`でアクセスできる
        title: Text(widget.title),
      ),
      body: Center(
        // 一つの子を持ち、中央に配置するレイアウト用のwidget
        child: Column(
            // 複数の子を持ち、縦方向に並べるwidget
            // Flutter DevToolsを開いて、Debug Printを有効にすると各Widgetの骨組みを確認できる
            mainAxisAlignment: MainAxisAlignment.center, // 主軸（縦軸）方向に中央寄せ
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  width: double.infinity,
                  child: Text(
                    _differenceTime.isBefore(DateTime.utc(0, 0, 0))
                        ? '-' + DateFormat.Hms().format(DateTime.utc(0, 0, 0).add(DateTime.utc(0, 0, 0).difference(_differenceTime)))
                        : DateFormat.Hms().format(_differenceTime),
                    style: Theme.of(context).textTheme.headline2,
                    textAlign: TextAlign.center,
                  )),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                height: 60,
                alignment: Alignment.center,
                child: Table(columnWidths: {
                  0: FixedColumnWidth(100),
                  1: FixedColumnWidth(70),
                }, children: [
                  TableRow(children: [
                    Text("Studied Time:", style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                    Text(DateFormat.Hms().format(_studyTime), style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                  ]),
                  TableRow(children: [
                    Text("Played Time:", style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                    Text(DateFormat.Hms().format(_playTime), style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                  ])
                ]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                          // FloatingActionButton だと、disabledの制御ができない
                          child: Text('Play'),
                          onPressed: !_isTimerStarted ? () => {_startTimer(TimerMode.Play)} : null, // nullを指定すると無効化
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                            onPrimary: Colors.white,
                            shape: const CircleBorder(),
                            side: _timerMode == TimerMode.Play ? BorderSide(color: Colors.red, width: 3) : BorderSide.none,
                          ))),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        child: Text('Stop'),
                        onPressed: _isTimerStarted ? _stopTimer : null,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blueGrey,
                          onPrimary: Colors.white,
                          shape: const CircleBorder(),
                        ),
                      )),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        child: Text('Study'),
                        onPressed: !_isTimerStarted ? () => {_startTimer(TimerMode.Study)} : null,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                          shape: const CircleBorder(),
                          side: _timerMode == TimerMode.Study ? BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
                        ),
                      ))
                ],
              ),
              Container(
                  width: double.infinity,
                  alignment: Alignment.bottomRight,
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    TextButton(
                      child: Text(
                        'edit',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      onPressed: _isTimerStarted ? null : _editTime,
                    ),
                    TextButton(
                      child: Text(
                        'reset',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      onPressed: _showResetDialog,
                    ),
                  ])),
            ]),
      ),
    );
  }
}

/// AndroidおよびiOS用のアラームモジュール
class Alarm {
  Timer _alarmTimer;

  /// アラームをスタートする
  void start() {
    // FlutterRingtonePlayer.play(
    //   android: AndroidSounds.notification, // Android用のサウンド
    //   ios: const IosSound(1023), // iOS用のサウンド
    //   looping: true, // Androidのみ。ストップするまで繰り返す。iOSの場合は自前でloopする必要あり。
    //   asAlarm: true, // Androidのみ。サイレントモードでも音を鳴らす
    //   volume: 0.1, // Androidのみ。0.0〜1.0
    // );
    // 以下の4つは典型的なパターンへのショートカット。
    // FlutterRingtonePlayer.playNotification(); // バックグラウンドでもスリープ中もOK。一度だけ音がなる
    // FlutterRingtonePlayer.playAlarm(); // バックグラウンドでもスリープ中もOK。止めるまでなり続ける
    // FlutterRingtonePlayer.playRingtone(); // 着信音を鳴らす。止めるまでなり続ける。playAlarmと同じだけど

    if (Platform.isAndroid) {
      FlutterRingtonePlayer.playAlarm();
    } else if (Platform.isIOS) {
      FlutterRingtonePlayer.playAlarm();
      _alarmTimer = Timer.periodic(
        Duration(seconds: 4),
        (Timer timer) {
          FlutterRingtonePlayer.playAlarm();
        },
      );
    }
    print("alarm started.");
  }

  /// アラームをストップする
  void stop() {
    if (Platform.isAndroid) {
      FlutterRingtonePlayer.stop();
    } else if (Platform.isIOS) {
      if (_alarmTimer != null && _alarmTimer.isActive) {
        _alarmTimer.cancel();
      }
    }
    print("alarm stopped.");
  }
}
