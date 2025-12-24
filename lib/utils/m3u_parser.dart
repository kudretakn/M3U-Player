import '../models/channel.dart';

class M3uParser {
  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;

    // Regex to extract attributes from #EXTINF line
    // Example: #EXTINF:-1 tvg-logo="http://logo.png" group-title="News",Channel Name
    final RegExp extInfRegex = RegExp(r'#EXTINF:.*?,(.*)');
    final RegExp logoRegex = RegExp(r'tvg-logo="([^"]*)"');
    final RegExp groupRegex = RegExp(r'group-title="([^"]*)"');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Extract name
        final nameMatch = extInfRegex.firstMatch(line);
        if (nameMatch != null) {
          currentName = nameMatch.group(1)?.trim();
        }

        // Extract logo
        final logoMatch = logoRegex.firstMatch(line);
        if (logoMatch != null) {
          currentLogo = logoMatch.group(1);
        }

        // Extract group
        final groupMatch = groupRegex.firstMatch(line);
        if (groupMatch != null) {
          currentGroup = groupMatch.group(1);
        }
      } else if (!line.startsWith('#')) {
        // Assume it's a URL if it doesn't start with #
        if (currentName != null) {
          final category = _determineCategory(currentGroup, line);
          channels.add(Channel(
            name: currentName,
            streamUrl: line,
            logoUrl: currentLogo,
            group: currentGroup,
            category: category,
          ));
          // Reset for next channel
          currentName = null;
          currentLogo = null;
          currentGroup = null;
        }
      }
    }

    return channels;
  }

  static ChannelCategory _determineCategory(String? group, String url) {
    final groupLower = group?.toLowerCase() ?? '';
    final urlLower = url.toLowerCase();

    // Series detection
    if (groupLower.contains('series') ||
        groupLower.contains('dizi') ||
        groupLower.contains('season') ||
        groupLower.contains('sezon') ||
        groupLower.contains('bölüm') ||
        groupLower.contains('episode')) {
      return ChannelCategory.series;
    }

    // Movie detection
    if (groupLower.contains('movie') ||
        groupLower.contains('film') ||
        groupLower.contains('vod') ||
        groupLower.contains('sinema') ||
        groupLower.contains('cinema') ||
        groupLower.contains('movies') ||
        urlLower.endsWith('.mp4') ||
        urlLower.endsWith('.mkv') ||
        urlLower.endsWith('.avi') ||
        urlLower.contains('movie') ||
        urlLower.contains('movies')) {
      return ChannelCategory.movie;
    }

    // Default to live
    return ChannelCategory.live;
  }
}
