import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_timer/notifer.dart';

/// タイマーのモード
enum TimerMode { Study, Play }

/// アプリケーション内で共有する状態
class TimeKeeper extends ChangeNotifier {
  Timer _timer;
  bool _isTimerStarted = false; // タイマーが実行中かどうか（PlayでもStudyでもOK）
  TimerMode _timerMode; // タイマーモード（Play or Study or Stop）
  bool _shouldShowDialog = false; // ダイアログを表示すべきか

  DateTime _studyTime = DateTime.utc(0, 0, 0);
  DateTime _playTime = DateTime.utc(0, 0, 0);

  bool _isTimerPaused = false; // タイマーがバックグラウンドで停止中かどうか
  DateTime _pausedTime = DateTime.utc(0, 0, 0); // タイマーがバックグラウンドで停止した時間
  Duration _willStopDuration = Duration.zero; // タイマーが停止するまでの経過時間
  int _notificationId = -1; // 通知ID
  Notifier notifier = Notifier();

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
    if (_timer != null && _timer.isActive) _timer.cancel();
    notifyListeners();
  }

  /// タイマーが00:00:00になった際のハンドラー
  /// タイマー停止・アラーム開始・ダイアログ表示を行う
  /// この処理はフォアグラウンドでしか呼ばれないので、ローカル通知は行わない
  void _handleTimeIsOver() async {
    if (totalTime != DateTime.utc(0, 0, 0) || _timerMode == TimerMode.Study) return;
    stopTimer();
    _shouldShowDialog = true;
  }

  /// アプリがバックグラウンドに遷移した際のタイマーに関連する処理をハンドリング
  void handleOnPaused() {
    if (!_isTimerStarted) return; // タイマーが起動してない時は何もしない
    _isTimerPaused = true;
    _pausedTime = DateTime.now(); // バックグラウンドに遷移した時間を記録
    if (_timerMode == TimerMode.Play && totalTime.compareTo(DateTime.utc(0, 0, 0)) > 0) {
      _willStopDuration = _studyTime.difference(_playTime);
      _notificationId = notifier.scheduleLocalNotification(_willStopDuration); // 通知をスケジュール
    }
    stopTimer();
  }

  /// アプリがバックグラウンドに復帰した際のタイマーに関連する処理をハンドリング
  void handleOnResumed() {
    if (!_isTimerPaused) return; // タイマー起動中にバックグラウンド遷移してない場合は何もしない
    Duration backgroundDuration = DateTime.now().difference(_pausedTime);
    if (_timerMode == TimerMode.Play && _willStopDuration.compareTo(Duration.zero) > 0 && _willStopDuration.compareTo(backgroundDuration) < 0) {
      _playTime = _playTime.add(totalTime.difference(DateTime.utc(0, 0, 0))); // Play時間を時間を進める
    } else {
      if (_timerMode == TimerMode.Study) {
        _studyTime = _studyTime.add(backgroundDuration);
      } else {
        _playTime = _playTime.add(backgroundDuration);
      }
      startTimer(_timerMode);
    }
    notifier.cancelScheduledLocalNotification(_notificationId); // 通知をキャンセル
    _isTimerPaused = false;
    _willStopDuration = Duration.zero;
    _notificationId = -1;
    notifyListeners();
  }
}
