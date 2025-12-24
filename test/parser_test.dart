import 'package:flutter_test/flutter_test.dart';
import 'package:m3u_player/utils/m3u_parser.dart';
import 'package:m3u_player/models/channel.dart';

void main() {
  group('M3uParser Tests', () {
    test('Parses Live TV correctly', () {
      const input = '''
#EXTINF:-1 tvg-logo="logo.png" group-title="Ulusal",TRT 1
http://example.com/stream.m3u8
''';
      final channels = M3uParser.parse(input);
      expect(channels.length, 1);
      expect(channels.first.category, ChannelCategory.live);
    });

    test('Parses Movies correctly (Group Name)', () {
      const input = '''
#EXTINF:-1 group-title="TR | FILMLER",Matrix
http://example.com/movie.mp4
''';
      final channels = M3uParser.parse(input);
      expect(channels.first.category, ChannelCategory.movie);
    });

    test('Parses Movies correctly (Extension)', () {
      const input = '''
#EXTINF:-1 group-title="General",My Video
http://example.com/video.mkv
''';
      final channels = M3uParser.parse(input);
      expect(channels.first.category, ChannelCategory.movie);
    });

    test('Parses Series correctly (Group Name)', () {
      const input = '''
#EXTINF:-1 group-title="TR | DIZILER",Breaking Bad S01
http://example.com/series.mp4
''';
      final channels = M3uParser.parse(input);
      expect(channels.first.category, ChannelCategory.series);
    });

    test('Parses Series correctly (Keywords)', () {
      const input = '''
#EXTINF:-1 group-title="Season 1",Episode 1
http://example.com/ep1.mp4
''';
      final channels = M3uParser.parse(input);
      expect(channels.first.category, ChannelCategory.series);
    });

    test('Parses VOD as Movie', () {
      const input = '''
#EXTINF:-1 group-title="VOD | Action",Action Movie
http://example.com/vod.mp4
''';
      final channels = M3uParser.parse(input);
      expect(channels.first.category, ChannelCategory.movie);
    });
  });
}
