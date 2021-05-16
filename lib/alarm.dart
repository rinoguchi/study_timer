import 'dart:async';
import 'dart:io';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

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
