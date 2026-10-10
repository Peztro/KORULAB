import 'package:flutter/material.dart';
import '../models/course_models.dart';

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
              'Contamina el aire',
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
            sentence:
                'Los paneles ___ convierten la luz solar en electricidad.',
            options: ['solares', 'eólicos', 'marinos', 'nucleares'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'La energía ___ se obtiene del movimiento del viento.',
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
            prompt: '¿Qué material se puede reciclar en el contenedor azul?',
            options: [
              'Papel y cartón',
              'Restos de comida',
              'Baterías',
              'Vidrio roto',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es una acción para reducir residuos?',
            options: [
              'Usar bolsas reutilizables',
              'Comprar plástico de un solo uso',
              'Tirar todo junto',
              'Usar más servilletas',
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
            sentence: 'Las tres R del reciclaje son: reducir, ___ y reciclar.',
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
              'Contaminan el agua',
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
              'Evaporación',
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
            sentence:
                'La ___ es el proceso por la que el agua pasa de líquido a vapor.',
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
            prompt:
                '¿Cuál es la principal fuente de contaminación del aire en las ciudades?',
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
              'Aumento de ozono',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Contaminante y fuente',
        pairs: const [
          MatchPair(
            term: 'CO₂',
            definition: 'Combustión de combustibles fósiles',
          ),
          MatchPair(
            term: 'Ozono',
            definition: 'Contaminación por reacciones químicas',
          ),
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
            sentence:
                'La ___ es la principal causa de la mala calidad del aire en ciudades.',
            options: ['contaminación vehicular', 'lluvia', 'nieve', 'neblina'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'El ___ es un gas que forma parte del efecto invernadero.',
            options: ['dióxido de carbono', 'oxígeno', 'nitrógeno', 'helio'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'La contaminación del aire causa problemas en el sistema ___.',
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
              'Aumento de sales minerales',
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
            sentence:
                'La contaminación del agua afecta principalmente a los ___.',
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
            prompt:
                '¿Cuánto tiempo tarda un plástico en degradarse en el suelo?',
            options: [
              'Más de 500 años',
              '1 año',
              '10 años',
              'Nunca se degrada',
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
              'Mayor fertilidad',
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
            sentence:
                'Los ___ dañan la estructura del suelo y matan microorganismos.',
            options: ['pesticidas', 'abonos', 'semillas', 'riegos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El suelo fértil es esencial para la ___ mundial.',
            options: [
              'producción de alimentos',
              'construcción',
              'minería',
              'turismo',
            ],
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
              'Enterrar basura',
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
              'Hoja verde',
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
            sentence:
                'El ___ puede ser reciclado infinitas veces sin perder calidad.',
            options: ['vidrio', 'plástico', 'papel', 'cartón'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'Los códigos de ___ indican qué tipo de plástico es.',
            options: ['reciclaje', 'barras', 'color', 'peso'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'Reciclar ___ ahorra más energía que reciclar otros materiales.',
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
              'Actividad volcánica',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt:
                '¿Cuánto ha aumentado la temperatura global en el último siglo?',
            options: ['Aproximadamente 1°C', 'Nada', '5°C', '10°C'],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Qué consecuencia tiene el cambio climático?',
            options: [
              'Aumento del nivel del mar',
              'Desaparición de montañas',
              'Menor radiación solar',
              'Menos días soleados',
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
          MatchPair(
            term: 'Deforestación',
            definition: 'Menos árboles = más CO₂',
          ),
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
            sentence:
                'El ___ es el principal causante del calentamiento global.',
            options: ['dióxido de carbono', 'oxígeno', 'nitrógeno', 'helio'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence: 'El derretimiento de los ___ aumenta el nivel del mar.',
            options: ['glaciares', 'volcanes', 'montañas', 'ríos'],
            answerIndex: 0,
          ),
          const FillBlankQuestion(
            sentence:
                'Los cambios en el ___ afectan la agricultura y la biodiversidad.',
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
              'Comprar por comprar',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es la mejor opción ecológica?',
            options: [
              'Comprar productos locales',
              'Importar de lejos',
              'Comprar mucha cantidad',
              'Elegir empaques grandes',
            ],
            answerIndex: 0,
          ),
          const Question(
            prompt: '¿Cuál es un impacto del exceso de consumo?',
            options: [
              'Generación de residuos',
              'Menor contaminación',
              'Más espacio verde',
              'Mejor biodiversidad',
            ],
            answerIndex: 0,
          ),
        ],
      ),
      MatchingActivity(
        title: 'Relaciona: Producto y impacto',
        pairs: const [
          MatchPair(
            term: 'Ropa de segunda mano',
            definition: 'Reduce residuos',
          ),
          MatchPair(term: 'Productos locales', definition: 'Menor transporte'),
          MatchPair(
            term: 'Empaques biodegradables',
            definition: 'Menos contaminación',
          ),
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
