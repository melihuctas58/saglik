import 'package:flutter/foundation.dart';

class ScanRecord<T> {
  final DateTime time;
  final List<T> items;
  final String? imagePath;
  ScanRecord({required this.time, required this.items, this.imagePath});
}

class ScanHistoryService<T> extends ChangeNotifier {
  static final ScanHistoryService instance = ScanHistoryService._();
  ScanHistoryService._();

  final List<ScanRecord<T>> _records = [];
  List<ScanRecord<T>> get records => List.unmodifiable(_records);

  void add(List<T> items, {String? imagePath}) {
    _records.insert(0, ScanRecord(time: DateTime.now(), items: items, imagePath: imagePath));
    notifyListeners();
  }

  void clear() {
    _records.clear();
    notifyListeners();
  }
}