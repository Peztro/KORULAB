import 'datos_juegos.dart';

/// Banco de preguntas de Trivia relámpago. Cada partida toma
/// [preguntasPorPartida] al azar.
const preguntasTrivia = <PreguntaTrivia>[
  PreguntaTrivia(
    '¿En qué caneca van los residuos orgánicos en Colombia?',
    'Verde',
    ['Blanca', 'Negra', 'Azul'],
  ),
  PreguntaTrivia(
    '¿Qué gas absorben los árboles del aire?',
    'Dióxido de carbono',
    ['Oxígeno', 'Helio', 'Nitrógeno'],
  ),
  PreguntaTrivia('¿Cuál de estas es una energía renovable?', 'Solar', [
    'Carbón',
    'Petróleo',
    'Gas natural',
  ]),
  PreguntaTrivia(
    '¿Qué animal poliniza muchas plantas que comemos?',
    'La abeja',
    ['La lombriz', 'El pez', 'El caracol'],
  ),
  PreguntaTrivia(
    '¿Cuánto tarda en degradarse una botella plástica?',
    'Cientos de años',
    ['Una semana', 'Un mes', 'Diez días'],
  ),
  PreguntaTrivia(
    '¿Qué significan las tres R?',
    'Reducir, reutilizar y reciclar',
    [
      'Romper, regar y rodar',
      'Recoger, revisar y regresar',
      'Reír, remar y reunir',
    ],
  ),
  PreguntaTrivia(
    '¿Qué parte de la planta hace la mayor parte de la '
        'fotosíntesis?',
    'Las hojas',
    ['Las raíces', 'Las flores', 'Las semillas'],
  ),
  PreguntaTrivia(
    '¿Cuál de estas acciones ahorra agua?',
    'Cerrar la llave al cepillarte',
    [
      'Ducharte 30 minutos',
      'Lavar el carro con manguera',
      'Dejar la llave goteando',
    ],
  ),
  PreguntaTrivia(
    '¿Qué nos protege de los rayos ultravioleta del Sol?',
    'La capa de ozono',
    ['Las nubes', 'La corteza', 'Los volcanes'],
  ),
  PreguntaTrivia('El compost se hace con…', 'Residuos orgánicos', [
    'Pilas usadas',
    'Vidrio',
    'Plástico',
  ]),
  PreguntaTrivia(
    '¿Dónde se deben dejar las pilas usadas?',
    'En un punto de recolección',
    ['En la caneca verde', 'En el río', 'Enterradas en el jardín'],
  ),
  PreguntaTrivia(
    '¿Qué país tiene más especies de aves del mundo?',
    'Colombia',
    ['Canadá', 'Egipto', 'Islandia'],
  ),
  PreguntaTrivia(
    '¿Por qué son importantes los páramos?',
    'Guardan y regulan el agua',
    ['Son muy calientes', 'Tienen volcanes activos', 'No tienen plantas'],
  ),
  PreguntaTrivia(
    '¿Cuál de estos transportes no contamina el aire?',
    'La bicicleta',
    ['La moto', 'El carro de gasolina', 'El avión'],
  ),
  PreguntaTrivia(
    '¿Qué es la huella de carbono?',
    'Los gases que generan nuestras actividades',
    ['La marca de un zapato', 'Un fósil muy antiguo', 'Un tipo de suelo'],
  ),
  PreguntaTrivia(
    '¿Qué pasa cuando se talan los bosques?',
    'Los animales pierden su hogar',
    ['Hay más oxígeno', 'Llueve más', 'No pasa nada'],
  ),
  PreguntaTrivia('¿Qué tipo de animal es un caracol como Koru?', 'Un molusco', [
    'Un insecto',
    'Un reptil',
    'Un mamífero',
  ]),
  PreguntaTrivia(
    '¿Cuál de estos objetos es reutilizable?',
    'Una bolsa de tela',
    ['Un pitillo plástico', 'Un vaso desechable', 'Una servilleta'],
  ),
  PreguntaTrivia(
    '¿Cuánta del agua del planeta es dulce?',
    'Muy poca: menos del 3 %',
    ['La mayoría', 'La mitad', 'Toda'],
  ),
  PreguntaTrivia(
    'Apagar los aparatos que no usas sirve para…',
    'Ahorrar energía',
    ['Gastar más luz', 'Calentar el agua', 'Nada'],
  ),
  PreguntaTrivia(
    '¿Qué parte de la Tierra está cubierta por agua?',
    'Cerca del 70 %',
    ['Cerca del 10 %', 'Cerca del 30 %', 'Cerca del 95 %'],
  ),
  PreguntaTrivia(
    '¿Cómo se llama el paso del agua líquida a vapor?',
    'Evaporación',
    ['Condensación', 'Congelación', 'Filtración'],
  ),
  PreguntaTrivia(
    '¿Cómo se llama cuando el vapor de agua forma las nubes?',
    'Condensación',
    ['Evaporación', 'Erosión', 'Fusión'],
  ),
  PreguntaTrivia(
    'La lluvia, la nieve y el granizo son formas de…',
    'Precipitación',
    ['Infiltración', 'Evaporación', 'Transpiración'],
  ),
  PreguntaTrivia(
    '¿Cuál de estas acciones gasta menos agua?',
    'Una ducha corta',
    [
      'Un baño en tina llena',
      'Lavar platos con la llave abierta',
      'Regar al mediodía',
    ],
  ),
  PreguntaTrivia(
    '¿Qué río atraviesa Colombia de sur a norte y desemboca en el Caribe?',
    'El Magdalena',
    ['El Amazonas', 'El Nilo', 'El Orinoco'],
  ),
  PreguntaTrivia(
    '¿Por qué es mejor regar las plantas temprano o al atardecer?',
    'Se evapora menos agua',
    ['Las plantas duermen al mediodía', 'El agua pesa menos', 'Hay más luz'],
  ),
  PreguntaTrivia(
    '¿Para qué sirve recoger el agua de lluvia?',
    'Para regar plantas y limpiar',
    ['Para contaminarla', 'Para botarla', 'Para nada'],
  ),
  PreguntaTrivia(
    'Una llave que gotea todo el día puede desperdiciar…',
    'Muchos litros de agua',
    ['Nada de agua', 'Una gota al año', 'Un vaso al mes'],
  ),
  PreguntaTrivia(
    '¿Qué es un humedal?',
    'Una zona con agua poco profunda y mucha vida',
    ['Un desierto', 'Un volcán', 'Una montaña nevada'],
  ),
  PreguntaTrivia(
    '¿Qué contamina el agua de los ríos?',
    'Arrojar basura y químicos',
    ['Sembrar árboles en la orilla', 'Mirar los peces', 'Tomar fotos'],
  ),
  PreguntaTrivia(
    '¿Dónde está la mayor parte del agua dulce del planeta?',
    'En glaciares y casquetes de hielo',
    ['En los ríos', 'En los lagos', 'En las nubes'],
  ),
  PreguntaTrivia('¿Qué energía aprovecha la fuerza del viento?', 'Eólica', [
    'Solar',
    'Geotérmica',
    'Nuclear',
  ]),
  PreguntaTrivia(
    '¿Qué energía aprovecha el calor del interior de la Tierra?',
    'Geotérmica',
    ['Eólica', 'Hidráulica', 'Solar'],
  ),
  PreguntaTrivia(
    '¿Qué energía se produce con la fuerza del agua de los ríos?',
    'Hidroeléctrica',
    ['Eólica', 'Solar', 'Geotérmica'],
  ),
  PreguntaTrivia('¿Qué bombillo gasta menos energía?', 'El LED', [
    'El incandescente',
    'El halógeno',
    'Todos gastan igual',
  ]),
  PreguntaTrivia(
    '¿Qué es el efecto invernadero?',
    'Gases que atrapan el calor en la atmósfera',
    ['Un tipo de huerta', 'Un viento frío', 'Una planta tropical'],
  ),
  PreguntaTrivia('¿Cuál de estos es un combustible fósil?', 'El petróleo', [
    'El viento',
    'La luz solar',
    'El agua',
  ]),
  PreguntaTrivia(
    '¿Qué les pasa a los glaciares con el calentamiento global?',
    'Se derriten',
    ['Crecen más', 'Se vuelven verdes', 'No cambian'],
  ),
  PreguntaTrivia(
    '¿Qué ayuda a frenar el calentamiento global?',
    'Usar menos combustibles fósiles',
    ['Quemar basura', 'Talar bosques', 'Dejar luces encendidas'],
  ),
  PreguntaTrivia(
    '¿Qué es el consumo fantasma de energía?',
    'Lo que gastan los aparatos enchufados sin usar',
    [
      'Un fantasma que roba luz',
      'La luz de la luna',
      'La energía de las pilas nuevas',
    ],
  ),
  PreguntaTrivia(
    '¿Qué convierte la luz del Sol en electricidad?',
    'Un panel solar',
    ['Un ventilador', 'Un radiador', 'Una nevera'],
  ),
  PreguntaTrivia(
    '¿Qué gas sale del escape de los carros y calienta el planeta?',
    'Dióxido de carbono',
    ['Oxígeno', 'Helio', 'Neón'],
  ),
  PreguntaTrivia(
    'Secar la ropa al sol en vez de usar secadora…',
    'Ahorra energía',
    ['Gasta más energía', 'Daña el planeta', 'Contamina el agua'],
  ),
  PreguntaTrivia('La energía del Sol es…', 'Renovable', [
    'No renovable',
    'Un combustible fósil',
    'Algo que se acaba mañana',
  ]),
  PreguntaTrivia('¿Cuál de estos recursos no es renovable?', 'El carbón', [
    'El viento',
    'La luz solar',
    'El agua de lluvia',
  ]),
  PreguntaTrivia(
    '¿Cuál es el ave nacional de Colombia?',
    'El cóndor de los Andes',
    ['El colibrí', 'El tucán', 'La guacamaya'],
  ),
  PreguntaTrivia(
    '¿Cuál es el árbol nacional de Colombia?',
    'La palma de cera del Quindío',
    ['El roble', 'El pino', 'El eucalipto'],
  ),
  PreguntaTrivia('¿Cuál es la flor nacional de Colombia?', 'La orquídea', [
    'La rosa',
    'El girasol',
    'El clavel',
  ]),
  PreguntaTrivia(
    '¿Qué tiene de especial el oso de anteojos?',
    'Es el único oso de Sudamérica',
    ['Vive en el Polo Norte', 'Es un mono', 'Es un ave'],
  ),
  PreguntaTrivia('¿Qué comen principalmente las abejas?', 'Néctar y polen', [
    'Hojas',
    'Carne',
    'Semillas de pino',
  ]),
  PreguntaTrivia('¿Cuál de estos animales es un anfibio?', 'La rana', [
    'La serpiente',
    'El tiburón',
    'El águila',
  ]),
  PreguntaTrivia(
    '¿Qué es una especie en peligro de extinción?',
    'Una que podría desaparecer para siempre',
    [
      'Una que vive en el mar',
      'Una muy común',
      'Una que solo vive en zoológicos',
    ],
  ),
  PreguntaTrivia(
    '¿Qué animal ayuda a sembrar bosques al dispersar semillas?',
    'El murciélago',
    ['La medusa', 'El pulpo', 'La estrella de mar'],
  ),
  PreguntaTrivia(
    '¿Qué hace la lombriz en el suelo?',
    'Lo airea y lo vuelve fértil',
    ['Lo contamina', 'Lo seca', 'Lo vuelve piedra'],
  ),
  PreguntaTrivia(
    '¿Por qué no se deben tener animales silvestres como mascotas?',
    'Sufren y se daña su ecosistema',
    ['Porque son baratos', 'Porque no comen', 'Porque son invisibles'],
  ),
  PreguntaTrivia('¿Qué es la biodiversidad?', 'La variedad de seres vivos', [
    'Un tipo de basura',
    'Un tipo de energía',
    'Un deporte',
  ]),
  PreguntaTrivia(
    'Colombia es uno de los países…',
    'Más biodiversos del mundo',
    ['Más fríos del mundo', 'Sin bosques', 'Sin ríos'],
  ),
  PreguntaTrivia('¿Qué tipo de animal es el manatí?', 'Un mamífero acuático', [
    'Un pez',
    'Un reptil',
    'Un ave',
  ]),
  PreguntaTrivia(
    '¿Qué animal marino confunde las bolsas plásticas con comida?',
    'La tortuga marina',
    ['El cóndor', 'La vaca', 'El camello'],
  ),
  PreguntaTrivia(
    '¿Qué son los arrecifes de coral?',
    'Ecosistemas marinos llenos de vida',
    ['Rocas sin vida', 'Plantas del desierto', 'Basura en el mar'],
  ),
  PreguntaTrivia(
    '¿Qué es un ecosistema?',
    'Seres vivos y el lugar donde viven, relacionados',
    ['Una máquina', 'Un tipo de plástico', 'Un planeta lejano'],
  ),
  PreguntaTrivia(
    '¿Qué es la cadena alimentaria?',
    'Quién se alimenta de quién en la naturaleza',
    ['Una cadena de metal', 'Un restaurante', 'Una receta'],
  ),
  PreguntaTrivia(
    'Las plantas son productoras porque…',
    'Fabrican su propio alimento',
    ['Comen insectos', 'Compran comida', 'No necesitan luz'],
  ),
  PreguntaTrivia(
    'Además de la abeja, ¿qué animal poliniza flores?',
    'El colibrí',
    ['El tiburón', 'La ballena', 'El cocodrilo'],
  ),
  PreguntaTrivia(
    '¿Qué es un animal endémico?',
    'El que solo vive en una región',
    [
      'El que vive en todo el mundo',
      'El que es mascota',
      'El que está extinto',
    ],
  ),
  PreguntaTrivia(
    '¿Qué animal visita el Pacífico colombiano para tener sus crías?',
    'La ballena jorobada',
    ['El pingüino emperador', 'El oso polar', 'El canguro'],
  ),
  PreguntaTrivia('¿Qué tipo de animal es el caimán del Orinoco?', 'Un reptil', [
    'Un pez',
    'Un ave',
    'Un anfibio',
  ]),
  PreguntaTrivia(
    '¿Qué come principalmente un caracol de jardín?',
    'Hojas y plantas',
    ['Carne', 'Peces', 'Insectos grandes'],
  ),
  PreguntaTrivia(
    '¿Qué hacen los buitres y gallinazos en la naturaleza?',
    'Limpian comiendo animales muertos',
    ['Polinizan flores', 'Fabrican miel', 'Construyen represas'],
  ),
  PreguntaTrivia('¿Qué es el chigüiro?', 'El roedor más grande del mundo', [
    'Un pez',
    'Un ave',
    'Un insecto',
  ]),
  PreguntaTrivia(
    '¿Qué animal es símbolo de la Amazonía y caza de noche?',
    'El jaguar',
    ['El pingüino', 'El koala', 'El camello'],
  ),
  PreguntaTrivia(
    '¿Qué necesitan las plantas para hacer la fotosíntesis?',
    'Luz, agua y dióxido de carbono',
    ['Solo tierra', 'Sal y azúcar', 'Oscuridad'],
  ),
  PreguntaTrivia(
    '¿Qué gas liberan las plantas en la fotosíntesis?',
    'Oxígeno',
    ['Dióxido de carbono', 'Metano', 'Humo'],
  ),
  PreguntaTrivia('¿Qué es la deforestación?', 'La tala o quema de bosques', [
    'Sembrar árboles',
    'Regar flores',
    'Reciclar papel',
  ]),
  PreguntaTrivia(
    '¿Cuál es el bosque tropical más grande del mundo?',
    'La Amazonía',
    ['La sabana de Bogotá', 'El Sahara', 'La Antártida'],
  ),
  PreguntaTrivia(
    '¿Qué son los manglares?',
    'Bosques costeros entre agua dulce y salada',
    ['Desiertos', 'Montañas nevadas', 'Campos de trigo'],
  ),
  PreguntaTrivia(
    'Las raíces de los árboles ayudan a…',
    'Evitar la erosión del suelo',
    ['Producir plástico', 'Atraer rayos', 'Secar los ríos'],
  ),
  PreguntaTrivia(
    '¿Qué es una especie invasora?',
    'Una que llega a un lugar nuevo y daña su ecosistema',
    ['Una planta nativa', 'Un animal en extinción', 'Un insecto que ayuda'],
  ),
  PreguntaTrivia(
    '¿Qué parte de la planta absorbe el agua del suelo?',
    'Las raíces',
    ['Las hojas', 'Los pétalos', 'Los frutos'],
  ),
  PreguntaTrivia(
    '¿Qué es un vivero?',
    'Un lugar donde se cultivan plantas pequeñas',
    ['Un zoológico', 'Un basurero', 'Un río'],
  ),
  PreguntaTrivia(
    '¿Qué es la reforestación?',
    'Volver a sembrar árboles donde se talaron',
    ['Cortar árboles', 'Quemar pasto', 'Construir edificios'],
  ),
  PreguntaTrivia('¿Qué es el frailejón?', 'Una planta típica del páramo', [
    'Un ave',
    'Un pez',
    'Un volcán',
  ]),
  PreguntaTrivia(
    '¿Qué hacen las flores para la planta?',
    'Ayudan a producir semillas',
    ['Absorben agua', 'La sostienen', 'Comen insectos'],
  ),
  PreguntaTrivia(
    '¿En qué caneca va una botella plástica limpia en Colombia?',
    'Blanca',
    ['Verde', 'Negra', 'Roja'],
  ),
  PreguntaTrivia('¿En qué caneca va el papel higiénico usado?', 'Negra', [
    'Blanca',
    'Verde',
    'Amarilla',
  ]),
  PreguntaTrivia(
    '¿Qué material se puede reciclar muchas veces sin perder calidad?',
    'El vidrio',
    ['El papel', 'El icopor', 'La servilleta'],
  ),
  PreguntaTrivia('¿Qué significa reutilizar?', 'Darle otro uso a un objeto', [
    'Botarlo',
    'Quemarlo',
    'Comprar otro igual',
  ]),
  PreguntaTrivia('¿Qué significa reducir?', 'Consumir y botar menos', [
    'Comprar más',
    'Usar más bolsas',
    'Romper cosas',
  ]),
  PreguntaTrivia('¿Qué es el icopor?', 'Un plástico difícil de reciclar', [
    'Un papel',
    'Un metal',
    'Un vidrio',
  ]),
  PreguntaTrivia(
    '¿Qué se hace con el aceite de cocina usado?',
    'Guardarlo y llevarlo a un punto de recolección',
    ['Botarlo por el lavaplatos', 'Echarlo al río', 'Enterrarlo'],
  ),
  PreguntaTrivia('¿Cuál de estos es un residuo peligroso?', 'Una pila usada', [
    'Una cáscara de fruta',
    'Una hoja seca',
    'Un papel limpio',
  ]),
  PreguntaTrivia(
    '¿Por qué se lavan los envases antes de reciclarlos?',
    'Para que se puedan aprovechar',
    ['Para que pesen más', 'Para que huelan mal', 'No hace falta'],
  ),
  PreguntaTrivia(
    '¿Qué es la economía circular?',
    'Reusar y reciclar en vez de botar',
    [
      'Gastar dinero en círculos',
      'Comprar sin parar',
      'Hacer monedas redondas',
    ],
  ),
  PreguntaTrivia(
    '¿Quiénes son los recicladores de oficio?',
    'Personas que recuperan materiales aprovechables',
    ['Personas que ensucian', 'Robots del espacio', 'Bomberos'],
  ),
  PreguntaTrivia(
    '¿Qué forma de comprar genera menos basura?',
    'A granel, en tu propia bolsa',
    ['Con muchas bolsas', 'En porciones individuales', 'Con doble empaque'],
  ),
  PreguntaTrivia(
    '¿Qué puedes hacer con un frasco de vidrio vacío?',
    'Usarlo para guardar cosas',
    ['Romperlo', 'Tirarlo al río', 'Quemarlo'],
  ),
  PreguntaTrivia(
    '¿Qué es un punto ecológico?',
    'Un lugar con canecas para separar residuos',
    ['Un parque de diversiones', 'Un tipo de árbol', 'Una tienda de dulces'],
  ),
  PreguntaTrivia('¿Qué se descompone más rápido?', 'Una cáscara de fruta', [
    'Una botella plástica',
    'Una lata',
    'Un frasco de vidrio',
  ]),
  PreguntaTrivia(
    '¿Qué se hace con un celular viejo que ya no sirve?',
    'Llevarlo a un punto de recolección de electrónicos',
    ['Botarlo en la caneca verde', 'Tirarlo al río', 'Enterrarlo'],
  ),
  PreguntaTrivia(
    '¿De qué se fabrica la mayoría del plástico?',
    'Del petróleo',
    ['De la arena', 'De las frutas', 'Del agua de mar'],
  ),
  PreguntaTrivia('¿De qué se fabrica el vidrio?', 'De arena', [
    'De madera',
    'De petróleo',
    'De hojas',
  ]),
  PreguntaTrivia(
    '¿Qué tienen en común el papel y el cartón?',
    'Vienen de los árboles',
    ['Vienen del petróleo', 'Son metales', 'Son vidrio'],
  ),
  PreguntaTrivia(
    '¿Por qué no se debe quemar la basura?',
    'Contamina el aire y daña la salud',
    ['Porque huele a flores', 'Porque da frío', 'No pasa nada'],
  ),
  PreguntaTrivia(
    'Si ves basura tirada en un parque, lo mejor es…',
    'Recogerla y botarla en la caneca',
    ['Dejarla ahí', 'Patearla', 'Enterrarla'],
  ),
  PreguntaTrivia(
    '¿Qué es mejor para llevar las compras?',
    'Una bolsa reutilizable',
    ['Muchas bolsas plásticas', 'Una caja de icopor', 'Bolsas nuevas cada vez'],
  ),
  PreguntaTrivia(
    '¿Cómo puedes ahorrar papel?',
    'Usando las hojas por ambos lados',
    [
      'Imprimiendo todo',
      'Arrugando hojas nuevas',
      'Usando una hoja por palabra',
    ],
  ),
  PreguntaTrivia('¿Qué ayuda más al planeta?', 'Comprar productos locales', [
    'Comprar todo importado',
    'Usar más empaques',
    'Botar comida',
  ]),
  PreguntaTrivia(
    '¿Qué se puede hacer con la comida que sobra?',
    'Guardarla o hacer compost',
    ['Botarla siempre', 'Echarla al río', 'Quemarla'],
  ),
  PreguntaTrivia(
    'Al salir de un salón vacío, lo mejor es…',
    'Apagar luces y ventiladores',
    ['Dejar todo prendido', 'Abrir las llaves', 'Prender el televisor'],
  ),
  PreguntaTrivia(
    '¿Qué transporte contamina menos por persona?',
    'El bus o el metro',
    ['Un carro para cada uno', 'Un avión privado', 'Una moto para cada uno'],
  ),
  PreguntaTrivia(
    '¿Qué es una huerta escolar?',
    'Un espacio para cultivar plantas en el colegio',
    ['Una cancha', 'Una sala de cómputo', 'Un basurero'],
  ),
  PreguntaTrivia(
    '¿Qué puedes hacer con la ropa que ya no usas?',
    'Donarla o reutilizarla',
    ['Quemarla', 'Tirarla al río', 'Dejarla en la calle'],
  ),
  PreguntaTrivia('No usar pitillos plásticos…', 'Reduce la basura plástica', [
    'Aumenta la basura',
    'Contamina el aire',
    'No cambia nada',
  ]),
  PreguntaTrivia(
    '¿Qué es el consumo responsable?',
    'Comprar solo lo necesario pensando en el planeta',
    ['Comprar todo lo que veas', 'No comer nunca', 'Botar las cosas nuevas'],
  ),
  PreguntaTrivia(
    '¿Qué hacer con una hoja que solo usaste por un lado?',
    'Usar el otro lado para borradores',
    ['Botarla de inmediato', 'Quemarla', 'Mojarla'],
  ),
  PreguntaTrivia(
    '¿Cuál de estos es un buen hábito en casa?',
    'Desconectar el cargador al terminar',
    [
      'Dejar la nevera abierta',
      'Dormir con el televisor prendido',
      'Lavar con la llave abierta',
    ],
  ),
  PreguntaTrivia('¿Cuándo se celebra el Día de la Tierra?', 'El 22 de abril', [
    'El 25 de diciembre',
    'El 1 de enero',
    'El 31 de octubre',
  ]),
  PreguntaTrivia(
    '¿Cuándo es el Día Mundial del Medio Ambiente?',
    'El 5 de junio',
    ['El 14 de febrero', 'El 20 de julio', 'El 7 de agosto'],
  ),
  PreguntaTrivia('¿Cuándo es el Día Mundial del Agua?', 'El 22 de marzo', [
    'El 1 de mayo',
    'El 8 de marzo',
    'El 12 de octubre',
  ]),
  PreguntaTrivia(
    '¿Qué es la atmósfera?',
    'La capa de aire que rodea la Tierra',
    ['El centro de la Tierra', 'El fondo del mar', 'Un tipo de roca'],
  ),
  PreguntaTrivia(
    '¿Qué es la contaminación del aire?',
    'Sustancias dañinas en el aire que respiramos',
    ['El aire fresco del campo', 'El olor de las flores', 'El viento fuerte'],
  ),
  PreguntaTrivia(
    '¿Qué causa la lluvia ácida?',
    'Gases contaminantes en el aire',
    ['Comer limones', 'Regar plantas', 'El arcoíris'],
  ),
  PreguntaTrivia(
    '¿Qué es la erosión?',
    'El desgaste del suelo por el agua o el viento',
    ['Un tipo de flor', 'Construir casas', 'Una lluvia de estrellas'],
  ),
  PreguntaTrivia(
    '¿Qué es un suelo fértil?',
    'Tierra con nutrientes donde las plantas crecen bien',
    ['Arena del desierto', 'Cemento', 'Plástico molido'],
  ),
  PreguntaTrivia('¿Qué le hace el compost al suelo?', 'Lo nutre', [
    'Lo envenena',
    'Lo vuelve plástico',
    'Lo seca',
  ]),
  PreguntaTrivia(
    '¿Qué mares u océanos bañan las costas de Colombia?',
    'El océano Pacífico y el mar Caribe',
    ['El Índico y el Ártico', 'Solo el Índico', 'Ninguno'],
  ),
  PreguntaTrivia('¿Cuántas regiones naturales tiene Colombia?', 'Seis', [
    'Dos',
    'Diez',
    'Tres',
  ]),
  PreguntaTrivia(
    '¿Qué es un parque nacional natural?',
    'Un área protegida para cuidar la naturaleza',
    ['Un centro comercial', 'Un parque de diversiones', 'Una fábrica'],
  ),
  PreguntaTrivia(
    '¿Qué tiene de especial la Sierra Nevada de Santa Marta?',
    'Es la montaña costera más alta del mundo',
    ['Es un desierto', 'Es una isla', 'Es un río'],
  ),
  PreguntaTrivia('¿Qué planeta es nuestro hogar?', 'La Tierra', [
    'Marte',
    'Venus',
    'Júpiter',
  ]),
];
