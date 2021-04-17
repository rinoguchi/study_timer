import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

void main() {
  runApp(MaterialApp(home: AlarmSamplePage()));
}

class AlarmSamplePage extends StatelessWidget {
  final Alarm _alarm = new Alarm();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: () => {_alarm.stop()},
          child: Text("Stop"),
        ),
        FloatingActionButton(
          onPressed: () => {_alarm.start()},
          child: Text("Start"),
        ),
      ],
    )));
  }
}

class Alarm {
  Timer _timer;

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

    FlutterRingtonePlayer.playAlarm();
    if (Platform.isIOS) {
      FlutterRingtonePlayer.playAlarm();
      _timer = Timer.periodic(
        Duration(seconds: 4),
        (Timer timer) => {FlutterRingtonePlayer.playAlarm()},
      );
    }
    print("alarm started.");
  }

  /// アラームをストップする
  void stop() {
    if (Platform.isAndroid) {
      FlutterRingtonePlayer.stop();
    } else if (Platform.isIOS) {
      if (_timer != null && _timer.isActive) _timer.cancel();
    }
    print("alarm stopped.");
  }
}
