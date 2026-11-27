import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/chat.dart';
import '../paginas_soporte.dart' show MessagesPage;
import '../servicio_notificaciones.dart';
import '../servicios/servicio_chat.dart';
import '../tema/tema_korulab.dart';
import '../widgets/selector_emojis.dart';
import '../widgets/ui_koru.dart';

String _hora(DateTime fecha) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  final hh = fecha.hour.toString().padLeft(2, '0');
  final mm = fecha.minute.toString().padLeft(2, '0');
  if (dia == hoy) return '$hh:$mm';
  if (hoy.difference(dia).inDays == 1) return 'Ayer';
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}';
}

void _aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

String _error(Object e) => switch (e) {
  PostgrestException(:final message) => message,
  StateError(:final message) => message,
  _ => 'Algo salió mal. Inténtalo de nuevo.',
};

// ─────────────────────────────────────────────────────────────────────────
//  Mensajes: chats, amigos y avisos
// ─────────────────────────────────────────────────────────────────────────

class MensajesPage extends StatefulWidget {
  const MensajesPage({super.key, required this.username, this.pestana = 0});

  final String username;

  /// 0 = Chats, 1 = Amigos, 2 = Avisos.
  final int pestana;

  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.pestana,
  )..addListener(() => setState(() {}));

  List<Conversacion> _chats = [];
  List<Amistad> _amistades = [];
  bool _cargando = true;
  String? _errorCarga;
  RealtimeChannel? _canal;

  @override
  void initState() {
    super.initState();
    _cargar();
    _canal = ServicioChat.escuchar('mensajes-${widget.username}', (_) {
      if (mounted) _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    final canal = _canal;
    if (canal != null) unawaited(ServicioChat.dejarDeEscuchar(canal));
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _errorCarga = null;
      });
    }
    try {
      final resultados = await Future.wait([
        ServicioChat.misConversaciones(),
        ServicioChat.misAmistades(),
      ]);
      if (!mounted) return;
      setState(() {
        _chats = resultados[0] as List<Conversacion>;
        _amistades = resultados[1] as List<Amistad>;
        _cargando = false;
        _errorCarga = null;
      });
    } catch (e) {
      debugPrint('No se pudieron cargar los mensajes: $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga =
            'No se pudieron cargar tus chats. Revisa tu conexión e '
            'inténtalo de nuevo.';
      });
    }
  }

  Future<void> _abrirChat(Contacto contacto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(contacto: contacto)),
    );
    if (mounted) _cargar(silencioso: true);
  }

  Future<void> _nuevo() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconTile(
                  icon: Icons.person_add_alt_1_rounded,
                  color: sheetContext.koru.hoja,
                  size: 44,
                ),
                title: const Text('Añadir un amigo'),
                subtitle: const Text('Búscalo por su @usuario o nombre'),
                onTap: () => Navigator.pop(sheetContext, 'amigo'),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: IconTile(
                  icon: Icons.school_rounded,
                  color: sheetContext.koru.agua,
                  size: 44,
                ),
                title: const Text('Escribir a un profesor'),
                subtitle: const Text('Pregunta tus dudas sobre las lecciones'),
                onTap: () => Navigator.pop(sheetContext, 'profesor'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || opcion == null) return;
    if (opcion == 'amigo') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnadirAmigoPage()),
      );
      if (mounted) _cargar(silencioso: true);
    } else {
      final profesor = await Navigator.push<Contacto>(
        context,
        MaterialPageRoute(builder: (_) => const ProfesoresPage()),
      );
      if (profesor != null && mounted) await _abrirChat(profesor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noLeidos = _chats.fold<int>(0, (t, c) => t + c.noLeidos);
    final solicitudes = _amistades
        .where((a) => !a.aceptada && a.entrante)
        .length;

    Tab pestana(String texto, int contador) => Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto),
          if (contador > 0) ...[
            const SizedBox(width: 6),
            Badge(label: Text('$contador')),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            pestana('Chats', noLeidos),
            pestana('Amigos', solicitudes),
            const Tab(text: 'Avisos'),
          ],
        ),
      ),
      floatingActionButton: _tabs.index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _nuevo,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Nuevo'),
            ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _contenido(
            () => _ChatsTab(
              chats: _chats,
              onAbrir: _abrirChat,
              onRefrescar: _cargar,
              onNuevo: _nuevo,
            ),
          ),
          _contenido(
            () => _AmigosTab(
              amistades: _amistades,
              onAbrirChat: _abrirChat,
              onCambio: () => _cargar(silencioso: true),
            ),
          ),
          MessagesPage(username: widget.username, embedded: true),
        ],
      ),
    );
  }

  Widget _contenido(Widget Function() construir) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_errorCarga != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorCarga!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    return construir();
  }
}

/// Mensaje centrado cuando una lista está vacía.
class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Center(
          child: IconTile(icon: icono, color: context.koru.hoja, size: 72),
        ),
        const SizedBox(height: 16),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (accion != null) ...[
          const SizedBox(height: 20),
          Center(child: accion),
        ],
      ],
    );
  }
}

// ── Pestaña Chats ───────────────────────────────────────────────────────

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({
    required this.chats,
    required this.onAbrir,
    required this.onRefrescar,
    required this.onNuevo,
  });

  final List<Conversacion> chats;
  final void Function(Contacto) onAbrir;
  final Future<void> Function() onRefrescar;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return RefreshIndicator(
      onRefresh: onRefrescar,
      child: chats.isEmpty
          ? _Vacio(
              icono: Icons.chat_bubble_rounded,
              titulo: 'Aún no tienes chats',
              texto:
                  'Escríbele a un amigo o a un profesor. Tus conversaciones '
                  'aparecerán aquí.',
              accion: FilledButton.icon(
                onPressed: onNuevo,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Empezar un chat'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: chats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, i) {
                final chat = chats[i];
                final sinLeer = chat.noLeidos > 0;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: KoruAvatar(
                    image: chat.contacto.foto?.provider,
                    name: chat.contacto.nombreVisible.replaceFirst('@', ''),
                    radius: 24,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          chat.contacto.nombreVisible,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: sinLeer
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (chat.contacto.esProfesor) ...[
                        const SizedBox(width: 6),
                        RoleBadge(chat.contacto.role),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${chat.ultimoEsMio ? 'Tú: ' : ''}${chat.ultimoMensaje}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: sinLeer
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: sinLeer ? FontWeight.w700 : null,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _hora(chat.ultimaFecha),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: sinLeer
                              ? koru.hoja
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: sinLeer ? FontWeight.w800 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sinLeer)
                        Badge(
                          label: Text('${chat.noLeidos}'),
                          backgroundColor: koru.hoja,
                          textColor: theme.colorScheme.onPrimary,
                        )
                      else
                        const SizedBox(height: 16),
                    ],
                  ),
                  onTap: () => onAbrir(chat.contacto),
                );
              },
            ),
    );
  }
}

// ── Pestaña Amigos ──────────────────────────────────────────────────────

class _AmigosTab extends StatelessWidget {
  const _AmigosTab({
    required this.amistades,
    required this.onAbrirChat,
    required this.onCambio,
  });

  final List<Amistad> amistades;
  final void Function(Contacto) onAbrirChat;
  final VoidCallback onCambio;

  Future<void> _ejecutar(
    BuildContext context,
    Future<void> Function() accion,
    String exito,
  ) async {
    try {
      await accion();
      if (context.mounted) _aviso(context, exito);
    } catch (e) {
      if (context.mounted) _aviso(context, _error(e));
    }
    onCambio();
  }

  Future<void> _eliminar(BuildContext context, Amistad amistad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar a ${amistad.contacto.nombreVisible}?'),
        content: const Text(
          'Dejarán de ser amigos y no podrán escribirse, salvo que uno de '
          'los dos sea profesor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    await _ejecutar(
      context,
      () => ServicioChat.eliminarAmistad(amistad.id),
      'Amistad eliminada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibidas = amistades
        .where((a) => !a.aceptada && a.entrante)
        .toList();
    final enviadas = amistades
        .where((a) => !a.aceptada && !a.entrante)
        .toList();
    final amigos = amistades.where((a) => a.aceptada).toList();

    return RefreshIndicator(
      onRefresh: () async => onCambio(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          FilledButton.tonalIcon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnadirAmigoPage()),
              );
              onCambio();
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Añadir amigo'),
          ),
          if (recibidas.isNotEmpty) ...[
            const SizedBox(height: 8),
            SectionTitle('Solicitudes recibidas (${recibidas.length})'),
            for (final a in recibidas)
              _FilaContacto(
                contacto: a.contacto,
                detalle: 'Quiere ser tu amigo',
                acciones: [
                  IconButton.filledTonal(
                    tooltip: 'Rechazar',
                    onPressed: () => _ejecutar(
                      context,
                      () =>
                          ServicioChat.responderSolicitud(a.id, aceptar: false),
                      'Solicitud rechazada.',
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Aceptar',
                    onPressed: () => _ejecutar(
                      context,
                      () =>
                          ServicioChat.responderSolicitud(a.id, aceptar: true),
                      '¡Ahora son amigos!',
                    ),
                    icon: const Icon(Icons.check_rounded),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 8),
          SectionTitle('Tus amigos (${amigos.length})'),
          if (amigos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Todavía no tienes amigos en Korulab. ¡Busca a tus compañeros!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final a in amigos)
            _FilaContacto(
              contacto: a.contacto,
              detalle: a.automatica && a.contacto.esProfesor
                  ? '@${a.contacto.username} · siempre en tus amigos'
                  : null,
              onTap: () => onAbrirChat(a.contacto),
              acciones: [
                IconButton.filledTonal(
                  tooltip: 'Enviar mensaje',
                  onPressed: () => onAbrirChat(a.contacto),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                ),
                if (!a.automatica)
                  PopupMenuButton<String>(
                    tooltip: 'Más opciones',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (_) => _eliminar(context, a),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar amigo'),
                      ),
                    ],
                  ),
              ],
            ),
          if (enviadas.isNotEmpty) ...[
            const SizedBox(height: 8),
            SectionTitle('Solicitudes enviadas (${enviadas.length})'),
            for (final a in enviadas)
              _FilaContacto(
                contacto: a.contacto,
                detalle: 'Esperando respuesta',
                acciones: [
                  TextButton(
                    onPressed: () => _ejecutar(
                      context,
                      () => ServicioChat.eliminarAmistad(a.id),
                      'Solicitud cancelada.',
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _FilaContacto extends StatelessWidget {
  const _FilaContacto({
    required this.contacto,
    this.detalle,
    this.acciones = const [],
    this.onTap,
  });

  final Contacto contacto;
  final String? detalle;
  final List<Widget> acciones;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                KoruAvatar(
                  image: contacto.foto?.provider,
                  name: contacto.nombreVisible.replaceFirst('@', ''),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              contacto.nombreVisible,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (contacto.esProfesor) ...[
                            const SizedBox(width: 6),
                            RoleBadge(contacto.role),
                          ],
                        ],
                      ),
                      Text(
                        detalle ?? '@${contacto.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ...acciones,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Añadir amigo
// ─────────────────────────────────────────────────────────────────────────

class AnadirAmigoPage extends StatefulWidget {
  const AnadirAmigoPage({super.key});

  @override
  State<AnadirAmigoPage> createState() => _AnadirAmigoPageState();
}

class _AnadirAmigoPageState extends State<AnadirAmigoPage> {
  final _busqueda = TextEditingController();
  Timer? _espera;
  List<Contacto> _resultados = [];
  List<Amistad> _amistades = [];
  bool _buscando = false;
  final Set<String> _enviando = {};

  @override
  void initState() {
    super.initState();
    _cargarAmistades();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargarAmistades() async {
    try {
      final amistades = await ServicioChat.misAmistades();
      if (mounted) setState(() => _amistades = amistades);
    } catch (e) {
      debugPrint('No se pudieron cargar las amistades: $e');
    }
  }

  void _alEscribir(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    setState(() => _buscando = true);
    try {
      final resultados = await ServicioChat.buscar(texto);
      if (!mounted || texto != _busqueda.text) return;
      setState(() => _resultados = resultados);
    } catch (e) {
      if (mounted) _aviso(context, _error(e));
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _agregar(Contacto contacto) async {
    setState(() => _enviando.add(contacto.id));
    try {
      final mensaje = await ServicioChat.enviarSolicitud(contacto.username);
      await _cargarAmistades();
      if (mounted) _aviso(context, mensaje);
    } catch (e) {
      if (mounted) _aviso(context, _error(e));
    } finally {
      if (mounted) setState(() => _enviando.remove(contacto.id));
    }
  }

  Widget _boton(Contacto contacto) {
    if (_enviando.contains(contacto.id)) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return switch (ServicioChat.relacionCon(contacto.id, _amistades)) {
      RelacionAmistad.amigos => const Chip(
        avatar: Icon(Icons.check_rounded, size: 16),
        label: Text('Amigos'),
      ),
      RelacionAmistad.enviada => const Chip(label: Text('Pendiente')),
      RelacionAmistad.recibida => FilledButton(
        onPressed: () => _agregar(contacto),
        child: const Text('Aceptar'),
      ),
      RelacionAmistad.ninguna => FilledButton.icon(
        onPressed: () => _agregar(contacto),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text('Agregar'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texto = _busqueda.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir amigo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _busqueda,
              autofocus: true,
              onChanged: _alEscribir,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busca por @usuario o nombre',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _buscando
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: texto.length < 2
                ? _Vacio(
                    icono: Icons.travel_explore_rounded,
                    titulo: 'Encuentra a tus compañeros',
                    texto: 'Escribe al menos 2 letras de su @usuario o nombre.',
                  )
                : _resultados.isEmpty && !_buscando
                ? _Vacio(
                    icono: Icons.person_search_rounded,
                    titulo: 'Sin resultados',
                    texto: 'No encontramos a nadie con "$texto".',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final c in _resultados)
                        _FilaContacto(contacto: c, acciones: [_boton(c)]),
                      if (_resultados.length >= 30)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Mostrando los primeros 30. Escribe más para '
                            'afinar la búsqueda.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
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

// ─────────────────────────────────────────────────────────────────────────
//  Profesores
// ─────────────────────────────────────────────────────────────────────────

/// Lista de profesores; al elegir uno devuelve su [Contacto].
class ProfesoresPage extends StatelessWidget {
  const ProfesoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escribir a un profesor')),
      body: FutureBuilder<List<Contacto>>(
        future: ServicioChat.profesores(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Vacio(
              icono: Icons.cloud_off_rounded,
              titulo: 'No se pudo cargar',
              texto: _error(snapshot.error!),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profesores = snapshot.data!;
          if (profesores.isEmpty) {
            return const _Vacio(
              icono: Icons.school_rounded,
              titulo: 'Todavía no hay profesores',
              texto: 'Cuando haya profesores en Korulab aparecerán aquí.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final p in profesores)
                _FilaContacto(
                  contacto: p,
                  onTap: () => Navigator.pop(context, p),
                  acciones: [
                    IconButton.filledTonal(
                      tooltip: 'Escribir',
                      onPressed: () => Navigator.pop(context, p),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Conversación
// ─────────────────────────────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.contacto});

  final Contacto contacto;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _texto = TextEditingController();
  final _scroll = ScrollController();
  List<MensajeDirecto> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;
  bool? _puedeEscribir;
  bool _mostrarEmojis = false;
  final _foco = FocusNode();
  final _selectorImagenes = ImagePicker();
  RealtimeChannel? _canal;

  String get _otro => widget.contacto.id;

  @override
  void initState() {
    super.initState();
    _cargar();
    _canal = ServicioChat.escuchar('chat-$_otro', _alLlegar);
    NotificationService.chatAbiertoCon = _otro;
  }

  @override
  void dispose() {
    if (NotificationService.chatAbiertoCon == _otro) {
      NotificationService.chatAbiertoCon = null;
    }
    final canal = _canal;
    if (canal != null) unawaited(ServicioChat.dejarDeEscuchar(canal));
    _texto.dispose();
    _scroll.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final resultados = await Future.wait([
        ServicioChat.mensajesCon(_otro),
        ServicioChat.puedeEscribirA(_otro),
      ]);
      if (!mounted) return;
      setState(() {
        _mensajes = resultados[0] as List<MensajeDirecto>;
        _puedeEscribir = resultados[1] as bool;
        _cargando = false;
      });
      unawaited(ServicioChat.marcarLeidos(_otro));
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _aviso(context, _error(e));
    }
  }

  void _alLlegar(MensajeDirecto? mensaje) {
    final yo = ServicioChat.miId;
    if (!mounted || yo == null) return;
    if (mensaje == null) {
      // Cambió alguna amistad: puede que ahora se pueda (o no) escribir.
      ServicioChat.puedeEscribirA(_otro).then((puede) {
        if (mounted) setState(() => _puedeEscribir = puede);
      });
      return;
    }
    if (!mensaje.esEntre(yo, _otro)) return;
    if (_mensajes.any((m) => m.id == mensaje.id)) return;
    setState(() => _mensajes = [..._mensajes, mensaje]);
    if (mensaje.remitenteId == _otro) {
      unawaited(ServicioChat.marcarLeidos(_otro));
    }
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await ServicioChat.enviarMensaje(_otro, texto);
      if (!mounted) return;
      _texto.clear();
      setState(() {
        if (!_mensajes.any((m) => m.id == mensaje.id)) {
          _mensajes = [..._mensajes, mensaje];
        }
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // La base de datos rechaza el mensaje si ya no pueden escribirse.
      if (e.code == '42501') {
        setState(() => _puedeEscribir = false);
        _aviso(context, 'Solo puedes escribir a tus amigos y a profesores.');
      } else {
        _aviso(context, _error(e));
      }
    } catch (e) {
      if (mounted) _aviso(context, _error(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _alternarEmojis() {
    if (_mostrarEmojis) {
      setState(() => _mostrarEmojis = false);
      _foco.requestFocus();
    } else {
      _foco.unfocus();
      setState(() => _mostrarEmojis = true);
    }
  }

  Future<void> _adjuntarImagen() async {
    try {
      final imagen = await _selectorImagenes.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (imagen == null || !mounted) return;
      final bytes = await imagen.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        _aviso(context, 'La imagen es muy grande (máximo 5 MB).');
        return;
      }
      final texto = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (_) =>
            _VistaPreviaImagen(bytes: bytes, textoInicial: _texto.text),
      );
      if (texto == null || !mounted) return;
      setState(() => _enviando = true);
      final mensaje = await ServicioChat.enviarImagen(
        _otro,
        bytes,
        texto: texto,
      );
      if (!mounted) return;
      _texto.clear();
      setState(() {
        if (!_mensajes.any((m) => m.id == mensaje.id)) {
          _mensajes = [..._mensajes, mensaje];
        }
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.code == '42501') {
        setState(() => _puedeEscribir = false);
        _aviso(context, 'Solo puedes escribir a tus amigos y a profesores.');
      } else {
        _aviso(context, _error(e));
      }
    } on StorageException catch (e) {
      if (mounted) _aviso(context, 'No se pudo subir la imagen: ${e.message}');
    } catch (e) {
      if (mounted) _aviso(context, _error(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contacto = widget.contacto;
    final yo = ServicioChat.miId;
    return PopScope(
      // Atrás cierra primero el panel de emojis.
      canPop: !_mostrarEmojis,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _mostrarEmojis = false);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              KoruAvatar(
                image: contacto.foto?.provider,
                name: contacto.nombreVisible.replaceFirst('@', ''),
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contacto.nombreVisible,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      contacto.esProfesor
                          ? 'Profesor · @${contacto.username}'
                          : '@${contacto.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _mensajes.isEmpty
                  ? _Vacio(
                      icono: Icons.waving_hand_rounded,
                      titulo: '¡Saluda a ${contacto.nombreVisible}!',
                      texto: contacto.esProfesor
                          ? 'Cuéntale tu duda sobre la lección.'
                          : 'Empieza la conversación.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: _mensajes.length,
                      itemBuilder: (context, i) {
                        // La lista va al revés para empezar abajo del todo.
                        final indice = _mensajes.length - 1 - i;
                        final m = _mensajes[indice];
                        final anterior = indice > 0
                            ? _mensajes[indice - 1]
                            : null;
                        final nuevoDia =
                            anterior == null ||
                            !DateUtils.isSameDay(anterior.fecha, m.fecha);
                        return Column(
                          children: [
                            if (nuevoDia) _SeparadorDia(fecha: m.fecha),
                            _Burbuja(mensaje: m, mio: m.remitenteId == yo),
                          ],
                        );
                      },
                    ),
            ),
            _Compositor(
              controlador: _texto,
              foco: _foco,
              enviando: _enviando,
              bloqueado: _puedeEscribir == false,
              emojisAbiertos: _mostrarEmojis,
              onEnviar: _enviar,
              onEmojis: _alternarEmojis,
              onImagen: _adjuntarImagen,
              onTocarTexto: () {
                if (_mostrarEmojis) setState(() => _mostrarEmojis = false);
              },
            ),
            if (_mostrarEmojis && _puedeEscribir != false)
              SafeArea(top: false, child: SelectorEmojis(controlador: _texto)),
          ],
        ),
      ),
    );
  }
}

class _SeparadorDia extends StatelessWidget {
  const _SeparadorDia({required this.fecha});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ahora = DateTime.now();
    final texto = DateUtils.isSameDay(fecha, ahora)
        ? 'Hoy'
        : DateUtils.isSameDay(fecha, ahora.subtract(const Duration(days: 1)))
        ? 'Ayer'
        : MaterialLocalizations.of(context).formatMediumDate(fecha);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            texto,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, required this.mio});

  final MensajeDirecto mensaje;
  final bool mio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fondo = mio ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final texto = mio ? scheme.onPrimaryContainer : scheme.onSurface;
    const r = Radius.circular(18);
    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: mensaje.tieneImagen
              ? const EdgeInsets.fromLTRB(4, 4, 10, 8)
              : const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: mio ? r : const Radius.circular(4),
              bottomRight: mio ? const Radius.circular(4) : r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mensaje.tieneImagen) _ImagenChat(ruta: mensaje.imagenPath!),
              if (mensaje.texto.trim().isNotEmpty)
                Padding(
                  padding: mensaje.tieneImagen
                      ? const EdgeInsets.fromLTRB(10, 8, 0, 0)
                      : EdgeInsets.zero,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      mensaje.texto,
                      style: theme.textTheme.bodyLarge?.copyWith(color: texto),
                    ),
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _horaExacta(mensaje.fecha),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: texto.withValues(alpha: 0.65),
                    ),
                  ),
                  if (mio) ...[
                    const SizedBox(width: 4),
                    Icon(
                      mensaje.leido != null
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: texto.withValues(alpha: 0.65),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _horaExacta(DateTime f) =>
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
}

class _Compositor extends StatelessWidget {
  const _Compositor({
    required this.controlador,
    required this.foco,
    required this.enviando,
    required this.bloqueado,
    required this.emojisAbiertos,
    required this.onEnviar,
    required this.onEmojis,
    required this.onImagen,
    required this.onTocarTexto,
  });

  final TextEditingController controlador;
  final FocusNode foco;
  final bool enviando;
  final bool bloqueado;
  final bool emojisAbiertos;
  final VoidCallback onEnviar;
  final VoidCallback onEmojis;
  final VoidCallback onImagen;
  final VoidCallback onTocarTexto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suave = theme.colorScheme.onSurfaceVariant;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    );
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: !emojisAbiertos,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: bloqueado
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 18, color: suave),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Para escribir, primero tienen que ser amigos.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: suave,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: emojisAbiertos ? 'Teclado' : 'Emojis',
                      onPressed: onEmojis,
                      icon: Icon(
                        emojisAbiertos
                            ? Icons.keyboard_rounded
                            : Icons.emoji_emotions_outlined,
                        color: suave,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controlador,
                        focusNode: foco,
                        onTap: onTocarTexto,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Mensaje',
                          counterText: '',
                          contentPadding: const EdgeInsets.fromLTRB(
                            18,
                            12,
                            4,
                            12,
                          ),
                          border: borde,
                          enabledBorder: borde,
                          focusedBorder: borde.copyWith(
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Enviar imagen',
                            onPressed: enviando ? null : onImagen,
                            icon: Icon(Icons.image_outlined, color: suave),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: enviando ? null : onEnviar,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Imagen de un mensaje: se carga con un enlace temporal del bucket privado.
/// Al tocarla se abre a pantalla completa con zoom.
class _ImagenChat extends StatelessWidget {
  const _ImagenChat({required this.ruta});

  final String ruta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ancho = MediaQuery.sizeOf(context).width * 0.62;
    Widget caja(Widget hijo) => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: ancho, height: ancho * 0.8, child: hijo),
    );
    final cargando = caja(
      ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
    final error = caja(
      ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return FutureBuilder<String>(
      future: ServicioChat.urlImagen(ruta),
      builder: (context, snapshot) {
        if (snapshot.hasError) return error;
        final url = snapshot.data;
        if (url == null) return cargando;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ImagenCompleta(url: url)),
          ),
          child: Hero(
            tag: ruta,
            child: caja(
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progreso) =>
                    progreso == null ? child : cargando,
                errorBuilder: (_, _, _) => error,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImagenCompleta extends StatelessWidget {
  const _ImagenCompleta({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Vista previa antes de enviar una imagen, con un texto opcional.
/// Devuelve el texto (puede ser vacío) o null si se cancela.
class _VistaPreviaImagen extends StatefulWidget {
  const _VistaPreviaImagen({required this.bytes, required this.textoInicial});

  final Uint8List bytes;
  final String textoInicial;

  @override
  State<_VistaPreviaImagen> createState() => _VistaPreviaImagenState();
}

class _VistaPreviaImagenState extends State<_VistaPreviaImagen> {
  late final _texto = TextEditingController(text: widget.textoInicial);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(KoruRadius.l),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: Image.memory(widget.bytes, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _texto,
            minLines: 1,
            maxLines: 3,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Añade un mensaje (opcional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _texto.text),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Botones sociales del perfil público
// ─────────────────────────────────────────────────────────────────────────

/// "Agregar amigo" y "Mensaje" para el perfil de otra persona.
/// No muestra nada en tu propio perfil.
class AccionesSociales extends StatefulWidget {
  const AccionesSociales({super.key, required this.username});

  final String username;

  @override
  State<AccionesSociales> createState() => _AccionesSocialesState();
}

class _AccionesSocialesState extends State<AccionesSociales> {
  Contacto? _contacto;
  RelacionAmistad _relacion = RelacionAmistad.ninguna;
  bool _puedeEscribir = false;
  bool _cargando = true;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final contacto = await ServicioChat.contactoPorUsuario(widget.username);
      if (contacto == null || contacto.id == ServicioChat.miId) {
        if (mounted) setState(() => _cargando = false);
        return;
      }
      final resultados = await Future.wait([
        ServicioChat.misAmistades(),
        ServicioChat.puedeEscribirA(contacto.id),
      ]);
      if (!mounted) return;
      setState(() {
        _contacto = contacto;
        _relacion = ServicioChat.relacionCon(
          contacto.id,
          resultados[0] as List<Amistad>,
        );
        _puedeEscribir = resultados[1] as bool;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('No se pudo cargar la relación: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final contacto = _contacto;
    if (contacto == null) return;
    setState(() => _ocupado = true);
    try {
      final mensaje = await ServicioChat.enviarSolicitud(contacto.username);
      if (mounted) _aviso(context, mensaje);
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _error(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacto = _contacto;
    if (_cargando || contacto == null) return const SizedBox.shrink();

    final Widget amistad = switch (_relacion) {
      RelacionAmistad.amigos => OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.how_to_reg_rounded),
        label: const Text('Amigos'),
      ),
      RelacionAmistad.enviada => OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule_rounded),
        label: const Text('Solicitud enviada'),
      ),
      RelacionAmistad.recibida => FilledButton.icon(
        onPressed: _ocupado ? null : _agregar,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Aceptar solicitud'),
      ),
      RelacionAmistad.ninguna => FilledButton.icon(
        onPressed: _ocupado ? null : _agregar,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Agregar amigo'),
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(child: amistad),
          if (_puedeEscribir) ...[
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(contacto: contacto),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('Mensaje'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
