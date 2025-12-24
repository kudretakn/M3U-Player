import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../utils/m3u_parser.dart';
import 'player_screen.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  List<Channel> channels = [];
  bool isLoading = true;
  String? errorMessage;
  
  // Default M3U URL for testing (Free TV channels)
  final TextEditingController _urlController = TextEditingController(
    text: 'https://iptv-org.github.io/iptv/index.m3u',
  );

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(_urlController.text));
      if (response.statusCode == 200) {
        final parsedChannels = M3uParser.parse(response.body);
        setState(() {
          channels = parsedChannels;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load channels: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3U Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChannels,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showUrlDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : channels.isEmpty
                  ? const Center(child: Text('No channels found'))
                  : ListView.builder(
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return ListTile(
                          autofocus: index == 0,
                          leading: channel.logoUrl != null
                              ? Image.network(
                                  channel.logoUrl!,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (c, o, s) => const Icon(Icons.tv),
                                )
                              : const Icon(Icons.tv),
                          title: Text(channel.name),
                          subtitle: channel.group != null ? Text(channel.group!) : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(channel: channel),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter M3U URL'),
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(hintText: 'https://example.com/playlist.m3u'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadChannels();
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}
