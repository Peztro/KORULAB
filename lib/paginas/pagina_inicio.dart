import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
import '../servicio_bd.dart';
import '../modelos/imagen_perfil.dart';
import '../modelos/perfil.dart';
import '../servicios/servicio_chat.dart';
import '../servicios/sesion_actual.dart';
import '../paginas/pagina_diverkoru.dart';
import '../paginas/pagina_mensajes.dart';
import '../paginas/pagina_nueva_contrasena.dart';
import '../tema/tema_korulab.dart';
import '../widgets/aviso_reciente.dart';
import '../widgets/ui_koru.dart';
import '../modelos/modelos_discusion.dart';
import '../servicio_notificaciones.dart';
import '../paginas/pagina_discusion.dart';
import '../paginas/pagina_retos_ecologicos.dart';
import '../paginas/pagina_login.dart';
import '../paginas/pagina_tienda.dart';
import '../paginas/pagina_ruta_eko.dart';
import '../pagina_perfil.dart';
import '../servicios/estadisticas_progreso.dart';
import '../paginas_soporte.dart';
import '../widgets/selector_cuentas.dart';
import '../cursos_docentes.dart';
import '../widgets/tarjeta_progreso.dart';
import '../widgets/mascota_flotante.dart';
import '../widgets/mascota_guia.dart';
import '../servicios/koru_controlador.dart';
import '../servicios/servicio_biometrico.dart';

// Página principal del usuario - muestra lecciones, actividades especiales y progreso
class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Estado de la página principal - gestiona navegación entre secciones y contenido dinámico
class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  DateTime? _lastBackPress;
  late String _currentUsername;
  // Foto, banner, nombre y género salen del perfil compartido en
  // SesionActual: si se editan en otra pantalla, esta se redibuja sola.
  Perfil? get _perfil => SesionActual.instancia.perfil;
  String get _displayName => _perfil?.displayName ?? '';
  String? get _gender => _perfil?.gender;
  ImagenPerfil? get _profilePhoto => _perfil?.foto;
  ImagenPerfil? get _banner => _perfil?.banner;
  String _userRole = DBService.roleStudent;
  bool _isAdmin = false;
  bool _isTeacher = false;
  final List<DiscussionSpace> _discussionSpaces = [
    DiscussionSpace(
      title: 'Ideas para cuidar el planeta',
      description: 'Comparte acciones sencillas que podemos aplicar cada día.',
      author: DBService.koruColDisplayName,
      authorHandle: DBService.koruColUsername,
      authorRole: DBService.roleAdmin,
      replies: [
        DiscussionReply(
          author: DBService.koruColDisplayName,
          authorHandle: DBService.koruColUsername,
          authorRole: DBService.roleAdmin,
          message: '¡Todas las ideas son bienvenidas!',
        ),
      ],
    ),
    DiscussionSpace(
      title: 'Preguntas sobre las lecciones',
      description: 'Ayuda a otros usuarios y resuelve tus dudas.',
      author: DBService.koruColDisplayName,
      authorHandle: DBService.koruColUsername,
      authorRole: DBService.roleAdmin,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentUsername = DBService.normalizeUsername(widget.username);
    SesionActual.instancia.addListener(_onSesionChanged);
    _loadDiscussionSpaces();
    _loadKorucolNotes();
    _loadRole();
    _loadProfilePhoto();
    _loadUserProgress();
    _cargarPendientesMensajes();
    _canalMensajes = ServicioChat.escuchar(
      'inicio-$_currentUsername',
      (_) => _cargarPendientesMensajes(),
    );
    _controlesDeEntrada();
    unawaited(NotificationService.startListening(_currentUsername));
  }

  @override
  void dispose() {
    final canal = _canalMensajes;
    if (canal != null) unawaited(ServicioChat.dejarDeEscuchar(canal));
    SesionActual.instancia.removeListener(_onSesionChanged);
    unawaited(NotificationService.stopListening(onlyFor: _currentUsername));
    super.dispose();
  }

  Future<void> _loadUserProgress() async {
    final activatedProtectors = await progressStats.loadCourseProgress(
      _currentUsername,
    );
    if (!mounted || activatedProtectors == 0) return;
    final protectorLabel = activatedProtectors == 1
        ? 'protector de racha'
        : 'protectores de racha';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se activaron automáticamente $activatedProtectors $protectorLabel.',
        ),
      ),
    );
  }

  void _onSesionChanged() {
    if (mounted) setState(() {});
  }

  /// Carga el perfil propio; DBService lo publica en SesionActual.
  Future<void> _loadProfilePhoto() async {
    final profile = await DBService.getUserProfile(_currentUsername);
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        _currentUsername = DBService.normalizeUsername(profile.username);
      }
      final role = profile?.role ?? DBService.roleStudent;
      _userRole = role;
      _role = role;
      _isRoleLoaded = true;
      _roleLoadError = null;
      _isAdmin = role == DBService.roleAdmin;
      _isTeacher = role == DBService.roleTeacher;
    });
  }

  String get _greeting => switch (_gender) {
    'female' => 'Bienvenida',
    'male' => 'Bienvenido',
    _ => 'Bienvenidx',
  };

  String get _currentDisplayName =>
      _displayName.trim().isEmpty ? _currentUsername : _displayName.trim();

  Future<void> _loadDiscussionSpaces() async {
    final storedSpaces = await DBService.getDiscussionSpaces();

    final loadedSpaces = storedSpaces.map((space) {
      final replies = (space['replies'] as List<Map<String, dynamic>>)
          .map(
            (reply) => DiscussionReply(
              id: reply['id'] as int?,
              author: reply['author'] as String,
              authorHandle: reply['author_handle'] as String? ?? '',
              authorRole:
                  reply['author_role'] as String? ?? DBService.roleStudent,
              authorPhoto: reply['author_photo'] as ImagenPerfil?,
              message: reply['message'] as String,
              createdAt: DateTime.tryParse(
                reply['created_at'] as String? ?? '',
              ),
            ),
          )
          .toList();
      return DiscussionSpace(
        id: space['id'] as int,
        title: space['title'] as String,
        description: space['description'] as String,
        isPinned: space['is_pinned'] as bool? ?? false,
        author: space['author'] as String,
        authorHandle: space['author_handle'] as String? ?? '',
        authorRole: space['author_role'] as String? ?? DBService.roleStudent,
        authorPhoto: space['author_photo'] as ImagenPerfil?,
        replies: replies,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _discussionSpaces
          ..clear()
          ..addAll(loadedSpaces);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1 && _role != DBService.roleAdmin) _loadKorucolNotes();
  }

  List<Map<String, dynamic>> _korucolNotes = [];

  Future<void> _loadKorucolNotes() async {
    try {
      final notes = await loadManageableLessons(
        _currentUsername,
        DBService.lessonDestinationKorucol,
      );
      if (mounted) setState(() => _korucolNotes = notes);
    } catch (_) {}
  }

  void _openRewardShop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RewardShopPage(username: _currentUsername),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(username: _currentUsername),
      ),
    );
  }

  void _openProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          username: _currentUsername,
          onProfileChanged: _onProfileChanged,
        ),
      ),
    );
  }

  String _role = DBService.roleStudent;
  bool _isRoleLoaded = false;
  String? _roleLoadError;

  Future<void> _loadRole() async {
    try {
      final role = await DBService.getUserRole(_currentUsername);
      if (!mounted) return;
      if (role != _role || !_isRoleLoaded || _roleLoadError != null) {
        setState(() {
          if (role != _role) _selectedIndex = 0;
          _role = role;
          _userRole = role;
          _isAdmin = role == DBService.roleAdmin;
          _isTeacher = role == DBService.roleTeacher;
          _isRoleLoaded = true;
          _roleLoadError = null;
        });
        if (role == DBService.roleStudent) {
          unawaited(
            MascotaGuia.mostrarSiEsPrimeraVez(context, _currentUsername),
          );
          _saludoDeKoru();
        }
      }
    } catch (error) {
      debugPrint('No se pudo cargar el rol de la cuenta: $error');
      if (mounted) {
        setState(() => _roleLoadError = 'No se pudo verificar tu rol.');
      }
    }
  }

  /// Al entrar: huella (si está activada) y, si la contraseña es temporal,
  /// obligar a crear una propia.
  Future<void> _controlesDeEntrada() async {
    await _checkBiometricOnEntry();
    if (!mounted || !DBService.debeCambiarContrasena) return;
    // Espera a que termine de pintarse el inicio antes de navegar.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NuevaContrasenaPage(),
      ),
    );
  }

  Future<void> _checkBiometricOnEntry() async {
    // Ya se verificó al abrir la app (pantalla de carga o login con huella).
    if (BiometricAuthService.verificadoEnEstaApertura) return;
    final biometricEnabled = await BiometricAuthService.isBiometricEnabled(
      _currentUsername,
    );
    final biometricAvailable =
        await BiometricAuthService.isBiometricAvailable();

    if (biometricEnabled && biometricAvailable && mounted) {
      final authenticated = await BiometricAuthService.authenticate(
        reason: 'Verifica tu identidad para acceder a Korulab',
      );

      if (!authenticated && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _openSupportReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportReviewPage(adminUsername: _currentUsername),
      ),
    );
  }

  void _openRoleManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleManagementPage(adminUsername: _currentUsername),
      ),
    );
  }

  void _openStudentProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentProfilesPage(requesterUsername: _currentUsername),
      ),
    );
  }

  // Solicitudes de amistad y mensajes sin leer, para el contador del menú.
  int _pendientesMensajes = 0;

  final _avisoKey = GlobalKey<AvisoRecienteState>();

  Widget _avisoReciente() => AvisoReciente(
    key: _avisoKey,
    username: _currentUsername,
    onVerTodos: () => _abrirMensajes(pestana: 2),
  );

  Future<void> _publicarAviso() async {
    final enviado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BroadcastMessagePage(senderUsername: _currentUsername),
      ),
    );
    if (!mounted || enviado != true) return;
    unawaited(_avisoKey.currentState?.recargar());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aviso publicado para todos los usuarios.')),
    );
  }

  /// Solicitudes de amistad recibidas (punto en la foto de la barra).
  int _solicitudesAmistad = 0;

  /// Cuántos chats tienen mensajes sin leer (globo del botón de mensajes).
  int _chatsSinLeer = 0;

  /// Escucha mensajes y amistades para mantener los contadores al día.
  RealtimeChannel? _canalMensajes;

  Future<void> _cargarPendientesMensajes() async {
    final p = await ServicioChat.pendientes();
    var chatsSinLeer = 0;
    try {
      final chats = await ServicioChat.misConversaciones();
      chatsSinLeer = chats.where((c) => c.noLeidos > 0).length;
    } catch (e) {
      debugPrint('No se pudieron contar los chats sin leer: $e');
    }
    if (!mounted) return;
    setState(() {
      _pendientesMensajes = p.solicitudes + p.noLeidos;
      _solicitudesAmistad = p.solicitudes;
      _chatsSinLeer = chatsSinLeer;
    });
  }

  Future<void> _openMessages() => _abrirMensajes();

  Future<void> _abrirMensajes({int pestana = 0}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MensajesPage(username: _currentUsername, pestana: pestana),
      ),
    );
    unawaited(_cargarPendientesMensajes());
    unawaited(_avisoKey.currentState?.recargar());
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherCourseEditorPage(username: _currentUsername),
      ),
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unidad publicada en Ruta Eko.')),
    );
  }

  Future<void> _openCreateLesson() async {
    await _openLessonEditor();
  }

  Future<void> _openCreateKorucolContent() async {
    await _openLessonEditor(
      initialDestination: DBService.lessonDestinationKorucol,
    );
  }

  Future<void> _openLessonEditor({String? initialDestination}) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTeacherLessonPage(
          teacherUsername: _currentUsername,
          initialDestination:
              initialDestination ?? DBService.lessonDestinationKoruclases,
        ),
      ),
    );
    if (!mounted || created != true) return;
    await _loadKorucolNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('La lección se publicó.')));
  }

  Future<void> _openSupportPage() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SupportRequestPage(
          username: _currentUsername,
          displayName: _currentDisplayName,
        ),
      ),
    );
    if (!mounted || sent != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu PQRS se envió correctamente.')),
    );
  }

  Future<void> _showAccountSwitcher() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await DBService.rememberCurrentAccount(
      displayName: _displayName,
      profilePhoto: _profilePhoto,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => AccountSwitcherSheet(
        onSwitch: (account) async {
          Navigator.pop(sheetContext);
          try {
            final username = await DBService.switchAccount(account.id);
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomePage(username: username)),
              (_) => false,
            );
          } catch (error) {
            final text = error is StateError ? error.message : '$error';
            messenger.showSnackBar(SnackBar(content: Text(text)));
          }
        },
        onAdd: () {
          Navigator.pop(sheetContext);
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const LoginPage(addAccount: true),
            ),
          );
        },
      ),
    );
  }

  void _onProfileChanged(String displayName, String username) {
    setState(() => _currentUsername = username);
    unawaited(_loadProfilePhoto());
    unawaited(progressStats.loadCourseProgress(username));
    _loadDiscussionSpaces();
    _loadKorucolNotes();
    _loadRole();
  }

  Widget _buildLessonsSection(ThemeData theme) {
    final koru = context.koru;
    return ListView(
      // Abajo deja sitio para Koru, que flota en la esquina.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _buildWelcomeHero(theme),
        const SizedBox(height: 16),
        _avisoReciente(),
        ProgressCard(username: _currentUsername),
        const SizedBox(height: 12),
        const SectionTitle('Explora'),
        FeatureCard(
          title: 'Ruta Eko',
          subtitle: 'Un sendero de aprendizaje sobre sostenibilidad',
          icon: Icons.route_rounded,
          color: koru.hoja,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RutaEkoPage(username: _currentUsername),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FeatureCard(
          title: 'Retos ekológicos',
          subtitle: 'Pequeñas acciones para el día a día',
          icon: Icons.emoji_events_rounded,
          color: koru.agua,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcoChallengesPage(username: _currentUsername),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FeatureCard(
          title: 'Tienda',
          subtitle: 'Canjea ekostrellas y revisa tu inventario',
          icon: Icons.storefront_rounded,
          color: koru.oro,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RewardShopPage(username: _currentUsername),
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta de bienvenida con saludo, racha y ekostrellas.
  Widget _buildWelcomeHero(ThemeData theme) {
    final koru = context.koru;
    return AnimatedBuilder(
      animation: progressStats,
      builder: (context, _) {
        final streak = progressStats.dailyStreak;
        final onHero = koru.textoHero;
        return Container(
          decoration: BoxDecoration(
            gradient: koru.degradadoHero,
            borderRadius: BorderRadius.circular(KoruRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -24,
                bottom: -28,
                child: Icon(
                  Icons.eco_rounded,
                  size: 150,
                  color: onHero.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting,',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onHero.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      _currentDisplayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: onHero,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      streak > 0
                          ? 'Llevas $streak ${streak == 1 ? 'día' : 'días'} cuidando el planeta. ¡Sigue así!'
                          : 'Completa una actividad hoy y empieza tu racha.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onHero.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _heroStat(
                            theme,
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFFA463),
                            value: '$streak',
                            label: streak == 1
                                ? 'día de racha'
                                : 'días de racha',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _heroStat(
                            theme,
                            icon: Icons.star_rounded,
                            color: const Color(0xFFFFD66B),
                            value: '${progressStats.ekostrellas}',
                            label: 'ekostrellas',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroStat(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    final onHero = context.koru.textoHero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(KoruRadius.m),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    height: 1.1,
                    color: onHero,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onHero.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDashboardAction({
    required ThemeData theme,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeatureCard(
        title: title,
        subtitle: description,
        icon: icon,
        color: color ?? context.koru.hoja,
        onTap: onTap,
      ),
    );
  }

  Widget _buildTeacherDashboard(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        PageHeader(
          title: '$_greeting, profe $_currentDisplayName',
          subtitle:
              'Crea unidades, comparte contenido y acompaña el avance de tus estudiantes.',
        ),
        _avisoReciente(),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Agregar unidad a Ruta Eko',
          description: 'Publica una nueva unidad con actividades.',
          icon: Icons.add_road,
          onTap: _openCreateCourse,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Agregar lección a Ruta Eko',
          description: 'Publica una lección suelta en el sendero.',
          icon: Icons.library_add_rounded,
          color: context.koru.tierra,
          onTap: _openCreateLesson,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Agregar contenido a Konsejos',
          description: 'Publica una nota o lección en Konsejos.',
          icon: Icons.post_add,
          color: context.koru.agua,
          onTap: _openCreateKorucolContent,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Perfiles de estudiantes',
          description: 'Consulta sus perfiles y progreso de aprendizaje.',
          icon: Icons.groups_outlined,
          color: context.koru.oro,
          onTap: _openStudentProfiles,
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const PageHeader(
          title: 'Consola de administración',
          subtitle:
              'Gestiona las solicitudes de soporte y los roles de las cuentas.',
        ),
        _avisoReciente(),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Publicar aviso para todos',
          description: 'Un comunicado que verá cada usuario al abrir la app.',
          icon: Icons.campaign_rounded,
          color: context.koru.oro,
          onTap: _publicarAviso,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Consultar PQRS',
          description:
              'Revisa las solicitudes recibidas y actualiza su estado.',
          icon: Icons.inbox_outlined,
          onTap: _openSupportReview,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Administrar roles',
          description:
              'Asigna los roles de administrador, profesor o estudiante.',
          icon: Icons.manage_accounts_outlined,
          color: context.koru.agua,
          onTap: _openRoleManagement,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Gestionar perfiles de estudiantes',
          description: 'Consulta progreso y elimina cuentas de estudiantes.',
          icon: Icons.groups_outlined,
          color: context.koru.oro,
          onTap: _openStudentProfiles,
        ),
      ],
    );
  }

  Widget _buildKorucolSection(ThemeData theme) {
    final koru = context.koru;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Konsejos',
            subtitle:
                'Ideas y consejos prácticos para cuidar el planeta en casa y en tu comunidad.',
          ),
          const SectionTitle('Contenido destacado'),
          _buildInfoCard(
            theme,
            'Cómo cuidar el agua',
            icon: Icons.water_drop_rounded,
            color: koru.agua,
            'Acciones sencillas para gastar menos agua cada día.',
            'Cierra el grifo mientras te cepillas los dientes o enjabonas los platos.\n\nPrefiere duchas cortas y reutiliza el agua limpia que dejas correr mientras se calienta para regar las plantas.\n\nRevisa si hay fugas: una llave que gotea puede desperdiciar muchos litros con el tiempo.',
          ),
          _buildInfoCard(
            theme,
            'Ahorro de energía',
            icon: Icons.bolt_rounded,
            color: koru.oro,
            'Reduce el consumo eléctrico sin complicar tu rutina.',
            'Aprovecha la luz natural y apaga las luces al salir de una habitación.\n\nDesconecta cargadores y aparatos que no estés usando; algunos siguen consumiendo energía en espera.\n\nCuando puedas, lava con cargas completas y seca la ropa al aire libre.',
          ),
          _buildInfoCard(
            theme,
            'Reciclaje creativo',
            icon: Icons.recycling_rounded,
            color: koru.hoja,
            'Reutiliza materiales antes de convertirlos en residuos.',
            'Usa frascos limpios para guardar alimentos u organizar objetos pequeños.\n\nConvierte cajas de cartón en organizadores y transforma una camiseta vieja en una bolsa reutilizable.\n\nAntes de reciclar, separa los materiales y sigue las normas de recolección de tu localidad. Pilas y electrónicos deben llevarse a puntos especiales.',
          ),
          ..._korucolNotes.map((note) => _buildKorucolNoteCard(theme, note)),
        ],
      ),
    );
  }

  Widget _buildKorucolNoteCard(ThemeData theme, Map<String, dynamic> note) {
    final author = note['teacher_name'] ?? 'Profesor';
    final card = _buildInfoCard(
      theme,
      note['title'] as String,
      icon: Icons.school_rounded,
      color: context.koru.tierra,
      '${note['summary']}\nPor $author',
      note['content'] as String,
    );
    if (note['can_manage'] != true) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: 0,
          right: 36,
          child: TeacherLessonMenu(
            lesson: note,
            username: _currentUsername,
            onChanged: _loadKorucolNotes,
          ),
        ),
      ],
    );
  }

  Widget _buildKorublogSection(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadDiscussionSpaces,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const PageHeader(
            title: 'Korublog',
            subtitle: 'Lecturas, historias y noticias del mundo Korulab.',
          ),
          SectionTitle(
            'Discusiones',
            trailing: FilledButton.icon(
              onPressed: _showCreateDiscussionDialog,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Nueva'),
            ),
          ),
          for (final space in _discussionSpaces)
            _buildDiscussionCard(theme, space),
        ],
      ),
    );
  }

  Future<void> _editDiscussionSpace(DiscussionSpace space) async {
    if (space.id == null) return;
    final titleController = TextEditingController(text: space.title);
    final descriptionController = TextEditingController(
      text: space.description,
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar publicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descriptionController,
              maxLength: 180,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              if (title.isEmpty || description.isEmpty) return;
              Navigator.pop(dialogContext, [title, description]);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;

    final updated = await DBService.updateDiscussionSpace(
      discussionId: space.id!,
      requesterUsername: _currentUsername,
      title: result[0],
      description: result[1],
    );
    if (!mounted) return;
    if (!updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para editar esta publicación.'),
        ),
      );
      return;
    }
    await _loadDiscussionSpaces();
  }

  Future<void> _deleteDiscussionSpace(DiscussionSpace space) async {
    if (space.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          'También se eliminarán sus comentarios. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await DBService.deleteDiscussionSpace(
      discussionId: space.id!,
      requesterUsername: _currentUsername,
    );
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para eliminar esta publicación.'),
        ),
      );
      return;
    }
    await _loadDiscussionSpaces();
  }

  Future<void> _toggleDiscussionPin(DiscussionSpace space) async {
    if (space.id == null || !_isAdmin) return;
    try {
      final updated = await DBService.setDiscussionPinned(
        adminUsername: _currentUsername,
        discussionId: space.id!,
        isPinned: !space.isPinned,
      );
      if (!mounted) return;
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo fijar la discusión.')),
        );
        return;
      }
      await _loadDiscussionSpaces();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            space.isPinned
                ? 'Discusión desfijada.'
                : 'Discusión fijada en Korublog.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('No se pudo cambiar el fijado de la discusión: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la discusión.')),
      );
    }
  }

  Widget _buildDiscussionCard(ThemeData theme, DiscussionSpace space) {
    final canManage =
        _isAdmin ||
        _isTeacher ||
        DBService.normalizeUsername(space.authorHandle) == _currentUsername;
    final muted = theme.colorScheme.onSurfaceVariant;
    final replies = space.replies.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => _openDiscussion(space),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => openPublicProfile(
                        context,
                        handle: space.authorHandle,
                        name: space.author,
                        photo: space.authorPhoto,
                      ),
                      child: KoruAvatar(
                        image: space.authorPhoto?.provider,
                        name: space.author,
                      ),
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
                                  space.author,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              RoleBadge(space.authorRole),
                            ],
                          ),
                          if (space.authorHandle.isNotEmpty)
                            Text(
                              '@${space.authorHandle}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (space.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: 'Fijada',
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 18,
                            color: context.koru.oro,
                          ),
                        ),
                      ),
                    if (canManage)
                      PopupMenuButton<String>(
                        tooltip: 'Administrar publicación',
                        icon: Icon(Icons.more_horiz_rounded, color: muted),
                        onSelected: (action) {
                          if (action == 'pin') _toggleDiscussionPin(space);
                          if (action == 'edit') _editDiscussionSpace(space);
                          if (action == 'delete') _deleteDiscussionSpace(space);
                        },
                        itemBuilder: (_) => [
                          if (_isAdmin)
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                space.isPinned
                                    ? 'Desfijar discusión'
                                    : 'Fijar discusión',
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        space.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        space.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            replies == 1
                                ? '1 respuesta'
                                : '$replies respuestas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Abrir',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDiscussionDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crear espacio de discusión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej. Huertos en casa',
              ),
            ),
            TextField(
              controller: descriptionController,
              maxLength: 180,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: '¿Sobre qué quieres conversar?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              if (title.isEmpty || description.isEmpty) return;
              Navigator.pop(dialogContext, [title, description]);
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    var wasSaved = false;
    try {
      await DBService.createDiscussionSpace(
        title: result[0],
        description: result[1],
        author: _currentDisplayName,
        authorHandle: _currentUsername,
      );
      wasSaved = true;
      await _loadDiscussionSpaces();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Publicación creada.')));
      }
    } catch (_) {
      if (!mounted) return;
      if (wasSaved) {
        try {
          await _loadDiscussionSpaces();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? 'La publicación se guardó, pero no se pudo actualizar la lista.'
                : 'No se pudo publicar. Comprueba los datos e inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  Future<void> _openDiscussion(DiscussionSpace space) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscussionPage(
          space: space,
          username: _currentUsername,
          displayName: _currentDisplayName,
          userRole: _userRole,
          authorPhoto: _profilePhoto,
          isAdmin: _isAdmin,
          isTeacher: _isTeacher,
        ),
      ),
    );
    if (mounted) await _loadDiscussionSpaces();
  }

  Widget _buildInfoCard(
    ThemeData theme,
    String title,
    String subtitle,
    String details, {
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeatureCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            builder: (context, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                Row(
                  children: [
                    IconTile(icon: icon, color: color, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(details, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        final last = _lastBackPress;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Pulsa atrás otra vez para salir'),
              duration: Duration(seconds: 2),
            ),
          );
      },
      child: _buildScaffold(context),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.logout_rounded,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tendrás que volver a entrar con tu usuario y contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    await DBService.logout();
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  /// Ejecuta [action] después de cerrar el menú lateral.
  void _fromDrawer(VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  Widget _buildDrawer(ThemeData theme) {
    final koru = context.koru;
    final isAdmin = _role == DBService.roleAdmin;

    Widget item({
      required IconData icon,
      required Color color,
      required String title,
      String? subtitle,
      int contador = 0,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: IconTile(icon: icon, color: color, size: 40),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing: contador > 0
              ? Badge(
                  label: Text('$contador'),
                  backgroundColor: koru.hoja,
                  textColor: theme.colorScheme.onPrimary,
                )
              : null,
          onTap: () => _fromDrawer(onTap),
        ),
      );
    }

    Widget section(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de perfil: tocarla abre "Mi perfil".
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Material(
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(KoruRadius.l),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: koru.degradadoHero,
                    image: _banner == null
                        ? null
                        : DecorationImage(
                            image: _banner!.provider,
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(
                              Colors.black54,
                              BlendMode.darken,
                            ),
                          ),
                  ),
                  child: InkWell(
                    onTap: () => _fromDrawer(_openProfilePage),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: koru.textoHero,
                                    width: 2,
                                  ),
                                ),
                                child: KoruAvatar(
                                  image: _profilePhoto?.provider,
                                  name: _currentDisplayName,
                                  radius: 30,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Cambiar de cuenta',
                                onPressed: () =>
                                    _fromDrawer(_showAccountSwitcher),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.25,
                                  ),
                                  foregroundColor: koru.textoHero,
                                ),
                                icon: const Icon(Icons.swap_horiz_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: koru.textoHero,
                            ),
                          ),
                          Text(
                            '@$_currentUsername',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: koru.textoHero.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  DBService.roleLabel(_role),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: koru.textoHero,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Ver perfil',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: koru.textoHero,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: koru.textoHero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  section('Comunicación'),
                  item(
                    icon: Icons.mail_rounded,
                    color: koru.agua,
                    title: 'Mensajes',
                    subtitle: 'Chats, amigos y avisos',
                    contador: _pendientesMensajes,
                    onTap: _openMessages,
                  ),
                  if (!isAdmin)
                    item(
                      icon: Icons.support_agent_rounded,
                      color: koru.oro,
                      title: 'Ayuda y PQRS',
                      subtitle: 'Escríbele al equipo de Korulab',
                      onTap: _openSupportPage,
                    ),
                  section('Cuenta'),
                  item(
                    icon: Icons.settings_rounded,
                    color: koru.tierra,
                    title: 'Ajustes',
                    subtitle: 'Apariencia y contraseña',
                    onTap: _openSettings,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                leading: IconTile(
                  icon: Icons.logout_rounded,
                  color: theme.colorScheme.error,
                  size: 40,
                ),
                title: Text(
                  'Cerrar sesión',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () => _fromDrawer(_confirmLogout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Añade a Koru en la esquina inferior derecha cuando [mostrar] es true.
  Widget _conKoru(bool mostrar, Widget contenido) {
    if (!mostrar || !_isRoleLoaded) return contenido;
    return Stack(
      children: [
        Positioned.fill(child: contenido),
        const Positioned(right: 16, bottom: 16, child: MascotaFlotante()),
      ],
    );
  }

  void _saludoDeKoru() {
    final nombre = _currentDisplayName.trim().split(RegExp(r'\s+')).first;
    unawaited(
      KoruControlador.instancia.reaccionar(
        EventoKoru.bienvenida,
        datos: {'nombre': nombre.startsWith('@') ? '' : nombre},
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = _role == DBService.roleAdmin;
    final isTeacher = _role == DBService.roleTeacher;
    final isStudent = _role == DBService.roleStudent;
    final destinations = isAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Consola',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Korublog',
            ),
          ]
        : [
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.dashboard_outlined),
              label: isTeacher ? 'Panel docente' : 'Página principal',
            ),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Konsejos',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports),
              label: 'DiverKoru',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Korublog',
            ),
          ];
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (open) {
        if (!open) return;
        _loadRole();
        _cargarPendientesMensajes();
      },
      backgroundColor: theme.colorScheme.surface,
      drawer: _buildDrawer(theme),
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Abrir menú de perfil',
            onPressed: _isRoleLoaded
                ? () => _scaffoldKey.currentState?.openDrawer()
                : null,
            // Punto verde si hay solicitudes de amistad pendientes.
            icon: Badge(
              isLabelVisible: _solicitudesAmistad > 0,
              smallSize: 10,
              backgroundColor: context.koru.hoja,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: KoruAvatar(
                  image: _profilePhoto?.provider,
                  name: _currentDisplayName,
                  radius: 15,
                ),
              ),
            ),
          ),
        ),
        title: Image.asset(
          theme.brightness == Brightness.dark
              ? 'assets/images/korualt.png'
              : 'assets/images/korulogo.png',
          height: 30,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        actions: [
          if (_isRoleLoaded && isStudent)
            AnimatedBuilder(
              animation: progressStats,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatPill(
                    icon: Icons.local_fire_department_rounded,
                    value: '${progressStats.dailyStreak}',
                    color: context.koru.fuego,
                    tooltip: 'Racha diaria: ${progressStats.dailyStreak} días',
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _openRewardShop,
                    child: StatPill(
                      icon: Icons.star_rounded,
                      value: '${progressStats.ekostrellas}',
                      color: context.koru.oro,
                      tooltip:
                          '${progressStats.ekostrellas} ekostrellas · Abrir tienda',
                    ),
                  ),
                ],
              ),
            ),
          if (_isRoleLoaded)
            IconButton(
              tooltip: _chatsSinLeer == 0
                  ? 'Mensajes'
                  : 'Mensajes · $_chatsSinLeer '
                        '${_chatsSinLeer == 1 ? 'chat' : 'chats'} sin leer',
              onPressed: _openMessages,
              icon: Badge(
                isLabelVisible: _chatsSinLeer > 0,
                label: Text(_chatsSinLeer > 9 ? '9+' : '$_chatsSinLeer'),
                backgroundColor: context.koru.hoja,
                textColor: theme.colorScheme.onPrimary,
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _conKoru(
        isStudent && _selectedIndex == 0,
        !_isRoleLoaded
            ? Center(
                child: _roleLoadError == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_roleLoadError!),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadRole,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
              )
            : isAdmin
            ? _selectedIndex == 0
                  ? _buildAdminDashboard(theme)
                  : _buildKorublogSection(theme)
            : _selectedIndex == 0
            ? _role == DBService.roleTeacher
                  ? _buildTeacherDashboard(theme)
                  : _buildLessonsSection(theme)
            : _selectedIndex == 1
            ? _buildKorucolSection(theme)
            : _selectedIndex == 2
            ? const DiverKoruSection()
            : _buildKorublogSection(theme),
      ),
      bottomNavigationBar: _isRoleLoaded
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: destinations,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
//  PROGRESS CARD
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
//  WIDGETS Y COMPONENTES
// ─────────────────────────────────────────────
