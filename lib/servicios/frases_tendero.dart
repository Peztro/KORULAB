import 'dart:math';

/// Frases de Koru cuando atiende la tienda.
///
/// Mezcla frases fijas sobre los productos con otras que dependen de las
/// [ekostrellas] que tiene el jugador. [precioMinimo] y [precioMaximo] son
/// el producto más barato y el más caro.
List<String> frasesTendero({
  required int ekostrellas,
  required int precioMinimo,
  required int precioMaximo,
}) {
  return [
    '¡Bienvenido a mi tienda! Aquí todo se paga con ekostrellas 🌟',
    '¿Dudas en una pregunta? La Pista descarta una opción incorrecta 💡',
    'Con Doble de ekostrellas, tu próxima actividad te da el doble ✨',
    'Con el Segundo intento puedes volver a elegir si te equivocas.',
    'El Protector de racha cuida tu 🔥 si un día no alcanzas a estudiar.',
    'Completa lecciones para ganar ekostrellas y vuelve por aquí 🐌',
    'Entre más aciertos, más ekostrellas ganas. ¡Concéntrate!',
    'Estas manzanas son de mi huerta… pero esas no están a la venta 🍎',
    if (ekostrellas < precioMinimo)
      'Te faltan ${precioMinimo - ekostrellas} ekostrellas para tu primera '
          'compra. ¡Tú puedes!'
    else if (ekostrellas >= precioMaximo)
      '¡Tienes ekostrellas para lo que quieras! ¿Qué te llevas hoy?'
    else
      'Con tus $ekostrellas ekostrellas ya puedes canjear algo 😉',
  ];
}

/// Elige una frase al azar distinta de [anterior] (si hay más de una).
String elegirFraseTendero(List<String> frases, String? anterior, Random azar) {
  final opciones = frases.where((f) => f != anterior).toList();
  final lista = opciones.isEmpty ? frases : opciones;
  return lista[azar.nextInt(lista.length)];
}
