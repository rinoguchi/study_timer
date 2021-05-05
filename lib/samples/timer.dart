import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(home: TimerPage()));
}

class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
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
          ),
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
          ),
        ],
      )
    ]));
  }
}
