import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/modelos/chat.dart';
import 'package:korulab/servicios/servicio_chat.dart';

void main() {
  group('Contacto', () {
    test('lee la fila y sabe si es profesor', () {
      final c = Contacto.desdeFila({
        'id': 'u1',
        'username': 'ana',
        'display_name': '',
        'role': 'teacher',
      });
      expect(c.id, 'u1');
      expect(c.nombreVisible, '@ana');
      expect(c.esProfesor, isTrue);
    });

    test('los administradores también cuentan como profesores', () {
      final c = Contacto.desdeFila({
        'id': 'u',
        'username': 'x',
        'role': 'admin',
      });
      expect(c.esProfesor, isTrue);
    });
  });

  test('Amistad usa other_id como id del contacto', () {
    final a = Amistad.desdeFila({
      'id': 5,
      'other_id': 'u2',
      'username': 'pepe',
      'display_name': 'Pepe',
      'role': 'student',
      'status': 'pending',
      'incoming': true,
    });
    expect(a.id, 5);
    expect(a.contacto.id, 'u2');
    expect(a.aceptada, isFalse);
    expect(a.entrante, isTrue);
  });

  test('Conversacion lee último mensaje y no leídos', () {
    final c = Conversacion.desdeFila({
      'partner_id': 'u3',
      'username': 'luz',
      'display_name': 'Luz',
      'last_body': 'Hola',
      'last_at': '2026-11-24T10:00:00Z',
      'last_from_me': true,
      'unread': 2,
    });
    expect(c.contacto.id, 'u3');
    expect(c.ultimoMensaje, 'Hola');
    expect(c.ultimoEsMio, isTrue);
    expect(c.noLeidos, 2);
    expect(c.ultimaFecha.isUtc, isFalse);
  });

  test('MensajeDirecto.esEntre funciona en ambos sentidos', () {
    final m = MensajeDirecto.desdeFila({
      'id': 1,
      'sender_id': 'a',
      'recipient_id': 'b',
      'body': 'hola',
      'created_at': '2026-11-24T10:00:00Z',
      'read_at': null,
    });
    expect(m.esEntre('a', 'b'), isTrue);
    expect(m.esEntre('b', 'a'), isTrue);
    expect(m.esEntre('a', 'c'), isFalse);
    expect(m.leido, isNull);
  });

  group('ServicioChat.relacionCon', () {
    Amistad amistad(
      String id, {
      required bool aceptada,
      bool entrante = false,
    }) => Amistad(
      id: 1,
      contacto: Contacto(id: id, username: id),
      aceptada: aceptada,
      entrante: entrante,
    );

    test('distingue amigos, enviadas, recibidas y ninguna', () {
      final todas = [
        amistad('amigo', aceptada: true),
        amistad('enviada', aceptada: false),
        amistad('recibida', aceptada: false, entrante: true),
      ];
      expect(ServicioChat.relacionCon('amigo', todas), RelacionAmistad.amigos);
      expect(
        ServicioChat.relacionCon('enviada', todas),
        RelacionAmistad.enviada,
      );
      expect(
        ServicioChat.relacionCon('recibida', todas),
        RelacionAmistad.recibida,
      );
      expect(ServicioChat.relacionCon('otro', todas), RelacionAmistad.ninguna);
    });
  });
}
