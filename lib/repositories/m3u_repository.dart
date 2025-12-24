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
        // Note: This is a public proxy, use with caution for sensitive data.
        // For production, a dedicated backend proxy is recommended.
        fetchUrl =
            'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
      }

      final response = await _client.get(Uri.parse(fetchUrl));

      if (response.statusCode == 200) {
        return M3uParser.parse(response.body);
      } else {
        throw Exception('Failed to load M3U: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching M3U: $e');
    }
  }
}
