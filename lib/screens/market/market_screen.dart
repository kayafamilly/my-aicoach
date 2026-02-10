import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/providers/coach_provider.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> _marketCoaches = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMarketCoaches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketCoaches() async {
    try {
      final String response =
          await rootBundle.loadString('assets/market_coaches.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _marketCoaches = data.cast<Map<String, dynamic>>();
        _filtered = List.from(_marketCoaches);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading market coaches: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_marketCoaches);
      } else {
        _filtered = _marketCoaches.where((c) {
          final name = (c['name'] as String? ?? '').toLowerCase();
          final desc = (c['description'] as String? ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) ||
              desc.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _importCoach(Map<String, dynamic> coach) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final name = coach['name'] ?? '';

    // Check if already imported
    final existing = await (db.select(db.coaches)
          ..where((t) => t.name.equals(name) & t.isCustom.equals(true)))
        .getSingleOrNull();

    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name is already in your coaches.')),
        );
      }
      return;
    }

    await db.into(db.coaches).insert(
          CoachesCompanion(
            name: Value(name),
            description: Value(coach['description'] as String? ?? ''),
            systemPrompt: Value(coach['systemPrompt'] as String? ?? ''),
            isCustom: const Value(true),
            isPremium: const Value(false),
            enableWebSearch: const Value(false),
          ),
        );

    if (mounted) {
      Provider.of<CoachProvider>(context, listen: false).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name imported successfully!')),
      );
      Navigator.pop(context); // close bottom sheet
    }
  }

  void _showCoachDetail(Map<String, dynamic> coach) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.smart_toy,
                            color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(coach['name'] as String? ?? '',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'by ${coach['creator'] ?? 'Community'}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.download,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${coach['downloads'] ?? 0} imports',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(coach['description'] as String? ?? '',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _importCoach(coach),
                      icon: const Icon(Icons.add),
                      label: const Text('Import Coach'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('About Market'),
                  content: const Text(
                      'Browse coaches created by the community and import them into your collection. '
                      'More coaches are added regularly!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search community coaches...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text('No coaches found',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final coach = _filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(Icons.smart_toy,
                                      color: theme.colorScheme.primary),
                                ),
                                title: Text(
                                  coach['name'] as String? ?? '',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      coach['description'] as String? ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 14,
                                            color: theme.colorScheme.outline),
                                        const SizedBox(width: 4),
                                        Text(
                                          coach['creator'] as String? ??
                                              'Community',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: theme
                                                      .colorScheme.outline),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.download,
                                            size: 14,
                                            color: theme.colorScheme.outline),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${coach['downloads'] ?? 0}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: theme
                                                      .colorScheme.outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _showCoachDetail(coach),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
