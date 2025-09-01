import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/scan_parser_service.dart';

enum ScanStatus { idle, processing, done, error }

class ScanViewModel extends ChangeNotifier {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final parser = ScanParserService();

  ScanStatus status = ScanStatus.idle;
  String? errorMessage;
  String? rawText;
  ParseResult? parseResult;

  Future<void> processImage(File file) async {
    status = ScanStatus.processing;
    errorMessage = null;
    rawText = null;
    parseResult = null;
    notifyListeners();
    try {
      final input = InputImage.fromFile(file);
      final result = await textRecognizer.processImage(input);
      rawText = result.text;
      parseResult = parser.parse(rawText!);
      status = ScanStatus.done;
    } catch (e) {
      errorMessage = e.toString();
      status = ScanStatus.error;
    }
    notifyListeners();
  }

  List<String> get tokens => parseResult?.tokens ?? [];
  List<String> get phrases => parseResult?.phrases ?? [];

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }
}