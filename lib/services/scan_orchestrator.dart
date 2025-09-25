import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ingredient.dart';
import 'ingredient_extractor.dart';
import 'scan_history_service.dart';
import '../services/popularity_service.dart'; // projendeki doğru yola göre kontrol et
import '../screens/scan_result_screen.dart';

class ScanOrchestrator {
  static bool _busy = false;

  static Future<void> startScan(BuildContext context, List<Ingredient> all) async {
    if (_busy) return;
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veri hazırlanıyor, lütfen sonra deneyin.')),
      );
      return;
    }

    _busy = true;
    bool progressOpen = false;
    try {
      // 1) Kamera izni
      var st = await Permission.camera.status;
      if (!st.isGranted) {
        st = await Permission.camera.request();
        if (!st.isGranted) {
          if (st.isPermanentlyDenied) {
            await openAppSettings();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kamera izni verilmedi.')),
            );
          }
          return;
        }
      }

      // 2) Foto çek
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x == null) return;
      final file = File(x.path);

      // 3) Progress (await yok, akış devam eder)
      progressOpen = true;
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 4) OCR
      final inputImage = InputImage.fromFile(file);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final ocr = await recognizer.processImage(inputImage);
      await recognizer.close();
      dev.log('OCR len=${ocr.text.length} blocks=${ocr.blocks.length}');

      // 5) Extractor (senin algoritman)
      List<Ingredient> hits = extractIngredientsFromOcr(ocr, all);
      if (hits.isEmpty) {
        hits = extractIngredients(ocr.text, all);
      }
      dev.log('Hits=${hits.length}: ${hits.take(5).map((e) => e.core.primaryName).toList()}');

      // 6) Popularity + History
      if (hits.isNotEmpty) {
        PopularityService.instance.bumpMany(
          hits,
          keyFn: (x) => x.core.primaryName.toLowerCase(),
        );
      }
      ScanHistoryService.instance.add(hits, imagePath: file.path, rawText: ocr.text);

      // 7) Progress kapat
      if (progressOpen && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        progressOpen = false;
      }

      // 8) Sonuç ekranı
      // ignore: use_build_context_synchronously
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ScanResultScreen(ingredients: hits, rawText: ocr.text),
      ));
    } catch (e, st) {
      dev.log('Scan error: $e', stackTrace: st);
      if (progressOpen && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarama hatası: $e')),
      );
    } finally {
      _busy = false;
    }
  }
}