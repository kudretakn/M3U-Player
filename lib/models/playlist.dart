enum PlaylistType { xtream, m3u }

class Playlist {
  final String name;
  final String url;
  final String? username;
  final String? password;
  final PlaylistType type;

  Playlist({
    required this.name,
    required this.url,
    this.username,
    this.password,
    this.type = PlaylistType.m3u,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'username': username,
      'password': password,
      'type': type.index,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'],
      url: json['url'],
      username: json['username'],
      password: json['password'],
      type: PlaylistType.values[json['type'] ?? 0],
    );
  }
}
