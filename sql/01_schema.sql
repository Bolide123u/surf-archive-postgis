-- 01 : schémas et tables du modèle cible
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS archive;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS qc;

CREATE TABLE ref.asset_type (
  asset_type_id serial PRIMARY KEY,
  code  text UNIQUE NOT NULL,
  label text NOT NULL
);
CREATE TABLE ref.status (
  status_code text PRIMARY KEY,
  label text NOT NULL
);
INSERT INTO ref.asset_type (code, label) VALUES
  ('PIPELINE', 'Pipeline sous-marin'), ('CABLE', 'Câble sous-marin');
INSERT INTO ref.status VALUES
  ('planned', 'Prévu'), ('installed', 'Installé / en service'), ('abandoned', 'Abandonné / déclassé');

CREATE TABLE archive.project (
  project_id serial PRIMARY KEY,
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  region text,
  source_format text,
  loaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE archive.asset (
  asset_id bigserial PRIMARY KEY,
  project_id    int  NOT NULL REFERENCES archive.project ON DELETE RESTRICT,
  asset_type_id int  NOT NULL REFERENCES ref.asset_type,
  source_id     text NOT NULL,
  name          text,
  status_code   text NOT NULL REFERENCES ref.status,
  operator      text,
  diameter_mm   int CHECK (diameter_mm > 0),
  install_year  int CHECK (install_year BETWEEN 1900 AND 2100),
  geom          geometry(LineString, 4326) NOT NULL,
  CONSTRAINT asset_geom_valid CHECK (ST_IsValid(geom)),
  UNIQUE (project_id, source_id)
);
CREATE INDEX asset_geom_gix ON archive.asset USING GIST (geom);
CREATE INDEX asset_project_ix ON archive.asset (project_id);

CREATE TABLE archive.document (
  document_id serial PRIMARY KEY,
  title text NOT NULL,
  doc_type text NOT NULL CHECK (doc_type IN ('plan', 'rapport', 'inspection')),
  uri text
);
-- table de liaison N-N entre ouvrages et documents
CREATE TABLE archive.asset_document (
  asset_id    bigint REFERENCES archive.asset    ON DELETE CASCADE,
  document_id int    REFERENCES archive.document ON DELETE CASCADE,
  PRIMARY KEY (asset_id, document_id)
);

-- zones de staging : structure brute de chaque projet source (tout en texte)
CREATE TABLE staging.proj_a (pipe_id text, pipe_name text, status_fr text, diam_mm text, operator text, wkt text);
CREATE TABLE staging.proj_b (cable_ref text, nom text, etat text, proprietaire text, annee_pose text, geom_wkt text);
