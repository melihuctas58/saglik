import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
// EKLE
import 'package:flutter/gestures.dart';
import '../utils/privacy_texts.dart';

class GoogleSignInScreen extends StatefulWidget {
  final void Function(User user) onSignedIn;
  const GoogleSignInScreen({super.key, required this.onSignedIn});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _doSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuthService.instance.signInWithGoogle();
      final user = cred.user;
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = 'Giriş başarısız.');
      } else {
        widget.onSignedIn(user);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDocSheet({required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.check),
                    label: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', height: 96),
                      const SizedBox(height: 24),
                      Text(
                        'Hesabınla devam et',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Google hesabınla tek dokunuşla giriş yap.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: cs.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _busy ? null : _doSignIn,
                          child: const Text(
                            'Google ile devam et',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: cs.error)),
                      ],
                      const SizedBox(height: 28),
                      // Kabul satırı (tıklanabilir)
                      Text.rich(
                        TextSpan(
                          text: 'Devam ederek ',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Gizlilik Politikası',
                              style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _openDocSheet(title: 'Gizlilik Politikası', content: privacyPolicyText),
                            ),
                            const TextSpan(text: ' ve '),
                            TextSpan(
                              text: 'Kullanım Koşulları',
                              style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _openDocSheet(title: 'Kullanım Koşulları', content: termsText),
                            ),
                            const TextSpan(text: '\'nı kabul ediyorsun.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_busy)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}