-- 02 : chargement des CSV en staging puis transformation vers le modèle cible
-- À lancer depuis le dossier du dépôt (chemins relatifs).
\copy staging.proj_a FROM 'data/projet_a_pipelines.csv' CSV HEADER
\copy staging.proj_b FROM 'data/projet_b_cables.csv' CSV HEADER

INSERT INTO archive.project (code, name, region, source_format) VALUES
  ('A', 'Projet A - Pipelines mer du Nord', 'Mer du Nord', 'CSV (WKT) - noms de colonnes EN'),
  ('B', 'Projet B - Câbles Méditerranée', 'Méditerranée', 'CSV (WKT) - noms de colonnes FR');

-- Projet A : mapping vers le modèle cible (rejets conservés dans qc.rejected)
CREATE TABLE IF NOT EXISTS qc.rejected (project text, source_id text, reason text);

-- doublons d'identifiant : on garde la première occurrence, on journalise le reste
INSERT INTO qc.rejected
SELECT 'A', pipe_id, 'identifiant en double'
FROM (SELECT pipe_id, row_number() OVER (PARTITION BY pipe_id ORDER BY ctid) rn FROM staging.proj_a) t
WHERE rn > 1;

INSERT INTO qc.rejected
SELECT 'A', pipe_id, 'géométrie invalide'
FROM staging.proj_a WHERE NOT ST_IsValid(ST_GeomFromText(wkt, 4326));

INSERT INTO archive.asset (project_id, asset_type_id, source_id, name, status_code, operator, diameter_mm, geom)
SELECT p.project_id, t.asset_type_id, s.pipe_id, s.pipe_name,
       CASE s.status_fr WHEN 'en service' THEN 'installed' WHEN 'projet' THEN 'planned' ELSE 'abandoned' END,
       s.operator, s.diam_mm::int, ST_GeomFromText(s.wkt, 4326)
FROM (SELECT *, row_number() OVER (PARTITION BY pipe_id ORDER BY ctid) rn FROM staging.proj_a) s
JOIN archive.project p ON p.code = 'A'
JOIN ref.asset_type t ON t.code = 'PIPELINE'
WHERE s.rn = 1 AND ST_IsValid(ST_GeomFromText(s.wkt, 4326));

-- Projet B
INSERT INTO archive.asset (project_id, asset_type_id, source_id, name, status_code, operator, install_year, geom)
SELECT p.project_id, t.asset_type_id, s.cable_ref, s.nom,
       CASE s.etat WHEN 'ACTIVE' THEN 'installed' WHEN 'PLANNED' THEN 'planned' ELSE 'abandoned' END,
       s.proprietaire, s.annee_pose::int, ST_GeomFromText(s.geom_wkt, 4326)
FROM staging.proj_b s
JOIN archive.project p ON p.code = 'B'
JOIN ref.asset_type t ON t.code = 'CABLE';

-- Documents d'exemple liés à quelques ouvrages (table de liaison)
INSERT INTO archive.document (title, doc_type, uri) VALUES
  ('Plan as-built Nord', 'plan', 'archive/plans/nord.pdf'),
  ('Rapport inspection 2025', 'inspection', 'archive/insp/2025.pdf'),
  ('Rapport de pose Med', 'rapport', 'archive/rapports/med.pdf');
INSERT INTO archive.asset_document
SELECT a.asset_id, d.document_id FROM archive.asset a, archive.document d
WHERE (d.title = 'Plan as-built Nord' AND a.source_id IN ('PA-001','PA-002','PA-003'))
   OR (d.title = 'Rapport inspection 2025' AND a.source_id IN ('PA-001','CB01'))
   OR (d.title = 'Rapport de pose Med' AND a.source_id IN ('CB01','CB02'));
