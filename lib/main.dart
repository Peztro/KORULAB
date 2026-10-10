import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';
import 'feedback_service.dart';
import 'notification_service.dart';
import 'register_page.dart';
import 'splash_page.dart';
import 'profile_page.dart';
import 'public_profile_page.dart';
import 'support_pages.dart';
import 'teacher_courses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.init();
  runApp(const KoruApp());
}

// ─────────────────────────────────────────────
// Widget raíz de la aplicación - configura el tema, rutas y pantalla inicial
// ─────────────────────────────────────────────
class KoruApp extends StatelessWidget {
  const KoruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Korulab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          // Color principal - usado en botones, AppBar y elementos destacados
          primary: Color(0xFF2E7D32),
          // Color del texto/iconos sobre primary
          onPrimary: Color(0xFFFFFFFF),
          // Variante clara del color primario - para fondos de botones, chips, etc.
          primaryContainer: Color(0xFFA5D6A7),
          // Color del texto/iconos sobre primaryContainer
          onPrimaryContainer: Color(0xFF1B5E20),

          // Color secundario - usado en acciones alternativas y énfasis
          secondary: Color(0xFF1976D2),
          // Color del texto/iconos sobre secondary
          onSecondary: Color(0xFFFFFFFF),
          // Variante clara del color secundario
          secondaryContainer: Color(0xFFBBDEFB),
          // Color del texto/iconos sobre secondaryContainer
          onSecondaryContainer: Color(0xFF0D47A1),

          // Color terciario - usado para efectos complementarios y énfasis adicional
          tertiary: Color(0xFF8D6E63),
          // Color del texto/iconos sobre tertiary
          onTertiary: Color(0xFFFFFFFF),
          // Variante clara del color terciario
          tertiaryContainer: Color(0xFFD7CCC8),
          // Color del texto/iconos sobre tertiaryContainer
          onTertiaryContainer: Color(0xFF5D4037),

          // Color para errores y alertas
          error: Color(0xFFD32F2F),
          // Color del texto/iconos sobre error
          onError: Color(0xFFFFFFFF),
          // Variante clara para fondos de errores
          errorContainer: Color(0xFFFFCDD2),
          // Color del texto/iconos sobre errorContainer
          onErrorContainer: Color(0xFFB71C1C),

          // Color de fondo principal - usado en Scaffold y superficies
          surface: Color(0xFF122014),
          // Color del texto/iconos sobre surface
          onSurface: Color(0xFFE8F5E8),
          // Contenedor de superficie - para elementos elevados y destacados
          surfaceContainerHighest: Color(0xFF1B3C22),
          // Color secundario del texto sobre surface
          onSurfaceVariant: Color(0xFFC2E8C4),

          // Color de contorno/borde para separadores y divisores
          outline: Color(0xFF758E77),
          // Variante del contorno - para bordes más suaves
          outlineVariant: Color(0xFF3F5E44),

          // Color de sombra - para sombras y profundidad
          shadow: Color(0xFF000000),
          // Color de oscurecimiento - para overlays y modales
          scrim: Color(0xFF000000),

          // Fondo inverso - para modo claro en apps oscuras
          inverseSurface: Color(0xFFE8F5E8),
          // Texto inverso - para modo claro en apps oscuras
          onInverseSurface: Color(0xFF122014),
          // Color primario inverso - para botones en modo inverso
          inversePrimary: Color(0xFF8DD99F),
          // Tinte de la superficie - aplicado a superficies de fondo
          surfaceTint: Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/home':
            final username = settings.arguments as String?;
            if (username != null) {
              return MaterialPageRoute(
                builder: (_) => HomePage(username: username),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginPage());
          default:
            return MaterialPageRoute(builder: (_) => const SplashPage());
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
// Página de inicio de sesión - permite a los usuarios autenticarse con usuario y contraseña
// ─────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.addAccount = false});

  // Cuando es true se abre desde "Agregar otra cuenta" y permite volver atrás.
  final bool addAccount;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Estado de la página de login - gestiona la lógica de validación y autenticación
class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final username = DBService.normalizeUsername(_usernameController.text);
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validar credenciales en la base de datos
      final isValid = await DBService.validateLogin(
        username: username,
        password: password,
      );

      if (isValid) {
        // Guardar sesión
        await DBService.saveSession(username);

        if (mounted) {
          final route = MaterialPageRoute(
            builder: (_) => HomePage(username: username),
          );
          if (widget.addAccount) {
            Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
          } else {
            Navigator.of(context).pushReplacement(route);
          }
        }
      } else {
        _showSnackBar('Usuario o contraseña incorrectos');
      }
    } catch (e) {
      _showSnackBar('Error al iniciar sesión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: widget.addAccount
          ? AppBar(
              backgroundColor: theme.colorScheme.surface,
              title: const Text('Agregar otra cuenta'),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/koruicon.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido a Korulab',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Usuario único',
                  hintText: 'tu_usuario',
                  prefixText: '@',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _goToRegister,
                    child: Text(
                      'Regístrate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSwitcherSheet extends StatefulWidget {
  const _AccountSwitcherSheet({required this.onSwitch, required this.onAdd});

  final void Function(Map<String, dynamic> account) onSwitch;
  final VoidCallback onAdd;

  @override
  State<_AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<_AccountSwitcherSheet> {
  List<Map<String, dynamic>> _accounts = [];
  final Set<String> _forgettingAccounts = {};
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _reloadAccounts();
  }

  Future<void> _reloadAccounts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final accounts = await DBService.getSavedAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar las cuentas: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _forget(Map<String, dynamic> account) async {
    final username = account['username'] as String? ?? '';
    final shouldForget = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: Text(
          'Se quitará @$username de tus cuentas guardadas en este dispositivo. '
          'La cuenta y su perfil no se eliminarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar cuenta'),
          ),
        ],
      ),
    );
    if (shouldForget != true || !mounted) return;

    final accountId = account['id'] as String;
    setState(() => _forgettingAccounts.add(accountId));
    try {
      await DBService.forgetAccount(accountId);
      if (!mounted) return;
      setState(() {
        _accounts.removeWhere((saved) => saved['id'] == accountId);
        _forgettingAccounts.remove(accountId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('@$username se quitó de tus cuentas guardadas.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _forgettingAccounts.remove(accountId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar la cuenta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadError != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isLoading ? null : _reloadAccounts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Cambiar de cuenta',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoading && _accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final account in _accounts)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: account['profile_photo'] is Uint8List
                    ? MemoryImage(account['profile_photo'] as Uint8List)
                    : null,
                child: account['profile_photo'] is Uint8List
                    ? null
                    : Text(
                        ((account['display_name'] as String).trim().isNotEmpty
                                    ? account['display_name'] as String
                                    : account['username'] as String)
                                .characters
                                .firstOrNull
                                ?.toUpperCase() ??
                            '?',
                      ),
              ),
              title: Text(
                (account['display_name'] as String).trim().isNotEmpty
                    ? account['display_name'] as String
                    : '@${account['username']}',
              ),
              subtitle: Text('@${account['username']}'),
              trailing: account['is_current'] == true
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : IconButton(
                      tooltip: 'Quitar cuenta guardada',
                      icon: _forgettingAccounts.contains(account['id'])
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close),
                      onPressed: _forgettingAccounts.contains(account['id'])
                          ? null
                          : () => _forget(account),
                    ),
              onTap:
                  account['is_current'] == true ||
                      _forgettingAccounts.contains(account['id'])
                  ? null
                  : () => widget.onSwitch(account),
            ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: const Text('Agregar otra cuenta'),
            onTap: widget.onAdd,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MODELOS DE DATOS
// ─────────────────────────────────────────────

// Convierte un id de progreso ("curso:actividad") en un nombre legible.
String describeActivityId(String id) {
  final parts = id.split(':');
  if (parts.length == 2) {
    final c = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    if (c != null &&
        a != null &&
        c < courses.length &&
        a < courses[c].activities.length) {
      return '${courses[c].title} · ${courses[c].activities[a].title}';
    }
  }
  return id;
}

// Representa un curso con su título, ícono y lista de actividades de aprendizaje
class Course {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<LessonActivity> activities;

  Course({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activities,
  });
}

// Clase abstracta base para todas las actividades educativas (quiz, matching, memory, etc)
abstract class LessonActivity {
  final String title;
  final ActivityType type;
  const LessonActivity({required this.title, required this.type});
}

enum ActivityType { quiz, matching, memory, fillBlank, sorting }

// Actividad de tipo cuestionario múltiple - los usuarios responden preguntas seleccionando opciones
class QuizActivity extends LessonActivity {
  final List<Question> questions;
  const QuizActivity({required super.title, required this.questions})
    : super(type: ActivityType.quiz);
}

// Representa una pregunta individual con opciones y respuesta correcta
class Question {
  final String prompt;
  final List<String> options;
  final int answerIndex;
  const Question({
    required this.prompt,
    required this.options,
    required this.answerIndex,
  });
}

// Actividad de relacionar - los usuarios emparejan términos con sus definiciones
class MatchingActivity extends LessonActivity {
  final List<MatchPair> pairs;
  const MatchingActivity({required super.title, required this.pairs})
    : super(type: ActivityType.matching);
}

// Representa un par de término y definición para actividades de relacionar
class MatchPair {
  final String term;
  final String definition;
  const MatchPair({required this.term, required this.definition});
}

// Actividad de memoria - juego tipo memorama para recordar parejas de elementos
class MemoryActivity extends LessonActivity {
  final List<MemoryCard> cards;
  const MemoryActivity({required super.title, required this.cards})
    : super(type: ActivityType.memory);
}

// Representa una tarjeta individual en el juego de memoria con emoji y etiqueta
class MemoryCard {
  final String emoji;
  final String label;
  const MemoryCard({required this.emoji, required this.label});
}

// Actividad de completar espacios - los usuarios rellenan los blancos en oraciones
class FillBlankActivity extends LessonActivity {
  final List<FillBlankQuestion> questions;
  const FillBlankActivity({required super.title, required this.questions})
    : super(type: ActivityType.fillBlank);
}

// Representa una pregunta de espacios en blanco con opciones de respuesta
class FillBlankQuestion {
  final String sentence; // uses ___ for blank
  final List<String> options;
  final int answerIndex;
  const FillBlankQuestion({
    required this.sentence,
    required this.options,
    required this.answerIndex,
  });
}

// Actividad de ordenamiento - los usuarios deben ordenar elementos en la secuencia correcta
class SortingActivity extends LessonActivity {
  final String instruction;
  final List<String> correctOrder;
  const SortingActivity({
    required super.title,
    required this.instruction,
    required this.correctOrder,
  }) : super(type: ActivityType.sorting);
}

// ─────────────────────────────────────────────
//  COURSE DATA
// ─────────────────────────────────────────────
final courses = <Course>[
  Course(
    title: 'Energía renovable',
    subtitle: 'Fuentes limpias y sostenibles',
    icon: Icons.bolt,
    activities: [
      QuizActivity(
        title: 'Quiz: Fuentes de energía',
        questions: [
          const Question(
            prompt: '¿Cuál de estas es una fuente de energía renovable?',
            options: ['Sol', 'Petróleo', 'Carbón', 'Gas natural'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué produce la energía solar?',
            options: ['Electricidad', 'Plástico', 'Carbón', 'Gasolina'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es una ventaja de la energía eólica?',
            options: [
              'No emite CO₂',
              'Consume agua',
              'Usa combustibles fósiles',
              'Contamina el aire',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Energía y fuente',
        pairs: const [
          MatchPair(term: 'Solar', definition: 'Energía del sol'),
          MatchPair(term: 'Eólica', definition: 'Energía del viento'),
          MatchPair(term: 'Hidráulica', definition: 'Energía del agua'),
          MatchPair(term: 'Geotérmica', definition: 'Calor de la Tierra'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Iconos de energía',
        cards: const [
          MemoryCard(emoji: '☀️', label: 'Solar'),
          MemoryCard(emoji: '💨', label: 'Eólica'),
          MemoryCard(emoji: '💧', label: 'Hidráulica'),
          MemoryCard(emoji: '🌋', label: 'Geotérmica'),
          MemoryCard(emoji: '🌊', label: 'Mareomotriz'),
          MemoryCard(emoji: '🔋', label: 'Almacenada'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa la oración',
        questions: [
          const FillBlankQuestion(
            sentence:
                'Los paneles ___ convierten la luz solar en electricidad.',
            options: ['solares', 'eólicos', 'marinos', 'nucleares'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'La energía ___ se obtiene del movimiento del viento.',
            options: ['eólica', 'solar', 'hidráulica', 'térmica'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Las ___ son estructuras que generan energía eólica.',
            options: ['turbinas', 'baterías', 'pilas', 'chimeneas'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena el proceso solar',
        instruction:
            'Ordena los pasos para generar electricidad solar correctamente:',
        correctOrder: [
          '☀️ El sol emite luz',
          '🔆 Los paneles absorben la luz',
          '⚡ Se genera electricidad',
          '🔋 Se almacena la energía',
          '🏠 Llega a los hogares',
        ],
      ),
    ],
  ),
  Course(
    title: 'Reciclaje',
    subtitle: 'Reduce, reutiliza y recicla',
    icon: Icons.recycling,
    activities: [
      QuizActivity(
        title: 'Quiz: ¿Qué reciclar?',
        questions: [
          const Question(
            prompt: '¿Qué material se puede reciclar en el contenedor azul?',
            options: [
              'Papel y cartón',
              'Restos de comida',
              'Baterías',
              'Vidrio roto',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es una acción para reducir residuos?',
            options: [
              'Usar bolsas reutilizables',
              'Comprar plástico de un solo uso',
              'Tirar todo junto',
              'Usar más servilletas',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿En qué contenedor va el vidrio?',
            options: ['Verde', 'Azul', 'Amarillo', 'Gris'],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Residuo y contenedor',
        pairs: const [
          MatchPair(term: '📄 Papel', definition: 'Contenedor azul'),
          MatchPair(term: '🍶 Vidrio', definition: 'Contenedor verde'),
          MatchPair(term: '🥤 Plástico', definition: 'Contenedor amarillo'),
          MatchPair(term: '🍌 Orgánico', definition: 'Contenedor marrón'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Materiales reciclables',
        cards: const [
          MemoryCard(emoji: '📰', label: 'Periódico'),
          MemoryCard(emoji: '🥛', label: 'Botella'),
          MemoryCard(emoji: '📦', label: 'Cartón'),
          MemoryCard(emoji: '🥫', label: 'Lata'),
          MemoryCard(emoji: '🍾', label: 'Vidrio'),
          MemoryCard(emoji: '👕', label: 'Ropa usada'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre reciclaje',
        questions: [
          const FillBlankQuestion(
            sentence: 'Las tres R del reciclaje son: reducir, ___ y reciclar.',
            options: ['reutilizar', 'rechazar', 'reparar', 'renovar'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El plástico tarda cientos de años en ___ .',
            options: ['degradarse', 'crecer', 'florecer', 'moverse'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena el ciclo del reciclaje',
        instruction: 'Pon en orden correcto el proceso de reciclaje:',
        correctOrder: [
          '🗑️ Separar los residuos',
          '🚛 Recoger el material',
          '🏭 Llevar a la planta',
          '♻️ Procesar y transformar',
          '🛍️ Crear nuevos productos',
        ],
      ),
    ],
  ),
  Course(
    title: 'Hábitat natural',
    subtitle: 'Bosques, animales y agua',
    icon: Icons.nature,
    activities: [
      QuizActivity(
        title: 'Quiz: Ecosistemas',
        questions: [
          const Question(
            prompt: '¿Por qué son importantes los bosques?',
            options: [
              'Producen oxígeno',
              'Generan basura',
              'Aumentan la lluvia ácida',
              'Contaminan el agua',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué animal vive en el bosque?',
            options: ['Zorro', 'Tiburón', 'Camello', 'Pingüino'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué proceso realizan las plantas para alimentarse?',
            options: [
              'Fotosíntesis',
              'Respiración',
              'Digestión',
              'Evaporación',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Animal y hábitat',
        pairs: const [
          MatchPair(term: '🦁 León', definition: 'Sabana africana'),
          MatchPair(term: '🐧 Pingüino', definition: 'Polo sur'),
          MatchPair(term: '🐠 Pez payaso', definition: 'Arrecife de coral'),
          MatchPair(term: '🦜 Guacamaya', definition: 'Selva tropical'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Flora y fauna',
        cards: const [
          MemoryCard(emoji: '🌳', label: 'Árbol'),
          MemoryCard(emoji: '🦋', label: 'Mariposa'),
          MemoryCard(emoji: '🐸', label: 'Rana'),
          MemoryCard(emoji: '🌺', label: 'Flor'),
          MemoryCard(emoji: '🦊', label: 'Zorro'),
          MemoryCard(emoji: '🍄', label: 'Hongo'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre naturaleza',
        questions: [
          const FillBlankQuestion(
            sentence:
                'Los ___ son los pulmones del planeta porque producen oxígeno.',
            options: ['bosques', 'desiertos', 'océanos', 'volcanes'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'La ___ es el proceso por la que el agua pasa de líquido a vapor.',
            options: ['evaporación', 'condensación', 'fotosíntesis', 'erosión'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Los ___ de coral son considerados la selva del mar.',
            options: ['arrecifes', 'glaciares', 'volcanes', 'ríos'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena la cadena alimentaria',
        instruction: 'Ordena la cadena alimentaria del bosque:',
        correctOrder: [
          '☀️ Sol (energía)',
          '🌿 Plantas (productores)',
          '🐛 Insecto (consumidor primario)',
          '🐸 Rana (consumidor secundario)',
          '🦅 Águila (consumidor terciario)',
        ],
      ),
    ],
  ),
  Course(
    title: 'Contaminación del aire',
    subtitle: 'Causas, efectos y soluciones',
    icon: Icons.cloud,
    activities: [
      QuizActivity(
        title: 'Quiz: Contaminación atmosférica',
        questions: [
          const Question(
            prompt:
                '¿Cuál es la principal fuente de contaminación del aire en las ciudades?',
            options: ['Vehículos', 'Árboles', 'Lluvia', 'Océanos'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué gas es responsable del efecto invernadero?',
            options: ['CO₂', 'Oxígeno', 'Nitrógeno', 'Helio'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es un efecto de la contaminación del aire?',
            options: [
              'Enfermedades respiratorias',
              'Más diversidad animal',
              'Mayor producción agrícola',
              'Aumento de ozono',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Contaminante y fuente',
        pairs: const [
          MatchPair(
            term: 'CO₂',
            definition: 'Combustión de combustibles fósiles',
          ),
          MatchPair(
            term: 'Ozono',
            definition: 'Contaminación por reacciones químicas',
          ),
          MatchPair(term: 'Humo', definition: 'Fábricas e industrias'),
          MatchPair(term: 'Polvo', definition: 'Erosión del suelo'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Contaminantes del aire',
        cards: const [
          MemoryCard(emoji: '🚗', label: 'Vehículos'),
          MemoryCard(emoji: '🏭', label: 'Industria'),
          MemoryCard(emoji: '💨', label: 'Emisiones'),
          MemoryCard(emoji: '😷', label: 'Salud'),
          MemoryCard(emoji: '🌫️', label: 'Smog'),
          MemoryCard(emoji: '☁️', label: 'Aire'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre aire limpio',
        questions: [
          const FillBlankQuestion(
            sentence:
                'La ___ es la principal causa de la mala calidad del aire en ciudades.',
            options: ['contaminación vehicular', 'lluvia', 'nieve', 'neblina'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'El ___ es un gas que forma parte del efecto invernadero.',
            options: ['dióxido de carbono', 'oxígeno', 'nitrógeno', 'helio'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'La contaminación del aire causa problemas en el sistema ___.',
            options: ['respiratorio', 'digestivo', 'nervioso', 'óseo'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena soluciones de aire limpio',
        instruction: 'Ordena las medidas para mejorar la calidad del aire:',
        correctOrder: [
          '🚗 Reducir uso de vehículos',
          '🌳 Plantar árboles',
          '🏭 Controlar emisiones industriales',
          '♻️ Usar energías limpias',
          '🌍 Concientizar a la población',
        ],
      ),
    ],
  ),
  Course(
    title: 'Contaminación del agua',
    subtitle: 'Protegiendo nuestros recursos hídricos',
    icon: Icons.water,
    activities: [
      QuizActivity(
        title: 'Quiz: Agua limpia',
        questions: [
          const Question(
            prompt: '¿Cuál es la mayor fuente de contaminación del agua?',
            options: ['Residuos industriales', 'Lluvia', 'Peces', 'Plantas'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué plástico es especialmente dañino para los océanos?',
            options: ['Microplásticos', 'Vidrio', 'Metal', 'Papel'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es un efecto del agua contaminada?',
            options: [
              'Muerte de peces y plantas',
              'Mayor producción de oxígeno',
              'Mejor sabor del agua',
              'Aumento de sales minerales',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Contaminante hídrico',
        pairs: const [
          MatchPair(term: 'Petróleo', definition: 'Derrames en océanos'),
          MatchPair(term: 'Plástico', definition: 'Botellas y bolsas'),
          MatchPair(term: 'Químicos', definition: 'Industrias y agricultura'),
          MatchPair(term: 'Metales pesados', definition: 'Fábricas'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Agua y contaminación',
        cards: const [
          MemoryCard(emoji: '💧', label: 'Agua'),
          MemoryCard(emoji: '🌊', label: 'Océano'),
          MemoryCard(emoji: '🐟', label: 'Pez'),
          MemoryCard(emoji: '🚫', label: 'Contaminación'),
          MemoryCard(emoji: '🧪', label: 'Químicos'),
          MemoryCard(emoji: '🌍', label: 'Planeta'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre agua limpia',
        questions: [
          const FillBlankQuestion(
            sentence: 'Los ___ son fragmentos pequeños de plástico en el agua.',
            options: ['microplásticos', 'cristales', 'granos', 'cristalinos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'La contaminación del agua afecta principalmente a los ___.',
            options: ['organismos acuáticos', 'árboles', 'pájaros', 'insectos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: '7 millones de ___ llegan a los océanos cada año.',
            options: ['toneladas de plástico', 'peces', 'algas', 'corales'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena protección del agua',
        instruction: 'Ordena acciones para proteger el agua limpia:',
        correctOrder: [
          '🚫 Evitar lanzar residuos',
          '♻️ Reutilizar el agua',
          '🔧 Reparar fugas',
          '🌱 Proteger ecosistemas acuáticos',
          '🌍 Educar sobre su cuidado',
        ],
      ),
    ],
  ),
  Course(
    title: 'Contaminación del suelo',
    subtitle: 'Preservando la tierra que nos sostiene',
    icon: Icons.landscape,
    activities: [
      QuizActivity(
        title: 'Quiz: Suelo saludable',
        questions: [
          const Question(
            prompt:
                '¿Cuánto tiempo tarda un plástico en degradarse en el suelo?',
            options: [
              'Más de 500 años',
              '1 año',
              '10 años',
              'Nunca se degrada',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué producto químico es muy dañino para el suelo?',
            options: ['Pesticidas', 'Agua', 'Arena', 'Sal'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es un efecto de la contaminación del suelo?',
            options: [
              'Reducción de nutrientes',
              'Aumento de producción',
              'Mejor retención de agua',
              'Mayor fertilidad',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Contaminante del suelo',
        pairs: const [
          MatchPair(term: 'Plástico', definition: 'No se degrada fácilmente'),
          MatchPair(term: 'Pesticidas', definition: 'Afectan cultivos'),
          MatchPair(term: 'Metales pesados', definition: 'Tóxicos'),
          MatchPair(term: 'Residuos', definition: 'Desechos diversos'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Suelo limpio',
        cards: const [
          MemoryCard(emoji: '🌱', label: 'Planta'),
          MemoryCard(emoji: '🚜', label: 'Agricultura'),
          MemoryCard(emoji: '🌾', label: 'Cultivo'),
          MemoryCard(emoji: '⚠️', label: 'Peligro'),
          MemoryCard(emoji: '♻️', label: 'Recuperar'),
          MemoryCard(emoji: '🌍', label: 'Tierra'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre suelo limpio',
        questions: [
          const FillBlankQuestion(
            sentence: 'El ___ es un método para restaurar suelos contaminados.',
            options: ['compostaje', 'riego', 'secado', 'congelación'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'Los ___ dañan la estructura del suelo y matan microorganismos.',
            options: ['pesticidas', 'abonos', 'semillas', 'riegos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El suelo fértil es esencial para la ___ mundial.',
            options: [
              'producción de alimentos',
              'construcción',
              'minería',
              'turismo',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena recuperación del suelo',
        instruction: 'Ordena pasos para recuperar suelo contaminado:',
        correctOrder: [
          '📊 Analizar contaminantes',
          '🔍 Identificar fuente',
          '🔧 Aplicar remediación',
          '🌱 Plantar vegetación',
          '✅ Monitorear recuperación',
        ],
      ),
    ],
  ),
  Course(
    title: 'Reciclaje inteligente',
    subtitle: 'Clasificación avanzada de residuos',
    icon: Icons.auto_awesome,
    activities: [
      QuizActivity(
        title: 'Quiz: Reciclaje avanzado',
        questions: [
          const Question(
            prompt: '¿Qué es el reciclaje inteligente?',
            options: [
              'Separar residuos por tipo',
              'Tirar todo junto',
              'Quemar plástico',
              'Enterrar basura',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué se puede reciclar infinitas veces?',
            options: ['Vidrio', 'Plástico', 'Papel', 'Comida'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es el símbolo de reciclaje universal?',
            options: [
              'Tres flechas en triángulo',
              'Círculo verde',
              'Mano abierta',
              'Hoja verde',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Material y reciclaje',
        pairs: const [
          MatchPair(term: 'Papel', definition: 'Reciclable 5-7 veces'),
          MatchPair(term: 'Vidrio', definition: 'Infinitamente reciclable'),
          MatchPair(term: 'Metal', definition: 'Muy valioso para reciclar'),
          MatchPair(term: 'Plástico PET', definition: 'Forma botellas nuevas'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Reciclaje inteligente',
        cards: const [
          MemoryCard(emoji: '♻️', label: 'Reciclar'),
          MemoryCard(emoji: '📄', label: 'Papel'),
          MemoryCard(emoji: '🔧', label: 'Metal'),
          MemoryCard(emoji: '🏭', label: 'Planta'),
          MemoryCard(emoji: '💰', label: 'Valor'),
          MemoryCard(emoji: '🌍', label: 'Planeta'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre reciclaje inteligente',
        questions: [
          const FillBlankQuestion(
            sentence:
                'El ___ puede ser reciclado infinitas veces sin perder calidad.',
            options: ['vidrio', 'plástico', 'papel', 'cartón'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Los códigos de ___ indican qué tipo de plástico es.',
            options: ['reciclaje', 'barras', 'color', 'peso'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'Reciclar ___ ahorra más energía que reciclar otros materiales.',
            options: ['aluminio', 'papel', 'vidrio', 'cartón'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena proceso de reciclaje inteligente',
        instruction: 'Ordena el proceso completo de reciclaje:',
        correctOrder: [
          '🏠 Separar en casa',
          '🚛 Recolección selectiva',
          '🏭 Transporte a planta',
          '🔄 Clasificación automática',
          '♻️ Transformación en nuevo producto',
        ],
      ),
    ],
  ),
  Course(
    title: 'Cambio climático',
    subtitle: 'Causas, consecuencias y acciones',
    icon: Icons.thermostat,
    activities: [
      QuizActivity(
        title: 'Quiz: Clima en cambio',
        questions: [
          const Question(
            prompt: '¿Cuál es la principal causa del cambio climático?',
            options: [
              'Emisiones de gases de efecto invernadero',
              'Rotación de la Tierra',
              'Lluvia',
              'Actividad volcánica',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt:
                '¿Cuánto ha aumentado la temperatura global en el último siglo?',
            options: ['Aproximadamente 1°C', 'Nada', '5°C', '10°C'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué consecuencia tiene el cambio climático?',
            options: [
              'Aumento del nivel del mar',
              'Desaparición de montañas',
              'Menor radiación solar',
              'Menos días soleados',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Causa y efecto climático',
        pairs: const [
          MatchPair(term: 'CO₂', definition: 'Calienta la atmósfera'),
          MatchPair(term: 'Metano', definition: 'Gas de efecto invernadero'),
          MatchPair(
            term: 'Deforestación',
            definition: 'Menos árboles = más CO₂',
          ),
          MatchPair(term: 'Industria', definition: 'Emite muchos gases'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Cambio climático',
        cards: const [
          MemoryCard(emoji: '🌡️', label: 'Calor'),
          MemoryCard(emoji: '🌍', label: 'Tierra'),
          MemoryCard(emoji: '❄️', label: 'Hielo'),
          MemoryCard(emoji: '🌪️', label: 'Tormenta'),
          MemoryCard(emoji: '🌊', label: 'Mar'),
          MemoryCard(emoji: '☀️', label: 'Sol'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre cambio climático',
        questions: [
          const FillBlankQuestion(
            sentence:
                'El ___ es el principal causante del calentamiento global.',
            options: ['dióxido de carbono', 'oxígeno', 'nitrógeno', 'helio'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El derretimiento de los ___ aumenta el nivel del mar.',
            options: ['glaciares', 'volcanes', 'montañas', 'ríos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'Los cambios en el ___ afectan la agricultura y la biodiversidad.',
            options: ['clima', 'terreno', 'color', 'tamaño'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena soluciones climáticas',
        instruction: 'Ordena acciones para combatir el cambio climático:',
        correctOrder: [
          '🚗 Reducir emisiones',
          '🌳 Plantar bosques',
          '⚡ Usar energía renovable',
          '🏭 Modernizar industrias',
          '🌍 Acuerdos internacionales',
        ],
      ),
    ],
  ),
  Course(
    title: 'Consumo responsable',
    subtitle: 'Decisiones ecológicas en el día a día',
    icon: Icons.shopping_bag,
    activities: [
      QuizActivity(
        title: 'Quiz: Consumo consciente',
        questions: [
          const Question(
            prompt: '¿Qué significa consumo responsable?',
            options: [
              'Comprar solo lo necesario',
              'Comprar todo lo que ves',
              'No comprar nada',
              'Comprar por comprar',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es la mejor opción ecológica?',
            options: [
              'Comprar productos locales',
              'Importar de lejos',
              'Comprar mucha cantidad',
              'Elegir empaques grandes',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es un impacto del exceso de consumo?',
            options: [
              'Generación de residuos',
              'Menor contaminación',
              'Más espacio verde',
              'Mejor biodiversidad',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Producto y impacto',
        pairs: const [
          MatchPair(
            term: 'Ropa de segunda mano',
            definition: 'Reduce residuos',
          ),
          MatchPair(term: 'Productos locales', definition: 'Menor transporte'),
          MatchPair(
            term: 'Empaques biodegradables',
            definition: 'Menos contaminación',
          ),
          MatchPair(term: 'Duradera', definition: 'Menos desecho'),
        ],
      ),
      MemoryActivity(
        title: 'Memoria: Consumo inteligente',
        cards: const [
          MemoryCard(emoji: '🛍️', label: 'Compra'),
          MemoryCard(emoji: '💭', label: 'Pensar'),
          MemoryCard(emoji: '♻️', label: 'Reciclar'),
          MemoryCard(emoji: '🌱', label: 'Eco'),
          MemoryCard(emoji: '💚', label: 'Amor'),
          MemoryCard(emoji: '🌍', label: 'Planeta'),
        ],
      ),
      FillBlankActivity(
        title: 'Completa sobre consumo responsable',
        questions: [
          const FillBlankQuestion(
            sentence: 'Antes de comprar, pregúntate si realmente lo ___.',
            options: ['necesitas', 'quieres', 'ves', 'te agrada'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Los productos ___ tienen menor huella de carbono.',
            options: ['locales', 'importados', 'empacados', 'costosos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'La moda ___ es una alternativa al consumo desmedido.',
            options: ['sostenible', 'costosa', 'rápida', 'online'],
            answerIndex: 0,
          ),
        ],
      ),
      SortingActivity(
        title: 'Ordena hábitos de consumo responsable',
        instruction: 'Ordena pasos para ser un consumidor consciente:',
        correctOrder: [
          '💭 Reflexionar antes de comprar',
          '📍 Elegir productos locales',
          '♻️ Preferir lo reutilizable',
          '🏪 Apoyar comercio responsable',
          '📣 Educar a otros',
        ],
      ),
    ],
  ),
];

// ─────────────────────────────────────────────
//  SEGUIMIENTO DE PROGRESO
// ─────────────────────────────────────────────

// Gestor de estadísticas del usuario - rastrear respuestas correctas, lecciones completadas, racha diaria y ekostrellas
class ProgressStats extends ChangeNotifier {
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _completedLessons = 0;
  int _dailyStreak = 0;
  int _ekostrellas = 0;
  int _hintCredits = 0;
  int _streakProtectors = 0;
  int _starMultipliers = 0;
  int _secondChances = 0;
  DateTime? _lastLessonDate;
  String? _progressUsername;
  bool _courseProgressLoaded = false;
  final Set<String> _completedActivityIds = {};

  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  int get completedLessons => _completedLessons;
  int get dailyStreak => _dailyStreak;
  int get ekostrellas => _ekostrellas;
  int get hintCredits => _hintCredits;
  int get streakProtectors => _streakProtectors;
  int get starMultipliers => _starMultipliers;
  int get secondChances => _secondChances;
  int get completedActivities => _completedActivityIds.length;
  bool get isCourseProgressLoaded => _courseProgressLoaded;
  int get totalLessons =>
      courses.fold<int>(0, (sum, course) => sum + course.activities.length);

  int get accuracyPercent =>
      _totalAnswers > 0 ? (_correctAnswers * 100 ~/ _totalAnswers) : 0;
  double get accuracyRatio =>
      _totalAnswers > 0 ? _correctAnswers / _totalAnswers : 0.0;

  Future<int> loadCourseProgress(String username) async {
    if (_progressUsername == username) return 0;
    _progressUsername = username;
    _courseProgressLoaded = false;
    _completedActivityIds.clear();
    _correctAnswers = 0;
    _totalAnswers = 0;
    _completedLessons = 0;
    _ekostrellas = 0;
    _dailyStreak = 0;
    _hintCredits = 0;
    _streakProtectors = 0;
    _starMultipliers = 0;
    _secondChances = 0;
    _lastLessonDate = null;
    notifyListeners();

    var activatedProtectors = 0;
    try {
      await DBService.pullProgress(username);
      final preferences = await SharedPreferences.getInstance();
      if (_progressUsername == username) {
        _completedActivityIds.addAll(
          preferences.getStringList('korulab_course_progress_$username') ?? [],
        );
        _ekostrellas = preferences.getInt('korulab_eko_stars_$username') ?? 0;
        _correctAnswers =
            preferences.getInt('korulab_correct_answers_$username') ?? 0;
        _totalAnswers =
            preferences.getInt('korulab_total_answers_$username') ?? 0;
        _completedLessons =
            preferences.getInt('korulab_completed_lessons_$username') ?? 0;
        _dailyStreak =
            preferences.getInt('korulab_daily_streak_$username') ?? 0;
        _hintCredits =
            preferences.getInt('korulab_hint_credits_$username') ?? 0;
        _streakProtectors =
            preferences.getInt('korulab_streak_protectors_$username') ?? 0;
        _starMultipliers =
            preferences.getInt('korulab_star_multipliers_$username') ?? 0;
        _secondChances =
            preferences.getInt('korulab_second_chances_$username') ?? 0;
        final savedDate = preferences.getString(
          'korulab_last_lesson_$username',
        );
        _lastLessonDate = savedDate == null
            ? null
            : DateTime.tryParse(savedDate);

        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final hadMissedDays =
            _lastLessonDate != null &&
            todayDate.difference(_lastLessonDate!).inDays > 1;
        activatedProtectors = _activateMissedDayProtectors(todayDate);
        if (hadMissedDays) await _saveUserProgress();
      }
    } catch (_) {
    } finally {
      if (_progressUsername == username) {
        _courseProgressLoaded = true;
        notifyListeners();
      }
    }
    return activatedProtectors;
  }

  int _activateMissedDayProtectors(DateTime today) {
    final lastLesson = _lastLessonDate;
    if (lastLesson == null) return 0;

    final missedDays = today.difference(lastLesson).inDays - 1;
    if (missedDays <= 0) return 0;

    final activated = _streakProtectors < missedDays
        ? _streakProtectors
        : missedDays;
    _streakProtectors -= activated;
    if (activated == missedDays) {
      _dailyStreak += missedDays;
    } else {
      _dailyStreak = 0;
    }
    _lastLessonDate = today.subtract(const Duration(days: 1));
    return activated;
  }

  bool isCourseUnlocked(int courseIndex) {
    for (var index = 0; index < courseIndex; index++) {
      for (
        var activityIndex = 0;
        activityIndex < courses[index].activities.length;
        activityIndex++
      ) {
        if (!_completedActivityIds.contains('$index:$activityIndex')) {
          return false;
        }
      }
    }
    return true;
  }

  // Actividades de cursos de profesores -> id de progreso.
  final Map<LessonActivity, String> customActivityIds = {};

  bool isActivityUnlocked(LessonActivity activity) {
    final customId = customActivityIds[activity];
    if (customId != null) {
      final parts = customId.split(':');
      if (parts.length != 2) return true;
      final targetCourse = int.tryParse(parts[0]);
      final targetActivity = int.tryParse(parts[1]);
      if (targetCourse == null ||
          targetActivity == null ||
          targetCourse >= courses.length) {
        return true;
      }
      for (var courseIndex = 0; courseIndex <= targetCourse; courseIndex++) {
        final end = courseIndex == targetCourse
            ? targetActivity
            : courses[courseIndex].activities.length;
        for (var activityIndex = 0; activityIndex < end; activityIndex++) {
          if (!_completedActivityIds.contains('$courseIndex:$activityIndex')) {
            return false;
          }
        }
      }
      return true;
    }
    for (var courseIndex = 0; courseIndex < courses.length; courseIndex++) {
      for (
        var activityIndex = 0;
        activityIndex < courses[courseIndex].activities.length;
        activityIndex++
      ) {
        final currentActivity = courses[courseIndex].activities[activityIndex];
        if (identical(currentActivity, activity)) return true;
        if (!_completedActivityIds.contains('$courseIndex:$activityIndex')) {
          return false;
        }
      }
    }
    return false;
  }

  String _activityProgressId(LessonActivity activity) {
    final customId = customActivityIds[activity];
    if (customId != null) return customId;
    for (var courseIndex = 0; courseIndex < courses.length; courseIndex++) {
      final activityIndex = courses[courseIndex].activities.indexOf(activity);
      if (activityIndex >= 0) return '$courseIndex:$activityIndex';
    }
    return activity.title;
  }

  Future<void> _saveUserProgress() async {
    final username = _progressUsername;
    if (username == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        'korulab_course_progress_$username',
        _completedActivityIds.toList(),
      );
      await preferences.setInt(
        'korulab_correct_answers_$username',
        _correctAnswers,
      );
      await preferences.setInt(
        'korulab_total_answers_$username',
        _totalAnswers,
      );
      await preferences.setInt(
        'korulab_completed_lessons_$username',
        _completedLessons,
      );
      await preferences.setInt('korulab_eko_stars_$username', _ekostrellas);
      await preferences.setInt('korulab_daily_streak_$username', _dailyStreak);
      await preferences.setInt('korulab_hint_credits_$username', _hintCredits);
      await preferences.setInt(
        'korulab_streak_protectors_$username',
        _streakProtectors,
      );
      await preferences.setInt(
        'korulab_star_multipliers_$username',
        _starMultipliers,
      );
      await preferences.setInt(
        'korulab_second_chances_$username',
        _secondChances,
      );
      final lastLesson = _lastLessonDate;
      if (lastLesson != null) {
        await preferences.setString(
          'korulab_last_lesson_$username',
          lastLesson.toIso8601String(),
        );
      }
    } catch (_) {}
    unawaited(DBService.pushProgress(username));
  }

  bool buyHint() {
    if (!_courseProgressLoaded || _ekostrellas < RewardShopPage.hintPrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.hintPrice;
    _hintCredits++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool buyStreakProtector() {
    if (!_courseProgressLoaded ||
        _ekostrellas < RewardShopPage.streakProtectorPrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.streakProtectorPrice;
    _streakProtectors++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool buyStarMultiplier() {
    if (!_courseProgressLoaded ||
        _ekostrellas < RewardShopPage.starMultiplierPrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.starMultiplierPrice;
    _starMultipliers++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool buySecondChance() {
    if (!_courseProgressLoaded ||
        _ekostrellas < RewardShopPage.secondChancePrice) {
      return false;
    }
    _ekostrellas -= RewardShopPage.secondChancePrice;
    _secondChances++;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool useHint() {
    if (_hintCredits <= 0) return false;
    _hintCredits--;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool useSecondChance() {
    if (_secondChances <= 0) return false;
    _secondChances--;
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  bool isTeacherLessonCompleted(int lessonId) {
    return _completedActivityIds.contains('teacher:$lessonId');
  }

  bool isActivityCompleted(LessonActivity activity) {
    return _completedActivityIds.contains(_activityProgressId(activity));
  }

  bool completeTeacherLesson(int lessonId) {
    if (!_courseProgressLoaded ||
        !_completedActivityIds.add('teacher:$lessonId')) {
      return false;
    }
    _recordLessonDay();
    _correctAnswers++;
    _totalAnswers++;
    _completedLessons++;
    if (_starMultipliers > 0) {
      _starMultipliers--;
      _ekostrellas += 100;
    } else {
      _ekostrellas += 50;
    }
    unawaited(_saveUserProgress());
    notifyListeners();
    return true;
  }

  void _recordLessonDay() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (_lastLessonDate == todayDate) return;
    if (_lastLessonDate == null) {
      _dailyStreak = 1;
    } else {
      _activateMissedDayProtectors(todayDate);
      final daysSinceLastLesson = todayDate.difference(_lastLessonDate!).inDays;
      _dailyStreak = daysSinceLastLesson == 1 && _dailyStreak > 0
          ? _dailyStreak + 1
          : 1;
    }
    _lastLessonDate = todayDate;
  }

  void reportLessonResult(
    int correct,
    int total, {
    required LessonActivity activity,
    int incorrectAttempts = 0,
  }) {
    _recordLessonDay();
    _correctAnswers += correct;
    _totalAnswers += correct + incorrectAttempts;
    _completedLessons += 1;
    final earnedStars = total > 0 ? (correct * 50 ~/ total) : 0;
    if (_starMultipliers > 0) {
      _starMultipliers--;
      _ekostrellas += earnedStars * 2;
    } else {
      _ekostrellas += earnedStars;
    }
    _completedActivityIds.add(_activityProgressId(activity));
    unawaited(_saveUserProgress());
    notifyListeners();
  }
}

final progressStats = ProgressStats();

class RewardShopPage extends StatefulWidget {
  static const int hintPrice = 25;
  static const int streakProtectorPrice = 100;
  static const int starMultiplierPrice = 75;
  static const int secondChancePrice = 40;

  final String username;

  const RewardShopPage({super.key, required this.username});

  @override
  State<RewardShopPage> createState() => _RewardShopPageState();
}

class _RewardShopPageState extends State<RewardShopPage> {
  @override
  void initState() {
    super.initState();
    progressStats.loadCourseProgress(widget.username);
  }

  void _showPurchaseResult(bool purchased, String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          purchased
              ? '$itemName añadido a tu inventario.'
              : 'No tienes suficientes ekostrellas.',
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required IconData icon,
    required String title,
    required String description,
    required int price,
    required int owned,
    required VoidCallback onPurchase,
  }) {
    final theme = Theme.of(context);
    final canAfford = progressStats.ekostrellas >= price;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.18),
                  child: Icon(icon, color: theme.colorScheme.primaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text('Tienes $owned'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canAfford ? onPurchase : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text('Canjear por $price ekostrellas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tienda de recompensas'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) {
          if (!progressStats.isCourseProgressLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${progressStats.ekostrellas} ekostrellas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Canjea tus estrellas por ayudas para las lecciones y tu racha.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _buildProductCard(
                icon: Icons.lightbulb_outline,
                title: 'Pista para una pregunta',
                description:
                    'Elimina una opción incorrecta en quizzes y actividades de completar.',
                price: RewardShopPage.hintPrice,
                owned: progressStats.hintCredits,
                onPurchase: () =>
                    _showPurchaseResult(progressStats.buyHint(), 'Pista'),
              ),
              _buildProductCard(
                icon: Icons.stars_outlined,
                title: 'Doble de ekostrellas',
                description:
                    'Duplica las ekostrellas de la próxima actividad que completes.',
                price: RewardShopPage.starMultiplierPrice,
                owned: progressStats.starMultipliers,
                onPurchase: () => _showPurchaseResult(
                  progressStats.buyStarMultiplier(),
                  'Doble de ekostrellas',
                ),
              ),
              _buildProductCard(
                icon: Icons.replay,
                title: 'Segundo intento',
                description:
                    'Después de una respuesta incorrecta, permite elegir de nuevo en quizzes y ejercicios de completar.',
                price: RewardShopPage.secondChancePrice,
                owned: progressStats.secondChances,
                onPurchase: () => _showPurchaseResult(
                  progressStats.buySecondChance(),
                  'Segundo intento',
                ),
              ),
              _buildProductCard(
                icon: Icons.shield_outlined,
                title: 'Protector de racha',
                description:
                    'Se activa automáticamente por cada día que no completes una lección.',
                price: RewardShopPage.streakProtectorPrice,
                owned: progressStats.streakProtectors,
                onPurchase: () => _showPurchaseResult(
                  progressStats.buyStreakProtector(),
                  'Protector de racha',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DiscussionReply {
  final int? id;
  final String author;
  final String authorHandle;
  final String authorRole;
  final Uint8List? authorPhoto;
  final String message;
  final DateTime createdAt;

  DiscussionReply({
    this.id,
    required this.author,
    this.authorHandle = '',
    this.authorRole = DBService.roleStudent,
    this.authorPhoto,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class DiscussionSpace {
  final int? id;
  String title;
  String description;
  final bool isPinned;
  final String author;
  final String authorHandle;
  final String authorRole;
  final Uint8List? authorPhoto;
  final DateTime createdAt;
  final List<DiscussionReply> replies;

  DiscussionSpace({
    this.id,
    required this.title,
    required this.description,
    this.isPinned = false,
    required this.author,
    this.authorHandle = '',
    this.authorRole = DBService.roleStudent,
    this.authorPhoto,
    DateTime? createdAt,
    List<DiscussionReply>? replies,
  }) : createdAt = createdAt ?? DateTime.now(),
       replies = replies ?? [];
}

// Abre el perfil público de un autor de Korublog al tocar su foto.
void openPublicProfile(
  BuildContext context, {
  required String handle,
  required String name,
  Uint8List? photo,
}) {
  if (handle.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PublicProfilePage(
        username: handle,
        fallbackName: name,
        fallbackPhoto: photo,
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  PÁGINAS PRINCIPALES
// ─────────────────────────────────────────────

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
      builder: (sheetContext) => _AccountSwitcherSheet(
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
            title: 'RETOS ECOLÓGICOS',
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
                                      color: theme
                                          .colorScheme
                                          .onPrimaryContainer,
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

// Tarjeta que muestra el progreso general del usuario (respuestas, lecciones, racha diaria)
class ProgressCard extends StatefulWidget {
  final String username;

  const ProgressCard({super.key, required this.username});

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  bool _isExpanded = false;
  bool _userChangedExpansion = false;

  String get _preferenceKey =>
      'korulab_progress_expanded_${DBService.normalizeUsername(widget.username)}';

  @override
  void initState() {
    super.initState();
    _loadExpansionPreference();
  }

  @override
  void didUpdateWidget(covariant ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (DBService.normalizeUsername(oldWidget.username) !=
        DBService.normalizeUsername(widget.username)) {
      _isExpanded = false;
      _userChangedExpansion = false;
      _loadExpansionPreference();
    }
  }

  Future<void> _loadExpansionPreference() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedValue = preferences.getBool(_preferenceKey);
      if (!mounted || _userChangedExpansion || savedValue == null) return;
      setState(() => _isExpanded = savedValue);
    } catch (error) {
      debugPrint('No se pudo cargar la preferencia de progreso: $error');
    }
  }

  Future<void> _toggleExpanded() async {
    final expanded = !_isExpanded;
    setState(() {
      _isExpanded = expanded;
      _userChangedExpansion = true;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_preferenceKey, expanded);
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la preferencia de Progreso.'),
          ),
        );
      }
    } catch (error) {
      debugPrint('No se pudo guardar la preferencia de progreso: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la preferencia de Progreso.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progressStats,
      builder: (context, _) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.insights, color: theme.colorScheme.primary),
                title: Text(
                  'Progreso',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: !_isExpanded
                    ? Text(
                        '${progressStats.completedActivities} actividades · '
                        '${progressStats.accuracyPercent}% precisión',
                      )
                    : null,
                trailing: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: _toggleExpanded,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _ProgressRing(
                                    percentage: progressStats.totalLessons == 0
                                        ? 0
                                        : (progressStats.completedActivities *
                                                  100 ~/
                                                  progressStats.totalLessons)
                                              .clamp(0, 100)
                                              .toInt(),
                                    label: 'Lecciones hechas',
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ProgressRing(
                                    percentage: progressStats.accuracyPercent,
                                    label: 'Precisión',
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${progressStats.completedActivities} de '
                              '${progressStats.totalLessons} actividades '
                              'completadas',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sigue avanzando para completar tu primera unidad.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int percentage;
  final String label;
  final Color color;

  const _ProgressRing({
    required this.percentage,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: percentage.clamp(0, 100) / 100,
                  strokeWidth: 9,
                  backgroundColor: theme.colorScheme.outlineVariant,
                  color: color,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  COURSE CARD
// ─────────────────────────────────────────────
// Catálogo de cursos y actividades disponibles en Koruclases
class EcoChallengesPage extends StatefulWidget {
  final String username;

  const EcoChallengesPage({super.key, required this.username});

  @override
  State<EcoChallengesPage> createState() => _EcoChallengesPageState();
}

class _EcoChallengesPageState extends State<EcoChallengesPage> {
  static const _challenges =
      <({String id, String title, String description, IconData icon})>[
        (
          id: 'bottle',
          title: 'Usa una botella reutilizable',
          description: 'Evita comprar una botella desechable hoy.',
          icon: Icons.water_drop_outlined,
        ),
        (
          id: 'recycle',
          title: 'Separa tus residuos',
          description: 'Clasifica papel, envases y residuos orgánicos.',
          icon: Icons.recycling,
        ),
        (
          id: 'lights',
          title: 'Ahorra energía',
          description: 'Apaga las luces y desconecta lo que no uses.',
          icon: Icons.bolt,
        ),
        (
          id: 'walk',
          title: 'Elige movilidad sostenible',
          description:
              'Camina, usa bicicleta o transporte público en un trayecto.',
          icon: Icons.directions_walk,
        ),
        (
          id: 'food',
          title: 'Reduce el desperdicio de comida',
          description: 'Planifica una comida con lo que ya tienes en casa.',
          icon: Icons.restaurant_outlined,
        ),
        (
          id: 'reuse',
          title: 'Dale otro uso a un objeto',
          description:
              'Reutiliza un envase, repara algo o comparte lo que no necesitas.',
          icon: Icons.recycling_outlined,
        ),
      ];

  late final String _progressKey = 'korulab_eco_challenges_${widget.username}';
  final Set<String> _completed = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getStringList(_progressKey) ?? [];
      if (mounted) {
        setState(() {
          _completed.addAll(saved);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleChallenge(String id, bool? isCompleted) async {
    setState(() {
      if (isCompleted ?? false) {
        _completed.add(id);
      } else {
        _completed.remove(id);
      }
    });

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_progressKey, _completed.toList());
      unawaited(DBService.pushProgress(widget.username));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el progreso.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = _completed.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Retos ecológicos'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Un reto a tu ritmo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pequeñas acciones cotidianas también ayudan a cuidar el planeta.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount de ${_challenges.length} acciones completadas',
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: completedCount / _challenges.length,
                          minHeight: 8,
                        ),
                        if (completedCount == _challenges.length) ...[
                          const SizedBox(height: 12),
                          Text(
                            '¡Reto completado! Gracias por ponerlo en práctica.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._challenges.map((challenge) {
                  final isCompleted = _completed.contains(challenge.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.65),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: isCompleted,
                          onChanged: (value) =>
                              _toggleChallenge(challenge.id, value),
                          controlAffinity: ListTileControlAffinity.trailing,
                          secondary: Icon(
                            challenge.icon,
                            color: theme.colorScheme.primaryContainer,
                          ),
                          title: Text(challenge.title),
                          subtitle: Text(challenge.description),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => EcoChallengeJournalPage(
                                      username: widget.username,
                                      challengeId: challenge.id,
                                      challengeTitle: challenge.title,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.menu_book_outlined),
                              label: const Text('Abrir diario'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class EcoChallengeJournalPage extends StatefulWidget {
  final String username;
  final String challengeId;
  final String challengeTitle;

  const EcoChallengeJournalPage({
    super.key,
    required this.username,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  State<EcoChallengeJournalPage> createState() =>
      _EcoChallengeJournalPageState();
}

class _EcoChallengeJournalPageState extends State<EcoChallengeJournalPage> {
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _loadError = false;
    });
    try {
      final entries = await DBService.getEcoJournalEntries(
        username: widget.username,
        challengeId: widget.challengeId,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _addEntry() async {
    final noteController = TextEditingController();
    final photos = <Uint8List>[];
    try {
      final shouldSave = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva nota del día',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Qué hiciste hoy y cómo ayudó a este reto?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Tu experiencia',
                      hintText: 'Escribe los detalles de tu proceso...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final images = await _imagePicker.pickMultiImage(
                          maxWidth: 1600,
                          maxHeight: 1600,
                          imageQuality: 85,
                        );
                        for (final image in images) {
                          photos.add(await image.readAsBytes());
                        }
                        if (sheetContext.mounted) {
                          setModalState(() {});
                        }
                      } catch (_) {
                        if (mounted)
                          _showMessage('No se pudieron cargar las fotos.');
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      photos.isEmpty
                          ? 'Agregar fotos'
                          : 'Agregar más fotos (${photos.length})',
                    ),
                  ),
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                photos[index],
                                width: 94,
                                height: 94,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton(
                                onPressed: () =>
                                    setModalState(() => photos.removeAt(index)),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (noteController.text.trim().isEmpty &&
                          photos.isEmpty) {
                        _showMessage('Escribe una nota o agrega una foto.');
                        return;
                      }
                      Navigator.of(sheetContext).pop(true);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar en mi diario'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (shouldSave != true) return;

      await DBService.addEcoJournalEntry(
        username: widget.username,
        challengeId: widget.challengeId,
        note: noteController.text,
        photos: photos,
      );
      if (!mounted) return;
      await _loadEntries();
      _showMessage('Tu entrada quedó guardada.');
    } catch (_) {
      if (mounted)
        _showMessage('No se pudo guardar la entrada. Inténtalo de nuevo.');
    }
  }

  Future<void> _deleteEntry(int entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('¿Quieres eliminar esta nota y sus fotos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DBService.deleteEcoJournalEntry(
        entryId: entryId,
        username: widget.username,
      );
      await _loadEntries();
    } catch (_) {
      if (mounted) _showMessage('No se pudo eliminar la entrada.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario del reto'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Nueva entrada'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar tu diario.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loadEntries,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  widget.challengeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra tus acciones, reflexiones y fotos día a día.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (_entries.isEmpty)
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 40),
                          SizedBox(height: 12),
                          Text(
                            'Tu diario está listo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Agrega una nota o una foto para contar cómo avanzas con este reto.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._entries.map((entry) {
                    final note = entry['note'] as String;
                    final photos = entry['photos'] as List<Uint8List>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDate(entry['created_at'] as String),
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar entrada',
                                  onPressed: () =>
                                      _deleteEntry(entry['id'] as int),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(note),
                            ],
                            if (photos.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 150,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) => ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      photos[index],
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class RutaEkoPage extends StatefulWidget {
  final String username;

  const RutaEkoPage({super.key, required this.username});

  @override
  State<RutaEkoPage> createState() => _RutaEkoPageState();
}

class _RutaEkoPageState extends State<RutaEkoPage> {
  List<_RutaEkoTrailUnit> _trailUnits = [];
  bool _isLoadingTeacherLessons = true;
  String? _lessonLoadError;
  String? _realtimeError;
  int _lessonLoadRequest = 0;
  RealtimeChannel? _lessonChangesChannel;
  Future<void>? _builtInCourseMigration;

  @override
  void initState() {
    super.initState();
    progressStats.loadCourseProgress(widget.username);
    _loadTeacherLessons();
    _subscribeToLessonChanges();
  }

  void _subscribeToLessonChanges() {
    _lessonChangesChannel = Supabase.instance.client
        .channel('ruta-eko-lessons-${widget.username}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DBService.teacherLessonTable,
          callback: (_) => _loadTeacherLessons(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DBService.teacherCourseTable,
          callback: (_) => _loadTeacherLessons(),
        )
        .subscribe((status, error) {
          if (!mounted) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            setState(() => _realtimeError = null);
            unawaited(_loadTeacherLessons());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('Ruta Eko realtime error: $error');
            setState(() {
              _realtimeError =
                  'No se pudieron activar las actualizaciones automáticas. '
                  'Verifica que la migración de Ruta Eko esté aplicada; '
                  'también puedes deslizar hacia abajo para actualizar.';
            });
          }
        });
  }

  Future<void> _loadTeacherLessons() async {
    final request = ++_lessonLoadRequest;
    try {
      if (DBService.normalizeUsername(widget.username) == 'p.yuli') {
        _builtInCourseMigration ??= DBService.ensureTeacherCourses(
          teacherUsername: 'p.yuli',
          courses: [
            for (final course in courses)
              {
                'title': course.title,
                'subtitle': course.subtitle,
                'activities': encodeCourseActivities(course),
              },
          ],
        );
        await _builtInCourseMigration;
      }
      final lessons = await loadManageableLessons(
        widget.username,
        DBService.lessonDestinationKoruclases,
      );
      lessons.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] as String? ?? '');
        final bDate = DateTime.tryParse(b['created_at'] as String? ?? '');
        if (aDate == null && bDate != null) return 1;
        if (aDate != null && bDate == null) return -1;
        if (aDate != null && bDate != null) {
          final dateOrder = aDate.compareTo(bDate);
          if (dateOrder != 0) return dateOrder;
        }
        return (a['id'] as int).compareTo(b['id'] as int);
      });
      final courseRows = await loadManageableCourses(widget.username);
      if (!mounted || request != _lessonLoadRequest) return;
      final trailUnits = <_RutaEkoTrailUnit>[
        for (final row in courseRows)
          _RutaEkoTrailUnit.course(courseFromRow(row), row),
        for (final row in lessons) _RutaEkoTrailUnit.lesson(row),
      ]..sort(_compareRutaEkoUnits);
      setState(() {
        _trailUnits = trailUnits;
        _lessonLoadError = null;
        _isLoadingTeacherLessons = false;
      });
    } catch (error) {
      debugPrint('No se pudo actualizar Ruta Eko: $error');
      if (!mounted || request != _lessonLoadRequest) return;
      if (DBService.normalizeUsername(widget.username) == 'p.yuli') {
        _builtInCourseMigration = null;
      }
      setState(() {
        _lessonLoadError =
            DBService.normalizeUsername(widget.username) == 'p.yuli'
            ? 'No se pudo migrar el contenido inicial. Verifica que p.yuli '
                  'tenga rol de profesor e inténtalo de nuevo.'
            : 'No se pudo cargar el sendero. Intenta actualizar.';
        _isLoadingTeacherLessons = false;
      });
    }
  }

  @override
  void dispose() {
    final channel = _lessonChangesChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ruta Eko'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) {
          if (!progressStats.isCourseProgressLoaded ||
              _isLoadingTeacherLessons) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _loadTeacherLessons,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_lessonLoadError != null || _realtimeError != null)
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _lessonLoadError ?? _realtimeError!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ...[
                  const SizedBox(height: 20),
                  Text(
                    'Sendero de Ruta Eko',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completa cada unidad para desbloquear la siguiente.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_trailUnits.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'El sendero se está preparando. Inicia sesión con '
                          'la cuenta docente p.yuli y abre Ruta Eko una vez '
                          'para migrar el contenido inicial.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    _UnitTrailProgress(units: _trailUnits),
                    const SizedBox(height: 16),
                    for (final entry in _trailUnits.indexed)
                      if (entry.$2.course != null)
                        TeacherCourseCard(
                          row: entry.$2.row,
                          courseOverride: entry.$2.course,
                          username: widget.username,
                          onChanged: _loadTeacherLessons,
                          unitNumber: entry.$1 + 1,
                          isUnlocked:
                              entry.$1 == 0 ||
                              _trailUnits[entry.$1 - 1].isCompleted,
                        )
                      else
                        _TeacherLessonCard(
                          unitNumber: entry.$1 + 1,
                          lesson: entry.$2.row,
                          username: widget.username,
                          onChanged: _loadTeacherLessons,
                          isUnlocked:
                              entry.$1 == 0 ||
                              _trailUnits[entry.$1 - 1].isCompleted,
                        ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherLessonCard extends StatelessWidget {
  final int unitNumber;
  final Map<String, dynamic> lesson;
  final String username;
  final Future<void> Function() onChanged;
  final bool isUnlocked;

  const _TeacherLessonCard({
    required this.unitNumber,
    required this.lesson,
    required this.username,
    required this.onChanged,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonId = lesson['id'] as int;
    final isCompleted = progressStats.isTeacherLessonCompleted(lessonId);
    final nodeColor = isCompleted || isUnlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: isUnlocked
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isUnlocked
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _TeacherLessonPage(lesson: lesson),
                ),
              )
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Completa la unidad ${unitNumber - 1} para desbloquear esta.',
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'UNIDAD $unitNumber',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: nodeColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                lesson['title'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                lesson['summary'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson['teacher_name'] as String? ?? 'Profesor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (lesson['can_manage'] == true)
                    TeacherLessonMenu(
                      lesson: lesson,
                      username: username,
                      onChanged: onChanged,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 4,
                    color: nodeColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: nodeColor,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isUnlocked
                      ? Icons.eco_outlined
                      : Icons.lock_outline,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: card),
      ],
    );
  }
}

class _RutaEkoTrailUnit {
  final Map<String, dynamic> row;
  final Course? course;

  const _RutaEkoTrailUnit.course(this.course, this.row);

  const _RutaEkoTrailUnit.lesson(this.row) : course = null;

  int get builtInCourseIndex {
    if (course == null ||
        DBService.normalizeUsername(row['teacher_username'] as String? ?? '') !=
            'p.yuli') {
      return -1;
    }
    return courses.indexWhere((item) => item.title == course!.title);
  }

  bool get isCompleted => course == null
      ? progressStats.isTeacherLessonCompleted(row['id'] as int)
      : course!.activities.isNotEmpty &&
            course!.activities.every(progressStats.isActivityCompleted);

  DateTime? get createdAt =>
      DateTime.tryParse(row['created_at'] as String? ?? '');
}

int _compareRutaEkoUnits(_RutaEkoTrailUnit a, _RutaEkoTrailUnit b) {
  final aBuiltIn = a.builtInCourseIndex;
  final bBuiltIn = b.builtInCourseIndex;
  if (aBuiltIn >= 0 && bBuiltIn >= 0) {
    return aBuiltIn.compareTo(bBuiltIn);
  }
  if (aBuiltIn >= 0) return -1;
  if (bBuiltIn >= 0) return 1;
  final aDate = a.createdAt;
  final bDate = b.createdAt;
  if (aDate != null && bDate != null) {
    final dateOrder = aDate.compareTo(bDate);
    if (dateOrder != 0) return dateOrder;
  }
  return (a.row['id'] as int).compareTo(b.row['id'] as int);
}

class _UnitTrailProgress extends StatelessWidget {
  final List<_RutaEkoTrailUnit> units;

  const _UnitTrailProgress({required this.units});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedUnits = units.where((unit) => unit.isCompleted).length;
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${completedUnits} de ${units.length} unidades completadas'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: units.isEmpty ? 0 : completedUnits / units.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

// Carga lecciones marcando cuáles puede editar o eliminar el usuario.
Future<List<Map<String, dynamic>>> loadManageableLessons(
  String username,
  String destination,
) async {
  final lessons = await DBService.getTeacherLessons(destination: destination);
  return [
    for (final lesson in lessons)
      {
        ...lesson,
        'can_manage': await DBService.canManageLesson(username, lesson),
      },
  ];
}

class TeacherLessonMenu extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final String username;
  final Future<void> Function() onChanged;

  const TeacherLessonMenu({
    super.key,
    required this.lesson,
    required this.username,
    required this.onChanged,
  });

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateTeacherLessonPage(teacherUsername: username, lesson: lesson),
      ),
    );
    if (saved == true) await onChanged();
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar lección'),
        content: Text('¿Eliminar "${lesson['title']}"? No se puede deshacer.'),
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
    if (confirmed != true) return;
    final deleted = await DBService.deleteTeacherLesson(
      requesterUsername: username,
      lessonId: lesson['id'] as int,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Lección eliminada.' : 'No se pudo eliminar la lección.',
        ),
      ),
    );
    if (deleted) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      onSelected: (value) =>
          value == 'edit' ? _edit(context) : _delete(context),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
      ],
    );
  }
}

class _TeacherLessonPage extends StatelessWidget {
  final Map<String, dynamic> lesson;

  const _TeacherLessonPage({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonId = lesson['id'] as int;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(lesson['title'] as String),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) {
          final isCompleted = progressStats.isTeacherLessonCompleted(lessonId);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                lesson['summary'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                lesson['content'] as String,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: isCompleted
                    ? null
                    : () {
                        final completed = progressStats.completeTeacherLesson(
                          lessonId,
                        );
                        if (completed && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lección completada. ¡Buen trabajo!',
                              ),
                            ),
                          );
                        }
                      },
                icon: Icon(isCompleted ? Icons.check_circle : Icons.done),
                label: Text(
                  isCompleted ? 'Completada' : 'Marcar como completada',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Tarjeta de curso - muestra su estado bloqueado o disponible
class CourseCard extends StatelessWidget {
  final Course course;
  final int courseIndex;

  const CourseCard({
    required this.course,
    required this.courseIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progressStats,
      builder: (context, _) {
        final isUnlocked = progressStats.isCourseUnlocked(courseIndex);
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isUnlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CoursePage(course: course, courseIndex: courseIndex),
                    ),
                  )
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Completa el curso anterior para continuar.',
                      ),
                    ),
                  ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Icon(
                      course.icon,
                      size: 28,
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.activities.length} actividades',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.chevron_right : Icons.lock_outline,
                    color: isUnlocked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
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

// ─────────────────────────────────────────────
//  SPECIAL ACTIVITY CARD
// ─────────────────────────────────────────────
// Tarjeta para actividades especiales - Korucol, retos, talleres y contenido destacado
class SpecialActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SpecialActivityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: color.withOpacity(0.15),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, size: 32, color: color),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DiscussionPage extends StatefulWidget {
  final DiscussionSpace space;
  final String username;
  final String displayName;
  final String userRole;
  final Uint8List? authorPhoto;
  final bool isAdmin;
  final bool isTeacher;

  const DiscussionPage({
    required this.space,
    required this.username,
    required this.displayName,
    required this.userRole,
    required this.authorPhoto,
    required this.isAdmin,
    required this.isTeacher,
    super.key,
  });

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final _replyController = TextEditingController();

  bool get _canManageSpace =>
      widget.isAdmin ||
      widget.isTeacher ||
      DBService.normalizeUsername(widget.space.authorHandle) ==
          DBService.normalizeUsername(widget.username);

  bool _canManageReply(DiscussionReply reply) =>
      widget.isAdmin ||
      widget.isTeacher ||
      DBService.normalizeUsername(reply.authorHandle) ==
          DBService.normalizeUsername(widget.username);

  Future<void> _submitReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;
    final discussionId = widget.space.id;
    if (discussionId == null) return;
    try {
      final replyId = await DBService.addDiscussionReply(
        discussionId: discussionId,
        author: widget.displayName,
        message: message,
        authorHandle: widget.username,
      );
      if (!mounted) return;
      setState(() {
        widget.space.replies.add(
          DiscussionReply(
            id: replyId,
            author: widget.displayName,
            authorHandle: widget.username,
            authorRole: widget.userRole,
            authorPhoto: widget.authorPhoto,
            message: message,
          ),
        );
        _replyController.clear();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo publicar el comentario.')),
        );
      }
    }
  }

  Future<void> _editSpace() async {
    final titleController = TextEditingController(text: widget.space.title);
    final descriptionController = TextEditingController(
      text: widget.space.description,
    );
    final values = await showDialog<List<String>>(
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
    if (!mounted || values == null || widget.space.id == null) return;

    final updated = await DBService.updateDiscussionSpace(
      discussionId: widget.space.id!,
      requesterUsername: widget.username,
      title: values[0],
      description: values[1],
    );
    if (!mounted) return;
    if (!updated) {
      _showDiscussionMessage('No tienes permiso para editar esta publicación.');
      return;
    }
    setState(() {
      widget.space.title = values[0];
      widget.space.description = values[1];
    });
  }

  Future<void> _deleteSpace() async {
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
    if (confirmed != true || !mounted || widget.space.id == null) return;
    final deleted = await DBService.deleteDiscussionSpace(
      discussionId: widget.space.id!,
      requesterUsername: widget.username,
    );
    if (!mounted) return;
    if (!deleted) {
      _showDiscussionMessage(
        'No tienes permiso para eliminar esta publicación.',
      );
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _editReply(DiscussionReply reply) async {
    if (reply.id == null) return;
    final controller = TextEditingController(text: reply.message);
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Comentario',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted || message == null) return;
    final updated = await DBService.updateDiscussionReply(
      replyId: reply.id!,
      requesterUsername: widget.username,
      message: message,
    );
    if (!mounted) return;
    if (!updated) {
      _showDiscussionMessage('No tienes permiso para editar este comentario.');
      return;
    }
    final index = widget.space.replies.indexWhere(
      (item) => item.id == reply.id,
    );
    if (index >= 0) {
      setState(() {
        widget.space.replies[index] = DiscussionReply(
          id: reply.id,
          author: reply.author,
          authorHandle: reply.authorHandle,
          authorPhoto: reply.authorPhoto,
          message: message,
          createdAt: reply.createdAt,
        );
      });
    }
  }

  Future<void> _deleteReply(DiscussionReply reply) async {
    if (reply.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Quieres eliminar este comentario?'),
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
    final deleted = await DBService.deleteDiscussionReply(
      replyId: reply.id!,
      requesterUsername: widget.username,
    );
    if (!mounted) return;
    if (!deleted) {
      _showDiscussionMessage(
        'No tienes permiso para eliminar este comentario.',
      );
      return;
    }
    setState(() {
      widget.space.replies.removeWhere((item) => item.id == reply.id);
    });
  }

  void _showDiscussionMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Espacio de discusión'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_canManageSpace)
            PopupMenuButton<String>(
              tooltip: 'Administrar publicación',
              onSelected: (action) {
                if (action == 'edit') _editSpace();
                if (action == 'delete') _deleteSpace();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar publicación')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar publicación'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.space.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.space.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => openPublicProfile(
                        context,
                        handle: widget.space.authorHandle,
                        name: widget.space.author,
                        photo: widget.space.authorPhoto,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: widget.space.authorPhoto == null
                            ? null
                            : MemoryImage(widget.space.authorPhoto!),
                        child: widget.space.authorPhoto == null
                            ? Icon(
                                Icons.person,
                                color: theme.colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.space.author,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.space.authorHandle.isNotEmpty)
                            Text(
                              '@${widget.space.authorHandle}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            DBService.roleLabel(widget.space.authorRole),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Respuestas (${widget.space.replies.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.space.replies.isEmpty)
                  Text(
                    'Todavía no hay respuestas. Sé el primero en participar.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...widget.space.replies.map((reply) {
                    final canManageReply = _canManageReply(reply);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.65),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => openPublicProfile(
                            context,
                            handle: reply.authorHandle,
                            name: reply.author,
                            photo: reply.authorPhoto,
                          ),
                          child: CircleAvatar(
                            backgroundImage: reply.authorPhoto == null
                                ? null
                                : MemoryImage(reply.authorPhoto!),
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.2),
                            child: reply.authorPhoto == null
                                ? Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primaryContainer,
                                  )
                                : null,
                          ),
                        ),
                        title: Text(
                          reply.author,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reply.message),
                              if (reply.authorHandle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${reply.authorHandle}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              Text(
                                DBService.roleLabel(reply.authorRole),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: canManageReply
                            ? PopupMenuButton<String>(
                                tooltip: 'Administrar comentario',
                                onSelected: (action) {
                                  if (action == 'edit') _editReply(reply);
                                  if (action == 'delete') _deleteReply(reply);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar comentario'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar comentario'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Escribe una respuesta...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _submitReply,
                    icon: const Icon(Icons.send),
                    tooltip: 'Responder',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COURSE PAGE
// ─────────────────────────────────────────────
IconData _activityIcon(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return Icons.quiz;
    case ActivityType.matching:
      return Icons.compare_arrows;
    case ActivityType.memory:
      return Icons.grid_view;
    case ActivityType.fillBlank:
      return Icons.edit_note;
    case ActivityType.sorting:
      return Icons.sort;
  }
}

Color _activityColor(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return Colors.blue.shade400;
    case ActivityType.matching:
      return Colors.purple.shade400;
    case ActivityType.memory:
      return Colors.orange.shade400;
    case ActivityType.fillBlank:
      return Colors.teal.shade400;
    case ActivityType.sorting:
      return Colors.red.shade400;
  }
}

String _activityLabel(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return 'Quiz';
    case ActivityType.matching:
      return 'Relacionar';
    case ActivityType.memory:
      return 'Memoria';
    case ActivityType.fillBlank:
      return 'Completar';
    case ActivityType.sorting:
      return 'Ordenar';
  }
}

// Página de detalle del curso - muestra todas las actividades de un curso específico
class CoursePage extends StatelessWidget {
  final Course course;
  final int courseIndex;

  const CoursePage({
    required this.course,
    required this.courseIndex,
    super.key,
  });

  Widget _buildActivityPage(LessonActivity activity) {
    if (activity is QuizActivity) return QuizPage(activity: activity);
    if (activity is MatchingActivity) return MatchingPage(activity: activity);
    if (activity is MemoryActivity) return MemoryPage(activity: activity);
    if (activity is FillBlankActivity) return FillBlankPage(activity: activity);
    if (activity is SortingActivity) return SortingPage(activity: activity);
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: course.activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final activity = course.activities[index];
            final color = _activityColor(activity.type);
            final isUnlocked = progressStats.isActivityUnlocked(activity);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(_activityIcon(activity.type), color: color),
              ),
              title: Text(
                activity.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                _activityLabel(activity.type),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: Icon(
                isUnlocked ? Icons.play_arrow : Icons.lock_outline,
                color: isUnlocked
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.error,
              ),
              onTap: () {
                if (!isUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Completa la actividad anterior para continuar.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _buildActivityPage(activity),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED: RESULT SCREEN
// ─────────────────────────────────────────────
class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final int incorrectAttempts;
  final VoidCallback onRetry;
  final String activityName;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.incorrectAttempts = 0,
    required this.onRetry,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempts = score + incorrectAttempts;
    final pct = attempts > 0 ? score / attempts : 0.0;
    final emoji = pct == 1.0
        ? '🏆'
        : pct >= 0.7
        ? '⭐'
        : '💪';
    final msg = pct == 1.0
        ? '¡Perfecto!'
        : pct >= 0.7
        ? '¡Muy bien!'
        : '¡Sigue practicando!';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            msg,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $total correctas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Precisión: ${(pct * 100).toInt()}%'
            '${incorrectAttempts > 0 ? ' · $incorrectAttempts errores' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Intentar de nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: onRetry,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide(color: theme.colorScheme.primaryContainer),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al curso'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  1. QUIZ PAGE
// ─────────────────────────────────────────────
class QuizPage extends StatefulWidget {
  final QuizActivity activity;
  const QuizPage({super.key, required this.activity});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int questionIndex = 0;
  int score = 0;
  int incorrectAttempts = 0;
  int? selectedOption;
  int? _hintedOptionIndex;
  bool completed = false;
  bool _reportedCompletion = false;
  late List<Question> shuffledQuestions;

  @override
  void initState() {
    super.initState();
    shuffledQuestions = List.from(widget.activity.questions)..shuffle();
  }

  void _reset() {
    setState(() {
      completed = false;
      questionIndex = 0;
      selectedOption = null;
      _hintedOptionIndex = null;
      score = 0;
      incorrectAttempts = 0;
      _reportedCompletion = false;
      shuffledQuestions = List.from(widget.activity.questions)..shuffle();
    });
  }

  void _reportCompletion() {
    if (_reportedCompletion) return;
    _reportedCompletion = true;
    progressStats.reportLessonResult(
      score,
      shuffledQuestions.length,
      activity: widget.activity,
      incorrectAttempts: incorrectAttempts,
    );
  }

  void selectOption(int index) {
    if (selectedOption != null) return;
    setState(() {
      selectedOption = index;
      if (shuffledQuestions[questionIndex].answerIndex == index) {
        score++;
      } else {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      }
    });
  }

  void _useHint() {
    if (selectedOption != null || _hintedOptionIndex != null) return;
    final question = shuffledQuestions[questionIndex];
    final wrongOptions = [
      for (var index = 0; index < question.options.length; index++)
        if (index != question.answerIndex) index,
    ];
    if (wrongOptions.isEmpty) return;
    if (!progressStats.useHint()) return;
    setState(() => _hintedOptionIndex = wrongOptions.first);
  }

  void _useSecondChance() {
    if (selectedOption == null ||
        shuffledQuestions[questionIndex].answerIndex == selectedOption) {
      return;
    }
    if (!progressStats.useSecondChance()) return;
    setState(() => selectedOption = null);
  }

  void nextQuestion() {
    if (questionIndex + 1 >= shuffledQuestions.length) {
      setState(() {
        completed = true;
      });
      _reportCompletion();
      return;
    }
    setState(() {
      questionIndex++;
      selectedOption = null;
      _hintedOptionIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: completed
            ? ResultScreen(
                score: score,
                total: shuffledQuestions.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final theme = Theme.of(context);
    final question = shuffledQuestions[questionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (questionIndex + 1) / shuffledQuestions.length,
          backgroundColor: theme.colorScheme.outlineVariant,
          color: theme.colorScheme.primaryContainer,
        ),
        const SizedBox(height: 12),
        Text(
          'Pregunta ${questionIndex + 1} de ${shuffledQuestions.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          question.prompt,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child:
              selectedOption != null &&
                  question.answerIndex != selectedOption &&
                  progressStats.secondChances > 0
              ? TextButton.icon(
                  onPressed: _useSecondChance,
                  icon: const Icon(Icons.replay),
                  label: Text(
                    'Segundo intento (${progressStats.secondChances})',
                  ),
                )
              : TextButton.icon(
                  onPressed:
                      selectedOption != null ||
                          _hintedOptionIndex != null ||
                          progressStats.hintCredits == 0
                      ? null
                      : _useHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Pista (${progressStats.hintCredits})'),
                ),
        ),
        const SizedBox(height: 24),
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          final isSelected = selectedOption == index;
          final isCorrect = question.answerIndex == index;
          final isEliminated = _hintedOptionIndex == index;
          Color? cardColor;
          Color? textColor;
          if (selectedOption != null) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade800;
              textColor = Colors.white;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade800;
              textColor = Colors.white;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEliminated
                    ? theme.colorScheme.outlineVariant
                    : cardColor ??
                          theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                foregroundColor: isEliminated
                    ? theme.colorScheme.onSurfaceVariant
                    : textColor ?? theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              onPressed: isEliminated ? null : () => selectOption(index),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEliminated ? '$option  ·  Descartada' : option,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          onPressed: selectedOption == null ? null : nextQuestion,
          child: Text(
            questionIndex + 1 == shuffledQuestions.length
                ? 'Finalizar'
                : 'Siguiente',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  2. MATCHING PAGE
// ─────────────────────────────────────────────
class MatchingPage extends StatefulWidget {
  final MatchingActivity activity;
  const MatchingPage({super.key, required this.activity});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  late List<String> terms;
  late List<String> definitions;
  String? selectedTerm;
  Map<String, String> matched = {};
  Set<String> wrongAttempts = {};
  int incorrectAttempts = 0;
  bool completed = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final pairs = List.of(widget.activity.pairs)..shuffle();
    terms = pairs.map((p) => p.term).toList();
    definitions = pairs.map((p) => p.definition).toList()..shuffle();
    selectedTerm = null;
    matched = {};
    wrongAttempts = {};
    incorrectAttempts = 0;
    completed = false;
    _reportedCompletion = false;
  }

  void _onTermTap(String term) {
    if (matched.containsKey(term)) return;
    setState(() => selectedTerm = term);
  }

  void _onDefinitionTap(String def) {
    if (selectedTerm == null) return;
    final correctDef = widget.activity.pairs
        .firstWhere((p) => p.term == selectedTerm)
        .definition;
    if (def == correctDef) {
      setState(() {
        matched[selectedTerm!] = def;
        selectedTerm = null;
        if (matched.length == widget.activity.pairs.length) {
          completed = true;
          if (!_reportedCompletion) {
            _reportedCompletion = true;
            progressStats.reportLessonResult(
              widget.activity.pairs.length,
              widget.activity.pairs.length,
              activity: widget.activity,
              incorrectAttempts: incorrectAttempts,
            );
          }
        }
      });
    } else {
      setState(() {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
        wrongAttempts.add('${selectedTerm!}_$def');
        selectedTerm = null;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => wrongAttempts.clear());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: completed
            ? ResultScreen(
                score: widget.activity.pairs.length,
                total: widget.activity.pairs.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: () => setState(_reset),
                activityName: widget.activity.title,
              )
            : Column(
                children: [
                  Text(
                    'Toca un término y luego su definición correcta.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        // Terms column
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Términos',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...terms.map((term) {
                                final isMatched = matched.containsKey(term);
                                final isSelected = selectedTerm == term;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onTermTap(term),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green.shade800.withOpacity(
                                                0.7,
                                              )
                                            : isSelected
                                            ? Colors.purple.shade900
                                                  .withOpacity(0.8)
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isMatched
                                              ? Colors.green.shade400
                                              : isSelected
                                              ? Colors.purple.shade400
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        term,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Definitions column
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Definiciones',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...definitions.map((def) {
                                final isMatched = matched.containsValue(def);
                                final isWrong = wrongAttempts.any(
                                  (k) => k.endsWith('_$def'),
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onDefinitionTap(def),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green.shade800.withOpacity(
                                                0.7,
                                              )
                                            : isWrong
                                            ? Colors.red.shade900.withOpacity(
                                                0.8,
                                              )
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isMatched
                                              ? Colors.green.shade400
                                              : isWrong
                                              ? Colors.red.shade400
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        def,
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  3. MEMORY CARD GAME PAGE
// ─────────────────────────────────────────────
class MemoryPage extends StatefulWidget {
  final MemoryActivity activity;
  const MemoryPage({super.key, required this.activity});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  late List<MemoryItem> cardItems;
  List<int> selectedIndices = [];
  int score = 0;
  int incorrectAttempts = 0;
  bool completed = false;
  bool busy = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final cards = widget.activity.cards;
    final doubled = <MemoryCard>[];
    for (final card in cards) {
      doubled.add(card);
      doubled.add(card);
    }
    doubled.shuffle();

    cardItems = doubled.map((c) => MemoryItem(card: c)).toList();
    selectedIndices.clear();
    score = 0;
    incorrectAttempts = 0;
    completed = false;
    busy = false;
    _reportedCompletion = false;
  }

  void _onCardTap(int index) {
    if (busy || cardItems[index].isFlipped || cardItems[index].isMatched)
      return;

    setState(() {
      cardItems[index].isFlipped = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      final firstIdx = selectedIndices[0];
      final secondIdx = selectedIndices[1];
      final firstCard = cardItems[firstIdx].card;
      final secondCard = cardItems[secondIdx].card;

      if (firstCard.label == secondCard.label) {
        setState(() {
          cardItems[firstIdx].isMatched = true;
          cardItems[secondIdx].isMatched = true;
          selectedIndices.clear();
          score++;
          if (score == widget.activity.cards.length) {
            completed = true;
            if (!_reportedCompletion) {
              _reportedCompletion = true;
              progressStats.reportLessonResult(
                widget.activity.cards.length,
                widget.activity.cards.length,
                activity: widget.activity,
                incorrectAttempts: incorrectAttempts,
              );
            }
          }
        });
      } else {
        setState(() {
          incorrectAttempts++;
          unawaited(vibrateOnWrongAnswer());
          busy = true;
        });
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              cardItems[firstIdx].isFlipped = false;
              cardItems[secondIdx].isFlipped = false;
              selectedIndices.clear();
              busy = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: completed
            ? ResultScreen(
                score: widget.activity.cards.length,
                total: widget.activity.cards.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : Column(
                children: [
                  Text(
                    'Encuentra las parejas de iconos ecológicos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: cardItems.length,
                      itemBuilder: (context, index) {
                        final item = cardItems[index];
                        final showFace = item.isFlipped || item.isMatched;

                        return GestureDetector(
                          onTap: () => _onCardTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: showFace
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.2)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: showFace
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.outlineVariant,
                                width: 2,
                              ),
                              boxShadow: showFace
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: showFace
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.card.emoji,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.card.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Icon(
                                      Icons.eco,
                                      size: 36,
                                      color: theme.colorScheme.primaryContainer,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class MemoryItem {
  final MemoryCard card;
  bool isFlipped = false;
  bool isMatched = false;
  MemoryItem({
    required this.card,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

// ─────────────────────────────────────────────
//  4. FILL IN THE BLANK PAGE
// ─────────────────────────────────────────────
class FillBlankPage extends StatefulWidget {
  final FillBlankActivity activity;
  const FillBlankPage({super.key, required this.activity});

  @override
  State<FillBlankPage> createState() => _FillBlankPageState();
}

class _FillBlankPageState extends State<FillBlankPage> {
  int currentQuestionIndex = 0;
  int score = 0;
  int incorrectAttempts = 0;
  int? selectedOptionIndex;
  int? _hintedOptionIndex;
  bool completed = false;
  bool _reportedCompletion = false;

  void _reset() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      incorrectAttempts = 0;
      selectedOptionIndex = null;
      _hintedOptionIndex = null;
      completed = false;
      _reportedCompletion = false;
    });
  }

  void _selectOption(int index) {
    if (selectedOptionIndex != null) return;
    setState(() {
      selectedOptionIndex = index;
      if (widget.activity.questions[currentQuestionIndex].answerIndex ==
          index) {
        score++;
      } else {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      }
    });
  }

  void _useHint() {
    if (selectedOptionIndex != null || _hintedOptionIndex != null) return;
    final question = widget.activity.questions[currentQuestionIndex];
    final wrongOptions = [
      for (var index = 0; index < question.options.length; index++)
        if (index != question.answerIndex) index,
    ];
    if (wrongOptions.isEmpty) return;
    if (!progressStats.useHint()) return;
    setState(() => _hintedOptionIndex = wrongOptions.first);
  }

  void _useSecondChance() {
    if (selectedOptionIndex == null ||
        widget.activity.questions[currentQuestionIndex].answerIndex ==
            selectedOptionIndex) {
      return;
    }
    if (!progressStats.useSecondChance()) return;
    setState(() => selectedOptionIndex = null);
  }

  void _nextQuestion() {
    if (currentQuestionIndex + 1 >= widget.activity.questions.length) {
      setState(() {
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        progressStats.reportLessonResult(
          score,
          widget.activity.questions.length,
          activity: widget.activity,
          incorrectAttempts: incorrectAttempts,
        );
      }
    } else {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        _hintedOptionIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: completed
            ? ResultScreen(
                score: score,
                total: widget.activity.questions.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final q = widget.activity.questions[currentQuestionIndex];
    final sentenceParts = q.sentence.split('___');
    final String part1 = sentenceParts.isNotEmpty ? sentenceParts[0] : '';
    final String part2 = sentenceParts.length > 1 ? sentenceParts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (currentQuestionIndex + 1) / widget.activity.questions.length,
          backgroundColor: theme.colorScheme.outlineVariant,
          color: theme.colorScheme.primaryContainer,
        ),
        const SizedBox(height: 12),
        Text(
          'Pregunta ${currentQuestionIndex + 1} de ${widget.activity.questions.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.titleLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(text: part1),
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: selectedOptionIndex == null
                          ? theme.colorScheme.surfaceContainerHighest
                          : (q.answerIndex == selectedOptionIndex
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedOptionIndex == null
                            ? theme.colorScheme.outline
                            : (q.answerIndex == selectedOptionIndex
                                  ? Colors.green.shade400
                                  : Colors.red.shade400),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      selectedOptionIndex == null
                          ? ' ____ '
                          : q.options[selectedOptionIndex!],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: part2),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child:
              selectedOptionIndex != null &&
                  q.answerIndex != selectedOptionIndex &&
                  progressStats.secondChances > 0
              ? TextButton.icon(
                  onPressed: _useSecondChance,
                  icon: const Icon(Icons.replay),
                  label: Text(
                    'Segundo intento (${progressStats.secondChances})',
                  ),
                )
              : TextButton.icon(
                  onPressed:
                      selectedOptionIndex != null ||
                          _hintedOptionIndex != null ||
                          progressStats.hintCredits == 0
                      ? null
                      : _useHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Pista (${progressStats.hintCredits})'),
                ),
        ),
        const SizedBox(height: 40),
        ...List.generate(q.options.length, (index) {
          final option = q.options[index];
          final isSelected = selectedOptionIndex == index;
          final isCorrect = q.answerIndex == index;
          final isEliminated = _hintedOptionIndex == index;
          Color? cardColor;
          Color? textColor;
          if (selectedOptionIndex != null) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade800;
              textColor = Colors.white;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade800;
              textColor = Colors.white;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEliminated
                    ? theme.colorScheme.outlineVariant
                    : cardColor ??
                          theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                foregroundColor: isEliminated
                    ? theme.colorScheme.onSurfaceVariant
                    : textColor ?? theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              onPressed: isEliminated ? null : () => _selectOption(index),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEliminated ? '$option  ·  Descartada' : option,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          onPressed: selectedOptionIndex == null ? null : _nextQuestion,
          child: Text(
            currentQuestionIndex + 1 == widget.activity.questions.length
                ? 'Finalizar'
                : 'Siguiente',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  5. SORTING / ORDERING PROCESS PAGE
// ─────────────────────────────────────────────
class SortingPage extends StatefulWidget {
  final SortingActivity activity;
  const SortingPage({super.key, required this.activity});

  @override
  State<SortingPage> createState() => _SortingPageState();
}

class _SortingPageState extends State<SortingPage> {
  late List<String> currentOrder;
  bool completed = false;
  bool hasError = false;
  bool _reportedCompletion = false;
  int incorrectAttempts = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      currentOrder = List.from(widget.activity.correctOrder)..shuffle();
      completed = false;
      hasError = false;
      _reportedCompletion = false;
      incorrectAttempts = 0;
    });
  }

  void _checkOrder() {
    bool isCorrect = true;
    for (int i = 0; i < currentOrder.length; i++) {
      if (currentOrder[i] != widget.activity.correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      setState(() {
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        progressStats.reportLessonResult(
          widget.activity.correctOrder.length,
          widget.activity.correctOrder.length,
          activity: widget.activity,
          incorrectAttempts: incorrectAttempts,
        );
      }
    } else {
      setState(() {
        hasError = true;
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El orden no es correcto. ¡Sigue intentándolo!'),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            hasError = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: completed
            ? ResultScreen(
                score: widget.activity.correctOrder.length,
                total: widget.activity.correctOrder.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.activity.instruction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantén presionado y arrastra para reordenar los pasos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Theme(
                      data: theme.copyWith(canvasColor: Colors.transparent),
                      child: ReorderableListView.builder(
                        itemCount: currentOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final String item = currentOrder.removeAt(oldIndex);
                            currentOrder.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final step = currentOrder[index];
                          return Card(
                            key: ValueKey(step),
                            margin: const EdgeInsets.only(bottom: 12),
                            color: hasError
                                ? Colors.red.shade900.withOpacity(0.5)
                                : theme.colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: hasError
                                    ? Colors.red
                                    : theme.colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(
                                step,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              trailing: Icon(
                                Icons.drag_handle,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _checkOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Verificar Orden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
