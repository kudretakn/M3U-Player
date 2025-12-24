import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../repositories/m3u_repository.dart';
import '../utils/url_utils.dart';
import 'channel_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final M3uRepository _repository = M3uRepository();
  List<Channel> allChannels = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUrlDialog();
    });
  }

  Future<void> _loadChannels(String url) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedChannels = await _repository.fetchChannels(url);
      setState(() {
        allChannels = fetchedChannels;
        _isLoading = false;
      });

      if (fetchedChannels.isEmpty) {
        if (mounted) {
          _showDebugDialog(url);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showDebugDialog(String url) async {
    // Re-fetch raw content for debugging
    String debugContent = "Loading raw content...";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata Ayıklama'),
        content: FutureBuilder<String>(
          future: _repository.testConnection(url),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()));
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Kanal listesi boş geldi. Sunucudan dönen ham veri:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: Text(snapshot.data ?? 'Veri alınamadı'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog() {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: allChannels.isEmpty, // Force input if no channels
      builder: (context) {
        return AlertDialog(
          title: const Text('M3U / Xtream Codes Giriş'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL veya Sunucu Adresi',
                    hintText: 'http://example.com',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Xtream Codes (İsteğe Bağlı)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String url = urlController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                if (url.isNotEmpty) {
                  String finalUrl = url;
                  if (username.isNotEmpty && password.isNotEmpty) {
                    finalUrl = UrlUtils.constructXtreamUrl(
                      host: url,
                      username: username,
                      password: password,
                    );
                  }

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final result = await _repository.testConnection(finalUrl);

                  // Hide loading
                  Navigator.pop(context);

                  // Show result
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Bağlantı Testi Sonucu'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Denenen Adres:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(finalUrl,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 10),
                            const Text('Sonuç:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(result),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Test Et'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                String url = urlController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                if (url.isNotEmpty) {
                  String finalUrl = url;
                  if (username.isNotEmpty && password.isNotEmpty) {
                    finalUrl = UrlUtils.constructXtreamUrl(
                      host: url,
                      username: username,
                      password: password,
                    );
                  }

                  showDialog(
                    context: context,
                    builder: (context) {
                      final TextEditingController confirmController =
                          TextEditingController(text: finalUrl);
                      return AlertDialog(
                        title: const Text('Bağlantı Adresini Onayla'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                'Oluşturulan bağlantı adresi aşağıdadır. Lütfen kontrol edin ve gerekirse düzenleyin.'),
                            const SizedBox(height: 16),
                            TextField(
                              controller: confirmController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Tam Bağlantı Adresi',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadChannels(confirmController.text.trim());
                            },
                            child: const Text('Onayla ve Yükle'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text('Yükle'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCategory(ChannelCategory? category) {
    if (allChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce kanal listesi yükleyin.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelListScreen(
          channels: allChannels,
          initialCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3U Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showUrlDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 50),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showUrlDialog,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (allChannels.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            'Toplam ${allChannels.length} kanal yüklendi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildCategoryCard(
                              'Tüm Kanallar',
                              Icons.list,
                              Colors.orangeAccent,
                              null, // Null category means ALL
                            ),
                            _buildCategoryCard(
                              'Canlı Yayınlar',
                              Icons.live_tv,
                              Colors.redAccent,
                              ChannelCategory.live,
                            ),
                            _buildCategoryCard(
                              'Filmler',
                              Icons.movie,
                              Colors.blueAccent,
                              ChannelCategory.movie,
                            ),
                            _buildCategoryCard(
                              'Diziler',
                              Icons.video_library,
                              Colors.green,
                              ChannelCategory.series,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryCard(
      String title, IconData icon, Color color, ChannelCategory? category) {
    final count = category == null
        ? allChannels.length
        : allChannels.where((c) => c.category == category).length;
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToCategory(category),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count İçerik',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
