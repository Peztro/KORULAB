import 'package:flutter/material.dart';

import 'modelos/imagen_perfil.dart';
import 'modelos/perfil.dart';
import 'paginas/pagina_mensajes.dart';
import 'servicio_bd.dart';
import 'tema/tema_korulab.dart';
import 'widgets/boton_inicio.dart';
import 'widgets/ui_koru.dart';

/// Perfil público de una persona (desde Korublog, el chat, etc.).
///
/// Entre estudiantes el progreso de aprendizaje (lecciones, racha y
/// respuestas en Korublog) es privado: el servidor no lo entrega y aquí se
/// muestra un candado. La propia persona, los profes y los admins sí lo ven.
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

typedef _Actividad = Map<String, List<Map<String, dynamic>>>;

class _PublicProfilePageState extends State<PublicProfilePage> {
  late final Future<(PerfilPublico?, _Actividad)> _data = _load();

  /// 0 = publicaciones, 1 = respuestas.
  int _pestana = 0;

  Future<(PerfilPublico?, _Actividad)> _load() async {
    final profile = await DBService.getPublicProfile(widget.username);
    final activity = profile == null
        ? <String, List<Map<String, dynamic>>>{'posts': [], 'replies': []}
        : await DBService.getPublicActivity(widget.username);
    return (profile, activity);
  }

  static String fecha(dynamic iso) {
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
    return Scaffold(
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Mensaje(
              icono: Icons.error_outline,
              texto: 'No se pudo cargar el perfil.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (profile, activity) = snapshot.data!;
          if (profile == null) {
            return const _Mensaje(
              icono: Icons.person_off_outlined,
              texto: 'Este perfil no está disponible.',
            );
          }
          return _contenido(context, profile, activity);
        },
      ),
    );
  }

  Widget _contenido(
    BuildContext context,
    PerfilPublico perfil,
    _Actividad actividad,
  ) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final username = perfil.username;
    final nombre = perfil.displayName.trim();
    final visible = nombre.isEmpty ? '@$username' : nombre;
    final esEstudiante = perfil.role == DBService.roleStudent;
    final verProgreso = perfil.progresoVisible;
    final unido = fecha(perfil.createdAt?.toIso8601String());
    final publicaciones = actividad['posts'] ?? const [];
    final respuestas = actividad['replies'] ?? const [];
    final pestana = verProgreso ? _pestana : 0;

    final datos = <(IconData, String, Color)>[
      if (perfil.occupation.isNotEmpty)
        (Icons.school_rounded, perfil.occupation, koru.agua),
      if (perfil.location.isNotEmpty)
        (Icons.place_rounded, perfil.location, koru.fuego),
      if (unido.isNotEmpty)
        (Icons.cake_rounded, 'En Korulab desde el $unido', koru.oro),
    ];

    final cifras = <_Cifra>[
      _Cifra(
        perfil.publicaciones,
        'Publicaciones',
        Icons.forum_rounded,
        koru.agua,
      ),
      if (verProgreso) ...[
        _Cifra(
          perfil.respuestas,
          'Respuestas',
          Icons.chat_bubble_rounded,
          koru.tierra,
        ),
        if (esEstudiante) ...[
          _Cifra(
            perfil.leccionesCompletadas,
            'Lecciones',
            Icons.school_rounded,
            koru.hoja,
          ),
          _Cifra(
            perfil.rachaDiaria,
            'Días de racha',
            Icons.local_fire_department_rounded,
            koru.fuego,
          ),
        ],
      ],
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          actions: const [BotonInicio()],
          flexibleSpace: FlexibleSpaceBar(
            // Portada arriba y la foto montada sobre su borde inferior.
            background: Stack(
              children: [
                Positioned.fill(
                  bottom: 66,
                  child: _Portada(banner: perfil.banner),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  child: Center(
                    child: _FotoGrande(
                      username: username,
                      nombre: visible,
                      foto: perfil.foto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Aparece(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Text(
                    visible,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        '@$username',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      RoleBadge(perfil.role),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AccionesSociales(username: username),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.list(
            children: [
              if (datos.isNotEmpty)
                _Aparece(
                  orden: 1,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (icono, texto, color) in datos)
                        _Pastilla(icono: icono, texto: texto, color: color),
                    ],
                  ),
                ),
              if (perfil.bio.isNotEmpty || perfil.learningGoal.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Aparece(
                  orden: 2,
                  child: _SobreMi(bio: perfil.bio, meta: perfil.learningGoal),
                ),
              ],
              const SizedBox(height: 16),
              _Aparece(
                orden: 3,
                child: Row(
                  children: [
                    for (final (i, c) in cifras.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _TarjetaCifra(cifra: c)),
                    ],
                  ],
                ),
              ),
              if (!verProgreso && esEstudiante) ...[
                const SizedBox(height: 10),
                _Aparece(
                  orden: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Su progreso de aprendizaje es privado.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    'En Korublog',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (verProgreso)
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text(
                            'Publicaciones (${publicaciones.length})',
                          ),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Respuestas (${respuestas.length})'),
                        ),
                      ],
                      selected: {pestana},
                      onSelectionChanged: (s) =>
                          setState(() => _pestana = s.first),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: pestana == 0
                    ? _ListaActividad(
                        key: const ValueKey('publicaciones'),
                        vacio: '$visible aún no ha publicado en Korublog.',
                        icono: Icons.forum_rounded,
                        color: koru.agua,
                        elementos: [
                          for (final p in publicaciones)
                            (
                              p['title'] as String? ?? '',
                              p['description'] as String? ?? '',
                              fecha(p['created_at']),
                            ),
                        ],
                      )
                    : _ListaActividad(
                        key: const ValueKey('respuestas'),
                        vacio: '$visible aún no ha respondido en Korublog.',
                        icono: Icons.chat_bubble_rounded,
                        color: koru.tierra,
                        elementos: [
                          for (final r in respuestas)
                            (
                              'En: ${r['discussion_title'] ?? 'una discusión'}',
                              r['message'] as String? ?? '',
                              fecha(r['created_at']),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Portada: el banner de la persona o el degradado de Korulab con hojas.
class _Portada extends StatelessWidget {
  const _Portada({required this.banner});
  final ImagenPerfil? banner;

  @override
  Widget build(BuildContext context) {
    final koru = context.koru;
    if (banner != null) {
      return Image(image: banner!.provider, fit: BoxFit.cover);
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: koru.degradadoHero),
      child: Stack(
        children: [
          for (final (x, y, tam, giro) in const [
            (0.08, 0.25, 46.0, -0.4),
            (0.78, 0.15, 60.0, 0.5),
            (0.55, 0.55, 34.0, 0.2),
            (0.25, 0.7, 28.0, -0.8),
            (0.9, 0.7, 38.0, 0.9),
          ])
            Align(
              alignment: Alignment(x * 2 - 1, y * 2 - 1),
              child: Transform.rotate(
                angle: giro,
                child: Icon(
                  Icons.eco_rounded,
                  size: tam,
                  color: koru.textoHero.withValues(alpha: 0.14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Foto grande con aro de color. Al tocarla se ve en pantalla completa.
class _FotoGrande extends StatelessWidget {
  const _FotoGrande({
    required this.username,
    required this.nombre,
    required this.foto,
  });

  final String username;
  final String nombre;
  final ImagenPerfil? foto;

  @override
  Widget build(BuildContext context) {
    final koru = context.koru;
    final theme = Theme.of(context);
    final avatar = Hero(
      tag: 'foto-perfil-$username',
      child: KoruAvatar(
        image: foto?.provider,
        name: nombre.replaceFirst('@', ''),
        radius: 52,
      ),
    );
    return GestureDetector(
      onTap: foto == null
          ? null
          : () => Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black87,
                pageBuilder: (_, _, _) =>
                    _FotoCompleta(username: username, foto: foto!),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [koru.hoja, koru.agua, koru.oro]),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
          ),
          child: avatar,
        ),
      ),
    );
  }
}

class _FotoCompleta extends StatelessWidget {
  const _FotoCompleta({required this.username, required this.foto});
  final String username;
  final ImagenPerfil foto;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Hero(
                    tag: 'foto-perfil-$username',
                    child: Image(image: foto.provider, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Biografía y meta de aprendizaje.
class _SobreMi extends StatelessWidget {
  const _SobreMi({required this.bio, required this.meta});
  final String bio;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KoruRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty) ...[
            Text(
              'Sobre mí',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(bio, style: theme.textTheme.bodyLarge),
          ],
          if (bio.isNotEmpty && meta.isNotEmpty) const SizedBox(height: 14),
          if (meta.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: koru.hoja.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(KoruRadius.m),
                border: Border(left: BorderSide(color: koru.hoja, width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_rounded, color: koru.hoja, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi meta',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: koru.hoja,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(meta, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cifra {
  const _Cifra(this.valor, this.etiqueta, this.icono, this.color);
  final int valor;
  final String etiqueta;
  final IconData icono;
  final Color color;
}

/// Tarjeta de una cifra: el número sube contando al aparecer.
class _TarjetaCifra extends StatelessWidget {
  const _TarjetaCifra({required this.cifra});
  final _Cifra cifra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: cifra.color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(KoruRadius.m),
      ),
      child: Column(
        children: [
          Icon(cifra.icono, color: cifra.color, size: 22),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: cifra.valor.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            cifra.etiqueta,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Publicaciones o respuestas. Cada tarjeta se despliega al tocarla.
class _ListaActividad extends StatelessWidget {
  const _ListaActividad({
    super.key,
    required this.vacio,
    required this.icono,
    required this.color,
    required this.elementos,
  });

  final String vacio;
  final IconData icono;
  final Color color;
  final List<(String, String, String)> elementos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (elementos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icono, size: 40, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              vacio,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final (i, (titulo, cuerpo, fecha)) in elementos.indexed)
          _Aparece(
            orden: i.clamp(0, 6),
            child: _TarjetaActividad(
              titulo: titulo,
              cuerpo: cuerpo,
              fecha: fecha,
              icono: icono,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _TarjetaActividad extends StatefulWidget {
  const _TarjetaActividad({
    required this.titulo,
    required this.cuerpo,
    required this.fecha,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String cuerpo;
  final String fecha;
  final IconData icono;
  final Color color;

  @override
  State<_TarjetaActividad> createState() => _TarjetaActividadState();
}

class _TarjetaActividadState extends State<_TarjetaActividad> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KoruRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(KoruRadius.m),
          onTap: () => setState(() => _abierta = !_abierta),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: widget.icono, color: widget.color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo,
                          maxLines: _abierta ? null : 1,
                          overflow: _abierta ? null : TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.cuerpo,
                          maxLines: _abierta ? null : 2,
                          overflow: _abierta ? null : TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.fecha,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _abierta ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada suave: aparece y sube un poco, una parte tras otra.
class _Aparece extends StatelessWidget {
  const _Aparece({required this.child, this.orden = 0});

  final Widget child;
  final int orden;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + orden * 90),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: child,
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackButton(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icono, size: 48),
                  const SizedBox(height: 8),
                  Text(texto),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
