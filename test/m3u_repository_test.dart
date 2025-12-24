import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:m3u_player/repositories/m3u_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'm3u_repository_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('M3uRepository', () {
    test('returns list of channels if the http call completes successfully',
        () async {
      final client = MockClient();
      final repository = M3uRepository(client: client);

      when(client.get(Uri.parse('https://example.com/playlist.m3u')))
          .thenAnswer((_) async => http.Response('''
#EXTM3U
#EXTINF:-1,Channel 1
http://stream.url/1
''', 200));

      final channels =
          await repository.fetchChannels('https://example.com/playlist.m3u');

      expect(channels, isA<List>());
      expect(channels.length, 1);
      expect(channels[0].name, 'Channel 1');
    });

    test('throws an exception if the http call completes with an error', () {
      final client = MockClient();
      final repository = M3uRepository(client: client);

      when(client.get(Uri.parse('https://example.com/playlist.m3u')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(repository.fetchChannels('https://example.com/playlist.m3u'),
          throwsException);
    });
  });
}
