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
      'SELECT id, name, data, updated_at FROM project WHERE user_id = $1 ORDER BY updated_at DESC',
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

    // UPSERT: Insertar o actualizar si existe
    const { rows } = await pool.query(
      `INSERT INTO project (id, user_id, name, data)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE
       SET name = EXCLUDED.name,
           data = EXCLUDED.data,
           updated_at = now()
       WHERE project.user_id = $2
       RETURNING id, name, data, updated_at`,
      [projectId, req.user.id, name, data],
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

app.listen(port, () => {
  console.log(`API listening on :${port}`);
});
// Force redeploy 1765485346
// Force redeploy 1765485365
// Deploy v2.2.1 1765489091
