import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: c.surfaceVariant,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Uygulama Hakkında'),
              subtitle: const Text('Malzeme içeriği ve risk seviyeleriyle ilgili bilgilendirme'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Bildirimler'),
            subtitle: const Text('Önemli içerik güncellemelerini al'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Gizlilik Politikası'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Kullanım Koşulları'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(color: c.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}