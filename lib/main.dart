import 'dart:async';
import 'package:flutter/material.dart';
import 'db_service.dart';
import 'register_page.dart';
import 'splash_page.dart';

void main() {
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
  const LoginPage({super.key});

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
    final username = _usernameController.text.trim();
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomePage(username: username),
            ),
          );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/koruicon.png',
                  height: 100, fit: BoxFit.contain),
              const SizedBox(height: 24),
              Text(
                'Bienvenido a Korulab',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Nombre de usuario',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Iniciar sesión',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  GestureDetector(
                    onTap: _isLoading ? null : _goToRegister,
                    child: Text('Regístrate',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
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

// ─────────────────────────────────────────────
//  MODELOS DE DATOS
// ─────────────────────────────────────────────

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
  const Question(
      {required this.prompt,
      required this.options,
      required this.answerIndex});
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
  const FillBlankQuestion(
      {required this.sentence,
      required this.options,
      required this.answerIndex});
}

// Actividad de ordenamiento - los usuarios deben ordenar elementos en la secuencia correcta
class SortingActivity extends LessonActivity {
  final String instruction;
  final List<String> correctOrder;
  const SortingActivity(
      {required super.title,
      required this.instruction,
      required this.correctOrder})
      : super(type: ActivityType.sorting);
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
              'Contamina el aire'
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
            sentence: 'Los paneles ___ convierten la luz solar en electricidad.',
            options: ['solares', 'eólicos', 'marinos', 'nucleares'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'La energía ___ se obtiene del movimiento del viento.',
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
            prompt:
                '¿Qué material se puede reciclar en el contenedor azul?',
            options: [
              'Papel y cartón',
              'Restos de comida',
              'Baterías',
              'Vidrio roto'
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es una acción para reducir residuos?',
            options: [
              'Usar bolsas reutilizables',
              'Comprar plástico de un solo uso',
              'Tirar todo junto',
              'Usar más servilletas'
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
            sentence:
                'Las tres R del reciclaje son: reducir, ___ y reciclar.',
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
              'Contaminan el agua'
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
              'Evaporación'
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
            sentence: 'La ___ es el proceso por la que el agua pasa de líquido a vapor.',
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
            prompt: '¿Cuál es la principal fuente de contaminación del aire en las ciudades?',
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
              'Aumento de ozono'
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Contaminante y fuente',
        pairs: const [
          MatchPair(term: 'CO₂', definition: 'Combustión de combustibles fósiles'),
          MatchPair(term: 'Ozono', definition: 'Contaminación por reacciones químicas'),
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
            sentence: 'La ___ es la principal causa de la mala calidad del aire en ciudades.',
            options: ['contaminación vehicular', 'lluvia', 'nieve', 'neblina'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El ___ es un gas que forma parte del efecto invernadero.',
            options: ['dióxido de carbono', 'oxígeno', 'nitrógeno', 'helio'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'La contaminación del aire causa problemas en el sistema ___.',
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
              'Aumento de sales minerales'
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
            sentence: 'La contaminación del agua afecta principalmente a los ___.',
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
            prompt: '¿Cuánto tiempo tarda un plástico en degradarse en el suelo?',
            options: [
              'Más de 500 años',
              '1 año',
              '10 años',
              'Nunca se degrada'
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
              'Mayor fertilidad'
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
            sentence: 'Los ___ dañan la estructura del suelo y matan microorganismos.',
            options: ['pesticidas', 'abonos', 'semillas', 'riegos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El suelo fértil es esencial para la ___ mundial.',
            options: ['producción de alimentos', 'construcción', 'minería', 'turismo'],
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
              'Enterrar basura'
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
              'Hoja verde'
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
            sentence: 'El ___ puede ser reciclado infinitas veces sin perder calidad.',
            options: ['vidrio', 'plástico', 'papel', 'cartón'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Los códigos de ___ indican qué tipo de plástico es.',
            options: ['reciclaje', 'barras', 'color', 'peso'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Reciclar ___ ahorra más energía que reciclar otros materiales.',
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
              'Actividad volcánica'
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuánto ha aumentado la temperatura global en el último siglo?',
            options: ['Aproximadamente 1°C', 'Nada', '5°C', '10°C'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué consecuencia tiene el cambio climático?',
            options: [
              'Aumento del nivel del mar',
              'Desaparición de montañas',
              'Menor radiación solar',
              'Menos días soleados'
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
          MatchPair(term: 'Deforestación', definition: 'Menos árboles = más CO₂'),
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
            sentence: 'El ___ es el principal causante del calentamiento global.',
            options: ['dióxido de carbono', 'oxígeno', 'nitrógeno', 'helio'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El derretimiento de los ___ aumenta el nivel del mar.',
            options: ['glaciares', 'volcanes', 'montañas', 'ríos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Los cambios en el ___ afectan la agricultura y la biodiversidad.',
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
              'Comprar por comprar'
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es la mejor opción ecológica?',
            options: [
              'Comprar productos locales',
              'Importar de lejos',
              'Comprar mucha cantidad',
              'Elegir empaques grandes'
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es un impacto del exceso de consumo?',
            options: [
              'Generación de residuos',
              'Menor contaminación',
              'Más espacio verde',
              'Mejor biodiversidad'
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Producto y impacto',
        pairs: const [
          MatchPair(term: 'Ropa de segunda mano', definition: 'Reduce residuos'),
          MatchPair(term: 'Productos locales', definition: 'Menor transporte'),
          MatchPair(term: 'Empaques biodegradables', definition: 'Menos contaminación'),
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
  DateTime? _lastLessonDate;

  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  int get completedLessons => _completedLessons;
  int get dailyStreak => _dailyStreak;
  int get ekostrellas => _ekostrellas;
  int get totalLessons => courses.fold<int>(0, (sum, course) => sum + course.activities.length);

  int get accuracyPercent => _totalAnswers > 0 ? (_correctAnswers * 100 ~/ _totalAnswers) : 0;
  double get accuracyRatio => _totalAnswers > 0 ? _correctAnswers / _totalAnswers : 0.0;

  void reportLessonResult(int correct, int total) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_lastLessonDate != todayDate) {
      if (_lastLessonDate != null) {
        final yesterday = todayDate.subtract(const Duration(days: 1));
        if (_lastLessonDate == yesterday) {
          _dailyStreak += 1;
        } else {
          _dailyStreak = 1;
        }
      } else {
        _dailyStreak = 1;
      }
      _lastLessonDate = todayDate;
    }

    _correctAnswers += correct;
    _totalAnswers += total;
    _completedLessons += 1;
    _ekostrellas += total > 0 ? (correct * 50 ~/ total) : 0;
    notifyListeners();
  }
}

final progressStats = ProgressStats();

class DiscussionReply {
  final String author;
  final String message;
  final DateTime createdAt;

  DiscussionReply({
    required this.author,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class DiscussionSpace {
  final int? id;
  final String title;
  final String description;
  final String author;
  final DateTime createdAt;
  final List<DiscussionReply> replies;

  DiscussionSpace({
    this.id,
    required this.title,
    required this.description,
    required this.author,
    DateTime? createdAt,
    List<DiscussionReply>? replies,
  })  : createdAt = createdAt ?? DateTime.now(),
        replies = replies ?? [];
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
  int _selectedIndex = 0;
  final List<DiscussionSpace> _discussionSpaces = [
    DiscussionSpace(
      title: 'Ideas para cuidar el planeta',
      description: 'Comparte acciones sencillas que podemos aplicar cada día.',
      author: 'Korulab',
      replies: [
        DiscussionReply(
          author: 'Korulab',
          message: '¡Todas las ideas son bienvenidas!',
        ),
      ],
    ),
    DiscussionSpace(
      title: 'Preguntas sobre las lecciones',
      description: 'Ayuda a otros usuarios y resuelve tus dudas.',
      author: 'Korulab',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDiscussionSpaces();
  }

  Future<void> _loadDiscussionSpaces() async {
    final storedSpaces = await DBService.getDiscussionSpaces();
    if (storedSpaces.isEmpty) {
      for (final space in _discussionSpaces) {
        final id = await DBService.createDiscussionSpace(
          title: space.title,
          description: space.description,
          author: space.author,
        );
        for (final reply in space.replies) {
          await DBService.addDiscussionReply(
            discussionId: id,
            author: reply.author,
            message: reply.message,
          );
        }
      }
      await _loadDiscussionSpaces();
      return;
    }

    final loadedSpaces = storedSpaces.map((space) {
      final replies = (space['replies'] as List<Map<String, dynamic>>)
          .map((reply) => DiscussionReply(
                author: reply['author'] as String,
                message: reply['message'] as String,
                createdAt: DateTime.tryParse(reply['created_at'] as String? ?? ''),
              ))
          .toList();
      return DiscussionSpace(
        id: space['id'] as int,
        title: space['title'] as String,
        description: space['description'] as String,
        author: space['author'] as String,
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
    'Lecciones',
    'Aprende con Korucol',
    'Korublog',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildLessonsSection(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenido, ${widget.username}',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
              'Es hora de conocer un poco más de cómo cuidar el planeta!!',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          const ProgressCard(),
          const SizedBox(height: 20),
          Text('Actividades especiales',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SpecialActivityCard(
                  title: 'APRENDE CON KORUCOL',
                  subtitle: 'Sesiones en vivo y actividades prácticas',
                  icon: Icons.video_call,
                  color: Colors.blue.shade600,
                  onTap: () {
                    _onItemTapped(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SpecialActivityCard(
                  title: 'KORUBLOG',
                  subtitle: 'Comparte ideas y conecta con otros',
                  icon: Icons.forum,
                  color: Colors.orange.shade600,
                  onTap: () {
                    _onItemTapped(2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Lecciones disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          ...courses.map((course) => CourseCard(course: course)),
        ],
      ),
    );
  }

  Widget _buildKorucolSection(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aprende con Korucol',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Explora talleres, retos y contenido exclusivo para aprender de manera divertida.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SpecialActivityCard(
                  title: 'Talleres en vivo',
                  subtitle: 'Sesiones interactivas sobre sostenibilidad',
                  icon: Icons.lightbulb,
                  color: Colors.green.shade600,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Talleres - Próximamente'))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SpecialActivityCard(
                  title: 'Retos ecológicos',
                  subtitle: 'Pequeñas acciones para el día a día',
                  icon: Icons.emoji_events,
                  color: Colors.teal.shade600,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Retos ecológicos - Próximamente'))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Contenido destacado',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          _buildInfoCard(theme, 'Cómo cuidar el agua', 'Consejos prácticos para reducir el consumo.'),
          _buildInfoCard(theme, 'Ahorro de energía', 'Aprende a usar menos electricidad en casa.'),
          _buildInfoCard(theme, 'Reciclaje creativo', 'Proyectos fáciles con materiales reciclados.'),
        ],
      ),
    );
  }

  Widget _buildKorublogSection(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Korublog',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Lecturas, historias y noticias del mundo Korulab.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
          Text('Espacios de discusión',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          ..._discussionSpaces.map((space) => _buildDiscussionCard(theme, space)),
        ],
      ),
    );
  }

  Widget _buildDiscussionCard(ThemeData theme, DiscussionSpace space) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.forum, color: theme.colorScheme.primaryContainer),
        ),
        title: Text(space.title,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${space.description}\n${space.author} · ${space.replies.length} respuestas',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        isThreeLine: true,
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primaryContainer),
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
    titleController.dispose();
    descriptionController.dispose();

    if (!mounted || result == null) return;
    final id = await DBService.createDiscussionSpace(
      title: result[0],
      description: result[1],
      author: widget.username,
    );
    if (!mounted) return;
    setState(() {
      _discussionSpaces.insert(
        0,
        DiscussionSpace(
          id: id,
          title: result[0],
          description: result[1],
          author: widget.username,
        ),
      );
    });
  }

  Future<void> _openDiscussion(DiscussionSpace space) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscussionPage(
          space: space,
          username: widget.username,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildInfoCard(ThemeData theme, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        title: Text(title,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.arrow_forward, color: theme.colorScheme.primaryContainer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Image.asset('assets/images/korulogo.png',
            height: 60,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true),
        centerTitle: true,
        actions: [
          AnimatedBuilder(
            animation: progressStats,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${progressStats.ekostrellas} ekostrellas',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text(
                      '¿Estás seguro de que quieres cerrar sesión?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () async {
                        // Cerrar sesión de la base de datos
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
      body: _selectedIndex == 0
          ? _buildLessonsSection(theme)
          : _selectedIndex == 1
              ? _buildKorucolSection(theme)
              : _buildKorublogSection(theme),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Lecciones',
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
        ],
      ),
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
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progressStats,
      builder: (context, _) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progreso de hoy',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _MetricBox(
                      value: '${progressStats.completedLessons}/${progressStats.totalLessons}',
                      label: 'Lecciones',
                    ),
                    _MetricBox(
                      value: '${progressStats.accuracyPercent}%',
                      label: 'Precisión',
                    ),
                    _MetricBox(
                      value: '${progressStats.dailyStreak}',
                      label: 'Racha diaria',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                    'Sigue avanzando para completar tu primera unidad.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Caja individual que muestra una métrica específica del progreso del usuario
class _MetricBox extends StatelessWidget {
  final String value;
  final String label;
  const _MetricBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primaryContainer)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  COURSE CARD
// ─────────────────────────────────────────────
// Tarjeta de curso - muestra un curso con su título, descripción e icono
class CourseCard extends StatelessWidget {
  final Course course;
  const CourseCard({required this.course, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CoursePage(course: course))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outlineVariant, width: 2)),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Icon(course.icon,
                      size: 28,
                      color: theme.colorScheme.primaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 6),
                    Text(course.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('${course.activities.length} actividades',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                                color: theme.colorScheme.primaryContainer,
                                fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: color.withOpacity(0.15),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5), width: 2)),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, size: 32, color: color),
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscussionPage extends StatefulWidget {
  final DiscussionSpace space;
  final String username;

  const DiscussionPage({
    required this.space,
    required this.username,
    super.key,
  });

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final _replyController = TextEditingController();

  Future<void> _submitReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      widget.space.replies.add(
        DiscussionReply(author: widget.username, message: message),
      );
      _replyController.clear();
    });
    if (widget.space.id != null) {
      await DBService.addDiscussionReply(
        discussionId: widget.space.id!,
        author: widget.username,
        message: message,
      );
    }
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
                  ...widget.space.replies.map(
                    (reply) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: Icon(Icons.person, color: theme.colorScheme.primaryContainer),
                        ),
                        title: Text(
                          reply.author,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(reply.message),
                        ),
                      ),
                    ),
                  ),
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
  const CoursePage({required this.course, super.key});

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
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: course.activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final activity = course.activities[index];
          final color = _activityColor(activity.type);
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(_activityIcon(activity.type), color: color),
            ),
            title: Text(activity.title,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            subtitle: Text(_activityLabel(activity.type), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            trailing: Icon(Icons.play_arrow, color: theme.colorScheme.primaryContainer),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => _buildActivityPage(activity)),
            ),
          );
        },
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
  final VoidCallback onRetry;
  final String activityName;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.onRetry,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? score / total : 0.0;
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
          Text(msg,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('$score / $total correctas',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Intentar de nuevo'),
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary),
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
  int? selectedOption;
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
      score = 0;
      _reportedCompletion = false;
      shuffledQuestions = List.from(widget.activity.questions)..shuffle();
    });
  }

  void _reportCompletion() {
    if (_reportedCompletion) return;
    _reportedCompletion = true;
    progressStats.reportLessonResult(score, shuffledQuestions.length);
  }

  void selectOption(int index) {
    if (selectedOption != null) return;
    setState(() {
      selectedOption = index;
      if (shuffledQuestions[questionIndex].answerIndex == index) score++;
    });
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
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Text(question.prompt,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 24),
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          final isSelected = selectedOption == index;
          final isCorrect = question.answerIndex == index;
          Color? cardColor;
          Color? textColor;
          if (selectedOption != null) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade800;
              textColor = Colors.white;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade800;
              textColor = Colors.white;
            } else if (isCorrect) {
              cardColor = Colors.green.shade900.withOpacity(0.5);
              textColor = Colors.green.shade200;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                foregroundColor: textColor ?? theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                      width: 2,
                    )),
              ),
              onPressed: () => selectOption(index),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(option,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          );
        }),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
          onPressed: selectedOption == null ? null : nextQuestion,
          child: Text(questionIndex + 1 == shuffledQuestions.length
              ? 'Finalizar'
              : 'Siguiente'),
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
            progressStats.reportLessonResult(widget.activity.pairs.length, widget.activity.pairs.length);
          }
        }
      });
    } else {
      setState(() {
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
                onRetry: () => setState(_reset),
                activityName: widget.activity.title,
              )
            : Column(
                children: [
                  Text(
                    'Toca un término y luego su definición correcta.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                              Text('Términos',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              ...terms.map((term) {
                                final isMatched = matched.containsKey(term);
                                final isSelected = selectedTerm == term;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onTermTap(term),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green.shade800.withOpacity(0.7)
                                            : isSelected
                                                ? Colors.purple.shade900.withOpacity(0.8)
                                                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isMatched
                                                ? Colors.green.shade400
                                                : isSelected
                                                    ? Colors.purple.shade400
                                                    : Colors.transparent,
                                            width: 2),
                                      ),
                                      child: Text(term,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center),
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
                              Text('Definiciones',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              ...definitions.map((def) {
                                final isMatched = matched.containsValue(def);
                                final isWrong = wrongAttempts.any((k) => k.endsWith('_$def'));
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onDefinitionTap(def),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green.shade800.withOpacity(0.7)
                                            : isWrong
                                                ? Colors.red.shade900.withOpacity(0.8)
                                                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isMatched
                                                ? Colors.green.shade400
                                                : isWrong
                                                    ? Colors.red.shade400
                                                    : Colors.transparent,
                                            width: 2),
                                      ),
                                      child: Text(def,
                                          style: const TextStyle(fontSize: 12),
                                          textAlign: TextAlign.center),
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
    completed = false;
    busy = false;
    _reportedCompletion = false;
  }

  void _onCardTap(int index) {
    if (busy || cardItems[index].isFlipped || cardItems[index].isMatched) return;

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
              progressStats.reportLessonResult(widget.activity.cards.length, widget.activity.cards.length);
            }
          }
        });
      } else {
        setState(() {
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
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : Column(
                children: [
                  Text(
                    'Encuentra las parejas de iconos ecológicos.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: showFace ? theme.colorScheme.primaryContainer : theme.colorScheme.outlineVariant,
                                width: 2,
                              ),
                              boxShadow: showFace
                                  ? [
                                      BoxShadow(
                                          color: theme.colorScheme.primary.withOpacity(0.2),
                                          blurRadius: 8)
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: showFace
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item.card.emoji, style: const TextStyle(fontSize: 32)),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.card.label,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
  MemoryItem({required this.card, this.isFlipped = false, this.isMatched = false});
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
  int? selectedOptionIndex;
  bool completed = false;
  bool _reportedCompletion = false;

  void _reset() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      selectedOptionIndex = null;
      completed = false;
      _reportedCompletion = false;
    });
  }

  void _selectOption(int index) {
    if (selectedOptionIndex != null) return;
    setState(() {
      selectedOptionIndex = index;
      if (widget.activity.questions[currentQuestionIndex].answerIndex == index) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex + 1 >= widget.activity.questions.length) {
      setState(() {
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        progressStats.reportLessonResult(score, widget.activity.questions.length);
      }
    } else {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
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
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.titleLarge?.copyWith(height: 1.6, color: theme.colorScheme.onSurface),
              children: [
                TextSpan(text: part1),
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        const SizedBox(height: 40),
        ...List.generate(q.options.length, (index) {
          final option = q.options[index];
          final isSelected = selectedOptionIndex == index;
          final isCorrect = q.answerIndex == index;
          Color? cardColor;
          Color? textColor;
          if (selectedOptionIndex != null) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade800;
              textColor = Colors.white;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade800;
              textColor = Colors.white;
            } else if (isCorrect) {
              cardColor = Colors.green.shade900.withOpacity(0.5);
              textColor = Colors.green.shade200;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                foregroundColor: textColor ?? theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              onPressed: () => _selectOption(index),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(option, style: const TextStyle(fontSize: 16)),
              ),
            ),
          );
        }),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
          onPressed: selectedOptionIndex == null ? null : _nextQuestion,
          child: Text(currentQuestionIndex + 1 == widget.activity.questions.length
              ? 'Finalizar'
              : 'Siguiente'),
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
        progressStats.reportLessonResult(widget.activity.correctOrder.length, widget.activity.correctOrder.length);
      }
    } else {
      setState(() {
        hasError = true;
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
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Theme(
                      data: theme.copyWith(
                        canvasColor: Colors.transparent,
                      ),
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
                                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
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
                                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                              ),
                              trailing: Icon(Icons.drag_handle, color: theme.colorScheme.outline),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}