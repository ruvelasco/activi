-- Migración: Añadir columna cover_image_url a la tabla project
-- Fecha: 2025-12-28

ALTER TABLE project
ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

COMMENT ON COLUMN project.cover_image_url IS 'URL de la imagen de portada del proyecto (primera imagen de la primera página)';
