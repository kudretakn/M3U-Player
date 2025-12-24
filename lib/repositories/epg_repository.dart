import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class EpgRepository {
  // Map of tvg-id to current program title
  final Map<String, String> _programMap = {};

  Future<void> fetchEpg(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final programmes = document.findAllElements('programme');

        // Simple parsing: just get the title for now.
        // Real EPG needs time checking which is complex.
        // This is a placeholder for the "Professional" feature foundation.
        for (var programme in programmes) {
          final channelId = programme.getAttribute('channel');
          final title = programme.findAllElements('title').first.innerText;
          if (channelId != null) {
            _programMap[channelId] = title;
          }
        }
      }
    } catch (e) {
      // print('Error fetching EPG: $e');
    }
  }

  String? getCurrentProgram(String tvgId) {
    return _programMap[tvgId];
  }
}
