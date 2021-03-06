import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:study_timer/timeKeeper.dart';

/// 編集ページ
class EditPage extends StatefulWidget {
  final String title = 'Edit';

  @override
  _EditPageState createState() => _EditPageState();
}

/// タイマーページの状態を管理するクラス
class _EditPageState extends State<EditPage> {
  DateTime _studyTime; // 勉強した時間
  DateTime _playTime; // 遊んだ時間
  bool _isChanged = false;

  @override
  void didChangeDependencies() {
    TimeKeeper timeKeeper = context.read<TimeKeeper>();
    _studyTime = timeKeeper.studyTime;
    _playTime = timeKeeper.playTime;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    TimeKeeper timeKeeper = context.watch<TimeKeeper>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Container(
              width: 200,
              child: Row(children: [
                Text("Studied Time:"),
                TextButton(
                  child: Text(
                    'edit',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () async {
                    Picker(
                      adapter: DateTimePickerAdapter(type: PickerDateTimeType.kHMS, value: _studyTime, customColumnType: [3, 4, 5]),
                      title: Text("Select Time"),
                      onConfirm: (Picker picker, List value) {
                        setState(() => {_studyTime = DateTime.utc(0, 0, 0, value[0], value[1], value[2])});
                      },
                    ).showModal(context);
                    _isChanged = true;
                  },
                )
              ])),
          Container(
            child: Text(
              DateFormat.Hms().format(_studyTime),
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
          Container(
              width: 200,
              child: Row(children: [
                Text("Played Time:"),
                TextButton(
                  child: Text(
                    'edit',
                    textAlign: TextAlign.end,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    Picker(
                      adapter: DateTimePickerAdapter(type: PickerDateTimeType.kHMS, value: _playTime, customColumnType: [3, 4, 5]),
                      title: Text("Select Time"),
                      onConfirm: (Picker picker, List value) {
                        setState(() => {_playTime = DateTime.utc(0, 0, 0, value[0], value[1], value[2])});
                      },
                    ).showModal(context);
                    _isChanged = true;
                  },
                )
              ])),
          Container(
            child: Text(
              DateFormat.Hms().format(_playTime),
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                  width: 80,
                  height: 80,
                  child: ElevatedButton(
                      child: Text('Cancel'),
                      onPressed: () => {Navigator.pop(context)},
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueGrey,
                        onPrimary: Colors.white,
                        shape: const CircleBorder(),
                      ))),
              SizedBox(
                  width: 80,
                  height: 80,
                  child: ElevatedButton(
                      child: Text('Save'),
                      onPressed: !_isChanged
                          ? null
                          : () {
                              timeKeeper.studyTime = _studyTime;
                              timeKeeper.playTime = _playTime;
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                        shape: const CircleBorder(),
                      ))),
            ],
          ),
        ]),
      ),
    );
  }
}
