import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_service.dart';
import '../models/discussion_models.dart';
import '../notification_service.dart';
import '../pages/discussion_page.dart';
import '../pages/eco_challenges_page.dart';
import '../pages/login_page.dart';
import '../pages/reward_shop_page.dart';
import '../pages/ruta_eko_page.dart';
import '../profile_page.dart';
import '../services/progress_stats.dart';
import '../support_pages.dart';
import '../widgets/account_switcher_sheet.dart';
import '../teacher_courses.dart';
import '../widgets/home_cards.dart';
import '../widgets/progress_card.dart';

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
  String _displayName = '';
  String? _gender;
  String _userRole = DBService.roleStudent;
  bool _isAdmin = false;
  bool _isTeacher = false;
  Uint8List? _profilePhoto;
  Uint8List? _banner;
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
    _loadDiscussionSpaces();
    _loadKorucolNotes();
    _loadRole();
    _loadProfilePhoto();
    _loadUserProgress();
    unawaited(NotificationService.startListening(_currentUsername));
  }

  @override
  void dispose() {
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

  Future<void> _loadProfilePhoto() async {
    final profile = await DBService.getUserProfile(_currentUsername);
    if (!mounted) return;
    setState(() {
      _profilePhoto = profile?['profile_photo'] as Uint8List?;
      _banner = profile?['banner'] as Uint8List?;
      _currentUsername = DBService.normalizeUsername(
        profile?['username'] as String? ?? _currentUsername,
      );
      _displayName = profile?['display_name'] as String? ?? '';
      _gender = profile?['gender'] as String?;
      final role = profile?['role'] as String? ?? DBService.roleStudent;
      _userRole = role;
      _role = role;
      _isRoleLoaded = true;
      _roleLoadError = null;
      _isAdmin =
          role == DBService.roleAdmin ||
          (profile?['is_admin'] as int? ?? 0) == 1;
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
              authorPhoto: reply['author_photo'] as Uint8List?,
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
        authorPhoto: space['author_photo'] as Uint8List?,
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

  static const _sectionTitles = [
    'Página principal',
    'Aprende con Korucol',
    'Korublog',
  ];

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
        builder: (_) => SettingsPage(
          username: _currentUsername,
          displayName: _currentDisplayName,
          onOpenProfile: _openProfilePage,
          onSwitchAccount: _showAccountSwitcher,
        ),
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
      }
    } catch (error) {
      debugPrint('No se pudo cargar el rol de la cuenta: $error');
      if (mounted) {
        setState(() => _roleLoadError = 'No se pudo verificar tu rol.');
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

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesPage(username: _currentUsername),
      ),
    );
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
            final username = await DBService.switchAccount(
              account['id'] as String,
            );
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

  void _onProfileChanged(
    String displayName,
    String username,
    Uint8List? photo,
  ) {
    setState(() {
      _displayName = displayName;
      _currentUsername = username;
      _profilePhoto = photo;
    });
    unawaited(_loadProfilePhoto());
    unawaited(progressStats.loadCourseProgress(username));
    unawaited(
      DBService.rememberCurrentAccount(
        displayName: displayName,
        profilePhoto: photo,
      ),
    );
    _loadDiscussionSpaces();
    _loadKorucolNotes();
    _loadRole();
  }

  Widget _buildLessonsSection(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting, $_currentDisplayName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Es hora de conocer un poco más de cómo cuidar el planeta!!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: progressStats,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Racha',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${progressStats.dailyStreak} días',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ProgressCard(username: _currentUsername),
          const SizedBox(height: 20),
          Text(
            'Actividades especiales',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SpecialActivityCard(
            title: 'RUTA EKO',
            subtitle: 'Un sendero de aprendizaje sobre sostenibilidad',
            icon: Icons.menu_book,
            color: Colors.green.shade600,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RutaEkoPage(username: _currentUsername),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SpecialActivityCard(
            title: 'RETOS EKOLÓGICOS',
            subtitle: 'Pequeñas acciones para el día a día',
            icon: Icons.emoji_events,
            color: Colors.teal.shade600,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EcoChallengesPage(username: _currentUsername),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SpecialActivityCard(
            title: 'TIENDA',
            subtitle: 'Canjea ekostrellas y revisa tu inventario',
            icon: Icons.storefront,
            color: Colors.orange.shade700,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RewardShopPage(username: _currentUsername),
              ),
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
  }) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTeacherDashboard(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bienvenido docente, $_currentDisplayName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea unidades, comparte contenido y acompaña el avance de tus estudiantes.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Agregar unidad a Ruta Eko',
          description: 'Publica una nueva unidad con actividades.',
          icon: Icons.add_road,
          onTap: _openCreateCourse,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Agregar contenido a Korucol',
          description: 'Publica una nota o lección en Korucol.',
          icon: Icons.post_add,
          onTap: _openCreateKorucolContent,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Perfiles de estudiantes',
          description: 'Consulta sus perfiles y progreso de aprendizaje.',
          icon: Icons.groups_outlined,
          onTap: _openStudentProfiles,
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Consola de administración',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona las solicitudes de soporte y los roles de las cuentas.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
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
          onTap: _openRoleManagement,
        ),
        _buildRoleDashboardAction(
          theme: theme,
          title: 'Gestionar perfiles de estudiantes',
          description: 'Consulta progreso y elimina cuentas de estudiantes.',
          icon: Icons.groups_outlined,
          onTap: _openStudentProfiles,
        ),
      ],
    );
  }

  Widget _buildKorucolSection(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aprende con Korucol',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ideas y consejos prácticos para cuidar el planeta en casa y en tu comunidad.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Contenido destacado',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            theme,
            'Cómo cuidar el agua',
            'Acciones sencillas para gastar menos agua cada día.',
            'Cierra el grifo mientras te cepillas los dientes o enjabonas los platos.\n\nPrefiere duchas cortas y reutiliza el agua limpia que dejas correr mientras se calienta para regar las plantas.\n\nRevisa si hay fugas: una llave que gotea puede desperdiciar muchos litros con el tiempo.',
          ),
          _buildInfoCard(
            theme,
            'Ahorro de energía',
            'Reduce el consumo eléctrico sin complicar tu rutina.',
            'Aprovecha la luz natural y apaga las luces al salir de una habitación.\n\nDesconecta cargadores y aparatos que no estés usando; algunos siguen consumiendo energía en espera.\n\nCuando puedas, lava con cargas completas y seca la ropa al aire libre.',
          ),
          _buildInfoCard(
            theme,
            'Reciclaje creativo',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Korublog',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lecturas, historias y noticias del mundo Korulab.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showCreateDiscussionDialog,
              icon: const Icon(Icons.add_comment),
              label: const Text('Crear espacio de discusión'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Espacios de discusión',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._discussionSpaces.map(
            (space) => _buildDiscussionCard(theme, space),
          ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        leading: GestureDetector(
          onTap: () => openPublicProfile(
            context,
            handle: space.authorHandle,
            name: space.author,
            photo: space.authorPhoto,
          ),
          child: CircleAvatar(
            backgroundImage: space.authorPhoto == null
                ? null
                : MemoryImage(space.authorPhoto!),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: space.authorPhoto == null
                ? Icon(Icons.forum, color: theme.colorScheme.primaryContainer)
                : null,
          ),
        ),
        title: Text(
          '${space.isPinned ? '📌 ' : ''}${space.title}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                space.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                space.author,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (space.authorHandle.isNotEmpty)
                Text(
                  '@${space.authorHandle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                DBService.roleLabel(space.authorRole),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${space.replies.length} respuestas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canManage)
              PopupMenuButton<String>(
                tooltip: 'Administrar publicación',
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
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primaryContainer,
            ),
          ],
        ),
        onTap: () => _openDiscussion(space),
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
    String details,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: theme.colorScheme.primaryContainer,
        ),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(details)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
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
              label: 'Korucol',
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
        if (open) _loadRole();
      },
      backgroundColor: theme.colorScheme.surface,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  image: _banner == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(_banner!),
                          fit: BoxFit.cover,
                          colorFilter: const ColorFilter.mode(
                            Colors.black45,
                            BlendMode.darken,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.pop(context);
                        _openProfilePage();
                      },
                      child: Tooltip(
                        message: 'Editar perfil',
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage: _profilePhoto == null
                                  ? null
                                  : MemoryImage(_profilePhoto!),
                              child: _profilePhoto == null
                                  ? Icon(
                                      Icons.person,
                                      size: 32,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentDisplayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@$_currentUsername',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cambiar de cuenta',
                      icon: Icon(
                        Icons.swap_horiz,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _showAccountSwitcher,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Ajustes'),
                onTap: () {
                  Navigator.pop(context);
                  _openSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Mensajes'),
                subtitle: const Text('Avisos y comunicados'),
                onTap: () {
                  Navigator.pop(context);
                  _openMessages();
                },
              ),
              if (_role != DBService.roleAdmin)
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text('PQRS'),
                  subtitle: const Text('Contactar a @koruadm'),
                  onTap: () {
                    Navigator.pop(context);
                    _openSupportPage();
                  },
                ),
              if (_role == DBService.roleAdmin)
                ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('Revisión de PQRS'),
                  subtitle: const Text('Solicitudes recibidas'),
                  onTap: () {
                    Navigator.pop(context);
                    _openSupportReview();
                  },
                ),
              if (_role == DBService.roleTeacher)
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: const Text('Crear unidad'),
                  subtitle: const Text('Agregar contenido a Ruta Eko'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateCourse();
                  },
                ),
              if (_role == DBService.roleTeacher)
                ListTile(
                  leading: const Icon(Icons.library_add_outlined),
                  title: const Text('Crear lección'),
                  subtitle: const Text('Publicar en Ruta Eko o Korucol'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateLesson();
                  },
                ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        toolbarHeight: 68,
        leading: IconButton(
          tooltip: 'Abrir menú de perfil',
          onPressed: _isRoleLoaded
              ? () => _scaffoldKey.currentState?.openDrawer()
              : null,
          icon: CircleAvatar(
            radius: 17,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: _profilePhoto == null
                ? null
                : MemoryImage(_profilePhoto!),
            child: _profilePhoto == null
                ? Icon(
                    Icons.person,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) => Image.asset(
            'assets/images/korulogo.png',
            width: constraints.maxWidth,
            height: 48,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isRoleLoaded && isStudent) ...[
            AnimatedBuilder(
              animation: progressStats,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message:
                            'Racha diaria: ${progressStats.dailyStreak} días',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 20),
                            const SizedBox(width: 3),
                            Text(
                              '${progressStats.dailyStreak}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: '${progressStats.ekostrellas} ekostrellas',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 20),
                            const SizedBox(width: 3),
                            Text(
                              '${progressStats.ekostrellas}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.storefront_outlined),
              tooltip: 'Tienda de recompensas',
              onPressed: _openRewardShop,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text(
                    '¿Estás seguro de que quieres cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await DBService.logout();
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: !_isRoleLoaded
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
          : _buildKorublogSection(theme),
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
