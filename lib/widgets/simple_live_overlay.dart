import 'dart:math';
import 'package:flutter/material.dart';
import '../services/realtime_simple_controller.dart';

typedef OnDetectionTap = void Function(LiveDetectedIngredient det);

class SimpleLiveOverlay extends StatefulWidget {
  final List<LiveDetectedIngredient> matches;
  final Size cameraSize;
  final Size displaySize;
  final OnDetectionTap onTap;
  final bool showDebug;
  final double fps;
  const SimpleLiveOverlay({
    super.key,
    required this.matches,
    required this.cameraSize,
    required this.displaySize,
    required this.onTap,
    required this.showDebug,
    required this.fps,
  });

  @override
  State<SimpleLiveOverlay> createState() => _SimpleLiveOverlayState();
}

class _SimpleLiveOverlayState extends State<SimpleLiveOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final display = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final det = _hitTest(d.localPosition, display);
                if (det != null) widget.onTap(det);
              },
              child: CustomPaint(
                painter: _LivePainter(
                  matches: widget.matches.where((m)=> m.hasBoxes).toList(),
                  cameraSize: widget.cameraSize,
                  displaySize: display,
                  t: _anim.value,
                ),
                child: widget.showDebug
                    ? Positioned.fill(
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.all(8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(
                                  'Detections: ${widget.matches.length}\nFPS: ${widget.fps.toStringAsFixed(1)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  LiveDetectedIngredient? _hitTest(Offset pos, Size displaySize) {
    final scale = min(
      widget.displaySize.width / widget.cameraSize.width,
      widget.displaySize.height / widget.cameraSize.height,
    );
    final dx = (widget.displaySize.width - widget.cameraSize.width * scale) / 2;
    final dy = (widget.displaySize.height - widget.cameraSize.height * scale) / 2;

    for (final d in widget.matches) {
      if (d.boxes.isEmpty) continue;
      final r = d.boxes.first;
      final rect = Rect.fromLTRB(
        dx + r.left * scale,
        dy + r.top * scale,
        dx + r.right * scale,
        dy + r.bottom * scale,
      ).inflate(8);
      if (rect.contains(pos)) return d;
    }
    return null;
  }
}

class _LivePainter extends CustomPainter {
  final List<LiveDetectedIngredient> matches;
  final Size cameraSize;
  final Size displaySize;
  final double t;

  _LivePainter({
    required this.matches,
    required this.cameraSize,
    required this.displaySize,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cameraSize.width == 0 || cameraSize.height == 0) return;
    final scale = min(
      displaySize.width / cameraSize.width,
      displaySize.height / cameraSize.height,
    );
    final dx = (displaySize.width - cameraSize.width * scale) / 2;
    final dy = (displaySize.height - cameraSize.height * scale) / 2;

    for (final m in matches.take(30)) {
      final ageFade = m.ageMs < 400 ? m.ageMs / 400 : 1.0;
      final pulse = 1 + 0.08 * sin(t * 2 * pi);
      final rawRect = m.boxes.first;
      final rr = Rect.fromLTRB(
        dx + rawRect.left * scale,
        dy + rawRect.top * scale,
        dx + rawRect.right * scale,
        dy + rawRect.bottom * scale,
      ).inflate(4 * pulse);

      final fill = Paint()
        ..color = Colors.red.withOpacity(0.23 * ageFade)
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = Colors.red.withOpacity(0.95 * ageFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;

      canvas.drawRRect(RRect.fromRectAndRadius(rr, const Radius.circular(14)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(rr, const Radius.circular(14)), stroke);

      final label =
          '${m.match.ingredient.core.primaryName ?? ''}  ${m.match.score.toStringAsFixed(2)}';
      final span = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withOpacity(ageFade),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      );
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 280);
      final lb = Rect.fromLTWH(
        rr.left,
        rr.top - tp.height - 10,
        tp.width + 18,
        tp.height + 8,
      );
      final bg = Paint()..color = Colors.red.withOpacity(0.92 * ageFade);
      canvas.drawRRect(RRect.fromRectAndRadius(lb, const Radius.circular(20)), bg);
      tp.paint(canvas, Offset(lb.left + 9, lb.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LivePainter oldDelegate) =>
      oldDelegate.matches != matches || oldDelegate.t != t;
}