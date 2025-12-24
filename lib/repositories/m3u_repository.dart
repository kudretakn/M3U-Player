import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../utils/m3u_parser.dart';

class M3uRepository {
  final http.Client _client;

  M3uRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Channel>> fetchChannels(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));

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
