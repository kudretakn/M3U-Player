import 'package:flutter_test/flutter_test.dart';
import 'package:m3u_player/utils/url_utils.dart';

void main() {
  group('UrlUtils Tests', () {
    test('constructs Xtream URL correctly with http', () {
      final url = UrlUtils.constructXtreamUrl(
        host: 'http://example.com',
        username: 'user',
        password: '123',
      );
      expect(url,
          'http://example.com/get.php?username=user&password=123&type=m3u_plus&output=ts');
    });

    test('constructs Xtream URL correctly without scheme', () {
      final url = UrlUtils.constructXtreamUrl(
        host: 'example.com',
        username: 'user',
        password: '123',
      );
      expect(url,
          'http://example.com/get.php?username=user&password=123&type=m3u_plus&output=ts');
    });

    test('removes trailing slash', () {
      final url = UrlUtils.constructXtreamUrl(
        host: 'http://example.com/',
        username: 'user',
        password: '123',
      );
      expect(url,
          'http://example.com/get.php?username=user&password=123&type=m3u_plus&output=ts');
    });

    test('trims inputs', () {
      final url = UrlUtils.constructXtreamUrl(
        host: ' example.com ',
        username: ' user ',
        password: ' 123 ',
      );
      expect(url,
          'http://example.com/get.php?username=user&password=123&type=m3u_plus&output=ts');
    });
  });
}
