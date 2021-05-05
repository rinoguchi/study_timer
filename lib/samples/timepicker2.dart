import 'package:flutter/material.dart';

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
          final timeOfDay = await showTimePicker(
            context: context,
            initialTime: _timeOfDay,
            initialEntryMode: TimePickerEntryMode.input,
            builder: (BuildContext context, Widget child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                child: child,
              );
            },
          );
          setState(() => {_timeOfDay = timeOfDay});
        },
      ),
    ])));
  }
}
