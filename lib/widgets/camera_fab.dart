import 'package:flutter/material.dart';

class CameraFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String? heroTag;
  const CameraFab({super.key, required this.onPressed, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag ?? 'center_camera_fab',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.red, width: 3),
      ),
      child: const Icon(Icons.camera_alt, color: Colors.red),
    );
  }
}