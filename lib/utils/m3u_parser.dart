import '../models/channel.dart';

class M3uParser {
  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');
    
    String? currentName;
    String? currentLogo;
    String? currentGroup;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Parse metadata
        // Example: #EXTINF:-1 tvg-logo="http://..." group-title="News",Channel Name
        
        // Extract logo
        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        currentLogo = logoMatch?.group(1);

        // Extract group
        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        currentGroup = groupMatch?.group(1);

        // Extract name (everything after the last comma)
        final nameIndex = line.lastIndexOf(',');
        if (nameIndex != -1) {
          currentName = line.substring(nameIndex + 1).trim();
        } else {
          currentName = "Unknown Channel";
        }
      } else if (!line.startsWith('#')) {
        // It's a URL
        if (currentName != null) {
          channels.add(Channel(
            name: currentName,
            url: line,
            logoUrl: currentLogo,
            group: currentGroup,
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
}
