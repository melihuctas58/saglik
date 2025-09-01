import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/simple_ingredient_matcher.dart';
import '../services/realtime_simple_controller.dart';
import '../widgets/simple_live_overlay.dart';
import '../models/ingredient.dart';

class RealTimeSimpleScreen extends StatefulWidget {
  final SimpleIngredientMatcher matcher;
  const RealTimeSimpleScreen({super.key, required this.matcher});

  @override
  State<RealTimeSimpleScreen> createState() => _RealTimeSimpleScreenState();
}

class _RealTimeSimpleScreenState extends State<RealTimeSimpleScreen> {
  late RealtimeSimpleController ctrl;
  bool frozen = false;
  List<LiveDetectedIngredient> frozenList = [];
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    ctrl = RealtimeSimpleController(matcher: widget.matcher);
    ctrl.addListener(_listener);
    _start();
  }

  Future<void> _start() async {
    await ctrl.initWithPermission(_ensureCameraPermission);
    setState(()=> _initializing = false);
  }

  Future<bool> _ensureCameraPermission() async {
    final st = await Permission.camera.status;
    if (st.isGranted) return true;
    if (st.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    final r = await Permission.camera.request();
    return r.isGranted;
  }

  void _listener() {
    if (!mounted) return;
    if (!frozen) setState(() {});
  }

  @override
  void dispose() {
    ctrl.removeListener(_listener);
    ctrl.disposeAll();
    super.dispose();
  }

  void _toggleFreeze() {
    setState(() {
      frozen = !frozen;
      if (frozen) frozenList = ctrl.detections;
    });
  }

  void _openListPanel() {
    final list = frozen ? frozenList : ctrl.detections;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetectedListSheet(
        detections: list,
        threshold: ctrl.minScore,
        onThreshold: (v) => ctrl.setMinScore(v),
        onTapIngredient: (ing) {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/detail', arguments: ing);
        },
      ),
    );
  }

  void _onTapDetection(LiveDetectedIngredient det) {
    Navigator.pushNamed(context, '/detail', arguments: det.match.ingredient);
  }

  @override
  Widget build(BuildContext context) {
    final cam = ctrl.camera;
    final dets = frozen ? frozenList : ctrl.detections;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Canlı İçindekiler'),
        actions: [
          IconButton(
            icon: Icon(frozen ? Icons.play_arrow : Icons.pause),
            tooltip: 'Dondur',
            onPressed: _toggleFreeze,
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Liste',
            onPressed: _openListPanel,
          ),
          IconButton(
            icon: Icon(ctrl.debugStats ? Icons.bug_report : Icons.bug_report_outlined),
            tooltip: 'Debug',
            onPressed: () => ctrl.toggleDebug(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade600,
        onPressed: _openListPanel,
        icon: const Icon(Icons.visibility),
        label: Text('${dets.length} malzeme'),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (ctrl.errorMessage != null)
              ? _errorView(ctrl.errorMessage!)
              : (cam == null || !cam.value.isInitialized)
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : LayoutBuilder(
                      builder: (_, constraints) {
                        final displaySize =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        return Stack(
                          children: [
                            CameraPreview(cam),
                            if (ctrl.cameraSize != null)
                              SimpleLiveOverlay(
                                matches: dets.where((d)=> d.hasBoxes).toList(),
                                cameraSize: ctrl.cameraSize!,
                                displaySize: displaySize,
                                onTap: _onTapDetection,
                                showDebug: ctrl.debugStats,
                                fps: ctrl.fps,
                              ),
                            Positioned(
                              bottom: 14,
                              left: 12,
                              right: 12,
                              child: _bottomStrip(dets),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }

  Widget _errorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 54),
            const SizedBox(height: 12),
            Text(
              msg,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              onPressed: () {
                setState(()=> _initializing = true);
                ctrl.initWithPermission(_ensureCameraPermission).then((_){
                  setState(()=> _initializing = false);
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _bottomStrip(List<LiveDetectedIngredient> dets) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: dets
              .take(20)
              .map(
                (m) => GestureDetector(
                  onTap: () => _onTapDetection(m),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.match.ingredient.core.primaryName ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DetectedListSheet extends StatefulWidget {
  final List<LiveDetectedIngredient> detections;
  final double threshold;
  final ValueChanged<double> onThreshold;
  final ValueChanged<Ingredient> onTapIngredient;

  const _DetectedListSheet({
    required this.detections,
    required this.threshold,
    required this.onThreshold,
    required this.onTapIngredient,
  });

  @override
  State<_DetectedListSheet> createState() => _DetectedListSheetState();
}

class _DetectedListSheetState extends State<_DetectedListSheet> {
  late double _thr;

  @override
  void initState() {
    super.initState();
    _thr = widget.threshold;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.detections;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF181A1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Algılanan (${items.length})',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: Column(
                      children: [
                        Text('Eşik: ${_thr.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Slider(
                          value: _thr,
                          min: 0.20,
                          max: 0.60,
                          divisions: 40,
                          onChanged: (v) {
                            setState(() => _thr = v);
                            widget.onThreshold(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final d = items[i];
                  final ing = d.match.ingredient;
                  return ListTile(
                    dense: true,
                    onTap: () => widget.onTapIngredient(ing),
                    title: Text(
                      ing.core.primaryName ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Skor ${d.match.score.toStringAsFixed(2)}  |  Tok:${d.match.intersection}  |  ${d.hasBoxes ? "Kutulu" : "Kutusu yok"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}