import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// タイマーのモード
enum TimerMode { Study, Play, Stop }

/// アプリケーション内で共有する状態
class TimeKeeper extends ChangeNotifier {
  Timer _timer;
  bool _isTimerStarted = false; // タイマーが実行中かどうか（PlayでもStudyでもOK）
  TimerMode _timerMode = TimerMode.Stop; // タイマーモード（Play or Study or Stop）
  bool _shouldShowDialog = false; // ダイアログを表示すべきか

  DateTime _studyTime = DateTime.utc(0, 0, 0);
  DateTime _playTime = DateTime.utc(0, 0, 0);

  /// タイマーを開始する
  void startTimer(TimerMode timerMode) {
    _isTimerStarted = true;
    _timerMode = timerMode;

    // タイマー起動
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (Timer timer) {
        if (timerMode == TimerMode.Study) {
          _studyTime = _studyTime.add(Duration(seconds: 1));
        } else {
          _playTime = _playTime.add(Duration(seconds: 1));
        }
        _handleTimeIsOver();
        notifyListeners();
      },
    );
  }

  /// タイマーを停止する
  void stopTimer() {
    _isTimerStarted = false;
    _timerMode = TimerMode.Stop;
    if (_timer != null && _timer.isActive) _timer.cancel();
    notifyListeners();
  }

  bool get isTimerStarted => _isTimerStarted;
  TimerMode get timerMode => _timerMode;

  bool get shouldShowDialog => _shouldShowDialog;
  set shouldShowDialog(bool shouldShowDialog) {
    _shouldShowDialog = shouldShowDialog;
    notifyListeners();
  }

  DateTime get studyTime => _studyTime;
  String get studyTimeText => DateFormat.Hms().format(_studyTime);
  set studyTime(DateTime datetime) {
    _studyTime = datetime;
    notifyListeners();
  }

  DateTime get playTime => _playTime;
  String get playTimeText => DateFormat.Hms().format(_playTime);
  set playTime(DateTime datetime) {
    _playTime = datetime;
    notifyListeners();
  }

  DateTime get totalTime => DateTime.utc(0, 0, 0).add(_studyTime.difference(_playTime));
  String get totalTimeText {
    if (totalTime.isBefore(DateTime.utc(0, 0, 0))) {
      return '-' + DateFormat.Hms().format(DateTime.utc(0, 0, 0).add(DateTime.utc(0, 0, 0).difference(totalTime)));
    } else {
      return DateFormat.Hms().format(totalTime);
    }
  }

  /// タイマーが00:00:00になった際のハンドラー
  /// タイマー停止・アラーム開始・ダイアログ表示を行う
  /// この処理はフォアグラウンドでしか呼ばれないので、ローカル通知は行わない
  void _handleTimeIsOver() async {
    if (totalTime != DateTime.utc(0, 0, 0) || _timerMode == TimerMode.Study) return;
    stopTimer();
    _shouldShowDialog = true;
  }
}
