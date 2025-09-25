import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../screens/google_sign_in_screen.dart';

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({super.key});

  Future<void> _reauth(BuildContext context) async {
    // Çıkış + yeniden Google ile giriş
    await FirebaseAuthService.instance.signOut();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GoogleSignInScreen(
          onSignedIn: (User user) {
            Navigator.of(_); // pop current route
            Navigator.of(context).pop(); // kapat (üst üste ise)
          },
        ),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hoş geldin, ${FirebaseAuth.instance.currentUser?.displayName ?? ''}')),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuthService.instance.signOut();
    if (!context.mounted) return;
    // Çıkıştan sonra yeniden giriş ekranını aç
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GoogleSignInScreen(
          onSignedIn: (User user) {
            Navigator.of(_);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hoş geldin, ${FirebaseAuth.instance.currentUser?.displayName ?? ''}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Hesabı değiştir (Google)'),
            subtitle: const Text('Farklı bir Google hesabıyla devam et'),
            leading: const Icon(Icons.switch_account),
            onTap: () => _reauth(context),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Çıkış yap'),
            subtitle: const Text('Hesabından güvenle çık'),
            leading: const Icon(Icons.logout),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}