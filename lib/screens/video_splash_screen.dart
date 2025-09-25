import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class VideoSplashScreen extends StatefulWidget {
  final Widget next; // Video bitince geçilecek ekran (AppRoot)
  const VideoSplashScreen({super.key, required this.next});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late final VideoPlayerController _controller;
  Timer? _safetyTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..setLooping(false)
      ..setVolume(0);

    _initAndPlay();
  }

  Future<void> _initAndPlay() async {
    try {
      await _controller.initialize();

      // 1) Video hazır: native splash'i kaldır (ilk görülen şey doğrudan video)
      FlutterNativeSplash.remove();

      // 2) Oynat ve bitince geç
      if (!mounted) return;
      _controller.play();
      _controller.addListener(_checkEnd);

      // 3) Güvenlik: süre + 1sn sonra geç
      final maxWait = _controller.value.duration + const Duration(seconds: 1);
      _safetyTimer = Timer(maxWait, _goNext);

      // Ekranı yeniden çiz (videonun ilk frame'i görünsün)
      setState(() {});
    } catch (_) {
      // Herhangi bir nedenle initialize olmadıysa direkt geç
      _goNext();
    }
  }

  void _checkEnd() {
    if (!_controller.value.isInitialized) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 100) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _safetyTimer?.cancel();
    _controller.removeListener(_checkEnd);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.removeListener(_checkEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tam ekran kapla, taşma olursa cover (kesme) uygula
    final ready = _controller.value.isInitialized;
    return Scaffold(
      // AppBar yok, SafeArea yok: gerçek tam ekran
      body: ready
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // ekranı tamamen doldurur (gerekirse kırpar)
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(), // initialize anına kadar native splash ekranda (preserve)
    );
  }
}