import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';

class ChannelsProvider with ChangeNotifier {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  Map<String, List<Channel>> categories = {};
  String sourceUrl =
      'https://raw.githubusercontent.com/FunctionError/PiratesTv/main/combined_playlist.m3u';

  // Display order of categories (anything else goes after these, A-Z).
  static const List<String> _order = [
    'News', 'Entertainment', 'Movies', 'Music', 'Sports', 'Kids', 'Infotainment', 'Business',
    'Devotional', 'Knowledge', 'Regional', 'Other',
  ];

  // Fallback when the playlist has no group-title. First match wins.
  static const Map<String, List<String>> _keywords = {
    'Sports': ['sport', 'cricket', 'espn', 'eurosport', 'willow', 'wwe', 'ten 1', 'ten 2', 'ten 3', 'sony ten', 'sony six'],
    'News': ['news', 'aaj tak', 'ndtv', 'abp', 'tv9', 'republic', 'cnbc', 'times now', 'wion', 'zee business', 'et now', 'mirror now', 'india today', 'lok sabha', 'rajya sabha', 'sansad'],
    'Kids': ['kids', 'cartoon', 'nick', 'pogo', 'disney', 'hungama', 'sonic', 'toon', 'chutti', 'baby', 'duronto'],
    'Music': ['music', 'mtv', '9xm', 'b4u', 'zing', 'mastiii', 'vh1', 'tadka', 'songs', 'radio', 'mh1'],
    'Devotional': ['bhakti', 'aastha', 'sanskar', 'devotional', 'darshan', 'ishwar', 'gurbani', 'sikh', 'katha', 'quran', 'islam', 'church', 'jinvani', 'satsang', 'sadhna', 'shubh', 'divya'],
    'Knowledge': ['discovery', 'nat geo', 'national geographic', 'history', 'tlc', 'animal', 'knowledge', 'science', 'travelxp', 'fyi', 'epic', 'food', 'dd kisan'],
    'Movies': ['movie', 'cinema', 'film', 'max', 'pix', 'gold', 'flix', 'bollywood', 'cine', 'hbo', 'studio', 'pictures', 'utv', 'action'],
    'Regional': ['tamil', 'telugu', 'malayalam', 'kannada', 'bangla', 'bengali', 'marathi', 'gujarati', 'punjabi', 'bhojpuri', 'odia', 'oriya', 'assam', 'urdu', 'sun ', 'vijay', 'asianet', 'maa ', 'gemini', 'udaya', 'mazhavil', 'surya', 'etv', 'jalsha', 'zee 24', 'ptc', 'chardikla'],
    'Entertainment': ['zee', 'star', 'colors', 'sony', 'sab', '&tv', 'and tv', 'dangal', 'big magic', 'dd national', 'dd india', 'life ok', 'sahara'],
  };

  Future<List<Channel>> fetchM3UFile() async {
    final response = await http.get(Uri.parse(sourceUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load M3U file');
    }
    channels = [];

    String? name;
    String logoUrl = getDefaultLogoUrl();
    String? group;

    for (final raw in response.body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final attrs = _attrs(line);
        name = extractChannelName(line);
        logoUrl = _validUrl(attrs['tvg-logo']) ??
            extractLogoUrl(line) ??
            getDefaultLogoUrl();
        group = attrs['group-title'];
      } else if (!line.startsWith('#')) {
        if (name != null && name.isNotEmpty) {
          channels.add(Channel(
            name: name,
            logoUrl: logoUrl,
            streamUrl: line,
            category: _categorize(name, group),
          ));
        }
        name = null;
        logoUrl = getDefaultLogoUrl();
        group = null;
      }
    }
    _buildCategories();
    return channels;
  }

  Map<String, String> _attrs(String line) {
    final m = <String, String>{};
    for (final x in RegExp(r'([\w-]+)="([^"]*)"').allMatches(line)) {
      m[x.group(1)!.toLowerCase()] = x.group(2)!.trim();
    }
    return m;
  }

  String? _validUrl(String? u) => (u != null && isValidUrl(u)) ? u : null;

  String _categorize(String name, String? group) {
    if (group != null && group.trim().isNotEmpty) {
      final g = group.split(';').first.trim();
      if (g.isNotEmpty && g.toLowerCase() != 'undefined') return _title(g);
    }
    final n = name.toLowerCase();
    for (final e in _keywords.entries) {
      if (e.value.any((k) => n.contains(k))) return e.key;
    }
    return 'Other';
  }

  String _title(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  void _buildCategories() {
    final map = <String, List<Channel>>{};
    for (final c in channels) {
      map.putIfAbsent(c.category, () => []).add(c);
    }
    int rank(String k) {
      final i = _order.indexOf(k);
      return i < 0 ? 999 : i;
    }

    final keys = map.keys.toList()
      ..sort((a, b) => rank(a) != rank(b)
          ? rank(a).compareTo(rank(b))
          : a.compareTo(b));
    categories = {for (final k in keys) k: map[k]!};
  }

  String getDefaultLogoUrl() {
    return 'assets/images/tv-icon.png';
  }

  String? extractChannelName(String line) {
    return line.split(',').last.trim();
  }

  String? extractLogoUrl(String line) {
    List<String> parts = line.split('"');
    if (parts.length > 1 && isValidUrl(parts[1])) {
      return parts[1];
    } else if (parts.length > 5 && isValidUrl(parts[5])) {
      return parts[5];
    }
    return null;
  }

  bool isValidUrl(String url) {
    return url.startsWith('https') || url.startsWith('http');
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }
}
