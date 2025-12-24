enum ChannelCategory { live, movie, series, favorites }

class Channel {
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? group;
  final ChannelCategory category;
  final String? seriesName;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;

  Channel({
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.group,
    this.category = ChannelCategory.live,
    this.seriesName,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
  });

  @override
  String toString() {
    return 'Channel(name: $name, streamUrl: $streamUrl, logoUrl: $logoUrl, group: $group, category: $category)';
  }
}
