import 'package:flutter/material.dart';

import 'modelos/imagen_perfil.dart';
import 'modelos/perfil.dart';
import 'paginas/pagina_mensajes.dart';
import 'servicio_bd.dart';
import 'tema/tema_korulab.dart';
import 'widgets/ui_koru.dart';

/// Perfil público estilo red social, visible desde Korublog para cualquier rol.
class PublicProfilePage extends StatefulWidget {
  final String username;
  final String? fallbackName;
  final ImagenPerfil? fallbackPhoto;

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
  late final Future<(PerfilPublico?, Map<String, List<Map<String, dynamic>>>)>
  _data = _load();

  Future<(PerfilPublico?, Map<String, List<Map<String, dynamic>>>)>
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
    PerfilPublico profile,
    Map<String, List<Map<String, dynamic>>> activity,
  ) {
    final username = profile.username;
    final name = profile.displayName.trim();
    final photo = profile.foto;
    final banner = profile.banner;
    final role = profile.role;
    final joined = _date(profile.createdAt?.toIso8601String());
    final posts = activity['posts'] ?? const [];
    final replies = activity['replies'] ?? const [];
    final details = <(IconData, String)>[
      if (profile.occupation.isNotEmpty)
        (Icons.school_outlined, profile.occupation),
      if (profile.location.isNotEmpty) (Icons.place_outlined, profile.location),
      if (joined.isNotEmpty)
        (Icons.calendar_month_outlined, 'Se unió el $joined'),
    ];

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const SliverAppBar(pinned: true),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 130,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(KoruRadius.xl),
                        image: banner == null
                            ? null
                            : DecorationImage(
                                image: banner.provider,
                                fit: BoxFit.cover,
                              ),
                        gradient: banner != null
                            ? null
                            : context.koru.degradadoHero,
                      ),
                    ),
                    Positioned(
                      left: 32,
                      bottom: -48,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: KoruAvatar(
                          image: photo?.provider,
                          name: name.isEmpty ? username : name,
                          radius: 48,
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
                                RoleBadge(role),
                              ],
                            ),
                            AccionesSociales(username: username),
                            if (profile.bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                profile.bio,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                            if (profile.learningGoal.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: context.koru.hoja,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      profile.learningGoal,
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
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    _Stat(
                                      value: '${profile.publicaciones}',
                                      label: 'Publicaciones',
                                      icon: Icons.forum_rounded,
                                      color: context.koru.agua,
                                    ),
                                    _Stat(
                                      value: '${profile.respuestas}',
                                      label: 'Respuestas',
                                      icon: Icons.chat_bubble_rounded,
                                      color: context.koru.tierra,
                                    ),
                                    if (role == DBService.roleStudent) ...[
                                      _Stat(
                                        value:
                                            '${profile.leccionesCompletadas}',
                                        label: 'Lecciones',
                                        icon: Icons.school_rounded,
                                        color: context.koru.hoja,
                                      ),
                                      _Stat(
                                        value: '${profile.rachaDiaria}',
                                        label: 'Racha',
                                        icon:
                                            Icons.local_fire_department_rounded,
                                        color: context.koru.fuego,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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
  final IconData icon;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            empty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (title, body, date) = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
