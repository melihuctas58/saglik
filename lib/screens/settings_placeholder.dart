import 'package:flutter/material.dart';

class SettingsPlaceholder extends StatelessWidget {
  final bool darkMode;
  final bool technicalMode;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onTechnicalModeChanged;
  const SettingsPlaceholder({
    super.key,
    required this.darkMode,
    required this.technicalMode,
    required this.onDarkModeChanged,
    required this.onTechnicalModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Karanlık Tema'),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
          SwitchListTile(
            title: const Text('Teknik Mod'),
            subtitle: const Text('Regülasyon & teknik not bölümü'),
            value: technicalMode,
            onChanged: onTechnicalModeChanged,
          ),
          const SizedBox(height: 24),
          Text(
            'Compare ve Favoriler ileride eklenecek.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          )
        ],
      ),
    );
  }
}