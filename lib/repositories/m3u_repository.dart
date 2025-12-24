import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../utils/m3u_parser.dart';

class M3uRepository {
  final http.Client _client;

  M3uRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Channel>> fetchChannels(String url) async {
    try {
      return await _fetch(url);
    } catch (e) {
      // If the initial request fails and it was HTTPS, try HTTP
      if (url.startsWith('https://')) {
        try {
          final httpUrl = url.replaceFirst('https://', 'http://');
          return await _fetch(httpUrl);
        } catch (e2) {
          // If fallback also fails, throw the original error or a combined one
          throw Exception('Error fetching M3U: $e (Fallback failed: $e2)');
        }
      }
      throw Exception('Error fetching M3U: $e');
    }
  }

  Future<List<Channel>> _fetch(String url) async {
    String fetchUrl = url;
    if (kIsWeb) {
      // Use a CORS proxy for Web to avoid ClientException/CORS errors
      // Switching to CodeTabs as it is often more reliable for raw content
      fetchUrl =
          'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}';
    }

    final response = await _client.get(Uri.parse(fetchUrl));

    if (response.statusCode == 200) {
      final channels = M3uParser.parse(response.body);
      return channels;
    } else {
      throw Exception(
          'Failed to load M3U: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
