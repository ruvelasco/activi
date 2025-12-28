-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS app_user (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tabla de proyectos
CREATE TABLE IF NOT EXISTS project (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  data JSONB NOT NULL,
  cover_image_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_project_user ON project(user_id);

-- Tabla de tipos de actividades
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
);

CREATE INDEX IF NOT EXISTS idx_activity_type_order ON activity_type("order");
CREATE INDEX IF NOT EXISTS idx_activity_type_enabled ON activity_type(is_enabled);
