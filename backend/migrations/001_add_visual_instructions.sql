-- Migración: Añadir columnas para instrucciones visuales a activity_type
-- Fecha: 2025-12-28

-- Añadir columna para URL del pictograma de actividad
ALTER TABLE activity_type
ADD COLUMN IF NOT EXISTS activity_pictogram_url TEXT;

-- Añadir columna para URLs de pictogramas de materiales (array)
ALTER TABLE activity_type
ADD COLUMN IF NOT EXISTS material_pictogram_urls TEXT[];

-- Comentarios explicativos
COMMENT ON COLUMN activity_type.activity_pictogram_url IS 'URL del pictograma que representa la actividad (ej: imagen de puzzle para actividad de puzzle)';
COMMENT ON COLUMN activity_type.material_pictogram_urls IS 'Array de URLs de pictogramas de materiales necesarios para la actividad (ej: lápiz, tijeras, pegamento)';
