import 'imagen_perfil.dart';
import 'perfil.dart';

DateTime? _fecha(Object? valor) =>
    valor is String ? DateTime.tryParse(valor)?.toLocal() : null;

/// Otra persona de la app (amigo, profesor o resultado de búsqueda).
class Contacto {
  const Contacto({
    required this.id,
    required this.username,
    this.displayName = '',
    this.foto,
    this.role = Rol.estudiante,
  });

  factory Contacto.desdeFila(Map<String, dynamic> fila, {String idKey = 'id'}) {
    return Contacto(
      id: fila[idKey] as String,
      username: fila['username'] as String? ?? '',
      displayName: fila['display_name'] as String? ?? '',
      foto: ImagenPerfil.desde(fila['profile_photo']),
      role: fila['role'] as String? ?? Rol.estudiante,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final ImagenPerfil? foto;
  final String role;

  bool get esProfesor => role == Rol.profesor || role == Rol.admin;

  String get nombreVisible =>
      displayName.trim().isNotEmpty ? displayName.trim() : '@$username';
}

/// Amistad o solicitud de amistad con [contacto].
class Amistad {
  const Amistad({
    required this.id,
    required this.contacto,
    required this.aceptada,
    required this.entrante,
    this.automatica = false,
  });

  factory Amistad.desdeFila(Map<String, dynamic> fila) => Amistad(
    id: fila['id'] as int,
    contacto: Contacto.desdeFila(fila, idKey: 'other_id'),
    aceptada: fila['status'] == 'accepted',
    entrante: fila['incoming'] == true,
    automatica: fila['automatic'] == true,
  );

  final int id;
  final Contacto contacto;
  final bool aceptada;

  /// True si la solicitud la envió la otra persona.
  final bool entrante;

  /// Amistad creada por rol (admin con todos, profesor con estudiantes);
  /// no se puede eliminar.
  final bool automatica;
}

/// Resumen de una conversación para la lista de chats.
class Conversacion {
  const Conversacion({
    required this.contacto,
    required this.ultimoMensaje,
    required this.ultimaFecha,
    required this.ultimoEsMio,
    required this.noLeidos,
  });

  factory Conversacion.desdeFila(Map<String, dynamic> fila) => Conversacion(
    contacto: Contacto.desdeFila(fila, idKey: 'partner_id'),
    ultimoMensaje: fila['last_body'] as String? ?? '',
    ultimaFecha: _fecha(fila['last_at']) ?? DateTime.now(),
    ultimoEsMio: fila['last_from_me'] == true,
    noLeidos: (fila['unread'] as num?)?.toInt() ?? 0,
  );

  final Contacto contacto;
  final String ultimoMensaje;
  final DateTime ultimaFecha;
  final bool ultimoEsMio;
  final int noLeidos;
}

/// Mensaje privado entre dos personas.
class MensajeDirecto {
  const MensajeDirecto({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.texto,
    required this.fecha,
    this.leido,
    this.imagenPath,
  });

  factory MensajeDirecto.desdeFila(Map<String, dynamic> fila) => MensajeDirecto(
    id: fila['id'] as int,
    remitenteId: fila['sender_id'] as String,
    destinatarioId: fila['recipient_id'] as String,
    texto: fila['body'] as String? ?? '',
    fecha: _fecha(fila['created_at']) ?? DateTime.now(),
    leido: _fecha(fila['read_at']),
    imagenPath: fila['image_path'] as String?,
  );

  final int id;
  final String remitenteId;
  final String destinatarioId;
  final String texto;
  final DateTime fecha;
  final DateTime? leido;

  /// Ruta de la imagen en el bucket privado chat-images, si la hay.
  final String? imagenPath;

  bool get tieneImagen => imagenPath != null;

  /// ¿Pertenece este mensaje a la conversación entre [a] y [b]?
  bool esEntre(String a, String b) =>
      (remitenteId == a && destinatarioId == b) ||
      (remitenteId == b && destinatarioId == a);
}

/// Relación del usuario actual con otra persona, para mostrar el botón
/// adecuado (agregar, pendiente, aceptar, amigos).
enum RelacionAmistad { ninguna, enviada, recibida, amigos }
