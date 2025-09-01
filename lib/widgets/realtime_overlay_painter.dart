import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detected_ingredient.dart';

class RealTimeOverlay extends StatefulWidget {
  final List<DetectedIngredient> detections;
  final Size cameraSize;
  final Size displaySize;
  const RealTimeOverlay({
    super.key,
    required this.detections,
    required this.cameraSize,
    required this.displaySize,
  });

  @override
  State<RealTimeOverlay> createState() => _RealTimeOverlayState();
}

class _RealTimeOverlayState extends State<RealTimeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _riskColor(String r) {
    switch (r) {
      case 'red': return const Color(0xFFD94343);
      case 'yellow': return const Color(0xFFE8A534);
      case 'green': return const Color(0xFF24A669);
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_,__) {
        return CustomPaint(
          painter: _RealPainter(
            detections: widget.detections,
            cameraSize: widget.cameraSize,
            displaySize: widget.displaySize,
            t: _controller.value,
            riskColor: _riskColor,
          ),
        );
      },
    );
  }
}

class _RealPainter extends CustomPainter {
  final List<DetectedIngredient> detections;
  final Size cameraSize;
  final Size displaySize;
  final double t;
  final Color Function(String) riskColor;

  _RealPainter({
    required this.detections,
    required this.cameraSize,
    required this.displaySize,
    required this.t,
    required this.riskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cameraSize.width == 0 || cameraSize.height == 0) return;
    final scale = min(displaySize.width / cameraSize.width, displaySize.height / cameraSize.height);
    final dx = (displaySize.width - cameraSize.width * scale)/2;
    final dy = (displaySize.height - cameraSize.height * scale)/2;

    for (final d in detections) {
      final c = riskColor(d.risk);
      final ageMs = d.age.inMilliseconds.toDouble();
      final fade = ageMs < 400 ? ageMs/400 : 1.0;
      final pulse = 1 + 0.07 * sin(t * 2 * pi);

      for (final r in d.boxes.take(1)) {
        final rr = Rect.fromLTRB(
          dx + r.left * scale,
          dy + r.top * scale,
          dx + r.right * scale,
          dy + r.bottom * scale,
        ).inflate(4*pulse);

        final fill = Paint()
          ..color = c.withOpacity(0.25*fade);
        final border = Paint()
          ..color = c.withOpacity(0.9*fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;

        canvas.drawRRect(RRect.fromRectAndRadius(rr, const Radius.circular(10)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rr, const Radius.circular(10)), border);

        final label = '${d.canonical}  ${d.score.toStringAsFixed(2)}';
        final ts = TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withOpacity(fade),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          )
        );
        final tp = TextPainter(text: ts, textDirection: TextDirection.ltr)..layout(maxWidth: 260);
        final lb = Rect.fromLTWH(rr.left, rr.top - tp.height - 8, tp.width + 14, tp.height + 8);
        final lbBg = Paint()..color = c.withOpacity(0.85*fade);
        canvas.drawRRect(RRect.fromRectAndRadius(lb, const Radius.circular(18)), lbBg);
        tp.paint(canvas, Offset(lb.left + 7, lb.top + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealPainter old) =>
      old.detections != detections || old.t != t;
}