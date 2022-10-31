import 'package:flutter/material.dart';

class MyProvider extends ChangeNotifier {
  final List<Map<String, String>> _moviesInfo = [];
  List<Map<String, String>> get moviesInfo => _moviesInfo;

  final List<Map<String, String>> _tvsInfo = [];
  List<Map<String, String>> get tvsInfo => _tvsInfo;

  void setData({required Map<String, String> data}) {
    if (data["type"] == "movie") {
      _moviesInfo.add(data);
    } else {
      _tvsInfo.add(data);
    }
    notifyListeners();
  }
}
