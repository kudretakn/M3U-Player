import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../repositories/m3u_repository.dart';
import '../utils/url_utils.dart';
import 'player_screen.dart';

// Assuming ChannelCategory is defined in models/channel.dart or similar.
// If not, it needs to be defined here or in a separate file.
// For the purpose of this replacement, I'll define it here if not present in the original context.
// However, the instruction implies it's part of the existing structure or will be added.
// Let's assume it's an enum that categorizes channels.
enum ChannelCategory {
  live,
  movie,
  series,
  // Add other categories as needed
}

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final M3uRepository _repository = M3uRepository();
  List<Channel> allChannels = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Optionally load default channels or show dialog on first launch
    // _showUrlDialog();
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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showUrlDialog() {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                print('Yükle button pressed'); // Debug log
                Navigator.pop(context);
                String url = urlController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                print('URL Input: $url'); // Debug log
                print('Username Input: $username'); // Debug log

                if (url.isNotEmpty) {
                  if (username.isNotEmpty && password.isNotEmpty) {
                    final finalUrl = UrlUtils.constructXtreamUrl(
                      host: url,
                      username: username,
                      password: password,
                    );
                    print('Constructed Xtream URL: $finalUrl'); // Debug log
                    _loadChannels(finalUrl);
                  } else {
                    // Use URL as is
                    print('Using direct URL: $url'); // Debug log
                    _loadChannels(url);
                  }
                } else {
                  print('URL is empty'); // Debug log
                }
              },
              child: const Text('Yükle'),
            ),
          ],
        );
      },
    );
  }

  void _openPlayer(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(channel: channel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('M3U Player'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Canlı Yayınlar', icon: Icon(Icons.live_tv)),
              Tab(text: 'Filmler', icon: Icon(Icons.movie)),
              Tab(text: 'Diziler', icon: Icon(Icons.video_library)),
            ],
            indicatorColor: Colors.blueAccent,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'URL Yükle',
              onPressed: _showUrlDialog,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildChannelGrid(ChannelCategory.live),
            _buildChannelGrid(ChannelCategory.movie),
            _buildChannelGrid(ChannelCategory.series),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelGrid(ChannelCategory category) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showUrlDialog,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final filteredChannels =
        allChannels.where((c) => c.category == category).toList();

    if (filteredChannels.isEmpty) {
      if (allChannels.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.playlist_add, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Liste Boş',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sağ üstteki link ikonuna tıklayarak bir M3U URL ekleyin.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Text(
            'Bu kategoride içerik bulunamadı.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
        );
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredChannels.length,
      itemBuilder: (context, index) {
        return ChannelCard(
          channel: filteredChannels[index],
          onTap: () => _openPlayer(filteredChannels[index]),
        );
      },
    );
  }
}

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;

  const ChannelCard({super.key, required this.channel, required this.onTap});

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: _isFocused
                ? Border.all(color: Colors.blueAccent, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: widget.channel.logoUrl != null &&
                          widget.channel.logoUrl!.isNotEmpty
                      ? Image.network(
                          widget.channel.logoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.tv,
                                  size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.tv, size: 50, color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    widget.channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
