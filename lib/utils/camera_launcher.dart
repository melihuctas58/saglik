import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraLauncher {
  CameraLauncher._();
  static bool _opening = false;

  static Future<File?> pickWithNativeCamera(BuildContext context) async {
    if (_opening) return null; // çift tık guard
    _opening = true;
    try {
      // Kamera izni
      var st = await Permission.camera.status;
      if (!st.isGranted) {
        st = await Permission.camera.request();
        if (!st.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kamera izni verilmedi.')),
            );
          }
          // Kalıcı reddedildiyse ayarlara yönlendir
          if (st.isPermanentlyDenied) {
            await openAppSettings();
          }
          return null;
        }
      }

      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 92,
        maxWidth: 2200,
      );
      if (x == null) return null;
      return File(x.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Telefon kamerası açılamadı: $e')),
        );
      }
      return null;
    } finally {
      _opening = false;
    }
  }
}