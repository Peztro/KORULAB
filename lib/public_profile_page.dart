import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'db_service.dart';

/// Perfil público estilo red social, visible desde Korublog para cualquier rol.
class PublicProfilePage extends StatefulWidget {
  final String username;
  final String? fallbackName;
  final Uint8List? fallbackPhoto;

  const PublicProfilePage({
    super.key,
    required this.username,
    this.fallbackName,
    this.fallbackPhoto,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late final Future<
    (Map<String, dynamic>?, Map<String, List<Map<String, dynamic>>>)
  >
  _data = _load();

  Future<(Map<String, dynamic>?, Map<String, List<Map<String, dynamic>>>)>
  _load() async {
    final profile = await DBService.getPublicProfile(widget.username);
    final activity = profile == null
        ? <String, List<Map<String, dynamic>>>{'posts': [], 'replies': []}
        : await DBService.getPublicActivity(widget.username);
    return (profile, activity);
  }

  static String _date(dynamic iso) {
    final date = DateTime.tryParse('$iso');
    if (date == null) return '';
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              icon: Icons.error_outline,
              text: 'No se pudo cargar el perfil.',
              onBack: () => Navigator.pop(context),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (profile, activity) = snapshot.data!;
          if (profile == null) {
            return _Message(
              icon: Icons.person_off_outlined,
              text: 'Este perfil no está disponible.',
              onBack: () => Navigator.pop(context),
            );
          }
          return _content(theme, profile, activity);
        },
      ),
    );
  }

  Widget _content(
    ThemeData theme,
    Map<String, dynamic> profile,
    Map<String, List<Map<String, dynamic>>> activity,
  ) {
    final username = profile['username'] as String;
    final name = (profile['display_name'] as String?)?.trim() ?? '';
    final photo = profile['profile_photo'] as Uint8List?;
    final banner = profile['banner'] as Uint8List?;
    final role = profile['role'] as String?;
    final posts = activity['posts'] ?? const [];
    final replies = activity['replies'] ?? const [];
    final details = <(IconData, String)>[
      if ((profile['occupation'] as String? ?? '').isNotEmpty)
        (Icons.school_outlined, profile['occupation'] as String),
      if ((profile['location'] as String? ?? '').isNotEmpty)
        (Icons.place_outlined, profile['location'] as String),
      if (_date(profile['created_at']).isNotEmpty)
        (
          Icons.calendar_month_outlined,
          'Se unió el ${_date(profile['created_at'])}',
        ),
    ];

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        image: banner == null
                            ? null
                            : DecorationImage(
                                image: MemoryImage(banner),
                                fit: BoxFit.cover,
                              ),
                        gradient: banner != null
                            ? null
                            : LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.tertiary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: -48,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: photo == null
                              ? null
                              : MemoryImage(photo),
                          child: photo == null
                              ? Icon(
                                  Icons.person,
                                  size: 48,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? '@$username' : name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '@$username',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(DBService.roleLabel(role)),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            if ((profile['bio'] as String? ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                profile['bio'] as String,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                            if ((profile['learning_goal'] as String? ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      profile['learning_goal'] as String,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  for (final (icon, text) in details)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 16,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            text,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _Stat(
                                  value: '${profile['posts_count'] ?? 0}',
                                  label: 'Publicaciones',
                                ),
                                _Stat(
                                  value: '${profile['replies_count'] ?? 0}',
                                  label: 'Respuestas',
                                ),
                                if (role == DBService.roleStudent) ...[
                                  _Stat(
                                    value:
                                        '${profile['completed_lessons'] ?? 0}',
                                    label: 'Unidades',
                                  ),
                                  _Stat(
                                    value: '${profile['daily_streak'] ?? 0}',
                                    label: 'Racha',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeader(
              TabBar(
                tabs: [
                  Tab(text: 'Publicaciones'),
                  Tab(text: 'Respuestas'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _ActivityList(
              empty: 'Aún no ha publicado discusiones.',
              items: [
                for (final post in posts)
                  (
                    post['title'] as String? ?? '',
                    post['description'] as String? ?? '',
                    _date(post['created_at']),
                  ),
              ],
            ),
            _ActivityList(
              empty: 'Aún no ha respondido.',
              items: [
                for (final reply in replies)
                  (
                    'En: ${reply['discussion_title'] ?? 'una discusión'}',
                    reply['message'] as String? ?? '',
                    _date(reply['created_at']),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  final TabBar bar;

  const _TabsHeader(this.bar);

  @override
  double get minExtent => bar.preferredSize.height;

  @override
  double get maxExtent => bar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(color: Theme.of(context).colorScheme.surface, child: bar);

  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) => false;
}

class _ActivityList extends StatelessWidget {
  final String empty;
  final List<(String, String, String)> items;

  const _ActivityList({required this.empty, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(empty));
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (title, body, date) = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
          child: ListTile(
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
            trailing: Text(date, style: theme.textTheme.labelSmall),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onBack;

  const _Message({
    required this.icon,
    required this.text,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackButton(onPressed: onBack),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48),
                  const SizedBox(height: 8),
                  Text(text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
