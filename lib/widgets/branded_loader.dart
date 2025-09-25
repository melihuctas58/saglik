import 'dart:math' as math;
import 'package:flutter/material.dart';

class BrandedLoader extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color? ringColor;
  const BrandedLoader({
    super.key,
    this.size = 56,
    this.duration = const Duration(seconds: 2),
    this.ringColor,
  });

  @override
  State<BrandedLoader> createState() => _BrandedLoaderState();
}

class _BrandedLoaderState extends State<BrandedLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringColor = widget.ringColor ?? cs.primary.withOpacity(0.15);

    return SizedBox(
      width: widget.size + 16,
      height: widget.size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size + 12,
            height: widget.size + 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringColor,
            ),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              return Transform.rotate(
                angle: _c.value * 2 * math.pi,
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/logo.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}