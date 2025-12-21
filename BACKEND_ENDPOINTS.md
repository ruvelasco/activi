# Endpoints del Backend para Tipos de Actividades

Esta documentación especifica los endpoints que necesitas implementar en tu backend de Railway (`activi-production.up.railway.app` o `shimmering-benevolence-production.up.railway.app`) para gestionar los tipos de actividades.

## Base URL
```
https://activi-production.up.railway.app
```

---

## 1. Obtener todas las actividades

**Endpoint:** `GET /activity-types`

**Descripción:** Retorna todas las actividades ordenadas por el campo `order`.

**Headers:**
- `Authorization: Bearer {token}` (opcional - para verificar permisos)

**Respuesta exitosa:** `200 OK`
```json
[
  {
    "id": "shadow_matching",
    "name": "shadow_matching",
    "title": "Relacionar Sombras",
    "description": "Une cada imagen con su sombra",
    "infoTooltip": "Crea una actividad con imágenes y sombras...",
    "iconName": "link",
    "colorValue": 4282811858,
    "order": 1,
    "isNew": false,
    "isHighlighted": false,
    "isEnabled": true,
    "category": "individual",
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  },
  ...
]
```

**Respuesta sin datos:** `404 Not Found`
```json
{
  "error": "No se encontraron actividades"
}
```

---

## 2. Obtener actividad por nombre

**Endpoint:** `GET /activity-types/name/:name`

**Descripción:** Retorna una actividad específica por su nombre interno.

**Parámetros de ruta:**
- `name` (string) - Nombre interno de la actividad (ej: `shadow_matching`)

**Headers:**
- `Authorization: Bearer {token}` (opcional)

**Respuesta exitosa:** `200 OK`
```json
{
  "id": "shadow_matching",
  "name": "shadow_matching",
  "title": "Relacionar Sombras",
  "description": "Une cada imagen con su sombra",
  "infoTooltip": "Crea una actividad con imágenes y sombras...",
  "iconName": "link",
  "colorValue": 4282811858,
  "order": 1,
  "isNew": false,
  "isHighlighted": false,
  "isEnabled": true,
  "category": "individual",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

**Respuesta error:** `404 Not Found`
```json
{
  "error": "Actividad no encontrada"
}
```

---

## 3. Crear nueva actividad

**Endpoint:** `POST /activity-types`

**Descripción:** Crea una nueva actividad. **Requiere autenticación de administrador**.

**Headers:**
- `Authorization: Bearer {token}` (requerido)
- `Content-Type: application/json`

**Body:**
```json
{
  "name": "new_activity",
  "title": "Nueva Actividad",
  "description": "Descripción corta",
  "infoTooltip": "Información detallada...",
  "iconName": "auto_awesome",
  "colorValue": 4282811858,
  "order": 10,
  "isNew": true,
  "isHighlighted": false,
  "isEnabled": true,
  "category": "individual"
}
```

**Validaciones:**
- `name` es requerido y único
- `title` es requerido
- `description` es requerido
- `iconName` es requerido
- `colorValue` debe ser un entero válido (formato ARGB)
- `order` debe ser un número

**Respuesta exitosa:** `201 Created`
```json
{
  "id": "abc123xyz",
  "name": "new_activity",
  "title": "Nueva Actividad",
  "description": "Descripción corta",
  "infoTooltip": "Información detallada...",
  "iconName": "auto_awesome",
  "colorValue": 4282811858,
  "order": 10,
  "isNew": true,
  "isHighlighted": false,
  "isEnabled": true,
  "category": "individual",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

**Respuesta error (sin autenticación):** `401 Unauthorized`
```json
{
  "error": "No autenticado"
}
```

**Respuesta error (sin permisos):** `403 Forbidden`
```json
{
  "error": "No tienes permisos de administrador"
}
```

**Respuesta error (validación):** `400 Bad Request`
```json
{
  "error": "El nombre ya existe"
}
```

---

## 4. Actualizar actividad

**Endpoint:** `PUT /activity-types/:id`

**Descripción:** Actualiza una actividad existente. **Requiere autenticación de administrador**.

**Parámetros de ruta:**
- `id` (string) - ID de la actividad

**Headers:**
- `Authorization: Bearer {token}` (requerido)
- `Content-Type: application/json`

**Body:**
```json
{
  "name": "shadow_matching",
  "title": "Relacionar Sombras (Actualizado)",
  "description": "Nueva descripción",
  "infoTooltip": "Nuevo tooltip...",
  "iconName": "link",
  "colorValue": 4282811858,
  "order": 1,
  "isNew": false,
  "isHighlighted": false,
  "isEnabled": true,
  "category": "individual",
  "updatedAt": "2025-01-15T11:00:00Z"
}
```

**Respuesta exitosa:** `200 OK`
```json
{
  "id": "shadow_matching",
  "name": "shadow_matching",
  "title": "Relacionar Sombras (Actualizado)",
  "description": "Nueva descripción",
  "infoTooltip": "Nuevo tooltip...",
  "iconName": "link",
  "colorValue": 4282811858,
  "order": 1,
  "isNew": false,
  "isHighlighted": false,
  "isEnabled": true,
  "category": "individual",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T11:00:00Z"
}
```

**Respuesta error:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`

---

## 5. Eliminar actividad

**Endpoint:** `DELETE /activity-types/:id`

**Descripción:** Elimina una actividad. **Requiere autenticación de administrador**.

**Parámetros de ruta:**
- `id` (string) - ID de la actividad

**Headers:**
- `Authorization: Bearer {token}` (requerido)

**Respuesta exitosa:** `200 OK` o `204 No Content`
```json
{
  "message": "Actividad eliminada exitosamente"
}
```

**Respuesta error:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`

---

## 6. Reordenar actividades

**Endpoint:** `PUT /activity-types/reorder`

**Descripción:** Actualiza el orden de múltiples actividades. **Requiere autenticación de administrador**.

**Headers:**
- `Authorization: Bearer {token}` (requerido)
- `Content-Type: application/json`

**Body:**
```json
{
  "activities": [
    {
      "id": "pack",
      "order": 0
    },
    {
      "id": "shadow_matching",
      "order": 1
    },
    {
      "id": "puzzle",
      "order": 2
    }
  ]
}
```

**Respuesta exitosa:** `200 OK`
```json
{
  "message": "Orden actualizado exitosamente",
  "updatedCount": 3
}
```

**Respuesta error:** `401 Unauthorized`, `403 Forbidden`, `400 Bad Request`

---

## Modelo de datos

### ActivityType

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| id | string | Sí (generado) | ID único |
| name | string | Sí | Nombre interno único (ej: "shadow_matching") |
| title | string | Sí | Título visible (ej: "Relacionar Sombras") |
| description | string | Sí | Descripción breve |
| infoTooltip | string | No | Tooltip informativo detallado |
| iconName | string | Sí | Nombre del icono Material |
| colorValue | integer | Sí | Color en formato ARGB (4 bytes) |
| order | integer | Sí | Orden en el menú (menor = primero) |
| isNew | boolean | No (default: false) | Marcar como nueva |
| isHighlighted | boolean | No (default: false) | Destacar especialmente |
| isEnabled | boolean | No (default: true) | Habilitar/deshabilitar |
| category | string | No | Categoría (pack, individual, etc.) |
| createdAt | datetime | Sí (generado) | Fecha de creación |
| updatedAt | datetime | Sí (auto) | Fecha de última actualización |

---

## Notas de implementación

### Base de datos

Puedes usar cualquier base de datos. Sugerencias:

**PostgreSQL (recomendado para Railway):**
```sql
CREATE TABLE activity_types (
  id VARCHAR(255) PRIMARY KEY,
  name VARCHAR(255) UNIQUE NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  info_tooltip TEXT,
  icon_name VARCHAR(100) NOT NULL,
  color_value INTEGER NOT NULL,
  "order" INTEGER NOT NULL DEFAULT 999,
  is_new BOOLEAN DEFAULT FALSE,
  is_highlighted BOOLEAN DEFAULT FALSE,
  is_enabled BOOLEAN DEFAULT TRUE,
  category VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activity_types_order ON activity_types("order");
CREATE INDEX idx_activity_types_name ON activity_types(name);
CREATE INDEX idx_activity_types_enabled ON activity_types(is_enabled);
```

### Autenticación

Los endpoints de escritura (POST, PUT, DELETE) deben verificar:
1. Que el usuario esté autenticado (tiene token válido)
2. Que el usuario tenga rol de administrador

Puedes agregar un campo `isAdmin` o `role` en tu tabla de usuarios.

### Valores por defecto

Si la tabla está vacía, puedes poblarla con los valores por defecto que están en el archivo `activity_type_service.dart` del cliente Flutter.

### CORS

Asegúrate de tener CORS habilitado para permitir peticiones desde el cliente Flutter web.

---

## Testing

### Usando curl

```bash
# Obtener todas las actividades
curl https://activi-production.up.railway.app/activity-types

# Obtener por nombre
curl https://activi-production.up.railway.app/activity-types/name/shadow_matching

# Crear (requiere token)
curl -X POST https://activi-production.up.railway.app/activity-types \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","title":"Test","description":"Test desc","iconName":"auto_awesome","colorValue":4282811858,"order":99}'

# Actualizar (requiere token)
curl -X PUT https://activi-production.up.railway.app/activity-types/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","title":"Test Updated","description":"New desc","iconName":"auto_awesome","colorValue":4282811858,"order":99}'

# Eliminar (requiere token)
curl -X DELETE https://activi-production.up.railway.app/activity-types/test \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Próximos pasos

1. **Implementar los endpoints** en tu backend (Node.js, Python, Ruby, etc.)
2. **Crear la tabla** en tu base de datos
3. **Agregar middleware** de autenticación y autorización
4. **Poblar con datos iniciales** (opcional)
5. **Probar** cada endpoint con curl o Postman
6. **Integrar** la pantalla de administración en la app Flutter
