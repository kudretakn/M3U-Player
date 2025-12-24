import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/channel.dart';
import '../repositories/favorites_repository.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkFavorite();
    _initializePlayer();
  }

  Future<void> _checkFavorite() async {
    final isFav =
        await FavoritesRepository().isFavorite(widget.channel.streamUrl);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    final repo = FavoritesRepository();
    if (_isFavorite) {
      await repo.removeFavorite(widget.channel.streamUrl);
    } else {
      await repo.addFavorite(widget.channel.streamUrl);
    }
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _seekRelative(Duration duration) async {
    final position = _player.state.position;
    final newPosition = position + duration;
    // Clamp is handled by player usually, but good to be safe if needed.
    // MediaKit handles out of bounds gracefully.
    await _player.seek(newPosition);
  }

  void _initializePlayer() {
    _player = Player();
    _controller = VideoController(_player);

    _player.open(Media(widget.channel.streamUrl));
  }

  @override
  void dispose() {
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Video(key: _videoKey, controller: _controller),
          // Back button overlay
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Favorite button overlay
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_in_picture_alt,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      const MethodChannel('com.example.m3u_player/pip')
                          .invokeMethod('enterPiP');
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.pinkAccent : Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ),
          ),
          // Seek Buttons (Center Left/Right)
          Positioned(
            left: 50,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                iconSize: 50,
                icon: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay_10,
                        color: Colors.white), // Using replay_10 as base
                    Text('15s',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                onPressed: () => _seekRelative(const Duration(seconds: -15)),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                iconSize: 50,
                icon: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward_10,
                        color: Colors.white), // Using forward_10 as base
                    Text('15s',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                onPressed: () => _seekRelative(const Duration(seconds: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
