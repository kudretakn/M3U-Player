import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../repositories/playlist_repository.dart';
import '../utils/url_utils.dart';
import 'dashboard_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistRepository _repository = PlaylistRepository();
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final playlists = await _repository.getPlaylists();
    setState(() {
      _playlists = playlists;
      _isLoading = false;
    });
  }

  Future<void> _addPlaylist() async {
    showDialog(
      context: context,
      builder: (context) => AddPlaylistDialog(
        onAdd: (playlist) async {
          await _repository.savePlaylist(playlist);
          _loadPlaylists();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi Sil'),
        content: Text('${playlist.name} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deletePlaylist(playlist);
      _loadPlaylists();
    }
  }

  void _openPlaylist(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPlaylist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.playlist_add,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz hiç liste eklemediniz.\nSağ üstteki + butonuna basarak ekleyin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addPlaylist,
                        child: const Text('Liste Ekle'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.tv, color: Colors.blueAccent),
                        title: Text(
                          playlist.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          playlist.type == PlaylistType.xtream
                              ? 'Xtream Codes: ${playlist.username}'
                              : 'M3U URL',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deletePlaylist(playlist),
                        ),
                        onTap: () => _openPlaylist(playlist),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddPlaylistDialog extends StatefulWidget {
  final Function(Playlist) onAdd;

  const AddPlaylistDialog({super.key, required this.onAdd});

  @override
  State<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog> {
  bool _isXtream = true;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Liste Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Xtream'),
                    value: true,
                    groupValue: _isXtream,
                    onChanged: (v) => setState(() => _isXtream = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('M3U URL'),
                    value: false,
                    groupValue: _isXtream,
                    onChanged: (v) => setState(() => _isXtream = v!),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Liste Adı (Örn: Ev)'),
            ),
            if (_isXtream) ...[
              TextField(
                controller: _urlController,
                decoration:
                    const InputDecoration(labelText: 'URL (http://...)'),
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
              ),
            ] else ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'M3U Linki'),
              ),
            ],
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
            if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
              return;
            }

            String finalUrl = _urlController.text;
            if (_isXtream) {
              finalUrl = UrlUtils.constructXtreamUrl(
                host: _urlController.text,
                username: _usernameController.text,
                password: _passwordController.text,
              );
            }

            final playlist = Playlist(
              name: _nameController.text,
              url: finalUrl,
              username: _isXtream ? _usernameController.text : null,
              password: _isXtream ? _passwordController.text : null,
              type: _isXtream ? PlaylistType.xtream : PlaylistType.m3u,
            );

            widget.onAdd(playlist);
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
