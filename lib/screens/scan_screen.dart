import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../viewmodels/scan_view_model.dart';
import '../services/simple_ingredient_matcher.dart';

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
  String _rawPreview = '';

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_vmListener);
  }

  void _vmListener() {
    if (!mounted) return;
    if (widget.vm.status == ScanStatus.done && widget.vm.rawText != null) {
      final raw = widget.vm.rawText!;
      final res = widget.matcher.matchFromFullText(raw);
      setState(() {
        matches = res;
        _rawPreview = raw;
      });
      widget.onResult(res.map((e)=> e.ingredient).toList(), _image?.path);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.vm.removeListener(_vmListener);
    widget.vm.dispose();
    super.dispose();
  }

  Future<bool> _ensurePerm(Permission perm) async {
    var st = await perm.status;
    if (st.isGranted) return true;
    if (st.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    st = await perm.request();
    return st.isGranted;
  }

  Future<void> _pick(ImageSource src) async {
    if (_busy) return;
    setState(()=> _busy = true);
    try {
      final ok = await _ensurePerm(src == ImageSource.camera ? Permission.camera : Permission.photos);
      if (!ok) return;
      final picker = ImagePicker();
      final x = await picker.pickImage(source: src, imageQuality: 92, maxWidth: 2200);
      if (x == null) return;
      final f = File(x.path);
      setState(()=> _image = f);
      await widget.vm.processImage(f);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(()=> _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final processing = widget.vm.status == ScanStatus.processing;
    return Scaffold(
      appBar: AppBar(title: const Text('Foto Tarama')),
      body: Column(
        children: [
          Expanded(
            child: _image == null
              ? Center(child: Text('İçindekiler fotoğrafı çek / seç', style: TextStyle(color: Colors.grey.shade600)))
              : Image.file(_image!, fit: BoxFit.contain, width: double.infinity),
          ),
          if (processing) const LinearProgressIndicator(),
          if (matches.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                itemBuilder: (_, i) {
                  final m = matches[i];
                  final ing = m.ingredient;
                  return InkWell(
                    onTap: () => Navigator.pushNamed(context, '/detail', arguments: ing),
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: m.exact ? Colors.green.shade600 : Colors.blueGrey.shade700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ing.core.primaryName ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Skor: ${m.score.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Tok: ${m.intersection}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          const Spacer(),
                          Text(m.matchedSegment, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: Text(_busy ? '...' : 'Galeri'),
                    onPressed: _busy ? null : ()=> _pick(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_busy ? '...' : 'Kamera'),
                    onPressed: _busy ? null : ()=> _pick(ImageSource.camera),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}