# 📚 Índice de Documentación - KORULAB

Bienvenido a la documentación de KORULAB. Aquí encontrarás todo lo que necesitas para entender, usar y desarrollar la aplicación.

## 🚀 Comienza Aquí

**¿Nuevo en el proyecto?** Empieza por aquí:

1. Lee [README.md](../README.md) - Visión general del proyecto
2. Sigue [GUIA_DESARROLLO.md](#guía-de-desarrollo) - Configuración y primeros pasos
3. Aprende [ARQUITECTURA.md](#arquitectura) - Cómo está organizado el código

---

## 📖 Documentación Completa

### 🎯 Inicio Rápido
- **[README.md](../README.md)** - Descripción general, features, requisitos e instalación
- **[COMIENZA_AQUI.md](../COMIENZA_AQUI.md)** - Guía para animaciones (rápida referencia)

### 🏗️ Arquitectura
- **[ARQUITECTURA.md](./ARQUITECTURA.md)** - Visión de capas, módulos, flujos de datos y patrones
  - Capas (Presentation, Application, Data)
  - Módulos principales
  - Flujos de autenticación, lecciones y notificaciones
  - Patrones MVC, Singleton, Repository
  - Estructura de bases de datos

### 🎬 Animaciones
- **[ANIMACIONES_GUIA.md](../ANIMACIONES_GUIA.md)** - Referencia completa de animaciones
- **[ANIMACIONES_QUICKREF.md](../ANIMACIONES_QUICKREF.md)** - Cheatsheet rápido
- **[EJEMPLOS_ANIMACIONES.dart](../EJEMPLOS_ANIMACIONES.dart)** - Código de ejemplo

### 🧩 Componentes
- **[COMPONENTES.md](./COMPONENTES.md)** - Guía de todos los widgets reutilizables
  - Widgets animados (AnimatedCard, AnimatedButton, etc)
  - Tarjetas y contenedores
  - Inputs y formularios
  - Barras de progreso
  - Componentes de navegación
  - Ejemplos prácticos

### 💻 Desarrollo
- **[GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md)** - Guía completa para desarrolladores
  - Configuración del entorno (Windows, macOS, Linux)
  - Primeros pasos
  - Estructura del proyecto
  - Estándares de código
  - Flujos de trabajo comunes
  - Testing unitario y de widgets
  - Debugging con DevTools
  - Deployment (Android, iOS, Web)
  - Solución de problemas

### 🔌 API y Base de Datos
- **[API.md](./API.md)** - Documentación de Supabase y endpoints
  - Configuración de Supabase
  - Autenticación (registro, login, logout)
  - Usuarios (perfil, estadísticas)
  - Lecciones y cursos
  - Progreso del usuario
  - Comentarios y discusiones
  - Tienda y moneda
  - Retos ecológicos
  - Notificaciones
  - Códigos de error
  - Ejemplos completos

---

## 📁 Estructura de Documentación

```
docs/
├── INDEX.md                  ← Estás aquí
├── ARQUITECTURA.md           # Diseño de capas y módulos
├── COMPONENTES.md            # Widgets reutilizables
├── GUIA_DESARROLLO.md        # Para desarrolladores
├── API.md                    # Endpoints y Supabase
├── ROADMAP.md                # Planes futuros (próximamente)
└── FAQ.md                    # Preguntas frecuentes (próximamente)
```

---

## 🎓 Por Casos de Uso

### "Quiero agregar una animación"
1. Lee [ANIMACIONES_QUICKREF.md](../ANIMACIONES_QUICKREF.md)
2. Ver ejemplos en [EJEMPLOS_ANIMACIONES.dart](../EJEMPLOS_ANIMACIONES.dart)
3. Implementar usando guía en [ANIMACIONES_GUIA.md](../ANIMACIONES_GUIA.md)

### "Quiero crear una nueva pantalla"
1. Revisar estructura en [ARQUITECTURA.md](./ARQUITECTURA.md)
2. Seguir patrón en [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md) → "Crear una Nueva Pantalla"
3. Usar componentes de [COMPONENTES.md](./COMPONENTES.md)

### "Quiero conectar con la base de datos"
1. Entender conceptos en [API.md](./API.md) → "Configuración de Supabase"
2. Revisar ejemplos completos en [API.md](./API.md) → "Ejemplos Completos"
3. Seguir patrones de [ARQUITECTURA.md](./ARQUITECTURA.md) → "Data Layer"

### "Quiero hacer debugging"
1. Revisar herramientas en [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md) → "Debugging"
2. Ver solución de problemas en [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md) → "Solución de Problemas"

### "Quiero hacer deployment"
1. Seguir guía en [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md) → "Deployment"
2. Revisar checklist antes de publicar

### "Quiero entender la arquitectura"
1. Leer [ARQUITECTURA.md](./ARQUITECTURA.md)
2. Ver diagramas de flujos de datos
3. Revisar patrones de diseño

---

## 🔍 Búsqueda Rápida

### Por Tema

**Autenticación**
- [API.md](./API.md#autenticación) - Endpoints de autenticación
- [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md#integración-con-base-de-datos) - Implementación

**Lecciones y Cursos**
- [API.md](./API.md#lecciones-y-cursos) - Endpoints
- [ARQUITECTURA.md](./ARQUITECTURA.md#flujo-de-lección) - Flujo de datos

**Progreso**
- [API.md](./API.md#progreso) - Endpoints
- [ARQUITECTURA.md](./ARQUITECTURA.md#base-de-datos---supabase) - Esquema

**Animaciones**
- [ANIMACIONES_GUIA.md](../ANIMACIONES_GUIA.md) - Referencia completa
- [COMPONENTES.md](./COMPONENTES.md#widgets-animados) - Uso en componentes
- [EJEMPLOS_ANIMACIONES.dart](../EJEMPLOS_ANIMACIONES.dart) - Código

**Widgets**
- [COMPONENTES.md](./COMPONENTES.md) - Catálogo completo
- [ARQUITECTURA.md](./ARQUITECTURA.md#módulos) - Ubicación en proyecto

**Testing**
- [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md#testing) - Guía completa

**Errores**
- [API.md](./API.md#errores-y-códigos) - Códigos de error
- [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md#solución-de-problemas) - Troubleshooting

### Por Componente

**LoginPage**
- Flujo: [ARQUITECTURA.md](./ARQUITECTURA.md#flujo-de-autenticación)
- Componentes: [COMPONENTES.md](./COMPONENTES.md#formulario-completo)
- API: [API.md](./API.md#iniciar-sesión)
- Animaciones: [EJEMPLOS_ANIMACIONES.dart](../EJEMPLOS_ANIMACIONES.dart) → Formulario de login

**HomePage**
- Arquitectura: [ARQUITECTURA.md](./ARQUITECTURA.md#feature-modules)
- Componentes: [COMPONENTES.md](./COMPONENTES.md#lista-de-cursos-con-animación-escalonada)
- API: [API.md](./API.md#obtener-todos-los-cursos)

**LessonPage**
- Flujo: [ARQUITECTURA.md](./ARQUITECTURA.md#flujo-de-lección)
- API: [API.md](./API.md#obtener-contenido-de-lección)

---

## 🔧 Herramientas y Comandos

### Análisis y Formato

```bash
# Analizar código
flutter analyze

# Formatear código
dart format lib/

# Ambos
dart format lib/ && flutter analyze
```

### Testing

```bash
# Todos los tests
flutter test

# Test específico
flutter test test/widget_test.dart

# Con coverage
flutter test --coverage
```

### Ejecución

```bash
# Run en emulador
flutter run

# Run en dispositivo
flutter run -d <device-id>

# Run con hot reload
# Presiona 'r' en terminal
```

### Build

```bash
# APK (Android)
flutter build apk --release

# App Bundle (Android)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📞 Contacto y Soporte

### Donde obtener ayuda

- **Documentación oficial Flutter:** https://flutter.dev/docs
- **Documentación oficial Dart:** https://dart.dev/guides
- **Supabase Docs:** https://supabase.com/docs
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/flutter

### Reportar Problemas

Si encuentras un problema o error:
1. Verifica la sección "Solución de Problemas" en [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md)
2. Revisa los códigos de error en [API.md](./API.md#errores-y-códigos)
3. Crea un issue en el repositorio con:
   - Descripción clara del problema
   - Pasos para reproducir
   - Logs de error
   - Entorno (sistema operativo, versión de Flutter)

---

## 📋 Checklist de Lectura

### Para Desarrolladores Nuevos

- [ ] Leer [README.md](../README.md)
- [ ] Leer [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md) - Configuración
- [ ] Leer [ARQUITECTURA.md](./ARQUITECTURA.md) - Entender estructura
- [ ] Leer [COMPONENTES.md](./COMPONENTES.md) - Conocer widgets
- [ ] Revisar [EJEMPLOS_ANIMACIONES.dart](../EJEMPLOS_ANIMACIONES.dart) - Ver código real
- [ ] Hacer una pequeña tarea (ej: cambiar color de botón) para familiarizarse

### Para Agregar Funcionalidad

- [ ] Revisar [ARQUITECTURA.md](./ARQUITECTURA.md)
- [ ] Consultar ejemplos en [API.md](./API.md)
- [ ] Revisar [COMPONENTES.md](./COMPONENTES.md) para UI
- [ ] Revisar [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md#flujos-de-trabajo)
- [ ] Implementar
- [ ] Escribir tests
- [ ] Ejecutar `flutter analyze`
- [ ] Hacer commit con mensaje descriptivo

### Antes de Hacer Deployment

- [ ] Ejecutar `flutter analyze` - debe estar limpio
- [ ] Ejecutar `flutter test` - todos deben pasar
- [ ] Verificar funcionalidad en dispositivo real
- [ ] Revisar [GUIA_DESARROLLO.md](./GUIA_DESARROLLO.md#deployment)
- [ ] Seguir pasos de deployment específicos del platform

---

## 📊 Estadísticas de Documentación

- **Documentos:** 9+
- **Temas cubiertos:** 50+
- **Ejemplos de código:** 100+
- **Última actualización:** 2026-11-11
- **Versión de documentación:** 1.0.0

---

## 🔄 Mantener la Documentación

Cuando hagas cambios en el código:

1. Actualiza los archivos de documentación relacionados
2. Agrega ejemplos si cambiaste componentes públicos
3. Actualiza la fecha de última actualización
4. Sé consistente con el formato

Documentación = Código = Importante

---

## 📝 Notas

- Toda la documentación está en **español**
- Los ejemplos de código están en **Dart/Flutter**
- Se asume experiencia básica con Flutter y Dart
- Para conceptos muy avanzados, ver enlaces a documentación oficial

---

**Última actualización:** 2026-11-11  
**Mantener actualizado:** Especialmente cuando cambies arquitectura o agregues features
**¡Gracias por leer!** 🙏
