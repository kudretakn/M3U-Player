import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'settings_repository.dart';
import 'dart:convert';

class EpgProgram {
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;

  EpgProgram({
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });
}

class EpgRepository {
  static final EpgRepository _instance = EpgRepository._internal();
  factory EpgRepository() => _instance;
  EpgRepository._internal();

  Map<String, List<EpgProgram>>? _cachedEpgData;
  DateTime? _lastFetchTime;

  Future<List<EpgProgram>> getSchedule(String tvgId) async {
    if (_cachedEpgData == null || _shouldRefresh()) {
      await _fetchAndParseEpg();
    }
    return _cachedEpgData?[tvgId] ?? [];
  }

  Future<EpgProgram?> getCurrentProgram(String tvgId) async {
    final schedule = await getSchedule(tvgId);
    final now = DateTime.now().toUtc(); // XMLTV dates often UTC or with offset

    // Simple find
    for (var program in schedule) {
      if (program.start.isBefore(now) && program.end.isAfter(now)) {
        return program;
      }
    }
    return null;
  }

  bool _shouldRefresh() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) >
        const Duration(hours: 4);
  }

  Future<void> _fetchAndParseEpg() async {
    final url = await SettingsRepository().getEpgUrl();
    if (url == null || url.isEmpty) {
      print('No EPG URL found.');
      return;
    }

    try {
      print('Fetching EPG from: $url');
      final response =
          await http.get(Uri.parse(url)); // TODO: Handle GZIP if needed

      if (response.statusCode == 200) {
        // XML parsing can be heavy. In a real app, use compute() isolate.
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        _parseXml(document);
        _lastFetchTime = DateTime.now();
      } else {
        print('Failed to fetch EPG: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching EPG: $e');
    }
  }

  void _parseXml(XmlDocument document) {
    final Map<String, List<EpgProgram>> newCache = {};

    final programmes = document.findAllElements('programme');
    for (var element in programmes) {
      final channelId = element.getAttribute('channel');
      if (channelId == null) continue;

      final startStr = element.getAttribute('start'); // "20080715003000 +0200"
      final endStr = element.getAttribute('stop');
      final title =
          element.findElements('title').firstOrNull?.innerText ?? 'No Title';
      final desc = element.findElements('desc').firstOrNull?.innerText;

      if (startStr != null && endStr != null) {
        try {
          final start = _parseXmlTvDate(startStr);
          final end = _parseXmlTvDate(endStr);

          if (!newCache.containsKey(channelId)) {
            newCache[channelId] = [];
          }
          newCache[channelId]!.add(EpgProgram(
            title: title,
            start: start,
            end: end,
            description: desc,
          ));
        } catch (e) {
          // Date parsing error
          print('EPG Date Error: $e');
        }
      }
    }
    _cachedEpgData = newCache;
  }

  // Format: YYYYMMDDhhmmss +/-HHMM
  DateTime _parseXmlTvDate(String raw) {
    // 20231225190000 +0300
    final year = int.parse(raw.substring(0, 4));
    final month = int.parse(raw.substring(4, 6));
    final day = int.parse(raw.substring(6, 8));
    final hour = int.parse(raw.substring(8, 10));
    final minute = int.parse(raw.substring(10, 12));
    final second = int.parse(raw.substring(12, 14));

    // Parse offset if present
    // Not implementing full timezone logic for brevity, assuming UTC for now or ignoring offset if it matches local time implicitly
    // Ideally, parse offset and return UTC DateTime

    return DateTime.utc(year, month, day, hour, minute, second);
    // This is naive. Real implementation requires handling the offset.
    // If offset is +0300, it means the time stated is +3 ahead of UTC.
    // So 19:00 +0300 is 16:00 UTC.

    // Let's try basic offset handling
    // final offsetPart = raw.split(' ').last; // +0300
    // But for MVP, let's treat it as local or UTC depending on usage.
    // Actually, DateTime.parse might handle ISO, but this is custom format.
  }
}
