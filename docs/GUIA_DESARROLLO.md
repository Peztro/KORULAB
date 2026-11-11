# 👨‍💻 Guía de Desarrollo de KORULAB

## 📋 Contenido

1. [Configuración del Entorno](#configuración-del-entorno)
2. [Primeros Pasos](#primeros-pasos)
3. [Estructura del Proyecto](#estructura-del-proyecto)
4. [Estándares de Código](#estándares-de-código)
5. [Flujos de Trabajo](#flujos-de-trabajo)
6. [Testing](#testing)
7. [Debugging](#debugging)
8. [Deployment](#deployment)
9. [Solución de Problemas](#solución-de-problemas)

---

## 🛠️ Configuración del Entorno

### Requisitos Previos

- **Flutter SDK:** 3.0.0 o superior
- **Dart SDK:** 2.17.0 o superior
- **Android Studio** o **Visual Studio Code**
- **Android SDK:** 21 o superior
- **iOS Deployment Target:** 11.0 o superior (macOS)
- **Git:** Últimas versiones

### Instalación en Windows

```bash
# 1. Descargar Flutter SDK
# Ve a https://flutter.dev/docs/get-started/install/windows

# 2. Extraer en una carpeta (ej: C:\flutter)
# 3. Agregar flutter\bin a las variables de entorno PATH

# 4. Verificar instalación
flutter --version
dart --version

# 5. Obtener dependencias
flutter pub get

# 6. Ejecutar en emulador
flutter run
```

### Instalación en macOS

```bash
# 1. Usando Homebrew
brew install flutter

# 2. Verificar
flutter --version

# 3. Configurar iOS
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 4. Obtener dependencias
flutter pub get
```

### Instalación en Linux

```bash
# 1. Descargar y extraer
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_x.x.x-stable.tar.xz
tar xf flutter_linux_*.tar.xz

# 2. Agregar a PATH
export PATH="$PATH:~/flutter/bin"

# 3. Instalar dependencias
sudo apt install -y git curl build-essential

# 4. Ejecutar doctor
flutter doctor
```

### Configuración del IDE

#### Visual Studio Code

```json
// settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.enableSdkFormatter": true,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

Extensiones recomendadas:
- **Dart** (Dart-Code)
- **Flutter** (Dart-Code)
- **Awesome Flutter Snippets** (Nash)

#### Android Studio

1. Instalar plugins:
   - Flutter
   - Dart
   
2. Configurar SDK:
   - File → Project Structure
   - SDK Location → Agregar rutas de Flutter y Dart

---

## 🚀 Primeros Pasos

### Clonar el Repositorio

```bash
# Clonar
git clone <repository-url>
cd korulab

# Obtener dependencias
flutter pub get

# Verificar setup
flutter doctor
```

### Ejecutar la App

```bash
# Emulador Android
flutter emulators --launch android_emulator
flutter run

# Dispositivo Android conectado
flutter devices  # Ver dispositivos disponibles
flutter run -d <device-id>

# Emulador iOS (solo macOS)
open -a Simulator
flutter run

# Web
flutter run -d chrome

# Desktop (Windows)
flutter run -d windows
```

### Estructura Básica

```
korulab/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   ├── paginas/                  # Pantallas
│   ├── widgets/                  # Componentes
│   ├── modelos/                  # Data models
│   ├── servicios/                # Business logic
│   ├── datos/                    # Datos estáticos
│   └── theme.dart                # Temas
├── assets/                       # Recursos (imágenes, fuentes)
├── test/                         # Tests
├── pubspec.yaml                  # Dependencias
└── README.md                     # Documentación
```

---

## 📁 Estructura del Proyecto

### 📄 lib/main.dart

Punto de entrada de la aplicación. Define el tema, rutas y configuración global.

```dart
import 'package:flutter/material.dart';
import 'paginas/pagina_login.dart';
import 'paginas/pagina_inicio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar servicios aquí
  runApp(const KoruApp());
}

class KoruApp extends StatelessWidget {
  const KoruApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KORULAB',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        // Agregar más rutas aquí
      },
    );
  }
}
```

### 📁 lib/paginas/

Cada pantalla es una carpeta separada (opcional) o archivo individual.

```dart
import 'package:flutter/material.dart';
import '../widgets/animated_widgets.dart';
import '../servicio_bd.dart';

class MiPagina extends StatefulWidget {
  final String? parametro;
  
  const MiPagina({this.parametro});

  @override
  State<MiPagina> createState() => _MiPaginaState();
}

class _MiPaginaState extends State<MiPagina> {
  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    // Cargar datos, validar sesión, etc
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Página')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Retornar el contenido aquí
    return Container();
  }

  @override
  void dispose() {
    // Limpiar recursos
    super.dispose();
  }
}
```

### 🎨 lib/widgets/

Componentes reutilizables.

```dart
import 'package:flutter/material.dart';

class MiWidget extends StatelessWidget {
  final String titulo;
  final VoidCallback? onPressed;

  const MiWidget({
    required this.titulo,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(titulo),
        ),
      ),
    );
  }
}
```

### 📊 lib/modelos/

Modelos de datos.

```dart
class Usuario {
  final String id;
  final String username;
  final String email;
  final String? fotoPerfil;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    this.fotoPerfil,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fotoPerfil: json['foto_perfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'foto_perfil': fotoPerfil,
    };
  }
}
```

### 🔌 lib/servicios/

Lógica de negocio y servicios.

```dart
class LeccionService {
  static Future<List<Leccion>> obtenerLecciones(int cursoId) async {
    try {
      final response = await DBService.getLessons(courseId: cursoId);
      return response.map((data) => Leccion.fromJson(data)).toList();
    } catch (e) {
      print('Error al obtener lecciones: $e');
      rethrow;
    }
  }

  static Future<void> marcarCompletada(int leccionId) async {
    await DBService.updateProgress(lessonId: leccionId, completed: true);
  }
}
```

---

## 📝 Estándares de Código

### Convenciones de Nombres

```dart
// ✅ Archivos: snake_case
my_page.dart
user_service.dart

// ✅ Clases: PascalCase
class UserService {}
class HomePage extends StatelessWidget {}

// ✅ Variables: camelCase
String userName = '';
int userId = 0;

// ✅ Constantes: camelCase
const double defaultPadding = 16.0;
const String appName = 'KORULAB';

// ✅ Private: _camelCase
String _privateVariable = '';
void _privateMethod() {}
```

### Formateo

```bash
# Formatear archivos
dart format lib/

# Analizar código
flutter analyze

# Ambos juntos
dart format lib/ && flutter analyze
```

### Imports

```dart
// Orden: dart → flutter → packages → relativo
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/usuario.dart';
import '../servicios/db_service.dart';
import 'widget_local.dart';
```

### Documentación

```dart
/// Obtiene los datos del usuario desde la base de datos.
///
/// Parámetros:
/// * [userId] - ID único del usuario
/// * [includeProgress] - Si incluir progreso de lecciones
///
/// Retorna una lista de usuarios que coinciden con los criterios.
/// 
/// Lanza [DatabaseException] si ocurre un error.
Future<Usuario?> obtenerUsuario(
  String userId, {
  bool includeProgress = false,
}) async {
  // Implementación
}
```

### Manejo de Errores

```dart
// ✅ Bueno
try {
  await DBService.validateLogin(username: username, password: password);
} on DatabaseException catch (e) {
  print('Error de base de datos: ${e.message}');
  rethrow;
} catch (e) {
  print('Error inesperado: $e');
  rethrow;
}

// ❌ Evitar
try {
  await someFunction();
} catch (_) {
  // Silent catch es peligroso
}
```

---

## 🔄 Flujos de Trabajo

### Crear una Nueva Pantalla

```bash
# 1. Crear archivo
touch lib/paginas/pagina_nueva.dart

# 2. Crear clase base
cat > lib/paginas/pagina_nueva.dart << 'EOF'
import 'package:flutter/material.dart';

class NuevaPagina extends StatefulWidget {
  const NuevaPagina();

  @override
  State<NuevaPagina> createState() => _NuevaPaginaState();
}

class _NuevaPaginaState extends State<NuevaPagina> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Página')),
      body: const Center(child: Text('Contenido aquí')),
    );
  }
}
EOF

# 3. Registrar en main.dart
# Agregar a routes:
# '/nueva': (context) => const NuevaPagina(),
```

### Agregar Animaciones

```dart
import 'package:flutter/material.dart';
import '../widgets/animated_widgets.dart';

// Envolver widgets con AnimatedCard
AnimatedCard(
  delayDuration: Duration(milliseconds: 200),
  child: YourWidget(),
)

// O usar AnimatedListView para listas
AnimatedListView(
  items: items.map((item) => ItemWidget(item)).toList(),
  itemDelay: Duration(milliseconds: 100),
)
```

### Integración con Base de Datos

```dart
// 1. Crear modelo
// lib/modelos/mi_modelo.dart

// 2. Crear servicio
// lib/servicios/mi_service.dart
class MiService {
  static Future<MiModelo?> obtener(String id) async {
    final data = await DBService.query('tabla', id);
    return data != null ? MiModelo.fromJson(data) : null;
  }
}

// 3. Usar en pantalla
class MiPagina extends StatefulWidget {
  @override
  State<MiPagina> createState() => _MiPaginaState();
}

class _MiPaginaState extends State<MiPagina> {
  late Future<MiModelo?> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = MiService.obtener('id');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MiModelo?>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading(
            isLoading: true,
            child: Container(),
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Text('No hay datos');
        }
        return _buildContent(snapshot.data!);
      },
    );
  }

  Widget _buildContent(MiModelo modelo) {
    return ListView();
  }
}
```

---

## 🧪 Testing

### Tests Unitarios

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/modelos/usuario.dart';

void main() {
  group('Usuario', () {
    test('fromJson crea Usuario correctamente', () {
      final data = {
        'id': '123',
        'username': 'testuser',
        'email': 'test@example.com',
      };
      
      final usuario = Usuario.fromJson(data);
      
      expect(usuario.id, '123');
      expect(usuario.username, 'testuser');
      expect(usuario.email, 'test@example.com');
    });

    test('toJson convierte Usuario a Map', () {
      final usuario = Usuario(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
      );
      
      final json = usuario.toJson();
      
      expect(json['id'], '123');
      expect(json['username'], 'testuser');
    });
  });
}
```

### Tests de Widgets

```dart
void main() {
  testWidgets('HomePage muestra título', (WidgetTester tester) async {
    await tester.pumpWidget(const KoruApp());
    
    expect(find.text('KORULAB'), findsOneWidget);
  });

  testWidgets('Botón funciona correctamente', (WidgetTester tester) async {
    int clickCount = 0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () => clickCount++,
            child: const Text('Click'),
          ),
        ),
      ),
    );
    
    expect(clickCount, 0);
    await tester.tap(find.text('Click'));
    expect(clickCount, 1);
  });
}
```

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Test específico
flutter test test/widget_test.dart

# Con coverage
flutter test --coverage
```

---

## 🐛 Debugging

### Usar print/log

```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug: $variable');
}
```

### DevTools

```bash
# Abrir DevTools
flutter pub global activate devtools
devtools

# Conectar app
# El navegador abrirá en http://localhost:9100
```

### Breakpoints en VS Code

1. Abrir archivo
2. Click en número de línea
3. Ejecutar con `flutter run`
4. Debug toolbar aparecerá automáticamente

### Inspeccionar Widget

```dart
// Usar key para encontrar widgets
final key = GlobalKey<_MiWidgetState>();

MyWidget(key: key);

// Luego
key.currentState?.metodo();
```

---

## 🚀 Deployment

### Android

```bash
# 1. Crear keystore
keytool -genkey -v -keystore ~/key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias korulab

# 2. Configurar signing
# android/key.properties
storePassword=...
keyPassword=...
keyAlias=korulab
storeFile=../key.jks

# 3. Build APK
flutter build apk --release

# 4. Build App Bundle
flutter build appbundle --release

# Archivos en build/app/outputs/
```

### iOS

```bash
# 1. Abrir proyecto en Xcode
open ios/Runner.xcworkspace

# 2. Configurar Team ID y Bundle ID
# Xcode → Runner → Signing & Capabilities

# 3. Build
flutter build ios --release

# 4. Archive y distribuir desde Xcode
```

### Web

```bash
# Build para web
flutter build web --release

# Archivos en build/web/
# Puedes subirlos a cualquier hosting
```

---

## 🔧 Solución de Problemas

### "No Device Connected"

```bash
# Listar dispositivos
flutter devices

# Si no aparecen:
# Android: Habilitar debug USB en dispositivo
# iOS: Confiar en certificado

# Reconectar
flutter devices --refresh
```

### "Dependencias no encontradas"

```bash
# Limpiar y reinstalar
flutter clean
flutter pub get
flutter pub cache repair
flutter pub get
```

### "Build falló"

```bash
# Verificar análisis
flutter analyze

# Limpiar
flutter clean

# Rebuild
flutter build apk --debug
```

### "Hot Reload no funciona"

```bash
# Restart (completo)
# Press 'R' en terminal o Click en VS Code

# O usar hot_restart
flutter run --hot-reload
```

### "Error de versión de Dart"

```bash
# Verificar versión
dart --version

# Actualizar Flutter (incluye Dart)
flutter upgrade

# O cambiar SDK en pubspec.yaml
environment:
  sdk: ">=2.17.0 <3.0.0"
```

---

## 📚 Recursos Útiles

- [Documentación Flutter](https://flutter.dev/docs)
- [Documentación Dart](https://dart.dev/guides)
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Awesome](https://flutterawesome.com)
- [Pub.dev](https://pub.dev) - Repositorio de packages

---

**Última actualización:** 2026-11-11  
**Versión:** 1.0.0  
**Mantener actualizado:** Cuando cambies archivos o procesos
