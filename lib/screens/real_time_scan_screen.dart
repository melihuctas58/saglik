import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/realtime_detection_controller.dart';
import '../services/dictionary_builder.dart';
import '../widgets/realtime_overlay_painter.dart';
import '../models/detected_ingredient.dart';
import '../models/ingredient.dart';

class RealTimeScanScreen extends StatefulWidget {
  final Dictionary dictionary;
  const RealTimeScanScreen({super.key, required this.dictionary});

  @override
  State<RealTimeScanScreen> createState() => _RealTimeScanScreenState();
}

class _RealTimeScanScreenState extends State<RealTimeScanScreen> {
  late RealTimeDetectionController ctrl;
  bool frozen = false;
  List<DetectedIngredient> frozenList = [];

  @override
  void initState() {
    super.initState();
    ctrl = RealTimeDetectionController(dictionary: widget.dictionary);
    ctrl.addListener(_listener);
    ctrl.initCamera();
  }

  void _listener() {
    if (!mounted) return;
    if (!frozen) setState(() {});
  }

  @override
  void dispose() {
    ctrl.removeListener(_listener);
    ctrl.disposeCamera();
    super.dispose();
  }

  void _toggleFreeze() {
    setState(() {
      frozen = !frozen;
      if (frozen) {
        frozenList = ctrl.detections;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cam = ctrl.camera;
    final dets = frozen ? frozenList : ctrl.detections;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Canlı Tarama'),
        actions: [
          IconButton(
            icon: Icon(frozen ? Icons.play_arrow : Icons.pause),
            onPressed: _toggleFreeze,
          )
        ],
      ),
      body: cam == null || !cam.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (_, constraints) {
                final displaySize = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: [
                    CameraPreview(cam),
                    if (ctrl.cameraSize != null)
                      RealTimeOverlay(
                        detections: dets,
                        cameraSize: ctrl.cameraSize!,
                        displaySize: displaySize,
                      ),
                    Positioned(
                      bottom: 16,
                      left: 12,
                      right: 12,
                      child: _bottomBar(dets),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _bottomBar(List<DetectedIngredient> dets) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: dets.take(15).map((d)=> Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                d.canonical,
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: Colors.white.withOpacity(.9),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )).toList(),
        ),
      ),
    );
  }
}