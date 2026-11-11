# 🔌 Documentación de API - KORULAB

## 📋 Contenido

1. [Configuración de Supabase](#configuración-de-supabase)
2. [Autenticación](#autenticación)
3. [Usuarios](#usuarios)
4. [Lecciones y Cursos](#lecciones-y-cursos)
5. [Progreso](#progreso)
6. [Comentarios y Discusiones](#comentarios-y-discusiones)
7. [Tienda y Moneda](#tienda-y-moneda)
8. [Retos Ecológicos](#retos-ecológicos)
9. [Notificaciones](#notificaciones)
10. [Errores y Códigos](#errores-y-códigos)

---

## 🔐 Configuración de Supabase

### Inicialización en Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  runApp(const KoruApp());
}
```

### Variables de Entorno

Crear archivo `.env`:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
```

### Conexión Segura

```dart
// Usar anonKey para operaciones públicas
final supabase = Supabase.instance.client;

// Header de autenticación automático
final auth = supabase.auth;
```

---

## 🔑 Autenticación

### Registro de Usuario

**Endpoint:** `auth.signUp()`

```dart
Future<bool> registrarUsuario({
  required String email,
  required String password,
  required String username,
}) async {
  try {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': username,
      },
    );
    
    if (response.user != null) {
      // Crear registro en tabla 'users'
      await supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'username': username,
        'display_name': username,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    }
    return false;
  } on AuthException catch (error) {
    print('Error: ${error.message}');
    return false;
  }
}
```

### Iniciar Sesión

**Endpoint:** `auth.signInWithPassword()`

```dart
Future<bool> iniciarSesion({
  required String email,
  required String password,
}) async {
  try {
    final response = await Supabase.instance.client.auth
        .signInWithPassword(
          email: email,
          password: password,
        );
    
    if (response.user != null) {
      // Guardar sesión localmente
      await _guardarSesion(response.user!.id);
      return true;
    }
    return false;
  } on AuthException catch (error) {
    print('Error: ${error.message}');
    return false;
  }
}
```

### Cerrar Sesión

```dart
Future<void> cerrarSesion() async {
  await Supabase.instance.client.auth.signOut();
  // Limpiar datos locales
  await SharedPreferences.getInstance()
      .remove('session_user_id');
}
```

### Usuario Actual

```dart
User? obtenerUsuarioActual() {
  return Supabase.instance.client.auth.currentUser;
}

Future<String?> obtenerIdUsuarioActual() async {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.id;
}
```

---

## 👤 Usuarios

### Obtener Perfil de Usuario

**Endpoint:** `SELECT * FROM users WHERE id = ?`

```dart
Future<Map<String, dynamic>?> obtenerPerfil(String userId) async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    
    return response;
  } catch (error) {
    print('Error: $error');
    return null;
  }
}
```

### Actualizar Perfil

**Endpoint:** `UPDATE users SET ... WHERE id = ?`

```dart
Future<bool> actualizarPerfil({
  required String userId,
  String? displayName,
  String? genero,
  String? bio,
}) async {
  try {
    await Supabase.instance.client
        .from('users')
        .update({
          if (displayName != null) 'display_name': displayName,
          if (genero != null) 'genero': genero,
          if (bio != null) 'bio': bio,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

### Subir Foto de Perfil

**Endpoint:** `storage.upload()`

```dart
Future<String?> subirFotoPerfil({
  required String userId,
  required File imagen,
}) async {
  try {
    final nombreArchivo = 'profile_$userId';
    
    await Supabase.instance.client.storage
        .from('avatars')
        .upload(nombreArchivo, imagen);
    
    final url = Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(nombreArchivo);
    
    // Guardar URL en base de datos
    await actualizarPerfil(
      userId: userId,
      // Usar la URL...
    );
    
    return url;
  } catch (error) {
    print('Error: $error');
    return null;
  }
}
```

### Obtener Estadísticas de Usuario

```dart
Future<Map<String, dynamic>?> obtenerEstadisticas(String userId) async {
  try {
    final response = await Supabase.instance.client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .single();
    
    return response;
  } catch (error) {
    print('Error: $error');
    return null;
  }
}
```

**Respuesta:**

```json
{
  "user_id": "abc-123",
  "total_points": 1250,
  "completed_lessons": 15,
  "current_streak": 7,
  "achievements_count": 5,
  "friends_count": 12
}
```

---

## 📚 Lecciones y Cursos

### Obtener Todos los Cursos

**Endpoint:** `SELECT * FROM courses`

```dart
Future<List<Curso>> obtenerCursos() async {
  try {
    final response = await Supabase.instance.client
        .from('courses')
        .select()
        .order('orden', ascending: true);
    
    return (response as List)
        .map((data) => Curso.fromJson(data))
        .toList();
  } catch (error) {
    print('Error: $error');
    return [];
  }
}
```

**Respuesta:**

```json
[
  {
    "id": 1,
    "titulo": "Fundamentos de Ecología",
    "descripcion": "Aprende los conceptos básicos...",
    "tema_id": 1,
    "total_lecciones": 5,
    "orden": 1,
    "imagen": "url_imagen"
  }
]
```

### Obtener Lecciones de un Curso

**Endpoint:** `SELECT * FROM lessons WHERE course_id = ?`

```dart
Future<List<Leccion>> obtenerLecciones(int cursoId) async {
  try {
    final response = await Supabase.instance.client
        .from('lessons')
        .select()
        .eq('course_id', cursoId)
        .order('orden', ascending: true);
    
    return (response as List)
        .map((data) => Leccion.fromJson(data))
        .toList();
  } catch (error) {
    print('Error: $error');
    return [];
  }
}
```

### Obtener Contenido de Lección

**Endpoint:** `SELECT * FROM lessons WHERE id = ?`

```dart
Future<Map<String, dynamic>?> obtenerContenidoLeccion(int leccionId) async {
  try {
    final response = await Supabase.instance.client
        .from('lessons')
        .select()
        .eq('id', leccionId)
        .single();
    
    return response;
  } catch (error) {
    print('Error: $error');
    return null;
  }
}
```

**Respuesta:**

```json
{
  "id": 1,
  "titulo": "Introducción",
  "contenido": "HTML/texto con contenido...",
  "video_url": "https://youtube.com/...",
  "imagen": "url_imagen",
  "duracion_minutos": 15,
  "prerequisito_id": null
}
```

---

## 📊 Progreso

### Marcar Lección como Completada

**Endpoint:** `INSERT INTO user_progress ...`

```dart
Future<bool> marcarLeccionCompletada({
  required String userId,
  required int leccionId,
  required int puntosObtenidos,
}) async {
  try {
    await Supabase.instance.client
        .from('user_progress')
        .insert({
          'user_id': userId,
          'lesson_id': leccionId,
          'completada': true,
          'puntos_obtenidos': puntosObtenidos,
          'fecha_completada': DateTime.now().toIso8601String(),
        },
          onConflict: 'user_id,lesson_id',
        )
        .single();
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

### Obtener Progreso del Usuario

**Endpoint:** `SELECT * FROM user_progress WHERE user_id = ?`

```dart
Future<Map<String, dynamic>> obtenerProgreso(String userId) async {
  try {
    final response = await Supabase.instance.client
        .from('user_progress')
        .select()
        .eq('user_id', userId);
    
    return {
      'total_completadas': response.length,
      'puntos_totales': response.fold<int>(
        0,
        (sum, item) => sum + (item['puntos_obtenidos'] as int? ?? 0),
      ),
      'lecciones': response,
    };
  } catch (error) {
    print('Error: $error');
    return {};
  }
}
```

### Obtener Progreso del Curso

**Endpoint:** Consulta combinada

```dart
Future<double> obtenerProgresoCurso({
  required String userId,
  required int cursoId,
}) async {
  try {
    // Obtener total de lecciones
    final totalLecciones = await Supabase.instance.client
        .from('lessons')
        .select('id')
        .eq('course_id', cursoId);
    
    // Obtener completadas
    final completadas = await Supabase.instance.client
        .from('user_progress')
        .select('id')
        .eq('user_id', userId)
        .in_(
          'lesson_id',
          (totalLecciones as List).map((l) => l['id']).toList(),
        )
        .eq('completada', true);
    
    if (totalLecciones.isEmpty) return 0.0;
    
    return (completadas.length / totalLecciones.length) * 100;
  } catch (error) {
    print('Error: $error');
    return 0.0;
  }
}
```

---

## 💬 Comentarios y Discusiones

### Crear Discusión

**Endpoint:** `INSERT INTO discussions ...`

```dart
Future<bool> crearDiscusion({
  required String userId,
  required String titulo,
  required String contenido,
  int? leccionId,
}) async {
  try {
    await Supabase.instance.client
        .from('discussions')
        .insert({
          'user_id': userId,
          'titulo': titulo,
          'contenido': contenido,
          'lesson_id': leccionId,
          'created_at': DateTime.now().toIso8601String(),
        });
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

### Obtener Discusiones

**Endpoint:** `SELECT * FROM discussions`

```dart
Future<List<Discusion>> obtenerDiscusiones({
  int? leccionId,
  int limit = 20,
  int offset = 0,
}) async {
  try {
    var query = Supabase.instance.client
        .from('discussions')
        .select(
          '''
          *,
          user:users(username, foto_perfil),
          comentarios:comments(count)
          ''',
        )
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    if (leccionId != null) {
      query = query.eq('lesson_id', leccionId);
    }
    
    final response = await query;
    
    return (response as List)
        .map((data) => Discusion.fromJson(data))
        .toList();
  } catch (error) {
    print('Error: $error');
    return [];
  }
}
```

### Agregar Comentario

**Endpoint:** `INSERT INTO comments ...`

```dart
Future<bool> agregarComentario({
  required String userId,
  required int discusionId,
  required String contenido,
}) async {
  try {
    await Supabase.instance.client
        .from('comments')
        .insert({
          'user_id': userId,
          'discussion_id': discusionId,
          'contenido': contenido,
          'created_at': DateTime.now().toIso8601String(),
        });
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

---

## 🛍️ Tienda y Moneda

### Obtener Items de Tienda

**Endpoint:** `SELECT * FROM shop_items`

```dart
Future<List<ShopItem>> obtenerItemsTienda() async {
  try {
    final response = await Supabase.instance.client
        .from('shop_items')
        .select()
        .eq('visible', true)
        .order('precio', ascending: true);
    
    return (response as List)
        .map((data) => ShopItem.fromJson(data))
        .toList();
  } catch (error) {
    print('Error: $error');
    return [];
  }
}
```

**Respuesta:**

```json
[
  {
    "id": 1,
    "nombre": "Mascota Especial",
    "descripcion": "Una mascota única para tu perfil",
    "precio": 100,
    "tipo": "mascota",
    "imagen": "url_imagen",
    "raro": true
  }
]
```

### Comprar Item

**Endpoint:** `INSERT INTO purchases ... (actualiza puntos)`

```dart
Future<bool> comprarItem({
  required String userId,
  required int itemId,
}) async {
  try {
    // Obtener puntos del usuario
    final userStats = await Supabase.instance.client
        .from('user_stats')
        .select('total_points')
        .eq('user_id', userId)
        .single();
    
    // Obtener precio del item
    final item = await Supabase.instance.client
        .from('shop_items')
        .select('precio')
        .eq('id', itemId)
        .single();
    
    final puntos = userStats['total_points'] as int;
    final precio = item['precio'] as int;
    
    if (puntos < precio) {
      throw Exception('Puntos insuficientes');
    }
    
    // Registrar compra
    await Supabase.instance.client
        .from('purchases')
        .insert({
          'user_id': userId,
          'item_id': itemId,
          'precio_pagado': precio,
          'purchased_at': DateTime.now().toIso8601String(),
        });
    
    // Deducir puntos
    await Supabase.instance.client
        .from('user_stats')
        .update({
          'total_points': puntos - precio,
        })
        .eq('user_id', userId);
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

---

## 🌿 Retos Ecológicos

### Obtener Retos

**Endpoint:** `SELECT * FROM challenges`

```dart
Future<List<Reto>> obtenerRetos({
  String? dificultad, // 'facil', 'medio', 'dificil'
  int limit = 10,
}) async {
  try {
    var query = Supabase.instance.client
        .from('challenges')
        .select()
        .eq('activo', true);
    
    if (dificultad != null) {
      query = query.eq('dificultad', dificultad);
    }
    
    final response = await query.limit(limit);
    
    return (response as List)
        .map((data) => Reto.fromJson(data))
        .toList();
  } catch (error) {
    print('Error: $error');
    return [];
  }
}
```

### Completar Reto

**Endpoint:** `INSERT INTO challenge_progress ...`

```dart
Future<bool> completarReto({
  required String userId,
  required int retoId,
}) async {
  try {
    await Supabase.instance.client
        .from('challenge_progress')
        .insert({
          'user_id': userId,
          'challenge_id': retoId,
          'completada': true,
          'completed_at': DateTime.now().toIso8601String(),
        },
          onConflict: 'user_id,challenge_id',
        );
    
    // Agregar puntos
    const puntosReto = 50;
    await agregarPuntos(userId, puntosReto);
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

---

## 🔔 Notificaciones

### Crear Notificación

**Endpoint:** `INSERT INTO notifications ...`

```dart
Future<bool> crearNotificacion({
  required String userId,
  required String titulo,
  required String mensaje,
  String? tipo, // 'logro', 'mensaje', 'reto'
}) async {
  try {
    await Supabase.instance.client
        .from('notifications')
        .insert({
          'user_id': userId,
          'titulo': titulo,
          'mensaje': mensaje,
          'tipo': tipo,
          'leida': false,
          'created_at': DateTime.now().toIso8601String(),
        });
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

### Obtener Notificaciones

```dart
Future<List<Notificacion>> obtenerNotificaciones(
  String userId, {
  bool noLeidasSolo = false,
}) async {
  try {
    var query = Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    if (noLeidasSolo) {
      query = query.eq('leida', false);
    }
    
    final response = await query;
    
    return (response as List)
        .map((data) => Notificacion.fromJson(data))
        .toList();
  } catch (error) {
    print('Error: $error');
    return [];
  }
}
```

### Marcar Notificación como Leída

```dart
Future<bool> marcarNotificacionLeida(String notificacionId) async {
  try {
    await Supabase.instance.client
        .from('notifications')
        .update({'leida': true})
        .eq('id', notificacionId);
    
    return true;
  } catch (error) {
    print('Error: $error');
    return false;
  }
}
```

---

## ⚠️ Errores y Códigos

### Códigos de Error

| Código | Mensaje | Solución |
|--------|---------|----------|
| 401 | No autorizado | Verificar token de autenticación |
| 403 | Acceso denegado | Verificar permisos RLS |
| 404 | No encontrado | Verificar ID del recurso |
| 409 | Conflicto | Registro duplicado, usar upsert |
| 413 | Archivo muy grande | Comprimir imagen/archivo |
| 429 | Demasiadas solicitudes | Implementar rate limiting |
| 500 | Error del servidor | Contactar soporte |

### Manejo de Errores

```dart
try {
  final response = await Supabase.instance.client
      .from('tabla')
      .select();
} on AuthException catch (error) {
  print('Error de autenticación: ${error.message}');
  // Redirigir a login
} on PostgrestException catch (error) {
  print('Error de BD: ${error.message}');
  // Mostrar mensaje al usuario
} catch (error) {
  print('Error desconocido: $error');
}
```

### Rate Limiting

```dart
// Implementar delays entre solicitudes
const rateLimitDelay = Duration(milliseconds: 100);

Future<void> operacionConRateLimit() async {
  await Future.delayed(rateLimitDelay);
  // Ejecutar operación
}
```

---

## 📖 Ejemplos Completos

### Flujo Completo de Login

```dart
Future<bool> loginCompleto(String email, String password) async {
  try {
    // 1. Autenticar
    final authResponse = await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);
    
    if (authResponse.user == null) {
      throw Exception('Autenticación fallida');
    }
    
    // 2. Obtener datos del usuario
    final userId = authResponse.user!.id;
    final userData = await obtenerPerfil(userId);
    
    if (userData == null) {
      throw Exception('Usuario no encontrado');
    }
    
    // 3. Guardar sesión local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('username', userData['username']);
    
    return true;
  } catch (error) {
    print('Error en login: $error');
    return false;
  }
}
```

### Flujo Completo de Lección

```dart
Future<void> completarLeccionCompleta({
  required String userId,
  required int leccionId,
}) async {
  try {
    // 1. Obtener datos de la lección
    final leccion = await obtenerContenidoLeccion(leccionId);
    
    // 2. Mostrar contenido
    // ...
    
    // 3. Completar reto/quiz
    const puntosObtenidos = 100;
    
    // 4. Registrar progreso
    await marcarLeccionCompletada(
      userId: userId,
      leccionId: leccionId,
      puntosObtenidos: puntosObtenidos,
    );
    
    // 5. Crear notificación
    await crearNotificacion(
      userId: userId,
      titulo: '¡Lección completada!',
      mensaje: 'Ganaste $puntosObtenidos puntos',
    );
    
    // 6. Actualizar estadísticas
    // ...
    
    print('Lección completada exitosamente');
  } catch (error) {
    print('Error: $error');
  }
}
```

---

**Última actualización:** 2026-11-11  
**Versión:** 1.0.0  
**Mantener:** Cuando agregues nuevas tablas o endpoints
