import 'dart:async';
import 'package:flutter/material.dart';

class WelcomeAfterSigninScreen extends StatefulWidget {
  final String displayName;
  final Widget next; // Hoş geldinden sonra gidilecek ekran (ör: _IntroThenApp)

  const WelcomeAfterSigninScreen({
    super.key,
    required this.displayName,
    required this.next,
  });

  @override
  State<WelcomeAfterSigninScreen> createState() => _WelcomeAfterSigninScreenState();
}

class _WelcomeAfterSigninScreenState extends State<WelcomeAfterSigninScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _scale =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _c.forward();
    // 1.4 sn sonra "kendi context" ile ileri geç
    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.next),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.displayName.split(' ').first;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', height: 80),
                const SizedBox(height: 16),
                Text(
                  'Hoş geldin, $first 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}