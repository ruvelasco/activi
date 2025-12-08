# ARASAAC Activities API (Railway)

API REST mínima para login/registro y proyectos persistidos en Postgres (pensada para Railway).

## Configuración local
1. Copia `.env.example` a `.env` y completa `DATABASE_URL` y `JWT_SECRET`.
2. Crea tablas:
   ```sh
   psql "$DATABASE_URL" -f db.sql
   ```
3. Instala dependencias y arranca:
   ```sh
   npm install
   npm run dev
   ```

## Rutas
- `POST /auth/register` { email, password } → { token, user }
- `POST /auth/login` { email, password } → { token, user }
- `GET /projects` (Bearer token) → lista de proyectos
- `POST /projects` (Bearer token) { id?, name, data } → crea/actualiza
- `DELETE /projects/:id` (Bearer token) → borra proyecto

## Despliegue en Railway
1. Nuevo servicio "Web Service" apuntando al repo subcarpeta `backend/`.
2. Añade variable `DATABASE_URL` apuntando a un servicio Postgres de Railway.
3. Añade `JWT_SECRET` (cualquier cadena aleatoria larga).
4. Railway detecta `npm start` y expone el puerto configurado en `PORT` (por defecto 8080).
