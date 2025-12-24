import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../utils/m3u_parser.dart';

class M3uRepository {
  final http.Client _client;

  M3uRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Channel>> fetchChannels(String url) async {
    try {
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
    } catch (e) {
      throw Exception('Error fetching M3U: $e');
    }
  }
}
