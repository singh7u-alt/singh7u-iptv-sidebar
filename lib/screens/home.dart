import 'dart:async';

import 'package:flutter/material.dart';
import '../model/channel.dart';
import '../provider/channels_provider.dart';
import 'player.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ChannelsProvider provider = ChannelsProvider();
  final TextEditingController search = TextEditingController();
  bool _loading = true;
  bool _error = false;
  String _selected = 'All';
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await provider.fetchM3UFile();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void _select(String n) {
    if (n == _selected && _query.isEmpty) return;
    search.clear();
    setState(() {
      _selected = n;
      _query = '';
    });
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  List<Channel> get _visible {
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      return provider.channels
          .where((c) => c.name.toLowerCase().contains(q))
          .toList();
    }
    if (_selected == 'All') return provider.channels;
    return provider.categories[_selected] ?? const <Channel>[];
  }

  IconData _icon(String c) {
    switch (c) {
      case 'All': return Icons.apps;
      case 'News': return Icons.article;
      case 'Entertainment': return Icons.live_tv;
      case 'Movies': return Icons.movie;
      case 'Sports': return Icons.sports_cricket;
      case 'Music': return Icons.music_note;
      case 'Kids': return Icons.child_care;
      case 'Infotainment': return Icons.info;
      case 'Business': return Icons.business_center;
      case 'Devotional': return Icons.self_improvement;
      case 'Knowledge': return Icons.school;
      case 'Regional': return Icons.language;
      default: return Icons.tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load channels',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            ElevatedButton(
                autofocus: true, onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final wide = MediaQuery.of(context).size.width >= 700;
    final names = ['All', ...provider.categories.keys];
    final list = _visible;
    final title = _query.isNotEmpty ? 'Search results' : _selected;

    return Row(
      children: [
        SizedBox(width: wide ? 220 : 130, child: _sidebar(names)),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: search,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search channels...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text('${list.length} channels',
                        style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
              Expanded(child: _grid(list)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebar(List<String> names) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      itemCount: names.length,
      itemBuilder: (context, i) {
        final n = names[i];
        final count = n == 'All'
            ? provider.channels.length
            : provider.categories[n]!.length;
        final sel = n == _selected && _query.isEmpty;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            autofocus: i == 0,
            borderRadius: BorderRadius.circular(10),
            focusColor: Colors.white24,
            onFocusChange: (f) {
              if (f) _select(n);
            },
            onTap: () => _select(n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? Colors.white12 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(_icon(n), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(n,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal)),
                  ),
                  Text('$count',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _grid(List<Channel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No channels found'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => _ChannelCard(channel: list[i]),
    );
  }
}

class _ChannelCard extends StatefulWidget {
  final Channel channel;
  const _ChannelCard({Key? key, required this.channel}) : super(key: key);

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.channel;
    return AnimatedScale(
      scale: _focused ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onFocusChange: (f) => setState(() => _focused = f),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Player(channel: c)),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    c.logoUrl,
                    fit: BoxFit.contain,
                    cacheWidth: 200,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset('assets/images/tv-icon.png',
                            fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
