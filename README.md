# 🌿 KORULAB - Plataforma de Aprendizaje Ambiental

> **Aprende sobre ecología y sostenibilidad de forma interactiva y divertida**

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Dart](https://img.shields.io/badge/Dart-3.11+-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

---

## 📋 Contenido

- [Descripción](#descripción)
- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Documentación](#documentación)
- [Guía Rápida](#guía-rápida)
- [Contribución](#contribución)
- [Licencia](#licencia)

---

## 🎯 Descripción

**KORULAB** es una plataforma educativa interactiva diseñada para enseñar conceptos de ecología, sostenibilidad y cuidado ambiental. Combina lecciones, cuestionarios, retos y comunidades de discusión para crear una experiencia de aprendizaje engaging.

### Objetivos Principales
- ✅ Educar sobre temas ambientales
- ✅ Gamificar el aprendizaje
- ✅ Crear comunidad de usuarios comprometidos
- ✅ Fomentar acciones ecológicas reales

---

## ✨ Características

### 🎓 Educación
- 📚 Lecciones estructuradas por temas
- 🎯 Cuestionarios interactivos
- 📊 Seguimiento de progreso
- 🏆 Sistema de badges y logros

### 🎮 Gamificación
- 🔥 Racha diaria de aprendizaje
- 💰 Sistema de puntos y moneda (Korucoins)
- 🏪 Tienda de items virtuales
- 🎁 Recompensas por logros

### 👥 Comunidad
- 💬 Espacios de discusión
- 🤝 Colaboración entre usuarios
- 📝 Preguntas y respuestas
- 🌐 Conectar con otros estudiantes

### 🎬 Experiencia
- ✨ Animaciones suaves y profesionales
- 🎨 Diseño visual moderno
- 📱 Interfaz responsive
- 🌙 Tema oscuro optimizado

---

## 📱 Requisitos

### Hardware
- **iOS**: iPhone 11+ (iOS 11.0+)
- **Android**: Dispositivo con Android 5.0+
- **RAM**: Mínimo 2GB
- **Almacenamiento**: 100MB libre

### Software
- **Flutter**: 3.0 o superior
- **Dart**: 3.11 o superior
- **SDK**: 34+

### Cuentas
- Cuenta Supabase (base de datos)
- Configuración de Firebase (opcional)

---

## 🚀 Instalación

### 1️⃣ Requisitos Previos

```bash
# Verificar Flutter instalado
flutter doctor

# Verificar versiones
flutter --version
dart --version
```

### 2️⃣ Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/korulab.git
cd korulab
```

### 3️⃣ Instalar Dependencias

```bash
flutter pub get
```

### 4️⃣ Configurar Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=tu_url_supabase
SUPABASE_ANON_KEY=tu_anon_key
```

O configura en `lib/servicio_bd.dart`:

```dart
const String supabaseUrl = 'tu_url';
const String supabaseAnonKey = 'tu_key';
```

### 5️⃣ Ejecutar la Aplicación

```bash
# Desarrollo
flutter run

# Dispositivo específico
flutter run -d <device_id>

# Web
flutter run -d chrome

# Build Release
flutter build apk      # Android
flutter build ipa      # iOS
```

---

## 📁 Estructura del Proyecto

```
korulab/
├── lib/
│   ├── main.dart                      # Punto de entrada
│   ├── servicio_bd.dart              # Servicios de base de datos
│   ├── pagina_bienvenida.dart        # Splash screen
│   ├── pagina_perfil.dart            # Perfil de usuario
│   ├── pagina_registro.dart          # Registro
│   │
│   ├── paginas/                       # Pantallas principales
│   │   ├── pagina_inicio.dart        # Home
│   │   ├── pagina_login.dart         # Login
│   │   ├── pagina_curso.dart         # Detalle de curso
│   │   ├── pagina_quiz.dart          # Cuestionarios
│   │   ├── pagina_retos_ecologicos.dart  # Retos
│   │   ├── pagina_tienda.dart        # Tienda de items
│   │   ├── pagina_discusion.dart     # Discusiones
│   │   └── ...
│   │
│   ├── widgets/                       # Componentes reutilizables
│   │   ├── animated_widgets.dart     # Widgets con animaciones
│   │   ├── selector_cuentas.dart     # Selector de cuentas
│   │   ├── tarjetas_inicio.dart      # Tarjetas principales
│   │   ├── mascota_guia.dart         # Mascota guía
│   │   └── ...
│   │
│   ├── modelos/                       # Modelos de datos
│   │   ├── modelos_discusion.dart    # Modelos de discusión
│   │   └── ...
│   │
│   ├── servicios/                     # Servicios
│   │   ├── estadisticas_progreso.dart
│   │   └── ...
│   │
│   └── assets/                        # Recursos
│       ├── images/
│       ├── fonts/
│       └── ...
│
├── test/
│   └── widget_test.dart              # Tests
│
├── android/                           # Configuración Android
├── ios/                              # Configuración iOS
├── web/                              # Configuración Web
│
├── pubspec.yaml                      # Dependencias
├── analysis_options.yaml             # Análisis de código
├── README.md                         # Este archivo
└── ...

```

---

## 🚀 Guía Rápida

### Para Desarrolladores Nuevos

1. **Clonar y configurar:**
   ```bash
   git clone <repository>
   cd korulab
   flutter pub get
   ```

2. **Ejecutar en emulador:**
   ```bash
   flutter emulators --launch android_emulator
   flutter run
   ```

3. **Primeros pasos:**
   - Lee [docs/INDEX.md](./docs/INDEX.md) - Índice de documentación
   - Sigue [docs/GUIA_DESARROLLO.md](./docs/GUIA_DESARROLLO.md) - Setup completo
   - Revisa [docs/ARQUITECTURA.md](./docs/ARQUITECTURA.md) - Entender la estructura

### Para Agregar Funcionalidad

1. **Crear nueva pantalla:**
   - Seguir patrón en [docs/GUIA_DESARROLLO.md](./docs/GUIA_DESARROLLO.md#crear-una-nueva-pantalla)
   - Ver ejemplos en [lib/paginas/](./lib/paginas/)

2. **Usar componentes:**
   - Catálogo completo: [docs/COMPONENTES.md](./docs/COMPONENTES.md)
   - Widgets animados: [lib/widgets/animated_widgets.dart](./lib/widgets/animated_widgets.dart)

3. **Conectar con BD:**
   - Referencia: [docs/API.md](./docs/API.md)
   - Ejemplos: [docs/API.md#ejemplos-completos](./docs/API.md#ejemplos-completos)

### Para Agregar Animaciones

1. **Referencia rápida:** [ANIMACIONES_QUICKREF.md](./ANIMACIONES_QUICKREF.md)
2. **Guía completa:** [ANIMACIONES_GUIA.md](./ANIMACIONES_GUIA.md)
3. **Código de ejemplo:** [EJEMPLOS_ANIMACIONES.dart](./EJEMPLOS_ANIMACIONES.dart)

---

## 📚 Documentación

### Guías Principales

| Documento | Descripción |
|-----------|-------------|
| [docs/INDEX.md](./docs/INDEX.md) | Índice y navegación de toda la documentación |
| [docs/ARQUITECTURA.md](./docs/ARQUITECTURA.md) | Diseño de la aplicación |
| [docs/API.md](./docs/API.md) | Endpoints y servicios |
| [COMPONENTES.md](./docs/COMPONENTES.md) | Widgets y UI |
| [GUIA_DESARROLLO.md](./docs/GUIA_DESARROLLO.md) | Cómo desarrollar |
| [ANIMACIONES_GUIA.md](./ANIMACIONES_GUIA.md) | Sistema de animaciones |
| [CONTRIBUIR.md](./CONTRIBUTING.md) | Guía de contribución |

### Guías Adicionales

- **[COMIENZA_AQUI.md](./COMIENZA_AQUI.md)** - Introducción a animaciones
- **[ANIMACIONES_QUICKREF.md](./ANIMACIONES_QUICKREF.md)** - Referencia rápida
- **[CORRECCIONES_REALIZADAS.md](./CORRECCIONES_REALIZADAS.md)** - Historial de fixes

---

## 🏗️ Arquitectura

### Patrones Utilizados

- **MVC/MVVM**: Separación de vistas y lógica
- **Provider**: Gestión de estado (si aplica)
- **Bloc**: Manejo de lógica de negocio
- **Repository**: Acceso a datos

### Capas

```
┌─────────────────────────────┐
│   UI Layer (Widgets)        │  ← Pantallas y componentes
├─────────────────────────────┤
│   Logic Layer (Servicios)   │  ← Lógica de negocio
├─────────────────────────────┤
│   Data Layer (Supabase)     │  ← Base de datos
└─────────────────────────────┘
```

---

## 🔑 Servicios Principales

### DBService
Gestiona toda la interacción con la base de datos Supabase.

```dart
import 'servicio_bd.dart';

// Validar login
final isValid = await DBService.validateLogin(
  username: 'usuario',
  password: 'contraseña',
);

// Obtener usuario
final user = await DBService.getSessionUsername();

// Guardar sesión
await DBService.saveSession('usuario');
```

### NotificationService
Maneja notificaciones locales y en tiempo real.

```dart
import 'servicio_notificaciones.dart';

// Iniciar escucha
await NotificationService.startListening('usuario');

// Enviar notificación
await NotificationService.showNotification(
  title: 'Título',
  body: 'Cuerpo',
);
```

---

## 🎨 Componentes Animados

KORULAB incluye **8 widgets animados** listos para usar:

```dart
import 'widgets/animated_widgets.dart';

// Tarjeta animada (la más usada)
AnimatedCard(
  child: Text('Contenido'),
  delayDuration: Duration(milliseconds: 200),
)

// Lista escalonada
AnimatedListView(
  items: [Item1, Item2, Item3],
  itemDelay: Duration(milliseconds: 100),
)

// Botón animado
AnimatedElevatedButton(
  label: 'Presiona',
  onPressed: () {},
  icon: Icons.check,
)
```

Ver [ANIMACIONES_GUIA.md](./ANIMACIONES_GUIA.md) para más detalles.

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Test específico
flutter test test/widget_test.dart

# Con coverage
flutter test --coverage
```

### Crear Nuevos Tests

```dart
void main() {
  testWidgets('Mi test', (WidgetTester tester) async {
    await tester.pumpWidget(const KoruApp());
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
```

---

## 📊 Base de Datos

### Estructura Supabase

```sql
-- Usuarios
CREATE TABLE usuarios (
  id UUID PRIMARY KEY,
  username VARCHAR UNIQUE,
  email VARCHAR UNIQUE,
  contraseña VARCHAR,
  nombre_mostrado VARCHAR,
  genero VARCHAR,
  rol VARCHAR,
  foto_perfil BYTEA,
  banner BYTEA,
  fecha_creacion TIMESTAMP
);

-- Lecciones
CREATE TABLE lecciones (
  id SERIAL PRIMARY KEY,
  titulo VARCHAR,
  descripcion TEXT,
  contenido TEXT,
  ...
);

-- Progreso
CREATE TABLE progreso_usuario (
  id SERIAL PRIMARY KEY,
  usuario_id UUID,
  leccion_id INTEGER,
  completada BOOLEAN,
  puntos_obtenidos INTEGER,
  ...
);
```

---

## 🔐 Seguridad

### Políticas Implementadas

- ✅ Hashing de contraseñas
- ✅ Validación de entrada
- ✅ Autenticación Supabase
- ✅ Autorización por rol
- ✅ HTTPS/TLS
- ✅ Datos encriptados en tránsito

### Mejores Prácticas

```dart
// ✅ BIEN: Validar entrada
String sanitize(String input) {
  return input.trim().replaceAll(RegExp(r'[<>]'), '');
}

// ❌ MAL: No validar
String userInput = request.body;
```

---

## 🚀 Deployment

### Android

```bash
# Build release
flutter build apk --release

# Crear app bundle
flutter build appbundle --release

# Ubicación: build/app/outputs/
```

### iOS

```bash
# Build release
flutter build ipa --release

# Firmar y distribuir
# Ver: https://flutter.dev/docs/deployment/ios
```

### Web

```bash
# Build web
flutter build web --release

# Deploy (ejemplo con Firebase)
firebase deploy --only hosting
```

---

## 📈 Performance

### Métricas Objetivo

- ⚡ Tiempo de inicio: <2s
- 🎬 FPS: 60+ en animaciones
- 💾 Tamaño APK: <50MB
- 🔋 Batería: <5% por hora de uso

### Optimizaciones Aplicadas

- ✅ Lazy loading de imágenes
- ✅ Caché de datos
- ✅ Compresión de assets
- ✅ Tree-shaking de código
- ✅ Animaciones optimizadas

---

## 🐛 Reporte de Bugs

Encontraste un bug? Por favor:

1. Verifica que no esté reportado
2. Crea un issue con:
   - Descripción clara
   - Pasos para reproducir
   - Logs/screenshots
   - Dispositivo y versión de SO

---

## 💬 Soporte

### Canales de Soporte

- 📧 Email: support@korulab.com
- 🐦 Twitter: @korulab
- 💬 Discord: [Unirse al servidor](#)
- 📝 Issues: GitHub Issues

---

## 🤝 Contribuir

¿Quieres contribuir? ¡Excelente! Lee [CONTRIBUTING.md](./CONTRIBUTING.md)

### Proceso Rápido

1. Fork el proyecto
2. Crea una rama: `git checkout -b feature/nueva-feature`
3. Commit: `git commit -m 'Add nueva-feature'`
4. Push: `git push origin feature/nueva-feature`
5. Pull Request

---

## 📝 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver [LICENSE](./LICENSE) para detalles.

---

## 👥 Créditos

### Desarrollo
- **Equipo KORULAB** - Desarrollo principal
- **Contributors** - Contribuciones y feedback

### Tecnologías
- [Flutter](https://flutter.dev)
- [Supabase](https://supabase.com)
- [Material Design](https://material.io)

---

## 📌 Changelog

### Version 1.0.0 (2026-11-11)
- ✅ Lanzamiento inicial
- ✅ Sistema de autenticación
- ✅ Lecciones y cuestionarios
- ✅ Retos ecológicos
- ✅ Sistema de puntos
- ✅ Comunidad y discusiones
- ✨ Animaciones profesionales

---

## 🎯 Roadmap

### Q1 2026
- [ ] Soporte offline
- [ ] Sincronización automática
- [ ] Integración social media

### Q2 2026
- [ ] App web completa
- [ ] API REST pública
- [ ] Certificados digitales

### Q3 2026
- [ ] Integraciones con terceros
- [ ] Analytics avanzado
- [ ] Personalización de temas

---

**Última actualización:** 2026-11-11  
**Versión:** 1.0.0  
**Mantenedor:** Equipo KORULAB

---

¿Preguntas? Abre un issue o contacta al equipo de desarrollo.

