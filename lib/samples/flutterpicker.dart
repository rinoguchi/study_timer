import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(home: FlutterPickerPage()));
}

class FlutterPickerPage extends StatefulWidget {
  @override
  _FlutterPickerPageState createState() => _FlutterPickerPageState();
}

class _FlutterPickerPageState extends State<FlutterPickerPage> {
  DateTime _datetime;

  @override
  void initState() {
    _datetime = DateTime.utc(0, 0, 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(
        DateFormat.Hms().format(_datetime),
        style: Theme.of(context).textTheme.headline2,
      ),
      TextButton(
        child: Text('edit', style: TextStyle(decoration: TextDecoration.underline)),
        onPressed: () async {
          Picker(
            adapter: DateTimePickerAdapter(type: PickerDateTimeType.kHMS, value: _datetime, customColumnType: [3, 4, 5]),
            title: Text("Select Time"),
            onConfirm: (Picker picker, List value) {
              setState(() => {_datetime = DateTime.utc(0, 0, 0, value[0], value[1], value[2])});
            },
          ).showModal(context);
        },
      ),
    ])));
  }
}
