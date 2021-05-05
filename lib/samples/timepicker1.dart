import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(home: TimePickerPage()));
}

class TimePickerPage extends StatefulWidget {
  @override
  _TimePickerPageState createState() => _TimePickerPageState();
}

class _TimePickerPageState extends State<TimePickerPage> {
  TimeOfDay _timeOfDay;

  @override
  void initState() {
    _timeOfDay = TimeOfDay(hour: 0, minute: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(
        _timeOfDay.format(context),
        style: Theme.of(context).textTheme.headline2,
      ),
      TextButton(
        child: Text(
          'edit',
          style: TextStyle(decoration: TextDecoration.underline),
        ),
        onPressed: () async {
          final TimeOfDay timeOfDay = await showTimePicker(context: context, initialTime: _timeOfDay);
          setState(() => {_timeOfDay = timeOfDay});
        },
      ),
    ])));
  }
}
