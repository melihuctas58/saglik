import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/normalize.dart';
import '../models/detected_ingredient.dart';
import 'dictionary_builder.dart';
import 'realtime_matcher.dart';

class RealTimeDetectionController extends ChangeNotifier {
  RealTimeDetectionController({
    required this.dictionary,
    this.ocrIntervalMs = 500,
  }) {
    matcher = RealTimeMatcher(dictionary);
  }

  final Dictionary dictionary;
  late RealTimeMatcher matcher;

  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  CameraController? camera;
  bool _busy = false;
  DateTime _lastOcr = DateTime.fromMillisecondsSinceEpoch(0);
  int ocrIntervalMs;
  Size? cameraSize;

  final Map<String, DetectedIngredient> _live = {};

  List<DetectedIngredient> get detections =>
      _live.values.toList()..sort((a, b) => b.score.compareTo(a.score));

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first);
    camera = CameraController(
      back,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await camera!.initialize();
    cameraSize = Size(
      camera!.value.previewSize!.width,
      camera!.value.previewSize!.height,
    );
    await camera!.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy) return;
    if (DateTime.now().difference(_lastOcr).inMilliseconds < ocrIntervalMs) {
      return;
    }
    _lastOcr = DateTime.now();
    _busy = true;
    try {
      final bytes = _concatenatePlanes(image.planes);
      final input = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final visionText = await _recognizer.processImage(input);

      final ocLines = <_OcrLine>[];
      for (final block in visionText.blocks) {
        for (final line in block.lines) {
          final normLine = normalizePhrase(line.text);
          final tokens = tokenize(normLine);
          final words = <_OcrWord>[];
          for (final element in line.elements) {
            final nt = normalizePhrase(element.text);
            if (nt.isEmpty) continue;
            words.add(_OcrWord(text: nt, rect: element.boundingBox));
          }
          if (tokens.isNotEmpty) {
            ocLines.add(_OcrLine(tokens: tokens, words: words));
          }
        }
      }

      final tokenLines = ocLines.map((e) => e.tokens).toList();
      final matches = matcher.finalizeFrame(tokenLines);

      final now = DateTime.now();
      final updated = <String>{};

      for (final m in matches) {
        // bounding yaklaşımı: simple - eşleşen herhangi bir token geçen satırın tüm kelime kutularını al
        final candidateRects = <Rect>[];
        for (final line in ocLines) {
          bool lineHit = false;
          for (final unit in m.units) {
            final uTokens = unit.split(' ');
            if (_containsSubseq(line.tokens, uTokens)) {
              lineHit = true;
              break;
            }
          }
          if (lineHit) {
            for (final w in line.words) {
              candidateRects.add(w.rect);
            }
          }
        }
        if (candidateRects.isEmpty) continue;
        final merged = _mergeRects(candidateRects);

        final key = m.canonical;
        final existing = _live[key];
        if (existing == null) {
          _live[key] = DetectedIngredient(
            canonical: m.canonical,
            risk: m.risk,
            score: m.score,
            boxes: merged,
            firstSeen: now,
            lastSeen: now,
          );
        } else {
          final allRects = [...existing.boxes, ...merged];
          final newMerged = _mergeRects(allRects);
          _live[key] = existing.update(
            score: max(existing.score, m.score),
            boxes: newMerged,
          );
        }
        updated.add(key);
      }

      // prune
      final remove = <String>[];
      _live.forEach((k, v) {
        if (!updated.contains(k) &&
            now.difference(v.lastSeen).inSeconds > 5) {
          remove.add(k);
        }
      });
      for (final k in remove) {
        _live.remove(k);
      }

      notifyListeners();
    } catch (_) {
      // swallow
    } finally {
      _busy = false;
    }
  }

  bool _containsSubseq(List<String> base, List<String> pat) {
    if (pat.isEmpty) return false;
    if (pat.length > base.length) return false;
    for (int i = 0; i + pat.length <= base.length; i++) {
      bool ok = true;
      for (int j = 0; j < pat.length; j++) {
        if (base[i + j] != pat[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  List<Rect> _mergeRects(List<Rect> rects) {
    if (rects.isEmpty) return [];
    final list = [...rects];
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < list.length; i++) {
        for (int j = i + 1; j < list.length; j++) {
          if (_overlap(list[i], list[j])) {
            final m = Rect.fromLTRB(
              min(list[i].left, list[j].left),
              min(list[i].top, list[j].top),
              max(list[i].right, list[j].right),
              max(list[i].bottom, list[j].bottom),
            );
            list
              ..removeAt(j)
              ..removeAt(i)
              ..add(m);
            changed = true;
            break;
          }
        }
        if (changed) break;
      }
    }
    return list;
  }

  bool _overlap(Rect a, Rect b) {
    return !(a.right < b.left ||
        b.right < a.left ||
        a.bottom < b.top ||
        b.bottom < a.top);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final write = WriteBuffer();
    for (final p in planes) {
      write.putUint8List(p.bytes);
    }
    return write.done().buffer.asUint8List();
  }

  Future<void> disposeCamera() async {
    try {
      await camera?.stopImageStream();
    } catch (_) {}
    await camera?.dispose();
    _recognizer.close();
    super.dispose();
  }
}

class _OcrWord {
  final String text;
  final Rect rect;
  _OcrWord({required this.text, required this.rect});
}

class _OcrLine {
  final List<String> tokens;
  final List<_OcrWord> words;
  _OcrLine({required this.tokens, required this.words});
}