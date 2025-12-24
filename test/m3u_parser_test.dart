import 'package:flutter_test/flutter_test.dart';
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
    });

    test('parses multiple channels correctly', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-logo="logo1.png",Channel 1
http://stream.url/1
#EXTINF:-1 group-title="Sports",Channel 2
http://stream.url/2
''';

      final channels = M3uParser.parse(m3uContent);

      expect(channels.length, 2);
      expect(channels[0].name, 'Channel 1');
      expect(channels[0].logoUrl, 'logo1.png');
      expect(channels[1].name, 'Channel 2');
      expect(channels[1].group, 'Sports');
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
