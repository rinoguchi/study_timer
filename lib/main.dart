import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TimerApp());
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
class _TimerPageState extends State<TimerPage> {
  Timer _timer;
  bool _isTimerStarted;
  TimerMode _timerMode;

  DateTime _studyTime;
  DateTime _playTime;
  DateTime _totalTime;

  final DateFormat formatter = DateFormat('HH:mm:ss');
  final Alarm _alarm = new Alarm();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    if (_timer != null && _timer.isActive) _timer.cancel();
    _studyTime = DateTime.utc(0, 0, 0);
    _playTime = DateTime.utc(0, 0, 0);
    _totalTime = DateTime.utc(0, 0, 0);
    _timerMode = null;
    _isTimerStarted = false;
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
          _totalTime = DateTime.utc(0, 0, 0).add(_studyTime.difference(_playTime));
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
  /// タイマー停止・アラーム開始・ダイアログ表示・ローカル通知を行う
  void _handleTimeIsOver() async {
    if (_totalTime != DateTime.utc(0, 0, 0) || _timerMode == TimerMode.Study) return;
    _stopTimer();
    _alarm.start();
    _showTimeOverDialog();
    _showLocalNotification();
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
  void _showLocalNotification() {
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: AndroidInitializationSettings('app_icon'), iOS: IOSInitializationSettings()), // app_icon.pngを配置
    );
    flutterLocalNotificationsPlugin.show(
        0,
        'Time is over',
        'Please stop the alarm.',
        NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name', 'your channel description',
                importance: Importance.max, priority: Priority.high),
            iOS: IOSNotificationDetails()));
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
          child: SizedBox(
            width: 280,
            child: Column(
                // 複数の子を持ち、縦方向に並べるwidget
                // Flutter DevToolsを開いて、Debug Printを有効にすると各Widgetの骨組みを確認できる
                mainAxisAlignment: MainAxisAlignment.center, // 主軸（縦軸）方向に中央寄せ
                children: <Widget>[
                  Container(
                      width: double.infinity,
                      child: Text(
                        _totalTime.isBefore(DateTime.utc(0, 0, 0))
                            ? '-' + DateFormat.Hms().format(DateTime.utc(0, 0, 0).add(DateTime.utc(0, 0, 0).difference(_totalTime)))
                            : DateFormat.Hms().format(_totalTime),
                        style: Theme.of(context).textTheme.headline2,
                        textAlign: TextAlign.center,
                      )),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    height: 60,
                    alignment: Alignment.center,
                    child: Table(columnWidths: {
                      0: FixedColumnWidth(70),
                      1: FixedColumnWidth(70),
                    }, children: [
                      TableRow(children: [
                        Text("Studied:", style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                        Text(DateFormat.Hms().format(_studyTime), style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                      ]),
                      TableRow(children: [
                        Text("Played:", style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
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
                      height: 100,
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        child: Text(
                          'reset',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                        onPressed: _showResetDialog,
                      )),
                ]),
          ),
        ));
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
