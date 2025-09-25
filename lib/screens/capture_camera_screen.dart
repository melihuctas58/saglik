import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:image_picker/image_picker.dart';

class CaptureCameraScreen extends StatefulWidget {
  const CaptureCameraScreen({super.key});

  @override
  State<CaptureCameraScreen> createState() => _CaptureCameraScreenState();
}

class _CaptureCameraScreenState extends State<CaptureCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _taking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _controller;
    if (cam == null) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init(reopen: true);
    }
  }

  Future<void> _init({bool reopen = false}) async {
    try {
      setState(() => _initializing = true);
      final ok = await _ensureCameraPerm();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamera izni verilmedi.')));
        final f = await _fallbackNativeCamera();
        if (f != null && mounted) Navigator.pop(context, f);
        else if (mounted) Navigator.pop(context);
        return;
      }

      final cams = await availableCameras();
      if (cams.isEmpty) {
        final f = await _fallbackNativeCamera();
        if (f != null && mounted) Navigator.pop(context, f);
        else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamera bulunamadı.')));
          Navigator.pop(context);
        }
        return;
      }

      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final presets = <ResolutionPreset>[ResolutionPreset.medium, ResolutionPreset.low];
      final fmts = <ImageFormatGroup>[ImageFormatGroup.jpeg, ImageFormatGroup.yuv420, ImageFormatGroup.nv21];

      Object? lastErr;
      for (final p in presets) {
        for (final f in fmts) {
          try {
            await _initController(back, p, f);
            lastErr = null;
            break;
          } catch (e, st) {
            debugPrint('Camera init failed ($p, $f): $e\n$st');
            lastErr = e;
          }
        }
        if (lastErr == null) break;
      }
      if (lastErr != null) throw lastErr!;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kamera açılamadı: $e')));
      }
      final f = await _fallbackNativeCamera();
      if (f != null && mounted) {
        Navigator.pop(context, f);
      } else if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _initController(
    CameraDescription camera,
    ResolutionPreset preset,
    ImageFormatGroup fmt,
  ) async {
    final ctrl = CameraController(
      camera,
      preset,
      imageFormatGroup: fmt,
      enableAudio: false,
    );
    await ctrl.initialize();
    try {
      await ctrl.setFlashMode(FlashMode.off);
    } catch (_) {}
    try {
      await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _controller = ctrl);
  }

  Future<bool> _ensureCameraPerm() async {
    var st = await Permission.camera.status;
    if (st.isGranted) return true;
    if (st.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    st = await Permission.camera.request();
    return st.isGranted;
  }

  Future<File?> _fallbackNativeCamera() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 92,
        maxWidth: 2200,
      );
      if (x == null) return null;
      return File(x.path);
    } catch (e, st) {
      debugPrint('Native camera fallback failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kamera (yerel) açılamadı: $e')));
      }
      return null;
    }
  }

  Future<void> _take() async {
    if (_taking) return;
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized) {
      final f = await _fallbackNativeCamera();
      if (f != null && mounted) Navigator.pop(context, f);
      return;
    }

    setState(() => _taking = true);
    try {
      final x = await cam.takePicture();
      if (!mounted) return;
      Navigator.pop(context, File(x.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Çekim hatası: $e — yerel kameraya düşülüyor')));
      }
      final f = await _fallbackNativeCamera();
      if (f != null && mounted) Navigator.pop(context, f);
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Kamera'),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : (cam == null || !cam.value.isInitialized)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Önizleme açılamadı. Yerel kamerayı kullanabilirsin.', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _taking ? null : () async {
                            final f = await _fallbackNativeCamera();
                            if (f != null && mounted) Navigator.pop(context, f);
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Yerel kamerayla çek'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Center(child: CameraPreview(cam)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(.12),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: _taking ? null : _take,
                            icon: const Icon(Icons.camera),
                            label: Text(_taking ? '...' : 'Çek'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}