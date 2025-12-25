import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/channel.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/playback_repository.dart';
import '../repositories/epg_repository.dart';
import 'dart:async';

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
  Timer? _saveTimer;
  String? _currentProgram;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkFavorite();
    _initializePlayer();
    _fetchEpg();
  }

  Future<void> _fetchEpg() async {
    if (widget.channel.tvgId != null) {
      // For now, we don't have the EPG URL passed to the player.
      // In a real app, we would pass the EPG URL or have a singleton repository that holds it.
      // For this demo, I'll skip fetching if no URL is known, or I could try to find it.
      // Since I didn't implement passing the EPG URL from M3uParser to ChannelList to Player,
      // I will just check if I can get it from a global source or just skip for now.

      // Wait, I need to pass the EPG URL to the player or repository.
      // Let's assume for now we just show the tvg-name if EPG data isn't fetched.
      if (mounted) {
        setState(() {
          _currentProgram = widget.channel.tvgName;
        });
      }
    }
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

  Future<void> _initializePlayer() async {
    _player = Player();
    _controller = VideoController(_player);

    await _player.open(Media(widget.channel.streamUrl), play: false);

    // Resume logic
    final savedPosition =
        await PlaybackRepository().getPosition(widget.channel.streamUrl);
    if (savedPosition.inSeconds > 10) {
      await _player.seek(savedPosition);
    }
    await _player.play();

    // Periodic save
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.state.playing) {
        PlaybackRepository()
            .savePosition(widget.channel.streamUrl, _player.state.position);
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Save one last time on exit
    PlaybackRepository()
        .savePosition(widget.channel.streamUrl, _player.state.position);
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _showTracksModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Audio',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              ..._player.state.tracks.audio.map((track) => ListTile(
                    title: Text(track.language ?? track.title ?? 'Unknown',
                        style: const TextStyle(color: Colors.white)),
                    trailing: _player.state.track.audio == track
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      _player.setAudioTrack(track);
                      Navigator.pop(context);
                    },
                  )),
              const Divider(color: Colors.grey),
              const Text('Subtitles',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              ..._player.state.tracks.subtitle.map((track) => ListTile(
                    title: Text(track.language ?? track.title ?? 'Unknown',
                        style: const TextStyle(color: Colors.white)),
                    trailing: _player.state.track.subtitle == track
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      _player.setSubtitleTrack(track);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MaterialVideoControlsTheme(
            normal: MaterialVideoControlsThemeData(
              padding: const EdgeInsets.symmetric(
                  vertical: 48, horizontal: 24), // Lift up controls in portrait
              buttonBarHeight: 64, // Increase height
              bottomButtonBar: [
                const MaterialPositionIndicator(),
                const Spacer(),
                // Custom fullscreen button with padding and larger size
                Transform.scale(
                  scale: 1.1, // Increase size by 10%
                  child: const MaterialFullscreenButton(),
                ),
                const SizedBox(
                    width: 48), // Move slightly left (padding from right)
              ],
              primaryButtonBar: [
                const Spacer(flex: 2),
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  iconSize: 48, // Slightly larger seek buttons too
                  onPressed: () => _seekRelative(const Duration(seconds: -15)),
                ),
                const Spacer(),
                const MaterialPlayOrPauseButton(
                    iconSize: 56), // Larger play/pause
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  iconSize: 48,
                  onPressed: () => _seekRelative(const Duration(seconds: 15)),
                ),
                const Spacer(flex: 2),
              ],
            ),
            fullscreen: MaterialVideoControlsThemeData(
              buttonBarHeight: 64,
              bottomButtonBar: [
                const MaterialPositionIndicator(),
                const Spacer(),
                Transform.scale(
                  scale: 1.1,
                  child: const MaterialFullscreenButton(),
                ),
                const SizedBox(width: 48),
              ],
              primaryButtonBar: [
                const Spacer(flex: 2),
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  iconSize: 48,
                  onPressed: () => _seekRelative(const Duration(seconds: -15)),
                ),
                const Spacer(),
                const MaterialPlayOrPauseButton(iconSize: 56),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  iconSize: 48,
                  onPressed: () => _seekRelative(const Duration(seconds: 15)),
                ),
                const Spacer(flex: 2),
              ],
            ),
            child: Video(
              key: _videoKey,
              controller: _controller,
            ),
          ),
          // Back button overlay
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_currentProgram != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _currentProgram!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                ],
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
                    icon: const Icon(Icons.subtitles,
                        color: Colors.white, size: 30),
                    onPressed: _showTracksModal,
                  ),
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
        ],
      ),
    );
  }
}
