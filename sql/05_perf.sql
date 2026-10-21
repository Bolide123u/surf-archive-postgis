-- 05 : effet de l'index spatial. On ajoute des données synthétiques pour que la différence se voie.
INSERT INTO archive.asset (project_id, asset_type_id, source_id, status_code, geom)
SELECT (SELECT project_id FROM archive.project WHERE code='A'),
       (SELECT asset_type_id FROM ref.asset_type WHERE code='PIPELINE'),
       'PERF-' || g, 'planned',
       ST_MakeLine(ST_MakePoint(x, y), ST_MakePoint(x + 0.2, y + 0.1))::geometry(LineString, 4326)
FROM (SELECT g, -10 + random()*50 AS x, 30 + random()*40 AS y FROM generate_series(1, 200000) g) t;
ANALYZE archive.asset;

\echo '--- AVEC index GIST'
EXPLAIN ANALYZE SELECT count(*) FROM archive.asset
WHERE geom && ST_MakeEnvelope(0, 52, 3, 55, 4326);

DROP INDEX archive.asset_geom_gix;
\echo '--- SANS index GIST'
EXPLAIN ANALYZE SELECT count(*) FROM archive.asset
WHERE geom && ST_MakeEnvelope(0, 52, 3, 55, 4326);

CREATE INDEX asset_geom_gix ON archive.asset USING GIST (geom);
DELETE FROM archive.asset WHERE source_id LIKE 'PERF-%';
