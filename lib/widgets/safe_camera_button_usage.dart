// Bu dosya sadece kullanım örneği içindir, kendi animasyonlu butonunun onTap'ine aynısını koy.
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/camera_launcher.dart';
// import '../screens/scan_screen.dart'; // ScanScreen'e geçeceksen aç

class ExampleCameraButton extends StatelessWidget {
  final Future<void> Function(File) onImage; // OCR/işleme için
  const ExampleCameraButton({super.key, required this.onImage});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'scanFab', // benzersiz olsun
      onPressed: () async {
        final file = await CameraLauncher.pickWithNativeCamera(context);
        if (file == null) return;
        await onImage(file);
        // Eğer ScanScreen'e geçeceksen (ve onun image alan bir ctor'u varsa) şuna benzer aç:
        // Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        //   builder: (_) => ScanScreen(initialFile: file, ...),
        // ));
      },
      child: const Icon(Icons.camera_alt),
    );
  }
}