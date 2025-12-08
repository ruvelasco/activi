# Guía de Despliegue en Railway

## Paso 1: Crear el servicio PostgreSQL en Railway

1. Ve a tu proyecto en Railway
2. Haz clic en **"+ New"** → **"Database"** → **"Add PostgreSQL"**
3. Railway creará automáticamente la base de datos y generará las credenciales

## Paso 2: Ejecutar el script de creación de tablas

Hay **3 opciones** para crear las tablas:

### Opción A: Usando Railway CLI (Recomendado)

```bash
# 1. Instala Railway CLI
npm i -g @railway/cli

# 2. Inicia sesión
railway login

# 3. Vincula este proyecto
railway link

# 4. Ejecuta el script de inicialización
railway run node init-db.js
```

### Opción B: Usando psql desde tu computadora

```bash
# 1. Copia la DATABASE_URL desde Railway:
#    - Ve a tu servicio PostgreSQL en Railway
#    - Pestaña "Variables" → copia el valor de DATABASE_URL

# 2. Ejecuta el script SQL:
psql "postgresql://usuario:password@host:puerto/railway" -f db.sql

# Ejemplo:
# psql "postgresql://postgres:abc123@containers-us-west-123.railway.app:5432/railway" -f db.sql
```

### Opción C: Desde el panel de Railway (más simple)

```bash
# 1. En Railway, ve a tu servicio PostgreSQL
# 2. Pestaña "Data" → clic en "Query"
# 3. Copia y pega el contenido de db.sql
# 4. Ejecuta el query
```

## Paso 3: Crear el servicio de Backend en Railway

1. En tu proyecto de Railway, haz clic en **"+ New"** → **"GitHub Repo"**
2. Selecciona tu repositorio
3. Railway detectará automáticamente que es un proyecto Node.js

### Configurar Root Directory (IMPORTANTE)

Si tu backend está en una subcarpeta:

1. Ve a tu servicio web en Railway
2. **Settings** → **Source** → **Root Directory**
3. Escribe: `backend`
4. Guarda los cambios

## Paso 4: Configurar Variables de Entorno

En tu servicio de backend (NO en PostgreSQL):

1. Ve a la pestaña **"Variables"**
2. Haz clic en **"+ New Variable"** y añade:

```
NODE_ENV=production
JWT_SECRET=tu-secreto-super-seguro-aqui-cambialo
PORT=8080
```

3. Para `DATABASE_URL`:
   - Haz clic en **"+ New Variable"**
   - Selecciona **"Add Reference"**
   - Elige tu servicio PostgreSQL
   - Selecciona `DATABASE_URL`
   - Esto vinculará automáticamente la base de datos

## Paso 5: Desplegar

1. Railway desplegará automáticamente tu código
2. Espera a que termine el build (aparecerá "Active" en verde)
3. Railway te asignará una URL pública (ej: `https://tu-proyecto.up.railway.app`)

## Verificar que funciona

Prueba el endpoint de health:

```bash
curl https://tu-proyecto.up.railway.app/health
```

Deberías recibir:
```json
{"status":"ok"}
```

## Solución de problemas

### Error: "Cannot find module"
- Asegúrate de que `Root Directory` esté configurado en `backend`

### Error: "Database connection failed"
- Verifica que `DATABASE_URL` esté configurada como referencia al servicio PostgreSQL
- Verifica que las tablas se crearon correctamente

### Ver logs
- En Railway, ve a tu servicio de backend
- Pestaña **"Deployments"** → clic en el deployment activo
- Pestaña **"View Logs"**

## Conectar desde tu app Flutter

Actualiza la URL del API en tu proyecto Flutter con la URL de Railway:

```dart
// En tu archivo de configuración
const String apiBaseUrl = 'https://tu-proyecto.up.railway.app';
```

## Comandos útiles de Railway CLI

```bash
# Ver logs en tiempo real
railway logs

# Ver variables de entorno
railway variables

# Ejecutar comandos en el entorno de Railway
railway run <comando>

# Abrir el dashboard del proyecto
railway open
```
