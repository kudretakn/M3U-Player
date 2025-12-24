enum ChannelCategory { live, movie, series }

class Channel {
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? group;
  final ChannelCategory category;

  Channel({
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.group,
    this.category = ChannelCategory.live,
  });

  @override
  String toString() {
    return 'Channel(name: $name, streamUrl: $streamUrl, logoUrl: $logoUrl, group: $group, category: $category)';
  }
}
