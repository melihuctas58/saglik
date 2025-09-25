import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../viewmodels/scan_view_model.dart';
import '../services/simple_ingredient_matcher.dart';
import 'capture_camera_screen.dart';
import 'ingredient_detail_screen.dart';

// EKLENDİ:
import '../services/scan_history_service.dart';
import '../services/popularity_service.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  final ScanViewModel vm;
  final SimpleIngredientMatcher matcher;
  final void Function(List<dynamic> ingredients, String? imagePath) onResult;
  const ScanScreen({
    super.key,
    required this.vm,
    required this.matcher,
    required this.onResult,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _busy = false;
  List matches = [];

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_vmListener);
  }

  void _vmListener() {
    if (!mounted) return;

    // OCR tamamlandıysa
    if (widget.vm.status == ScanStatus.done && widget.vm.rawText != null) {
      final raw = widget.vm.rawText!;
      final res = widget.matcher.matchFromFullText(raw);

      setState(() => matches = res);

      // Güvenli geçmiş kaydı + popülerlik (ana ekrandaki onResult’a ek olarak)
      final ingredients = res.map((e) => e.ingredient).toList();
      if (ingredients.isNotEmpty) {
        try {
          PopularityService.instance.bumpMany(
            ingredients,
            keyFn: (x) => x.core.primaryName.toLowerCase(),
          );
        } catch (_) {}
      }
      try {
        ScanHistoryService.instance.add(
          ingredients,
          imagePath: _image?.path,
          rawText: raw,
        );
      } catch (_) {}

      // Ebeveyn callback (mevcut davranış sürsün)
      widget.onResult(ingredients, _image?.path);

      // Otomatik sonuç ekranına geç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ScanResultScreen(ingredients: ingredients, rawText: raw),
        ));
      });
    }

    setState(() {}); // durum değişikliği
  }

  @override
  void dispose() {
    widget.vm.removeListener(_vmListener);
    widget.vm.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2200,
      );
      if (x == null) return;
      final f = File(x.path);
      setState(() => _image = f);
      await widget.vm.processImage(f);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Galeri hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var st = await Permission.camera.status;
    if (st.isGranted) return true;
    if (st.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni kalıcı reddedilmiş, Ayarlar > İzinler\'den aç.')),
        );
      }
      await openAppSettings();
      return false;
    }
    st = await Permission.camera.request();
    return st.isGranted;
  }

  // 1) Telefonun kendi kamerası (native)
  Future<void> _openNativeCamera() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await _ensureCameraPermission();
      if (!ok) return;

      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 92,
        maxWidth: 2200,
      );
      if (x == null) return;
      final f = File(x.path);
      setState(() => _image = f);
      await widget.vm.processImage(f);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Telefon kamerası hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 2) Uygulama içi kamera (önizlemeli) -> açılmazsa otomatik native fallback
  Future<void> _openInAppCamera() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await _ensureCameraPermission();
      if (!ok) return;

      File? f = await Navigator.of(context).push<File>(
        MaterialPageRoute(builder: (_) => const CaptureCameraScreen()),
      );

      if (f == null) {
        // In-app kamera açılmadıysa native'e düş
        final picker = ImagePicker();
        final x = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 92,
          maxWidth: 2200,
        );
        if (x != null) f = File(x.path);
      }

      if (f == null) return;
      setState(() => _image = f);
      await widget.vm.processImage(f);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kamera açılmadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final processing = widget.vm.status == ScanStatus.processing;
    return Scaffold(
      appBar: AppBar(title: const Text('Etiketten Tara')),
      body: Column(
        children: [
          Expanded(
            child: _image == null
                ? Center(child: Text('İçindekiler fotoğrafı çek / seç', style: TextStyle(color: Colors.grey.shade600)))
                : Image.file(_image!, fit: BoxFit.contain, width: double.infinity),
          ),
          if (processing) const LinearProgressIndicator(),
          if (matches.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = matches[i];
                final ing = m.ingredient;
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => IngredientDetailScreen(ingredient: ing),
                  )),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.exact ? Colors.green.shade600 : Colors.blueGrey.shade700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ing.core.primaryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Skor: ${m.score.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(m.matchedSegment,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: Text(_busy ? '...' : 'Galeri'),
                    onPressed: _busy ? null : _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_outdoor),
                    label: Text(_busy ? '...' : 'Telefon Kamerası'),
                    onPressed: _busy ? null : _openNativeCamera,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_busy ? '...' : 'Uygulama Kamerası'),
                    onPressed: _busy ? null : _openInAppCamera,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}