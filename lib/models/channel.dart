class Channel {
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? group;

  Channel({
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.group,
  });

  @override
  String toString() {
    return 'Channel(name: $name, streamUrl: $streamUrl, logoUrl: $logoUrl, group: $group)';
  }
}
