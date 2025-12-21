import pkg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Client } = pkg;

const defaultActivities = [
  {
    id: 'pack',
    name: 'activity_pack',
    title: 'Pack de Actividades',
    description: 'Genera múltiples actividades de forma automática',
    infoTooltip: 'Genera múltiples actividades de forma automática. Selecciona qué tipos de actividades quieres crear y se generarán todas usando las imágenes del canvas.',
    iconName: 'auto_awesome',
    colorValue: 0xFF6A1B9A,
    order: 0,
    isHighlighted: true,
    category: 'pack',
  },
  {
    id: 'shadow_matching',
    name: 'shadow_matching',
    title: 'Relacionar Sombras',
    description: 'Une cada imagen con su sombra',
    infoTooltip: 'Crea una actividad con imágenes y sombras en 3 columnas con puntos de unión. El alumno traza líneas entre los puntos para relacionar cada imagen con su sombra.',
    iconName: 'link',
    colorValue: 0xFF1976D2,
    order: 1,
    category: 'individual',
  },
  {
    id: 'puzzle',
    name: 'puzzle',
    title: 'Puzle',
    description: 'Puzle de 4x4 para recortar',
    infoTooltip: 'Genera un puzle de 4x4 (16 piezas) con la imagen del canvas. Perfecto para imprimir, recortar y que el alumno lo monte.',
    iconName: 'extension',
    colorValue: 0xFFF57C00,
    order: 2,
    category: 'individual',
  },
  {
    id: 'writing_practice',
    name: 'writing_practice',
    title: 'Práctica de Escritura',
    description: 'Imágenes con pauta para escribir',
    infoTooltip: 'Organiza las imágenes en filas y columnas con pauta debajo de cada una para que el alumno escriba el nombre.',
    iconName: 'edit_note',
    colorValue: 0xFF388E3C,
    order: 3,
    category: 'individual',
  },
  {
    id: 'counting_practice',
    name: 'counting_practice',
    title: 'Práctica de Conteo',
    description: 'Contar elementos repetidos',
    infoTooltip: 'Crea ejercicios con cada imagen repetida un número aleatorio de veces en su caja, con espacio para escribir la cantidad.',
    iconName: 'calculate',
    colorValue: 0xFF7B1FA2,
    order: 4,
    category: 'individual',
  },
  {
    id: 'phonological_awareness',
    name: 'phonological_awareness',
    title: 'Conciencia Fonológica',
    description: 'Separar palabras en sílabas',
    infoTooltip: 'Separa las palabras en sílabas. Muestra la imagen, las sílabas separadas y líneas en pauta escolar para que el alumno repase cada sílaba.',
    iconName: 'hearing',
    colorValue: 0xFF6A1B9A,
    order: 5,
    category: 'individual',
  },
  {
    id: 'phonological_board',
    name: 'phonological_board',
    title: 'Tablero Fonológico (recortable)',
    description: 'Tablero con puzle y recortables',
    infoTooltip: 'Crea un tablero vertical con zona de puzle 2x2 y huecos para palabra, sílabas y letras, más otra hoja con las piezas y tarjetas recortables listas para imprimir.',
    iconName: 'view_column',
    colorValue: 0xFFE64A19,
    order: 6,
    category: 'individual',
  },
  {
    id: 'series',
    name: 'series',
    title: 'Series',
    description: 'Continuar patrones ABAB',
    infoTooltip: 'Muestra una serie de dos elementos alternados (ABAB...) y deja espacios en blanco para que el alumno continúe el patrón.',
    iconName: 'auto_awesome',
    colorValue: 0xFFC2185B,
    order: 7,
    category: 'individual',
  },
  {
    id: 'symmetry',
    name: 'symmetry',
    title: 'Simetrías',
    description: 'Encontrar objetos iguales al modelo',
    infoTooltip: 'Muestra un objeto modelo y una cuadrícula 5x5 con el mismo objeto en diferentes orientaciones (rotado, volteado). El alumno debe encontrar los iguales al modelo.',
    iconName: 'flip',
    colorValue: 0xFF00796B,
    order: 8,
    category: 'individual',
  },
  {
    id: 'phrases',
    name: 'phrases',
    title: 'Frases',
    description: 'Frases con pictogramas',
    infoTooltip: 'Muestra una imagen grande arriba y debajo la frase convertida en pictogramas para que el alumno lea o reconstruya.',
    iconName: 'forum_outlined',
    colorValue: 0xFF455A64,
    order: 9,
    category: 'individual',
  },
  {
    id: 'card',
    name: 'card',
    title: 'Tarjeta',
    description: 'Tarjeta con imagen y texto',
    infoTooltip: 'Genera una tarjeta con la imagen a la izquierda y texto (título + párrafo) a la derecha.',
    iconName: 'credit_card',
    colorValue: 0xFFE64A19,
    order: 10,
    category: 'individual',
  },
  {
    id: 'syllable_vocabulary',
    name: 'syllable_vocabulary',
    title: 'Vocabulario por Sílaba',
    description: 'Palabras que empiezan con una sílaba',
    infoTooltip: 'Genera automáticamente una lista de palabras con pictogramas de ARASAAC que empiezan con la sílaba que elijas (pa, ma, sa, etc.). No requiere añadir imágenes previamente.',
    iconName: 'abc',
    colorValue: 0xFF303F9F,
    order: 11,
    category: 'individual',
  },
  {
    id: 'semantic_field',
    name: 'semantic_field',
    title: 'Campo Semántico',
    description: 'Palabras relacionadas temáticamente',
    infoTooltip: 'Añade una imagen de ARASAAC con texto y genera automáticamente una cuadrícula 5x5 con palabras relacionadas del mismo campo semántico (animales, frutas, ropa, etc.).',
    iconName: 'category',
    colorValue: 0xFFFFA000,
    order: 12,
    category: 'individual',
  },
  {
    id: 'instructions',
    name: 'instructions',
    title: 'Instrucciones (Rodea)',
    description: 'Rodear elementos según instrucciones',
    infoTooltip: 'Genera una actividad con instrucciones tipo "Rodea 2 casas, 3 árboles". Los objetos aparecen distribuidos aleatoriamente con algunos distractores.',
    iconName: 'radio_button_checked',
    colorValue: 0xFFD32F2F,
    order: 13,
    category: 'individual',
  },
  {
    id: 'classification',
    name: 'classification',
    title: 'Clasificación',
    description: 'Clasificar objetos en categorías',
    infoTooltip: 'Crea una actividad de clasificación en 2 hojas: una con 2 cuadrados de categorías y otra con 10 objetos relacionados para recortar y clasificar. Requiere 2 imágenes de ARASAAC en el canvas.',
    iconName: 'dashboard',
    colorValue: 0xFF0097A7,
    order: 14,
    category: 'individual',
  },
  {
    id: 'phonological_squares',
    name: 'phonological_squares',
    title: 'Cuadrados Fonológicos',
    description: 'Pintar cuadrados por cada letra',
    infoTooltip: 'Muestra las imágenes del canvas con un rectángulo de 10 cuadrados (2 filas x 5 columnas) debajo de cada una. El alumno pinta un cuadrado por cada letra de la palabra.',
    iconName: 'grid_4x4',
    colorValue: 0xFF0288D1,
    order: 15,
    category: 'individual',
    isNew: true,
  },
  {
    id: 'crossword',
    name: 'crossword',
    title: 'Crucigrama',
    description: 'Crucigrama con las palabras',
    infoTooltip: 'Genera un crucigrama usando las palabras de las imágenes del canvas. Las imágenes sirven como pistas numeradas para completar el crucigrama.',
    iconName: 'apps',
    colorValue: 0xFF5D4037,
    order: 16,
    category: 'individual',
    isNew: true,
  },
  {
    id: 'word_search',
    name: 'word_search',
    title: 'Sopa de Letras',
    description: 'Encontrar palabras escondidas',
    infoTooltip: 'Crea una sopa de letras donde el alumno debe encontrar las palabras de las imágenes del canvas escondidas en una cuadrícula de 15x15 letras.',
    iconName: 'search',
    colorValue: 0xFF6A1B9A,
    order: 17,
    category: 'individual',
    isNew: true,
  },
  {
    id: 'sentence_completion',
    name: 'sentence_completion',
    title: 'Completar Frases',
    description: 'Frases con espacios en blanco',
    infoTooltip: 'Genera frases simples con las imágenes del canvas. Cada página muestra un modelo de frase completa y debajo la misma frase con espacios en blanco para completar. Incluye una página con recortables.',
    iconName: 'edit_note',
    colorValue: 0xFF00796B,
    order: 18,
    category: 'individual',
    isNew: true,
  },
];

async function seedActivities() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl:
      process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: false }
        : false,
  });

  try {
    console.log('Conectando a la base de datos...');
    await client.connect();
    console.log('✓ Conectado');

    console.log('\nInsertando actividades por defecto...');

    for (const activity of defaultActivities) {
      await client.query(
        `INSERT INTO activity_type (
          id, name, title, description, info_tooltip,
          icon_name, color_value, "order", is_new,
          is_highlighted, is_enabled, category
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          title = EXCLUDED.title,
          description = EXCLUDED.description,
          info_tooltip = EXCLUDED.info_tooltip,
          icon_name = EXCLUDED.icon_name,
          color_value = EXCLUDED.color_value,
          "order" = EXCLUDED."order",
          is_new = EXCLUDED.is_new,
          is_highlighted = EXCLUDED.is_highlighted,
          category = EXCLUDED.category,
          updated_at = now()`,
        [
          activity.id,
          activity.name,
          activity.title,
          activity.description,
          activity.infoTooltip,
          activity.iconName,
          activity.colorValue,
          activity.order,
          activity.isNew || false,
          activity.isHighlighted || false,
          true, // is_enabled siempre true por defecto
          activity.category,
        ]
      );
      console.log(`  ✓ ${activity.title}`);
    }

    // Verificar cuántas actividades hay
    const result = await client.query('SELECT COUNT(*) FROM activity_type');
    console.log(`\n✓ Total de actividades: ${result.rows[0].count}`);
  } catch (err) {
    console.error('Error al insertar actividades:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

seedActivities();
