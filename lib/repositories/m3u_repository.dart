import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../utils/m3u_parser.dart';
import 'settings_repository.dart';

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
    if (kIsWeb) {
      // Web Proxy Logic
      final proxies = [
        (String u) =>
            'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(u)}',
        (String u) => 'https://corsproxy.io/?${Uri.encodeComponent(u)}',
      ];

      for (var proxy in proxies) {
        try {
          final response = await _client.get(
            Uri.parse(proxy(url)),
            headers: {'User-Agent': 'IPTV Smarters Pro'},
          );
          if (response.statusCode == 200) {
            return M3uParser.parse(
                utf8.decode(response.bodyBytes, allowMalformed: true));
          }
        } catch (e) {
          print('Proxy failed: $e');
        }
      }
      throw Exception('All web proxies failed.');
    } else {
      // Native Logic
      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'IPTV Smarters Pro'},
      );

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes, allowMalformed: true);

        // Extract and save EPG URL
        final epgUrl = M3uParser.extractEpgUrl(content);
        if (epgUrl != null && epgUrl.isNotEmpty) {
          SettingsRepository().saveEpgUrl(epgUrl);
          print('EPG URL found and saved: $epgUrl');
        }

        final channels = M3uParser.parse(content);
        return await _filterChannels(channels);
      } else {
        throw Exception(
            'Failed to load M3U: ${response.statusCode} ${response.reasonPhrase}');
      }
    }
  }

  Future<List<Channel>> _filterChannels(List<Channel> channels) async {
    final settingsRepo = SettingsRepository();
    final adultFilterEnabled = await settingsRepo.isAdultFilterEnabled();

    if (!adultFilterEnabled) return channels;

    final adultKeywords = [
      'xxx',
      'porn',
      'adult',
      '+18',
      'sex',
      'erotic',
      'hardcore',
      'nsfw'
    ];

    return channels.where((channel) {
      final nameLower = channel.name.toLowerCase();
      final groupLower = channel.group?.toLowerCase() ?? '';

      for (var keyword in adultKeywords) {
        if (nameLower.contains(keyword) || groupLower.contains(keyword)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
