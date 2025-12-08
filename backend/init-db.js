import fs from 'fs';
import pkg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Client } = pkg;

async function initDatabase() {
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

    console.log('Leyendo script SQL...');
    const sql = fs.readFileSync('./db.sql', 'utf8');

    console.log('Ejecutando script de inicialización...');
    await client.query(sql);
    console.log('✓ Tablas creadas correctamente');

    // Verificar que las tablas existen
    const result = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name IN ('app_user', 'project')
      ORDER BY table_name;
    `);

    console.log('\nTablas encontradas:');
    result.rows.forEach((row) => {
      console.log(`  - ${row.table_name}`);
    });

    console.log('\n✓ Base de datos inicializada correctamente');
  } catch (err) {
    console.error('Error al inicializar la base de datos:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

initDatabase();
