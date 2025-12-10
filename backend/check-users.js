import pkg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Client } = pkg;

async function checkUsers() {
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
    console.log('✓ Conectado\n');

    // Ver todos los usuarios
    const usersResult = await client.query(
      'SELECT id, email, created_at FROM app_user ORDER BY created_at DESC'
    );

    console.log('=== USUARIOS EN LA BASE DE DATOS ===');
    if (usersResult.rows.length === 0) {
      console.log('No hay usuarios registrados');
    } else {
      usersResult.rows.forEach((user, index) => {
        console.log(`${index + 1}. ${user.email}`);
        console.log(`   ID: ${user.id}`);
        console.log(`   Creado: ${user.created_at}`);
        console.log('');
      });
    }

    // Ver todos los proyectos
    const projectsResult = await client.query(
      'SELECT id, user_id, name, updated_at FROM project ORDER BY updated_at DESC'
    );

    console.log('\n=== PROYECTOS EN LA BASE DE DATOS ===');
    if (projectsResult.rows.length === 0) {
      console.log('No hay proyectos');
    } else {
      projectsResult.rows.forEach((project, index) => {
        console.log(`${index + 1}. ${project.name}`);
        console.log(`   ID: ${project.id}`);
        console.log(`   Usuario: ${project.user_id}`);
        console.log(`   Actualizado: ${project.updated_at}`);
        console.log('');
      });
    }

  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

checkUsers();
