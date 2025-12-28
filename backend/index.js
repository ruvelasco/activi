import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import pkg from 'pg';

dotenv.config();

const { Pool } = pkg;
const app = express();
const port = process.env.PORT || 8080;
const jwtSecret = process.env.JWT_SECRET || 'dev-secret';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl:
    process.env.NODE_ENV === 'production'
      ? { rejectUnauthorized: false }
      : false,
});

app.use(cors());
app.use(express.json({ limit: '5mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Endpoint temporal para ejecutar migraciones
app.post('/migrations/run', async (req, res) => {
  // Permitir migraciones con token secreto o en desarrollo
  const { secret, dropTable } = req.body || {};
  if (process.env.NODE_ENV === 'production' && secret !== process.env.JWT_SECRET) {
    return res.status(403).json({ message: 'No permitido sin autenticación' });
  }

  try {
    // Opcionalmente eliminar la tabla si se solicita
    if (dropTable) {
      await pool.query(`DROP TABLE IF EXISTS activity_type CASCADE`);
    }

    // Crear tabla activity_type
    await pool.query(`
      CREATE TABLE IF NOT EXISTS activity_type (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        info_tooltip TEXT NOT NULL DEFAULT '',
        icon_name TEXT NOT NULL DEFAULT 'help_outline',
        color_value BIGINT NOT NULL DEFAULT 4280391411,
        "order" INTEGER NOT NULL DEFAULT 999,
        is_new BOOLEAN NOT NULL DEFAULT false,
        is_highlighted BOOLEAN NOT NULL DEFAULT false,
        is_enabled BOOLEAN NOT NULL DEFAULT true,
        category TEXT,
        activity_pictogram_url TEXT,
        material_pictogram_urls TEXT[],
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      )
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_activity_type_order ON activity_type("order")
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_activity_type_enabled ON activity_type(is_enabled)
    `);

    return res.json({ message: 'Migraciones ejecutadas correctamente' });
  } catch (err) {
    console.error('Migration error', err);
    return res.status(500).json({ message: 'Error ejecutando migraciones', error: err.message });
  }
});

// Endpoint temporal para añadir columnas de instrucciones visuales
app.post('/migrations/add-visual-instructions-columns', async (req, res) => {
  try {
    console.log('Añadiendo columnas de instrucciones visuales...');

    // Añadir columna para URL del pictograma de actividad
    await pool.query(`
      ALTER TABLE activity_type
      ADD COLUMN IF NOT EXISTS activity_pictogram_url TEXT
    `);

    // Añadir columna para URLs de pictogramas de materiales (array)
    await pool.query(`
      ALTER TABLE activity_type
      ADD COLUMN IF NOT EXISTS material_pictogram_urls TEXT[]
    `);

    console.log('✓ Columnas añadidas correctamente');

    return res.json({
      message: 'Columnas de instrucciones visuales añadidas correctamente',
      columns: ['activity_pictogram_url', 'material_pictogram_urls']
    });
  } catch (err) {
    console.error('Migration error', err);
    return res.status(500).json({ message: 'Error ejecutando migración', error: err.message });
  }
});

// Migración: añadir columna cover_image_url a project
app.post('/migrations/add-cover-image-to-projects', async (req, res) => {
  try {
    console.log('Añadiendo columna cover_image_url a project...');

    await pool.query(`
      ALTER TABLE project
      ADD COLUMN IF NOT EXISTS cover_image_url TEXT
    `);

    console.log('✓ Columna cover_image_url añadida correctamente');

    return res.json({
      message: 'Columna cover_image_url añadida correctamente',
      columns: ['cover_image_url']
    });
  } catch (err) {
    console.error('Migration error', err);
    return res.status(500).json({ message: 'Error ejecutando migración', error: err.message });
  }
});

// Endpoint temporal para poblar actividades por defecto
app.post('/migrations/seed-activities', async (req, res) => {
  const { secret } = req.body || {};
  if (process.env.NODE_ENV === 'production' && secret !== process.env.JWT_SECRET) {
    return res.status(403).json({ message: 'No permitido sin autenticación' });
  }

  const defaultActivities = [
    { id: 'pack', name: 'activity_pack', title: 'Pack de Actividades', description: 'Genera múltiples actividades de forma automática', infoTooltip: 'Genera múltiples actividades de forma automática. Selecciona qué tipos de actividades quieres crear y se generarán todas usando las imágenes del canvas.', iconName: 'auto_awesome', colorValue: 0xFF6A1B9A, order: 0, isHighlighted: true, category: 'pack' },
    { id: 'shadow_matching', name: 'shadow_matching', title: 'Relacionar Sombras', description: 'Une cada imagen con su sombra', infoTooltip: 'Crea una actividad con imágenes y sombras en 3 columnas con puntos de unión. El alumno traza líneas entre los puntos para relacionar cada imagen con su sombra.', iconName: 'link', colorValue: 0xFF1976D2, order: 1, category: 'individual' },
    { id: 'puzzle', name: 'puzzle', title: 'Puzle', description: 'Puzle de 4x4 para recortar', infoTooltip: 'Genera un puzle de 4x4 (16 piezas) con la imagen del canvas. Perfecto para imprimir, recortar y que el alumno lo monte.', iconName: 'extension', colorValue: 0xFFF57C00, order: 2, category: 'individual' },
    { id: 'writing_practice', name: 'writing_practice', title: 'Práctica de Escritura', description: 'Imágenes con pauta para escribir', infoTooltip: 'Organiza las imágenes en filas y columnas con pauta debajo de cada una para que el alumno escriba el nombre.', iconName: 'edit_note', colorValue: 0xFF388E3C, order: 3, category: 'individual' },
    { id: 'counting_practice', name: 'counting_practice', title: 'Práctica de Conteo', description: 'Contar elementos repetidos', infoTooltip: 'Crea ejercicios con cada imagen repetida un número aleatorio de veces en su caja, con espacio para escribir la cantidad.', iconName: 'calculate', colorValue: 0xFF7B1FA2, order: 4, category: 'individual' },
    { id: 'phonological_awareness', name: 'phonological_awareness', title: 'Conciencia Fonológica', description: 'Separar palabras en sílabas', infoTooltip: 'Separa las palabras en sílabas. Muestra la imagen, las sílabas separadas y líneas en pauta escolar para que el alumno repase cada sílaba.', iconName: 'hearing', colorValue: 0xFF6A1B9A, order: 5, category: 'individual' },
    { id: 'phonological_board', name: 'phonological_board', title: 'Tablero Fonológico (recortable)', description: 'Tablero con puzle y recortables', infoTooltip: 'Crea un tablero vertical con zona de puzle 2x2 y huecos para palabra, sílabas y letras, más otra hoja con las piezas y tarjetas recortables listas para imprimir.', iconName: 'view_column', colorValue: 0xFFE64A19, order: 6, category: 'individual' },
    { id: 'series', name: 'series', title: 'Series', description: 'Continuar patrones ABAB', infoTooltip: 'Muestra una serie de dos elementos alternados (ABAB...) y deja espacios en blanco para que el alumno continúe el patrón.', iconName: 'auto_awesome', colorValue: 0xFFC2185B, order: 7, category: 'individual' },
    { id: 'symmetry', name: 'symmetry', title: 'Simetrías', description: 'Encontrar objetos iguales al modelo', infoTooltip: 'Muestra un objeto modelo y una cuadrícula 5x5 con el mismo objeto en diferentes orientaciones (rotado, volteado). El alumno debe encontrar los iguales al modelo.', iconName: 'flip', colorValue: 0xFF00796B, order: 8, category: 'individual' },
    { id: 'phrases', name: 'phrases', title: 'Frases', description: 'Frases con pictogramas', infoTooltip: 'Muestra una imagen grande arriba y debajo la frase convertida en pictogramas para que el alumno lea o reconstruya.', iconName: 'forum_outlined', colorValue: 0xFF455A64, order: 9, category: 'individual' },
    { id: 'card', name: 'card', title: 'Tarjeta', description: 'Tarjeta con imagen y texto', infoTooltip: 'Genera una tarjeta con la imagen a la izquierda y texto (título + párrafo) a la derecha.', iconName: 'credit_card', colorValue: 0xFFE64A19, order: 10, category: 'individual' },
    { id: 'syllable_vocabulary', name: 'syllable_vocabulary', title: 'Vocabulario por Sílaba', description: 'Palabras que empiezan con una sílaba', infoTooltip: 'Genera automáticamente una lista de palabras con pictogramas de ARASAAC que empiezan con la sílaba que elijas (pa, ma, sa, etc.). No requiere añadir imágenes previamente.', iconName: 'abc', colorValue: 0xFF303F9F, order: 11, category: 'individual' },
    { id: 'semantic_field', name: 'semantic_field', title: 'Campo Semántico', description: 'Palabras relacionadas temáticamente', infoTooltip: 'Añade una imagen de ARASAAC con texto y genera automáticamente una cuadrícula 5x5 con palabras relacionadas del mismo campo semántico (animales, frutas, ropa, etc.).', iconName: 'category', colorValue: 0xFFFFA000, order: 12, category: 'individual' },
    { id: 'instructions', name: 'instructions', title: 'Instrucciones (Rodea)', description: 'Rodear elementos según instrucciones', infoTooltip: 'Genera una actividad con instrucciones tipo "Rodea 2 casas, 3 árboles". Los objetos aparecen distribuidos aleatoriamente con algunos distractores.', iconName: 'radio_button_checked', colorValue: 0xFFD32F2F, order: 13, category: 'individual' },
    { id: 'classification', name: 'classification', title: 'Clasificación', description: 'Clasificar objetos en categorías', infoTooltip: 'Crea una actividad de clasificación en 2 hojas: una con 2 cuadrados de categorías y otra con 10 objetos relacionados para recortar y clasificar. Requiere 2 imágenes de ARASAAC en el canvas.', iconName: 'dashboard', colorValue: 0xFF0097A7, order: 14, category: 'individual' },
    { id: 'phonological_squares', name: 'phonological_squares', title: 'Cuadrados Fonológicos', description: 'Pintar cuadrados por cada letra', infoTooltip: 'Muestra las imágenes del canvas con un rectángulo de 10 cuadrados (2 filas x 5 columnas) debajo de cada una. El alumno pinta un cuadrado por cada letra de la palabra.', iconName: 'grid_4x4', colorValue: 0xFF0288D1, order: 15, category: 'individual', isNew: true },
    { id: 'crossword', name: 'crossword', title: 'Crucigrama', description: 'Crucigrama con las palabras', infoTooltip: 'Genera un crucigrama usando las palabras de las imágenes del canvas. Las imágenes sirven como pistas numeradas para completar el crucigrama.', iconName: 'apps', colorValue: 0xFF5D4037, order: 16, category: 'individual', isNew: true },
    { id: 'word_search', name: 'word_search', title: 'Sopa de Letras', description: 'Encontrar palabras escondidas', infoTooltip: 'Crea una sopa de letras donde el alumno debe encontrar las palabras de las imágenes del canvas escondidas en una cuadrícula de 15x15 letras.', iconName: 'search', colorValue: 0xFF6A1B9A, order: 17, category: 'individual', isNew: true },
    { id: 'sentence_completion', name: 'sentence_completion', title: 'Completar Frases', description: 'Frases con espacios en blanco', infoTooltip: 'Genera frases simples con las imágenes del canvas. Cada página muestra un modelo de frase completa y debajo la misma frase con espacios en blanco para completar. Incluye una página con recortables.', iconName: 'edit_note', colorValue: 0xFF00796B, order: 18, category: 'individual', isNew: true },
  ];

  try {
    let count = 0;
    for (const activity of defaultActivities) {
      await pool.query(
        `INSERT INTO activity_type (
          id, name, title, description, info_tooltip,
          icon_name, color_value, "order", is_new,
          is_highlighted, is_enabled, category
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ON CONFLICT (id) DO UPDATE SET
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
          true,
          activity.category,
        ]
      );
      count++;
    }

    return res.json({ message: `${count} actividades insertadas/actualizadas correctamente` });
  } catch (err) {
    console.error('Seed error', err);
    return res.status(500).json({ message: 'Error insertando actividades', error: err.message });
  }
});

const createToken = (user) =>
  jwt.sign({ sub: user.id, email: user.email }, jwtSecret, {
    expiresIn: '7d',
  });

async function findUserByEmail(email) {
  const { rows } = await pool.query(
    'SELECT id, email, password_hash FROM app_user WHERE LOWER(email) = LOWER($1) LIMIT 1',
    [email],
  );
  return rows[0];
}

app.post('/auth/register', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password || password.length < 6) {
      return res
        .status(400)
        .json({ message: 'Email y contraseña (mín. 6 chars) son obligatorios' });
    }

    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ message: 'El usuario ya existe' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const { rows } = await pool.query(
      'INSERT INTO app_user (id, email, password_hash) VALUES ($1, $2, $3) RETURNING id, email',
      [uuidv4(), email, passwordHash],
    );
    const user = rows[0];
    const token = createToken(user);
    return res.status(201).json({ token, user });
  } catch (err) {
    console.error('Register error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ message: 'Email y contraseña son obligatorios' });
    }

    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Credenciales incorrectas' });
    }
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ message: 'Credenciales incorrectas' });
    }

    const token = createToken(user);
    return res.json({ token, user: { id: user.id, email: user.email } });
  } catch (err) {
    console.error('Login error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

const authMiddleware = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Falta token' });
  }
  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, jwtSecret);
    req.user = { id: payload.sub, email: payload.email };
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Token inválido o expirado' });
  }
};

app.get('/projects', authMiddleware, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, name, data, cover_image_url, updated_at FROM project WHERE user_id = $1 ORDER BY updated_at DESC',
      [req.user.id],
    );
    return res.json(rows);
  } catch (err) {
    console.error('Fetch projects error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

app.post('/projects', authMiddleware, async (req, res) => {
  try {
    const { id, name, data } = req.body || {};
    if (!name || !data) {
      return res.status(400).json({ message: 'Nombre y datos del proyecto son obligatorios' });
    }

    const projectId = id || uuidv4();

    // Extraer URL de imagen de portada del JSON data
    let coverImageUrl = null;
    try {
      const parsedData = typeof data === 'string' ? JSON.parse(data) : data;
      if (parsedData.coverImage && parsedData.coverImage.imageUrl) {
        coverImageUrl = parsedData.coverImage.imageUrl;
      }
    } catch (e) {
      // Si falla el parsing, continuar sin imagen de portada
      console.warn('No se pudo extraer coverImage:', e);
    }

    // UPSERT: Insertar o actualizar si existe
    const { rows } = await pool.query(
      `INSERT INTO project (id, user_id, name, data, cover_image_url)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO UPDATE
       SET name = EXCLUDED.name,
           data = EXCLUDED.data,
           cover_image_url = EXCLUDED.cover_image_url,
           updated_at = now()
       WHERE project.user_id = $2
       RETURNING id, name, data, cover_image_url, updated_at`,
      [projectId, req.user.id, name, data, coverImageUrl],
    );

    if (rows.length === 0) {
      return res.status(403).json({ message: 'No tienes permiso para modificar este proyecto' });
    }

    return res.status(id ? 200 : 201).json(rows[0]);
  } catch (err) {
    console.error('Save project error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

app.delete('/projects/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { rowCount } = await pool.query(
      'DELETE FROM project WHERE id = $1 AND user_id = $2',
      [id, req.user.id],
    );
    if (rowCount === 0) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }
    return res.status(204).send();
  } catch (err) {
    console.error('Delete project error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

// Proxy para separación de sílabas (evitar CORS)
app.get('/syllables', async (req, res) => {
  try {
    const { word } = req.query;

    if (!word) {
      return res.status(400).json({ message: 'Word parameter required' });
    }

    const url = `http://www.aulatea.com/silabas/website/silabas/index.php?json=1&word=${encodeURIComponent(word)}`;
    const response = await fetch(url);
    const data = await response.json();

    return res.json(data);
  } catch (err) {
    console.error('Syllables proxy error:', err);
    return res.status(500).json({ message: 'Error fetching syllables data' });
  }
});

// Proxy para SoyVisual (evitar CORS)
app.get('/soyvisual/search', async (req, res) => {
  try {
    const { query, type = 'photo', items_per_page = '20' } = req.query;

    if (!query) {
      return res.status(400).json({ message: 'Query parameter required' });
    }

    const url = new URL('https://www.soyvisual.org/api/v1/resources.json');
    url.searchParams.set('token', '6B5165B822AE4400813CF4EC490BF6AB');
    url.searchParams.set('query', query);
    url.searchParams.set('type', type);
    url.searchParams.set('items_per_page', items_per_page);
    url.searchParams.set('matching', 'contain');

    const response = await fetch(url.toString());
    const data = await response.json();

    // Reemplazar URLs de imágenes para que pasen por nuestro proxy
    const baseUrl = process.env.NODE_ENV === 'production'
      ? 'https://activi-production.up.railway.app'
      : `http://localhost:${port}`;

    const proxyData = data.map(item => ({
      ...item,
      image: {
        ...item.image,
        src: `${baseUrl}/soyvisual/image?url=${encodeURIComponent(item.image.src)}`
      },
      thumbnail: {
        ...item.thumbnail,
        src: `${baseUrl}/soyvisual/image?url=${encodeURIComponent(item.thumbnail.src)}`
      }
    }));

    return res.json(proxyData);
  } catch (err) {
    console.error('SoyVisual proxy error:', err);
    return res.status(500).json({ message: 'Error fetching SoyVisual data' });
  }
});

// Proxy para imágenes de SoyVisual
app.get('/soyvisual/image', async (req, res) => {
  try {
    const { url } = req.query;

    if (!url) {
      return res.status(400).json({ message: 'URL parameter required' });
    }

    const response = await fetch(url);
    const buffer = await response.arrayBuffer();

    res.set('Content-Type', response.headers.get('content-type') || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=86400'); // Cache por 24h
    res.send(Buffer.from(buffer));
  } catch (err) {
    console.error('SoyVisual image proxy error:', err);
    return res.status(500).send('Error fetching image');
  }
});

// ============================================
// ENDPOINTS DE GESTIÓN DE TIPOS DE ACTIVIDADES
// ============================================

// Obtener todos los tipos de actividades (público, con camelCase)
app.get('/activity-types', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM activity_type ORDER BY "order" ASC'
    );

    // Convertir snake_case a camelCase para el frontend
    const activities = rows.map(row => ({
      id: row.id,
      name: row.name,
      title: row.title,
      description: row.description,
      infoTooltip: row.info_tooltip,
      iconName: row.icon_name,
      colorValue: parseInt(row.color_value),
      order: row.order,
      isNew: row.is_new,
      isHighlighted: row.is_highlighted,
      isEnabled: row.is_enabled,
      category: row.category,
      activityPictogramUrl: row.activity_pictogram_url,
      materialPictogramUrls: row.material_pictogram_urls,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));

    return res.json(activities);
  } catch (err) {
    console.error('Fetch activity types error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

// Obtener un tipo de actividad por nombre (público)
app.get('/activity-types/name/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const { rows } = await pool.query(
      'SELECT * FROM activity_type WHERE name = $1 LIMIT 1',
      [name]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Actividad no encontrada' });
    }

    const row = rows[0];
    const activity = {
      id: row.id,
      name: row.name,
      title: row.title,
      description: row.description,
      infoTooltip: row.info_tooltip,
      iconName: row.icon_name,
      colorValue: parseInt(row.color_value),
      order: row.order,
      isNew: row.is_new,
      isHighlighted: row.is_highlighted,
      isEnabled: row.is_enabled,
      category: row.category,
      activityPictogramUrl: row.activity_pictogram_url,
      materialPictogramUrls: row.material_pictogram_urls,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };

    return res.json(activity);
  } catch (err) {
    console.error('Fetch activity type by name error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

// Crear un nuevo tipo de actividad (requiere autenticación)
app.post('/activity-types', authMiddleware, async (req, res) => {
  try {
    const {
      id,
      name,
      title,
      description,
      infoTooltip,
      iconName,
      colorValue,
      order,
      isNew,
      isHighlighted,
      isEnabled,
      category,
      activityPictogramUrl,
      materialPictogramUrls,
    } = req.body || {};

    if (!name || !title) {
      return res.status(400).json({ message: 'name y title son obligatorios' });
    }

    const activityId = id || uuidv4();

    const { rows } = await pool.query(
      `INSERT INTO activity_type (
        id, name, title, description, info_tooltip,
        icon_name, color_value, "order", is_new,
        is_highlighted, is_enabled, category,
        activity_pictogram_url, material_pictogram_urls
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *`,
      [
        activityId,
        name,
        title,
        description || '',
        infoTooltip || '',
        iconName || 'help_outline',
        colorValue || 0xFF2196F3,
        order || 999,
        isNew || false,
        isHighlighted || false,
        isEnabled !== undefined ? isEnabled : true,
        category,
        activityPictogramUrl,
        materialPictogramUrls,
      ]
    );

    const row = rows[0];
    const activity = {
      id: row.id,
      name: row.name,
      title: row.title,
      description: row.description,
      infoTooltip: row.info_tooltip,
      iconName: row.icon_name,
      colorValue: parseInt(row.color_value),
      order: row.order,
      isNew: row.is_new,
      isHighlighted: row.is_highlighted,
      isEnabled: row.is_enabled,
      category: row.category,
      activityPictogramUrl: row.activity_pictogram_url,
      materialPictogramUrls: row.material_pictogram_urls,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };

    return res.status(201).json(activity);
  } catch (err) {
    console.error('Create activity type error', err);
    if (err.code === '23505') {
      // Unique violation
      return res.status(409).json({ message: 'Ya existe una actividad con ese nombre' });
    }
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

// Actualizar un tipo de actividad (requiere autenticación)
app.put('/activity-types/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      title,
      description,
      infoTooltip,
      iconName,
      colorValue,
      order,
      isNew,
      isHighlighted,
      isEnabled,
      category,
      activityPictogramUrl,
      materialPictogramUrls,
    } = req.body || {};

    const { rows } = await pool.query(
      `UPDATE activity_type SET
        name = COALESCE($2, name),
        title = COALESCE($3, title),
        description = COALESCE($4, description),
        info_tooltip = COALESCE($5, info_tooltip),
        icon_name = COALESCE($6, icon_name),
        color_value = COALESCE($7, color_value),
        "order" = COALESCE($8, "order"),
        is_new = COALESCE($9, is_new),
        is_highlighted = COALESCE($10, is_highlighted),
        is_enabled = COALESCE($11, is_enabled),
        category = $12,
        activity_pictogram_url = $13,
        material_pictogram_urls = $14,
        updated_at = now()
      WHERE id = $1
      RETURNING *`,
      [
        id,
        name,
        title,
        description,
        infoTooltip,
        iconName,
        colorValue,
        order,
        isNew,
        isHighlighted,
        isEnabled,
        category,
        activityPictogramUrl,
        materialPictogramUrls,
      ]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Actividad no encontrada' });
    }

    const row = rows[0];
    const activity = {
      id: row.id,
      name: row.name,
      title: row.title,
      description: row.description,
      infoTooltip: row.info_tooltip,
      iconName: row.icon_name,
      colorValue: parseInt(row.color_value),
      order: row.order,
      isNew: row.is_new,
      isHighlighted: row.is_highlighted,
      isEnabled: row.is_enabled,
      category: row.category,
      activityPictogramUrl: row.activity_pictogram_url,
      materialPictogramUrls: row.material_pictogram_urls,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };

    return res.json(activity);
  } catch (err) {
    console.error('Update activity type error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

// Eliminar un tipo de actividad (requiere autenticación)
app.delete('/activity-types/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { rowCount } = await pool.query(
      'DELETE FROM activity_type WHERE id = $1',
      [id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ message: 'Actividad no encontrada' });
    }

    return res.status(204).send();
  } catch (err) {
    console.error('Delete activity type error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

// Reordenar tipos de actividades (requiere autenticación)
app.put('/activity-types/reorder', authMiddleware, async (req, res) => {
  try {
    const { activities } = req.body || {};

    if (!Array.isArray(activities)) {
      return res.status(400).json({ message: 'activities debe ser un array' });
    }

    // Actualizar el orden de cada actividad
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (const activity of activities) {
        if (!activity.id || activity.order === undefined) {
          await client.query('ROLLBACK');
          return res.status(400).json({ message: 'Cada actividad debe tener id y order' });
        }

        await client.query(
          'UPDATE activity_type SET "order" = $2, updated_at = now() WHERE id = $1',
          [activity.id, activity.order]
        );
      }

      await client.query('COMMIT');
      return res.json({ message: 'Orden actualizado correctamente' });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('Reorder activity types error', err);
    return res.status(500).json({ message: 'Error en servidor' });
  }
});

app.listen(port, () => {
  console.log(`API listening on :${port}`);
});
// Deploy v2.3.0 - Activity Types CRUD endpoints added
