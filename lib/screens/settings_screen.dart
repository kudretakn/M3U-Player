import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';

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
              ],
            ),
    );
  }
}
