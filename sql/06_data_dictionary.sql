-- 06 : dictionnaire de données généré depuis le catalogue (colonnes + commentaires)
COMMENT ON TABLE archive.asset IS 'Ouvrage sous-marin archivé (pipeline, câble...), tous projets confondus';
COMMENT ON COLUMN archive.asset.source_id IS 'Identifiant d''origine dans le projet source';
COMMENT ON COLUMN archive.asset.geom IS 'Tracé, WGS84 (EPSG:4326), géométrie valide obligatoire';
COMMENT ON TABLE archive.asset_document IS 'Table de liaison N-N ouvrages <-> documents';

\copy (SELECT c.table_schema, c.table_name, c.column_name, c.data_type, c.is_nullable, col_description((c.table_schema||'.'||c.table_name)::regclass, c.ordinal_position) AS description FROM information_schema.columns c WHERE c.table_schema IN ('ref','archive') ORDER BY 1,2,c.ordinal_position) TO 'docs/data_dictionary.csv' CSV HEADER
