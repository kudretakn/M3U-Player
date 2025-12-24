import 'package:flutter_test/flutter_test.dart';
import 'package:m3u_player/utils/m3u_parser.dart';

void main() {
  test('Parses M3U content correctly', () {
    const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-logo="http://logo.com/1.png" group-title="News",Channel 1
http://stream.com/1.m3u8
#EXTINF:-1,Channel 2
http://stream.com/2.m3u8
''';

    final channels = M3uParser.parse(m3uContent);

    expect(channels.length, 2);
    
    expect(channels[0].name, 'Channel 1');
    expect(channels[0].url, 'http://stream.com/1.m3u8');
    expect(channels[0].logoUrl, 'http://logo.com/1.png');
    expect(channels[0].group, 'News');

    expect(channels[1].name, 'Channel 2');
    expect(channels[1].url, 'http://stream.com/2.m3u8');
    expect(channels[1].logoUrl, null);
    expect(channels[1].group, null);
  });
}
