import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ingredient.dart';
import '../screens/scan_processing_screen.dart';

class ScanStarter {
  static bool _busy = false;

  static Future<void> start(
    BuildContext context,
    List<Ingredient> all, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (_busy) return;
    if (all.isEmpty) {
      _safeSnack(context, 'Veri hazırlanıyor, lütfen biraz sonra deneyin.');
      return;
    }

    _busy = true;
    try {
      // Kamera izni
      var st = await Permission.camera.status;
      if (!st.isGranted) {
        st = await Permission.camera.request();
        if (!st.isGranted) {
          if (st.isPermanentlyDenied) {
            await openAppSettings();
          } else {
            _safeSnack(context, 'Kamera izni verilmedi.');
          }
          return;
        }
      }

      // Fotoğraf çek
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x == null) {
        _safeSnack(context, 'İşlem iptal edildi.');
        return;
      }

      final file = File(x.path);
      dev.log('ScanStarter: image picked path=${file.path}');

      // Navigasyonu bir sonraki frame'e planla (bazı cihazlarda anlık push sorununu önler)
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Öncelik: navigatorKey varsa onu kullan
      final NavigatorState? nav = navigatorKey?.currentState;
      if (nav != null) {
        await nav.push(MaterialPageRoute(
          builder: (_) => ScanProcessingScreen(
            imageFile: file,
            allIngredients: all,
          ),
        ));
        return;
      }

      // Fallback: rootNavigator üzerinden push
      if (context.mounted) {
        await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (_) => ScanProcessingScreen(
            imageFile: file,
            allIngredients: all,
          ),
        ));
      } else {
        // Çok nadiren context dismount olabiliyor; elinde navKey yoksa güvenli uyarı
        dev.log('ScanStarter: context not mounted, navigation skipped');
        _safeSnack(context, 'Ekran yönlendirmesi yapılamadı (context). Tekrar deneyin.');
      }
    } catch (e, st) {
      dev.log('ScanStarter navigation/flow error: $e', stackTrace: st);
      _safeSnack(context, 'Tarama başlatılamadı: $e');
    } finally {
      _busy = false;
    }
  }

  static void _safeSnack(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}