import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../repositories/favorites_repository.dart';
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

  String? _selectedSeries;

  Future<void> _initializeData() async {
    // Filter by category first
    var categoryChannels = widget.channels;
    if (widget.initialCategory != null) {
      if (widget.initialCategory == ChannelCategory.favorites) {
        final favorites = await FavoritesRepository().getFavorites();
        categoryChannels = widget.channels
            .where((c) => favorites.contains(c.streamUrl))
            .toList();
      } else {
        categoryChannels = widget.channels
            .where((c) => c.category == widget.initialCategory)
            .toList();
      }
    }

    // Extract groups from the category-filtered list
    _groups = categoryChannels.map((c) => c.group ?? 'Diğer').toSet().toList();

    // Sort groups: Days first (Mon-Sun), then TR, then alphabetical
    _groups.sort((a, b) {
      final aDayIndex = _getDayIndex(a);
      final bDayIndex = _getDayIndex(b);

      // 1. Sort by Day Index (if both are days)
      if (aDayIndex != -1 && bDayIndex != -1) {
        return aDayIndex.compareTo(bDayIndex);
      }
      // 2. Prioritize Days over everything else
      if (aDayIndex != -1) return -1;
      if (bDayIndex != -1) return 1;

      // 3. Existing TR logic
      final aHasTr = a.toUpperCase().startsWith('TR');
      final bHasTr = b.toUpperCase().startsWith('TR');
      if (aHasTr && !bHasTr) return -1;
      if (!aHasTr && bHasTr) return 1;

      // 4. Alphabetical
      return a.compareTo(b);
    });

    if (mounted) {
      setState(() {
        // Initially show all channels in this category
        _filteredChannels = categoryChannels;
        _selectedSeries = null; // Reset series selection
      });
    }
  }

  void _filterChannels() {
    var result = widget.channels;

    // 1. Filter by Category
    if (widget.initialCategory != null) {
      if (widget.initialCategory == ChannelCategory.favorites) {
        // For favorites, we might want to skip series grouping or handle it differently.
        // For now, let's keep it simple: if favorite, show flat list or group if possible.
        // But the user asked for "Diziler" category specifically.
        // Let's rely on the _initializeData logic for the base list.
        result = result.where((c) => _filteredChannels.contains(c)).toList();
      } else {
        result =
            result.where((c) => c.category == widget.initialCategory).toList();
      }
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
    // 4. Filter by Series (if selected)
    else if (_selectedSeries != null) {
      result = result.where((c) => c.seriesName == _selectedSeries).toList();
    }

    setState(() {
      _filteredChannels = result;
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Auto-open drawer after built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openDrawer();
    });
  }

  // ... (keeping initializeData and filterChannels same) ...

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxWidth < 600;

        // Determine what to show in the grid
        List<dynamic> gridItems = [];
        bool isSeriesMode = widget.initialCategory == ChannelCategory.series &&
            _selectedSeries == null &&
            _searchController.text.isEmpty;

        if (isSeriesMode) {
          // Show Series Folders
          // Group filtered channels by seriesName
          final seriesNames = _filteredChannels
              .map((c) =>
                  c.seriesName ?? c.name) // Fallback to name if no seriesName
              .toSet()
              .toList();
          seriesNames.sort();
          gridItems = seriesNames;
        } else {
          // Show Channels/Episodes
          gridItems = _filteredChannels;
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Row(
              children: [
                Text(_getCategoryTitle(widget.initialCategory)),
                if (_selectedSeries != null) ...[
                  const Icon(Icons.chevron_right, color: Colors.grey),
                  Expanded(
                    child: Text(
                      _selectedSeries!,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              ],
            ),
            leading: _selectedSeries != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedSeries = null;
                        _filterChannels();
                      });
                    },
                  )
                : null, // Default hamburger menu will show since we have a drawer
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              SizedBox(
                width: isPortrait ? 200 : 300,
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
          drawer: Drawer(
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
          body: gridItems.isEmpty
              ? const Center(child: Text('İçerik bulunamadı'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isPortrait ? 2 : 5,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: gridItems.length,
                  itemBuilder: (context, index) {
                    if (isSeriesMode) {
                      final seriesName = gridItems[index] as String;
                      // Find first channel of this series to get logo
                      final firstChannel = _filteredChannels.firstWhere(
                          (c) => (c.seriesName ?? c.name) == seriesName,
                          orElse: () => _filteredChannels[0]);

                      return _buildSeriesCard(seriesName, firstChannel.logoUrl);
                    } else {
                      return ChannelCard(
                        channel: gridItems[index] as Channel,
                        onTap: () => _openPlayer(gridItems[index] as Channel),
                      );
                    }
                  },
                ),
        );
      },
    );
  }

  Widget _buildSeriesCard(String seriesName, String? logoUrl) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSeries = seriesName;
          _filterChannels();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: logoUrl != null && logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.folder,
                                size: 50, color: Colors.blueAccent),
                      )
                    : const Icon(Icons.folder,
                        size: 50, color: Colors.blueAccent),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  seriesName,
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
          _selectedSeries = null; // Reset series selection when changing group
          _selectedGroup = group;
          _filterChannels();
        });
        // Close the drawer after selection
        Navigator.pop(context);
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

  int _getDayIndex(String groupName) {
    final lowerName = groupName.toLowerCase();
    if (lowerName.contains('pazartesi')) return 0;
    if (lowerName.contains('salı') || lowerName.contains('sali')) return 1;
    if (lowerName.contains('çarşamba') || lowerName.contains('carsamba'))
      return 2;
    if (lowerName.contains('perşembe') || lowerName.contains('persembe'))
      return 3;
    if (lowerName.contains('cuma') && !lowerName.contains('cumartesi'))
      return 4;
    if (lowerName.contains('cumartesi')) return 5;
    if (lowerName.contains('pazar') && !lowerName.contains('pazartesi'))
      return 6;
    return -1;
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
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
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
          child: Stack(
            children: [
              Column(
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
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.pinkAccent : Colors.grey,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
