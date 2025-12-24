import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../utils/m3u_parser.dart'; // Ensure M3uParser is imported if needed, or remove if not used directly
import 'player_screen.dart';

class ChannelListScreen extends StatefulWidget {
  final List<Channel> channels;
  final ChannelCategory? initialCategory;

  const ChannelListScreen({
    super.key,
    required this.channels,
    this.initialCategory,
  });

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  List<Channel> _filteredChannels = [];
  List<String> _groups = [];
  String? _selectedGroup;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Filter by category first
    var categoryChannels = widget.channels;
    if (widget.initialCategory != null) {
      categoryChannels = widget.channels
          .where((c) => c.category == widget.initialCategory)
          .toList();
    }

    // Extract groups from the category-filtered list
    _groups = categoryChannels.map((c) => c.group ?? 'Diğer').toSet().toList()
      ..sort();

    // Initially show all channels in this category
    _filteredChannels = categoryChannels;
    _sortChannels();
  }

  void _sortChannels() {
    _filteredChannels.sort((a, b) {
      final aIsTr = a.name.toUpperCase().startsWith('TR');
      final bIsTr = b.name.toUpperCase().startsWith('TR');
      if (aIsTr && !bIsTr) return -1;
      if (!aIsTr && bIsTr) return 1;
      return a.name.compareTo(b.name);
    });
  }

  void _filterChannels() {
    var result = widget.channels;

    // 1. Filter by Category
    if (widget.initialCategory != null) {
      result =
          result.where((c) => c.category == widget.initialCategory).toList();
    }

    // 2. Filter by Group
    if (_selectedGroup != null) {
      result =
          result.where((c) => (c.group ?? 'Diğer') == _selectedGroup).toList();
    }

    // 3. Filter by Search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result =
          result.where((c) => c.name.toLowerCase().contains(query)).toList();
    }

    setState(() {
      _filteredChannels = result;
      _sortChannels();
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle(widget.initialCategory)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kanal Ara...',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              onChanged: (_) => _filterChannels(),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar (Groups)
          Container(
            width: 250,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black12,
                  width: double.infinity,
                  child: const Text(
                    'Kategoriler',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _groups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildGroupTile(null, 'Tümü');
                      }
                      final group = _groups[index - 1];
                      return _buildGroupTile(group, group);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content (Channels)
          Expanded(
            child: _filteredChannels.isEmpty
                ? const Center(child: Text('Kanal bulunamadı'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredChannels.length,
                    itemBuilder: (context, index) {
                      return ChannelCard(
                        channel: _filteredChannels[index],
                        onTap: () => _openPlayer(_filteredChannels[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(String? group, String title) {
    final isSelected = _selectedGroup == group;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blueAccent.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedGroup = group;
          _filterChannels();
        });
      },
    );
  }

  String _getCategoryTitle(ChannelCategory? category) {
    switch (category) {
      case ChannelCategory.live:
        return 'Canlı Yayınlar';
      case ChannelCategory.movie:
        return 'Filmler';
      case ChannelCategory.series:
        return 'Diziler';
      default:
        return 'Tüm Kanallar';
    }
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
