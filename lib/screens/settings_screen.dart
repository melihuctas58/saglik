import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: true,
            onChanged: (v){},
            title: const Text('Bildirimler'),
            subtitle: const Text('Örnek ayar (placeholder)'),
          ),
          ListTile(
            title: const Text('Veri Senkronizasyonu'),
            subtitle: const Text('Bulut yedek (yakında)'),
            trailing: const Icon(Icons.cloud_sync_outlined),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Hakkında'),
            subtitle: const Text('Sürüm 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}