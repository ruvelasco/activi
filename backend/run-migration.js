import fs from 'fs';
import pkg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Client } = pkg;

async function runMigration() {
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

    console.log('\nEjecutando migración: 001_add_visual_instructions.sql');
    const sql = fs.readFileSync('./migrations/001_add_visual_instructions.sql', 'utf8');

    await client.query(sql);
    console.log('✓ Migración ejecutada correctamente');

    // Verificar que las columnas existen
    const result = await client.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'activity_type'
      AND column_name IN ('activity_pictogram_url', 'material_pictogram_urls')
      ORDER BY column_name;
    `);

    console.log('\nColumnas añadidas:');
    result.rows.forEach((row) => {
      console.log(`  - ${row.column_name} (${row.data_type})`);
    });

    console.log('\n✓ Migración completada exitosamente');
  } catch (err) {
    console.error('Error al ejecutar la migración:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
