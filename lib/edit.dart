import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';

/// 編集ページ
class EditPage extends StatefulWidget {
  final String title = 'Edit';
  final DateTime studyTime;
  final DateTime playTime;
  EditPage(this.studyTime, this.playTime);

  @override
  _EditPageState createState() => _EditPageState();
}

/// タイマーページの状態を管理するクラス
class _EditPageState extends State<EditPage> with WidgetsBindingObserver {
  DateTime _studyTime; // 勉強した時間
  DateTime _playTime; // 遊んだ時間
  bool _isChanged;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // 初期化処理
  void _initialize() {
    _studyTime = widget.studyTime;
    _playTime = widget.playTime;
    _isChanged = false;
  }

  @override
  Widget build(BuildContext context) {
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
                          : () => {
                                Navigator.pop(context, {'studyTime': _studyTime, 'playTime': _playTime})
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
