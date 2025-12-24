class UrlUtils {
  static String constructXtreamUrl({
    required String host,
    required String username,
    required String password,
  }) {
    String url = host.trim();
    final user = username.trim();
    final pass = password.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return '$url/get.php?username=$user&password=$pass&type=m3u_plus&output=ts';
  }
}
