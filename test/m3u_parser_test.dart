import 'package:flutter_test/flutter_test.dart';
import 'package:m3u_player/models/channel.dart';
import 'package:m3u_player/utils/m3u_parser.dart';

void main() {
  group('M3uParser Tests', () {
    test('parses simple M3U correctly', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-logo="http://logo.png" group-title="News",Channel 1
http://stream.url/1
''';

      final channels = M3uParser.parse(m3uContent);

      expect(channels.length, 1);
      expect(channels[0].name, 'Channel 1');
      expect(channels[0].streamUrl, 'http://stream.url/1');
      expect(channels[0].logoUrl, 'http://logo.png');
      expect(channels[0].group, 'News');
      expect(channels[0].category, ChannelCategory.live);
    });

    test('categorizes movies correctly', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 group-title="Movies",Movie 1
http://stream.url/movie.mp4
#EXTINF:-1 group-title="VOD",Movie 2
http://stream.url/movie2
''';

      final channels = M3uParser.parse(m3uContent);

      expect(channels.length, 2);
      expect(channels[0].category, ChannelCategory.movie);
      expect(channels[1].category, ChannelCategory.movie);
    });

    test('categorizes series correctly', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 group-title="Series",Series 1
http://stream.url/series1
#EXTINF:-1 group-title="Dizi",Series 2
http://stream.url/series2
''';

      final channels = M3uParser.parse(m3uContent);

      expect(channels.length, 2);
      expect(channels[0].category, ChannelCategory.series);
      expect(channels[1].category, ChannelCategory.series);
    });

    test('handles empty lines and whitespace', () {
      const m3uContent = '''

#EXTM3U

#EXTINF:-1,Channel 1
http://stream.url/1

''';

      final channels = M3uParser.parse(m3uContent);

      expect(channels.length, 1);
      expect(channels[0].name, 'Channel 1');
    });
  });
}
