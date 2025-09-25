import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ingredient.dart';
import '../services/ingredient_extractor.dart'; // ✅ Senin güçlü algoritman
import '../services/scan_history_service.dart';
import '../services/popularity_service.dart';
import 'scan_result_screen.dart';

class ScanProcessingScreen extends StatefulWidget {
  final File imageFile;
  final List<Ingredient> allIngredients;

  const ScanProcessingScreen({
    super.key,
    required this.imageFile,
    required this.allIngredients,
  });

  @override
  State<ScanProcessingScreen> createState() => _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends State<ScanProcessingScreen> {
  String _status = 'Görüntü işleniyor...';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      // 1) OCR
      setState(() => _status = 'Metin tanıma (OCR)...');
      final inputImage = InputImage.fromFile(widget.imageFile);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final ocr = await recognizer.processImage(inputImage);
      await recognizer.close();
      dev.log('OCR len=${ocr.text.length}, blocks=${ocr.blocks.length}');

      // 2) Extractor (senin algoritman)
      setState(() => _status = 'Malzemeler çıkarılıyor...');
      List<Ingredient> hits = extractIngredientsFromOcr(ocr, widget.allIngredients);
      if (hits.isEmpty) {
        hits = extractIngredients(ocr.text, widget.allIngredients);
      }
      dev.log('Hits=${hits.length}: ${hits.take(5).map((e) => e.core.primaryName).toList()}');

      // 3) Popularity + History (kalıcı)
      if (hits.isNotEmpty) {
        PopularityService.instance.bumpMany(
          hits,
          keyFn: (x) => x.core.primaryName.toLowerCase(),
        );
      }
      ScanHistoryService.instance.add(
        hits,
        imagePath: widget.imageFile.path,
        rawText: ocr.text,
      );

      // 4) Sonuç ekranına geç
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ScanResultScreen(
          ingredients: hits,
          rawText: ocr.text,
          imagePath: widget.imageFile.path, // ✅ önizleme için
        ),
      ));
    } catch (e, st) {
      dev.log('Scan processing error: $e', stackTrace: st);
      if (!mounted) return;
      setState(() => _status = 'Hata: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('İşleniyor')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            const SizedBox(height: 16),
            Text(_status, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}