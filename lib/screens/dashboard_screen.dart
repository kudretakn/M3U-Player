import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/m3u_repository.dart';
import 'channel_list_screen.dart';

import 'settings_screen.dart';
import '../models/playlist.dart';

class DashboardScreen extends StatefulWidget {
  final Playlist playlist;

  const DashboardScreen({super.key, required this.playlist});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final M3uRepository _repository = M3uRepository();
  List<Channel> allChannels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedChannels =
          await _repository.fetchChannels(widget.playlist.url);
      setState(() {
        allChannels = fetchedChannels;
        _isLoading = false;
      });

      if (fetchedChannels.isEmpty) {
        if (mounted) {
          _showDebugDialog(widget.playlist.url);
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
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              // Refresh channels when returning from settings
              _loadChannels();
            },
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
                        onPressed: () => _loadChannels(),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isPortrait = constraints.maxWidth < 600;
                            return GridView.count(
                              crossAxisCount: isPortrait ? 1 : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isPortrait ? 3.0 : 1.5,
                              children: [
                                _buildCategoryCard(
                                  'Favoriler',
                                  Icons.favorite,
                                  Colors.pinkAccent,
                                  ChannelCategory.favorites,
                                ),
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryCard(
      String title, IconData icon, Color color, ChannelCategory? category) {
    if (category == ChannelCategory.favorites) {
      return FutureBuilder<List<String>>(
        future: FavoritesRepository().getFavorites(),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _buildCardContent(title, icon, color, category, count);
        },
      );
    }

    final count = category == null
        ? allChannels.length
        : allChannels.where((c) => c.category == category).length;
    return _buildCardContent(title, icon, color, category, count);
  }

  Widget _buildCardContent(String title, IconData icon, Color color,
      ChannelCategory? category, int count) {
    return GestureDetector(
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
    );
  }
}
