class Channel {
  final String name;
  final String url;
  final String? logoUrl;
  final String? group;

  Channel({
    required this.name,
    required this.url,
    this.logoUrl,
    this.group,
  });

  @override
  String toString() {
    return 'Channel(name: $name, url: $url, group: $group)';
  }
}
