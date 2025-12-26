import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../repositories/theme_repository.dart';
import '../main.dart'; // For ThemeManager

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  bool _adultFilterEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _repository.isAdultFilterEnabled();
    setState(() {
      _adultFilterEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleAdultFilter(bool value) async {
    await _repository.setAdultFilterEnabled(value);
    setState(() {
      _adultFilterEnabled = value;
    });
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renk Teması Seç'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppThemes.colors.length,
              itemBuilder: (context, index) {
                final color = AppThemes.colors[index];
                final name = AppThemes.names[index];
                final isSelected = ThemeManager.instance.value == index;

                return ListTile(
                  leading: CircleAvatar(backgroundColor: color),
                  title: Text(name),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    ThemeManager.instance.changeTheme(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Müstehcen İçerik Engelleyici'),
                  subtitle: const Text(
                      'Yetişkin içerikli kanalları ve grupları gizle (xxx, adult, vb.)'),
                  value: _adultFilterEnabled,
                  onChanged: _toggleAdultFilter,
                  secondary: const Icon(Icons.block, color: Colors.red),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Tema Rengi'),
                  subtitle: const Text('Uygulama temasını değiştirin'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showThemeDialog(context),
                ),
              ],
            ),
    );
  }
}
