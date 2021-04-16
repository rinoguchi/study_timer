import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(home: TimerSamplePage()));
}

class TimerSamplePage extends StatefulWidget {
  @override
  _TimerSamplePageState createState() => _TimerSamplePageState();
}

class _TimerSamplePageState extends State<TimerSamplePage> {
  Timer _timer;
  DateTime _time;

  @override
  void initState() {
    _time = DateTime.utc(0, 0, 0);
    super.initState();
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
          ), // This trailing comma makes auto-formatting nicer for build methods.
          FloatingActionButton(
            onPressed: () {
              // タイマー起動
              _timer = Timer.periodic(
                Duration(seconds: 1),
                (Timer timer) {
                  setState(() {
                    _time = _time.add(Duration(seconds: 1));
                  });
                },
              );
            },
            child: Text("Start"),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ],
      )
    ]));
  }
}
