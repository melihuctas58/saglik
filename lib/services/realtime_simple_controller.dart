import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ingredient.dart';                // <-- EKLENDİ (ÖNEMLİ)
import '../services/simple_ingredient_matcher.dart';
import '../utils/simple_normalize.dart';

class LiveDetectedIngredient {
  final SimpleIngredientMatch match;
  final List<Rect> boxes;
  final DateTime firstSeen;
  final DateTime lastSeen;
  LiveDetectedIngredient({
    required this.match,
    required this.boxes,
    required this.firstSeen,
    required this.lastSeen,
  });
  double get ageMs => DateTime.now().difference(firstSeen).inMilliseconds.toDouble();
  bool get hasBoxes => boxes.isNotEmpty;

  LiveDetectedIngredient update({
    SimpleIngredientMatch? newMatch,
    List<Rect>? newBoxes,
  }) {
    return LiveDetectedIngredient(
      match: newMatch ?? match,
      boxes: newBoxes ?? boxes,
      firstSeen: firstSeen,
      lastSeen: DateTime.now(),
    );
  }
}

class RealtimeSimpleController extends ChangeNotifier {
  final SimpleIngredientMatcher matcher;
  int throttleMs;
  double minScore;

  RealtimeSimpleController({
    required this.matcher,
    this.throttleMs = 520,
    this.minScore = 0.30,
  });

  CameraController? camera;
  Size? cameraSize;
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _busy = false;
  bool _initialized = false;
  bool get initialized => _initialized;

  String? errorMessage;

  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  int _frameCounter = 0;
  DateTime _fpsWindowStart = DateTime.now();
  double fps = 0;

  final Map<String, LiveDetectedIngredient> _detected = {};
  List<LiveDetectedIngredient> get detections =>
      _detected.values.toList()..sort((a,b)=> b.match.score.compareTo(a.match.score));

  Timer? _pruneTimer;

  bool debugStats = false;
  void toggleDebug() {
    debugStats = !debugStats;
    notifyListeners();
  }

  Future<void> init() async => initWithPermission(() async => true);

  Future<void> initWithPermission(Future<bool> Function() ensurePermission) async {
    try {
      final ok = await ensurePermission();
      if (!ok) {
        errorMessage = 'Kamera izni verilmedi';
        notifyListeners();
        return;
      }
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
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
      _startPrune();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Kamera başlatılamadı: $e';
      notifyListeners();
    }
  }

  void _startPrune() {
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final now = DateTime.now();
      final dead = <String>[];
      _detected.forEach((k,v){
        if (now.difference(v.lastSeen).inSeconds > 6) dead.add(k);
      });
      for (final k in dead) {
        _detected.remove(k);
      }
      if (dead.isNotEmpty) notifyListeners();
    });
  }

  void setMinScore(double v) {
    minScore = v;
    notifyListeners();
  }

  Future<void> _onFrame(CameraImage image) async {
    _frameCounter++;
    final now = DateTime.now();
    if (now.difference(_fpsWindowStart).inMilliseconds >= 1000) {
      fps = _frameCounter / (now.difference(_fpsWindowStart).inMilliseconds / 1000);
      _frameCounter = 0;
      _fpsWindowStart = now;
    }

    if (_busy) return;
    if (now.difference(_lastRun).inMilliseconds < throttleMs) return;

    _lastRun = now;
    _busy = true;
    try {
      final bytes = _planesToBytes(image.planes);
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

      final sb = StringBuffer();
      final ocrElements = <_Elem>[];
      final liveTokens = <String>{};

      for (final block in visionText.blocks) {
        for (final line in block.lines) {
          sb.write(line.text);
          sb.write(' , ');
          for (final el in line.elements) {
            final raw = SimpleNormalize.basic(el.text);
            if (raw.isEmpty) continue;
            final lower = raw.toLowerCase();
            final ascii = SimpleNormalize.lowerAscii(lower);
            ocrElements.add(_Elem(raw: raw, lower: lower, ascii: ascii, rect: el.boundingBox));
            for (final t in SimpleNormalize.tokenize(lower)) {
              liveTokens.add(t);
              liveTokens.add(SimpleNormalize.lowerAscii(t));
            }
          }
        }
      }

      final fullText = sb.toString();
      if (fullText.trim().isEmpty && liveTokens.isEmpty) {
        _busy = false;
        return;
      }

      final segMatches = fullText.trim().isEmpty
          ? <SimpleIngredientMatch>[]
          : matcher.matchFromFullText(fullText, minScore: minScore);

      final tokenMatches = liveTokens.isEmpty
          ? <SimpleIngredientMatch>[]
          : matcher.matchFromTokens(liveTokens, minScore: minScore);

      final combined = <Ingredient, SimpleIngredientMatch>{};
      for (final m in segMatches) {
        combined[m.ingredient] = m;
      }
      for (final m in tokenMatches) {
        final prev = combined[m.ingredient];
        if (prev == null || m.score > prev.score) {
          combined[m.ingredient] = m;
        }
      }

      final moment = DateTime.now();
      combined.values.forEach((m) {
        final key = m.ingredient.core.primaryName?.toLowerCase() ?? m.ingredient.hashCode.toString();
        final boxes = _locateBoxesForMatch(m, ocrElements);
        final existing = _detected[key];
        if (existing == null) {
          _detected[key] = LiveDetectedIngredient(
            match: m,
            boxes: boxes,
            firstSeen: moment,
            lastSeen: moment,
          );
        } else {
          final mergedBoxes = _mergeRectList([...existing.boxes, ...boxes]);
          final better = m.score > existing.match.score ? m : existing.match;
          _detected[key] = existing.update(
            newMatch: better,
            newBoxes: mergedBoxes,
          );
        }
      });

      notifyListeners();
    } catch (_) {
      // ignore
    } finally {
      _busy = false;
    }
  }

  List<Rect> _locateBoxesForMatch(SimpleIngredientMatch m, List<_Elem> elems) {
    final tokens = <String>{};
    final prim = SimpleNormalize.basic(m.ingredient.core.primaryName ?? '');
    if (prim.isNotEmpty) {
      for (final t in SimpleNormalize.tokenize(prim.toLowerCase())) {
        tokens.add(t);
        tokens.add(SimpleNormalize.lowerAscii(t));
      }
    }
    for (final t in m.matchedTokens) {
      final tl = t.toLowerCase();
      tokens.add(tl);
      tokens.add(SimpleNormalize.lowerAscii(tl));
    }
    if (tokens.isEmpty) return [];

    final boxes = <Rect>[];
    for (final e in elems) {
      if (tokens.contains(e.lower) || tokens.contains(e.ascii)) {
        boxes.add(e.rect);
      }
    }
    if (boxes.isEmpty) return [];
    return _mergeRectList(boxes);
  }

  List<Rect> _mergeRectList(List<Rect> rects) {
    if (rects.isEmpty) return [];
    final list = [...rects];
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i=0;i<list.length;i++) {
        for (int j=i+1;j<list.length;j++) {
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
    return !(a.right < b.left || b.right < a.left || a.bottom < b.top || b.bottom < a.top);
  }

  Uint8List _planesToBytes(List<Plane> planes) {
    final wb = WriteBuffer();
    for (final p in planes) {
      wb.putUint8List(p.bytes);
    }
    return wb.done().buffer.asUint8List();
  }

  Future<void> disposeAll() async {
    try {
      await camera?.stopImageStream();
    } catch (_) {}
    await camera?.dispose();
    _recognizer.close();
    _pruneTimer?.cancel();
    super.dispose();
  }
}

class _Elem {
  final String raw;
  final String lower;
  final String ascii;
  final Rect rect;
  _Elem({
    required this.raw,
    required this.lower,
    required this.ascii,
    required this.rect,
  });
}