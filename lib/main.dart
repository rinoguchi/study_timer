import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_timer/timeKeeper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'alarm.dart';
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
        home: ChangeNotifierProvider(
          create: (context) => TimeKeeper(),
          child: TimerPage(),
        ));
  }
}

/// タイマーページ
class TimerPage extends StatefulWidget {
  final String title = 'Study Timer';
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// アプリのライフサイクルが変更された際に実行される処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    TimeKeeper timeKeeper = context.read<TimeKeeper>();
    if (state == AppLifecycleState.paused) {
      print('app is paused.');
      timeKeeper.handleOnPaused();
    } else if (state == AppLifecycleState.resumed) {
      print('app is resumed.');
      timeKeeper.handleOnResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    TimeKeeper timeKeeper = context.watch<TimeKeeper>();

    /// 編集画面を表示する
    void _startEdit() {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
                  value: timeKeeper,
                  child: EditPage(),
                )),
      );
    }

    /// タイマー終了通知をダイアログ表示
    if (timeKeeper.shouldShowDialog) {
      Alarm alarm = Alarm();
      alarm.start();
      // NOTE: setState() or markNeedsBuild() called during build. エラーの回避のため
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      alarm.stop();
                      timeKeeper.shouldShowDialog = false;
                      Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                    },
                  ),
                ],
              );
            });
      });
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
                    timeKeeper.stopTimer();
                    timeKeeper.studyTime = DateTime.utc(0, 0, 0);
                    timeKeeper.playTime = DateTime.utc(0, 0, 0);

                    Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                  },
                ),
              ],
            );
          });
    }

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
                    timeKeeper.totalTimeText,
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
                    Text(timeKeeper.studyTimeText, style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                  ]),
                  TableRow(children: [
                    Text("Played Time:", style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
                    Text(timeKeeper.playTimeText, style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.start),
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
                          onPressed: !timeKeeper.isTimerStarted ? () => {timeKeeper.startTimer(TimerMode.Play)} : null, // nullを指定すると無効化
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                            onPrimary: Colors.white,
                            shape: const CircleBorder(),
                            side: timeKeeper.timerMode == TimerMode.Play ? BorderSide(color: Colors.red, width: 3) : BorderSide.none,
                          ))),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        child: Text('Stop'),
                        onPressed: timeKeeper.isTimerStarted ? timeKeeper.stopTimer : null,
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
                        onPressed: !timeKeeper.isTimerStarted ? () => {timeKeeper.startTimer(TimerMode.Study)} : null,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                          shape: const CircleBorder(),
                          side: timeKeeper.timerMode == TimerMode.Study ? BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
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
                      onPressed: timeKeeper.isTimerStarted ? null : _startEdit,
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
