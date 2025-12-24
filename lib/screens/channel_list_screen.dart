import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  // Dummy data for initial testing
  final List<Channel> channels = [
    Channel(
        name: 'CNN',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/CNN_International_logo.svg/1200px-CNN_International_logo.svg.png',
        group: 'News'),
    Channel(
        name: 'BBC World',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/BBC_World_News_2022.svg/1200px-BBC_World_News_2022.svg.png',
        group: 'News'),
    Channel(
        name: 'ESPN',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/ESPN_logo.svg/1200px-ESPN_logo.svg.png',
        group: 'Sports'),
    Channel(
        name: 'National Geographic',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/National_Geographic_Logo.svg/1200px-National_Geographic_Logo.svg.png',
        group: 'Documentary'),
    Channel(
        name: 'HBO',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/HBO_logo.svg/1200px-HBO_logo.svg.png',
        group: 'Movies'),
    Channel(
        name: 'Euronews',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Euronews_logo.svg/1200px-Euronews_logo.svg.png',
        group: 'News'),
    Channel(
        name: 'Al Jazeera',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Aljazeera_eng.svg/1200px-Aljazeera_eng.svg.png',
        group: 'News'),
    Channel(
        name: 'Fox News',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Fox_News_Channel_logo.svg/1200px-Fox_News_Channel_logo.svg.png',
        group: 'News'),
    Channel(
        name: 'MSNBC',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/MSNBC_logo.svg/1200px-MSNBC_logo.svg.png',
        group: 'News'),
    Channel(
        name: 'CNBC',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/CNBC_logo.svg/1200px-CNBC_logo.svg.png',
        group: 'News'),
    Channel(
        name: 'Sky News',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Sky_News_logo.svg/1200px-Sky_News_logo.svg.png',
        group: 'News'),
    Channel(
        name: 'Bloomberg',
        streamUrl: '',
        logoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Bloomberg_Television_logo.svg/1200px-Bloomberg_Television_logo.svg.png',
        group: 'News'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3U Player'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // Adjust for TV screen size
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            return ChannelCard(channel: channels[index]);
          },
        ),
      ),
    );
  }
}

class ChannelCard extends StatefulWidget {
  final Channel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
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
                child: widget.channel.logoUrl != null
                    ? Image.network(
                        widget.channel.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.tv, size: 50, color: Colors.grey),
                      )
                    : const Icon(Icons.tv, size: 50, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 1,
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
          ],
        ),
      ),
    );
  }
}
