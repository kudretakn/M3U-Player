import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'player_screen.dart';

class SeriesScreen extends StatefulWidget {
  final List<Channel> channels;

  const SeriesScreen({super.key, required this.channels});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  Map<String, List<Channel>> _seriesMap = {};
  List<String> _seriesTitles = [];
  Channel?
      _selectedSeriesForEpisodes; // If not null, show episodes for this series

  @override
  void initState() {
    super.initState();
    _groupSeries();
  }

  void _groupSeries() {
    _seriesMap = {};
    for (var channel in widget.channels) {
      final seriesName = channel.seriesName ?? channel.name;
      if (!_seriesMap.containsKey(seriesName)) {
        _seriesMap[seriesName] = [];
      }
      _seriesMap[seriesName]!.add(channel);
    }
    _seriesTitles = _seriesMap.keys.toList()..sort();
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
    if (_selectedSeriesForEpisodes != null) {
      return _buildEpisodeList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diziler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _seriesTitles.length,
        itemBuilder: (context, index) {
          final title = _seriesTitles[index];
          final episodes = _seriesMap[title]!;
          final firstEpisode = episodes.isNotEmpty ? episodes.first : null;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSeriesForEpisodes =
                    firstEpisode; // Use channel as marker, or just boolean logic
                // Actually better to store the title
              });
            },
            child: _buildSeriesCard(title, firstEpisode),
          );
        },
      ),
    );
  }

  // Re-implementing build to handle state better
  Widget _buildSeriesCard(String title, Channel? sampleChannel) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EpisodeListScreen(
              seriesTitle: title,
              episodes: _seriesMap[title]!,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: sampleChannel?.logoUrl != null
                    ? Image.network(
                        sampleChannel!.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.movie_filter,
                            size: 50,
                            color: Colors.grey),
                      )
                    : const Icon(Icons.movie_filter,
                        size: 50, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    // This part is handled by navigation to EpisodeListScreen
    return Container();
  }
}

class EpisodeListScreen extends StatelessWidget {
  final String seriesTitle;
  final List<Channel> episodes;

  const EpisodeListScreen(
      {super.key, required this.seriesTitle, required this.episodes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(seriesTitle),
      ),
      body: ListView.builder(
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(episode.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(channel: episode),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
