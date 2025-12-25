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
      if (mounted) {
        // Ask user what to do
        final shouldResume = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Kaldığın Yerden Devam Et?',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'Önceki izleme noktasından devam etmek ister misin?\n(${_formatDuration(savedPosition)})',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Baştan Başla',
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Devam Et',
                    style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );

        if (shouldResume == true) {
          // Robust Way: Wait for duration to be known before seeking
          StreamSubscription<Duration>? subscription;
          subscription = _player.stream.duration.listen((duration) {
            if (duration != Duration.zero) {
              _player.seek(savedPosition);
              subscription?.cancel();
            }
          });
        }
      }
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          _currentProgram!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    ),
                ],
              ),
            ),
          ),
          // Favorite button overlay (Moved down to avoid overlap)
          Positioned(
            top: 80,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white, size: 30),
                    tooltip: 'Yayın Akışı',
                    onPressed: _showEpgModal,
                  ),
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

  Future<void> _fetchEpg() async {
    if (widget.channel.tvgId != null) {
      final current =
          await EpgRepository().getCurrentProgram(widget.channel.tvgId!);
      if (mounted) {
        setState(() {
          if (current != null) {
            final start = _formatTime(current.start);
            final end = _formatTime(current.end);
            _currentProgram = '$start - $end: ${current.title}';
          } else {
            _currentProgram = widget.channel.tvgName ?? widget.channel.name;
          }
        });
      }
    } else {
      setState(() {
        _currentProgram = widget.channel.tvgName ?? widget.channel.name;
      });
    }
  }

  void _showEpgModal() async {
    if (widget.channel.tvgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kanal için yayın akışı bulunamadı.')),
      );
      return;
    }

    final schedule = await EpgRepository().getSchedule(widget.channel.tvgId!);
    if (!mounted) return;

    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayın akışı bilgisi yüklenemedi.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${widget.channel.name} - Yayın Akışı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: schedule.length,
                    itemBuilder: (context, index) {
                      final program = schedule[index];
                      final isNow =
                          DateTime.now().toUtc().isAfter(program.start) &&
                              DateTime.now().toUtc().isBefore(program.end);

                      return ListTile(
                        leading: Text(
                          _formatTime(program.start),
                          style: TextStyle(
                            color: isNow ? Colors.blueAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: Text(
                          program.title,
                          style: TextStyle(
                            color: isNow ? Colors.white : Colors.white70,
                            fontWeight:
                                isNow ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: program.description != null
                            ? Text(
                                program.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white30),
                              )
                            : null,
                        tileColor:
                            isNow ? Colors.blueAccent.withOpacity(0.1) : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    // Add 3 hours for simplistic timezone fix if assumed UTC, or just raw. Use raw logic for MVP.
    // If date is UTC, just toLocal() might work if device is in correct zone.
    // Let's use toLocal() which is safer.
    final local = date.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
}
