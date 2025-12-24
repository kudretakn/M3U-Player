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
      // Fallback 1: If 404 and using get.php, try player_api.php
      if (e.toString().contains('404') && url.contains('get.php')) {
        try {
          final altUrl = url.replaceFirst('get.php', 'player_api.php');
          return await _fetch(altUrl);
        } catch (e3) {
          // Ignore and proceed to other fallbacks or throw
        }
      }

      // Fallback 2: If HTTPS fails, try HTTP
      if (url.startsWith('https://')) {
        try {
          final httpUrl = url.replaceFirst('https://', 'http://');
          // Also apply get.php -> player_api.php logic to HTTP fallback if needed
          try {
            return await _fetch(httpUrl);
          } catch (e4) {
            if (e4.toString().contains('404') && httpUrl.contains('get.php')) {
              final altHttpUrl =
                  httpUrl.replaceFirst('get.php', 'player_api.php');
              return await _fetch(altHttpUrl);
            }
            rethrow;
          }
        } catch (e2) {
          throw Exception('Error fetching M3U: $e (Fallback failed: $e2)');
        }
      }
      throw Exception('Error fetching M3U: $e');
    }
  }

  Future<String> testConnection(String url) async {
    try {
      String fetchUrl = url;
      if (kIsWeb) {
        fetchUrl =
            'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}';
      }

      var response = await _client.get(
        Uri.parse(fetchUrl),
        headers: {'User-Agent': 'IPTV Smarters Pro'},
      );

      // If 404 and get.php, try player_api.php
      if (response.statusCode == 404 && url.contains('get.php')) {
        final altUrl = url.replaceFirst('get.php', 'player_api.php');
        String altFetchUrl = altUrl;
        if (kIsWeb) {
          altFetchUrl =
              'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(altUrl)}';
        }
        final altResponse = await _client.get(
          Uri.parse(altFetchUrl),
          headers: {'User-Agent': 'IPTV Smarters Pro'},
        );

        return 'Primary (get.php): 404 Not Found\n'
            'Secondary (player_api.php): ${altResponse.statusCode} ${altResponse.reasonPhrase}\n'
            'Body: ${altResponse.body.substring(0, altResponse.body.length > 100 ? 100 : altResponse.body.length)}';
      }

      return 'Status Code: ${response.statusCode}\n'
          'Reason: ${response.reasonPhrase}\n'
          'Body Preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
    } catch (e) {
      return 'Connection Error: $e';
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

    final response = await _client.get(
      Uri.parse(fetchUrl),
      headers: {
        'User-Agent': 'IPTV Smarters Pro', // Mimic a popular player
      },
    );

    if (response.statusCode == 200) {
      final channels = M3uParser.parse(response.body);
      return channels;
    } else {
      throw Exception(
          'Failed to load M3U: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
