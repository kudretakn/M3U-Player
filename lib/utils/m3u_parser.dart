import '../models/channel.dart';

class M3uParser {
  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;

    // Regex to extract attributes from #EXTINF line
    // Example: #EXTINF:-1 tvg-logo="http://logo.png" group-title="News",Channel Name
    final RegExp extInfRegex = RegExp(r'#EXTINF:.*?,(.*)');
    final RegExp logoRegex = RegExp(r'tvg-logo="([^"]*)"');
    final RegExp groupRegex = RegExp(r'group-title="([^"]*)"');
    final RegExp tvgIdRegex = RegExp(r'tvg-id="([^"]*)"');
    final RegExp tvgNameRegex = RegExp(r'tvg-name="([^"]*)"');

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

        // Extract tvg-id
        final tvgIdMatch = tvgIdRegex.firstMatch(line);
        if (tvgIdMatch != null) {
          currentTvgId = tvgIdMatch.group(1);
        }

        // Extract tvg-name
        final tvgNameMatch = tvgNameRegex.firstMatch(line);
        if (tvgNameMatch != null) {
          currentTvgName = tvgNameMatch.group(1);
        }
      } else if (!line.startsWith('#')) {
        // Assume it's a URL if it doesn't start with #
        if (currentName != null) {
          var category = _determineCategory(currentGroup, line);
          String? seriesName;

          // Try to extract series name regardless of initial category
          // This helps catch series that might be mislabeled as movies
          final potentialSeriesName = _extractSeriesName(currentName);

          // If the extracted name is significantly different (shorter) than the full name,
          // it likely means we successfully stripped SxxExx, implying it IS a series.
          if (potentialSeriesName != currentName &&
              potentialSeriesName.length < currentName.length) {
            category = ChannelCategory.series;
            seriesName = potentialSeriesName;
          } else if (category == ChannelCategory.series) {
            seriesName = potentialSeriesName;
          }

          channels.add(Channel(
            name: currentName,
            streamUrl: line,
            logoUrl: currentLogo,
            group: currentGroup,
            category: category,
            seriesName: seriesName,
            tvgId: currentTvgId,
            tvgName: currentTvgName,
          ));
          // Reset for next channel
          currentName = null;
          currentLogo = null;
          currentGroup = null;
          currentTvgId = null;
          currentTvgName = null;
        }
      }
    }
    return channels;
  }

  static String? extractEpgUrl(String content) {
    // Look for #EXTM3U header line
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.trim().startsWith('#EXTM3U')) {
        // Try url-tvg
        final urlTvgMatch = RegExp(r'url-tvg="([^"]*)"').firstMatch(line);
        if (urlTvgMatch != null) return urlTvgMatch.group(1);

        // Try x-tvg-url
        final xTvgUrlMatch = RegExp(r'x-tvg-url="([^"]*)"').firstMatch(line);
        if (xTvgUrlMatch != null) return xTvgUrlMatch.group(1);

        break; // Header usually implies first relevant line, stop if found but empty
      }
    }
    return null;
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

  static String _extractSeriesName(String name) {
    // Common patterns: "Series Name S01 E01", "Series Name S01E01", "Series Name 1. Sezon 1. Bölüm"
    // We want to extract just "Series Name"

    // Regex for S01E01 or S01 E01
    final sxxExxRegex = RegExp(r'\s*S\d+\s*E\d+.*', caseSensitive: false);
    if (sxxExxRegex.hasMatch(name)) {
      return name.replaceAll(sxxExxRegex, '').trim();
    }

    // Regex for "1. Sezon" or "Sezon 1"
    final seasonRegex = RegExp(r'\s*\d+\.?\s*Sezon.*', caseSensitive: false);
    if (seasonRegex.hasMatch(name)) {
      return name.replaceAll(seasonRegex, '').trim();
    }

    final seasonRegex2 = RegExp(r'\s*Sezon\s*\d+.*', caseSensitive: false);
    if (seasonRegex2.hasMatch(name)) {
      return name.replaceAll(seasonRegex2, '').trim();
    }

    // Regex for "1. Bölüm" or "Bölüm 1"
    final episodeRegex = RegExp(r'\s*\d+\.?\s*Bölüm.*', caseSensitive: false);
    if (episodeRegex.hasMatch(name)) {
      return name.replaceAll(episodeRegex, '').trim();
    }

    final episodeRegex2 = RegExp(r'\s*Bölüm\s*\d+.*', caseSensitive: false);
    if (episodeRegex2.hasMatch(name)) {
      return name.replaceAll(episodeRegex2, '').trim();
    }

    // Regex for " - E01" or " E01"
    final e01Regex = RegExp(r'\s*[-]?\s*E\d+.*', caseSensitive: false);
    if (e01Regex.hasMatch(name)) {
      return name.replaceAll(e01Regex, '').trim();
    }

    return name;
  }
}
