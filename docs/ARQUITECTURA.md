# 🏗️ Arquitectura de KORULAB

## 📋 Contenido

- [Visión General](#visión-general)
- [Capas](#capas)
- [Módulos](#módulos)
- [Flujos de Datos](#flujos-de-datos)
- [Patrones Usados](#patrones-usados)
- [Decisiones de Diseño](#decisiones-de-diseño)

---

## 🎯 Visión General

KORULAB sigue una arquitectura **en capas con separación de responsabilidades**, permitiendo que cada componente tenga un propósito específico.

```
┌─────────────────────────────────────────┐
│        PRESENTATION LAYER               │
│   (Widgets, Pantallas, UI)              │
├─────────────────────────────────────────┤
│        APPLICATION LAYER                │
│   (Servicios, Lógica de Negocio)        │
├─────────────────────────────────────────┤
│        DATA LAYER                       │
│   (Modelos, Repositorios, Supabase)     │
└─────────────────────────────────────────┘
```

---

## 📊 Capas

### 1. Presentation Layer (UI)

**Responsabilidades:**
- Mostrar datos al usuario
- Capturar interacciones del usuario
- Delegar lógica compleja

**Ubicación:** `lib/paginas/`, `lib/widgets/`

**Ejemplo:**
```dart
class HomePage extends StatefulWidget {
  final String username;
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // UI logic only - no business logic
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: // widgets aquí
    );
  }
}
```

### 2. Application Layer

**Responsabilidades:**
- Lógica de negocio
- Gestión de estado
- Orquestación de servicios

**Ubicación:** `lib/servicios/`, `lib/`

**Ejemplo:**
```dart
class DBService {
  static Future<bool> validateLogin({
    required String username,
    required String password,
  }) async {
    // Lógica de validación
    return isValid;
  }
}
```

### 3. Data Layer

**Responsabilidades:**
- Acceso a datos
- Persistencia
- Transformación de datos

**Ubicación:** `lib/modelos/`

**Ejemplo:**
```dart
class Usuario {
  final String id;
  final String username;
  final String email;
  
  Usuario.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      username = json['username'],
      email = json['email'];
}
```

---

## 🧩 Módulos

### Core Modules

```
lib/
├── main.dart                    # Punto de entrada
├── servicio_bd.dart             # Base de datos
├── servicio_notificaciones.dart # Notificaciones
└── servicio_comentarios.dart    # Comentarios
```

### Feature Modules

```
lib/paginas/
├── pagina_login.dart            # Autenticación
├── pagina_inicio.dart           # Home
├── pagina_curso.dart            # Lecciones
├── pagina_quiz.dart             # Cuestionarios
├── pagina_retos_ecologicos.dart # Retos
├── pagina_tienda.dart           # Tienda
├── pagina_discusion.dart        # Comunidad
└── ...
```

### UI Modules

```
lib/widgets/
├── animated_widgets.dart        # Animaciones
├── tarjetas_inicio.dart         # Tarjetas
├── tarjeta_progreso.dart        # Progreso
├── mascota_guia.dart            # Mascota
└── ...
```

### Support Modules

```
lib/
├── modelos/                     # Modelos de datos
├── servicios/                   # Servicios
└── datos/                       # Datos estáticos
```

---

## 🔄 Flujos de Datos

### Flujo de Autenticación

```
┌─────────────────┐
│   LoginPage     │  ← Usuario ingresa credenciales
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ DBService.validateLogin()   │  ← Valida en Supabase
└────────┬────────────────────┘
         │
         ├─ ✓ Credenciales válidas
         │
         ▼
┌─────────────────────────────┐
│ DBService.saveSession()     │  ← Guarda en SharedPrefs
└────────┬────────────────────┘
         │
         ▼
┌─────────────────┐
│   HomePage      │  ← Usuario autenticado
└─────────────────┘
```

### Flujo de Lección

```
┌─────────────────┐
│   HomePage      │  ← Usuario selecciona curso
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ DBService.getLessons()      │  ← Obtiene lecciones
└────────┬────────────────────┘
         │
         ▼
┌─────────────────┐
│  PageCurso      │  ← Muestra lección
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│ DBService.updateProgress()   │  ← Marca como completada
└──────────────────────────────┘
```

### Flujo de Notificaciones

```
┌──────────────────────────┐
│ Usuario realiza acción   │
└────────┬─────────────────┘
         │
         ▼
┌───────────────────────────────┐
│ NotificationService.show()    │  ← Muestra localmente
└────────┬──────────────────────┘
         │
         ▼
┌────────────────────────┐
│ Notificación visible   │
└────────────────────────┘
```

---

## 🎨 Patrones Usados

### 1. MVC (Model-View-Controller)

**Implementación:**
- **Model:** `lib/modelos/`
- **View:** `lib/paginas/`, `lib/widgets/`
- **Controller:** `lib/servicios/`, `lib/servicio_bd.dart`

**Ventaja:** Separación clara de responsabilidades

### 2. Singleton Pattern

```dart
class DBService {
  static final DBService _instance = DBService._internal();
  
  factory DBService() {
    return _instance;
  }
  
  DBService._internal();
}
```

**Uso:** Garantiza una única instancia de servicios

### 3. Repository Pattern

```dart
class LessonRepository {
  Future<List<Lesson>> getAllLessons() async {
    // Obtiene de Supabase
  }
  
  Future<void> saveLessonProgress(String id) async {
    // Persiste progreso
  }
}
```

**Ventaja:** Abstrae la fuente de datos

### 4. State Management

**Actual:** StatefulWidget + setState()

**Recomendado para escalar:** Provider, Bloc, Riverpod

### 5. Dependency Injection

```dart
// Patrón constructor injection
class HomePage {
  final DBService dbService;
  
  HomePage({required this.dbService});
}
```

---

## 🗂️ Estructura de Archivos Detallada

### lib/paginas/ - Feature Screens

Cada pantalla sigue este patrón:

```dart
// 1. Import necesarios
import 'package:flutter/material.dart';
import '../servicio_bd.dart';

// 2. StatefulWidget o StatelessWidget
class MiPagina extends StatefulWidget {
  final String parametro;
  
  const MiPagina({required this.parametro});
  
  @override
  State<MiPagina> createState() => _MiPaginaState();
}

// 3. Estado
class _MiPaginaState extends State<MiPagina> {
  // Variables de estado
  String _data = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Cargar datos
  }
  
  @override
  Widget build(BuildContext context) {
    // Build UI
    return Scaffold();
  }
}
```

### lib/widgets/ - Componentes Reutilizables

```dart
// Widget reutilizable
class MiComponente extends StatelessWidget {
  final String titulo;
  final VoidCallback onPressed;
  
  const MiComponente({
    required this.titulo,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        onTap: onPressed,
      ),
    );
  }
}
```

### lib/modelos/ - Data Models

```dart
class Leccion {
  final int id;
  final String titulo;
  final String contenido;
  
  Leccion({
    required this.id,
    required this.titulo,
    required this.contenido,
  });
  
  factory Leccion.fromJson(Map<String, dynamic> json) {
    return Leccion(
      id: json['id'],
      titulo: json['titulo'],
      contenido: json['contenido'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
    };
  }
}
```

---

## 🔌 Servicios Principales

### DBService - Base de Datos

```dart
class DBService {
  // Autenticación
  static Future<bool> validateLogin({...}) async { }
  static Future<void> saveSession(String username) async { }
  static Future<bool> hasActiveSession() async { }
  
  // Usuario
  static Future<Map?> getUserData(String username) async { }
  static Future<void> updateUserProfile({...}) async { }
  
  // Progreso
  static Future<void> updateProgress({...}) async { }
  static Future<Map> getUserProgress(String username) async { }
  
  // Lecciones
  static Future<List> getLessons({...}) async { }
  static Future<Map?> getLessonContent(int id) async { }
}
```

### NotificationService - Notificaciones

```dart
class NotificationService {
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async { }
  
  static Future<void> startListening(String username) async { }
}
```

### CommentService - Comentarios

```dart
class CommentService {
  static Future<void> addComment({...}) async { }
  static Future<List> getComments({...}) async { }
  static Future<void> deleteComment(String id) async { }
}
```

---

## 🔐 Seguridad

### Validación de Entrada

```dart
String sanitize(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'[<>{}]'), '')
      .substring(0, min(input.length, 255));
}
```

### Gestión de Sesiones

```dart
// Guardar sesión
await SharedPreferences.getInstance()
    .setString('session_username', username);

// Verificar sesión
final prefs = await SharedPreferences.getInstance();
final username = prefs.getString('session_username');
```

### Autenticación

```dart
// Usar Supabase para autenticación segura
final response = await Supabase.instance.client
    .auth
    .signInWithPassword(email: email, password: password);
```

---

## 📊 Base de Datos - Supabase

### Tablas Principales

```sql
-- Usuarios
users
├── id (UUID)
├── username (VARCHAR UNIQUE)
├── email (VARCHAR UNIQUE)
├── password_hash (VARCHAR)
├── nombre_mostrado (VARCHAR)
├── genero (VARCHAR)
├── rol (VARCHAR: admin, teacher, student)
├── foto_perfil (BYTEA)
├── banner (BYTEA)
└── fecha_creacion (TIMESTAMP)

-- Lecciones
lessons
├── id (SERIAL)
├── titulo (VARCHAR)
├── descripcion (TEXT)
├── contenido (TEXT)
├── tema_id (INT)
├── orden (INT)
└── fecha_creacion (TIMESTAMP)

-- Progreso
user_progress
├── id (SERIAL)
├── usuario_id (UUID)
├── leccion_id (INT)
├── completada (BOOLEAN)
├── puntos_obtenidos (INT)
├── fecha_completada (TIMESTAMP)
└── fecha_creacion (TIMESTAMP)

-- Discusiones
discussion_spaces
├── id (UUID)
├── titulo (VARCHAR)
├── descripcion (TEXT)
├── creador_id (UUID)
├── fecha_creacion (TIMESTAMP)
└── activa (BOOLEAN)
```

---

## 🎬 Animaciones

KORULAB utiliza 8 widgets animados personalizados:

```dart
// Tarjeta con fade + slide
AnimatedCard(
  child: Widget,
  delayDuration: Duration,
)

// Lista escalonada
AnimatedListView(
  items: [Widget],
  itemDelay: Duration,
)

// Botón con escala
AnimatedElevatedButton(
  label: String,
  onPressed: VoidCallback,
)

// Y 5 más...
```

Ver [ANIMACIONES_GUIA.md](../ANIMACIONES_GUIA.md)

---

## 🧪 Testing

### Estructura de Tests

```dart
void main() {
  group('DBService', () {
    test('validateLogin retorna true con credenciales válidas', () async {
      final result = await DBService.validateLogin(
        username: 'test',
        password: 'password',
      );
      expect(result, isTrue);
    });
  });
}
```

### Ubicación

```
test/
├── widget_test.dart
├── unit/
│   ├── servicio_bd_test.dart
│   └── ...
└── integration/
    ├── login_test.dart
    └── ...
```

---

## 📈 Performance Considerations

### Optimizaciones Implementadas

1. **Lazy Loading**
   - Las lecciones se cargan bajo demanda
   - Las imágenes se comprimen

2. **Caching**
   - SharedPreferences para sesión
   - In-memory cache de datos

3. **Animaciones Eficientes**
   - SingleTickerProviderStateMixin
   - Curves optimizadas

4. **Build Optimization**
   - const constructors
   - Key en listas

---

## 🚀 Escalabilidad

### Para Crecer

1. **State Management:** Migrar a Provider/Bloc
2. **API:** Crear REST API en backend
3. **Testing:** Agregar más tests
4. **CI/CD:** Implementar pipeline
5. **Analytics:** Agregar tracking
6. **Localization:** Soportar múltiples idiomas

---

**Última actualización:** 2026-11-11  
**Versión:** 1.0.0
