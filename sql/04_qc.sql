-- 04 : contrôles qualité, regroupés dans une vue unique
CREATE OR REPLACE VIEW qc.v_issues AS
SELECT 'asset sans document' AS check_name, a.source_id, p.code AS project
FROM archive.asset a JOIN archive.project p USING (project_id)
WHERE NOT EXISTS (SELECT 1 FROM archive.asset_document ad WHERE ad.asset_id = a.asset_id)
UNION ALL
SELECT 'projet sans ouvrage', p.code, p.code FROM archive.project p
WHERE NOT EXISTS (SELECT 1 FROM archive.asset a WHERE a.project_id = p.project_id)
UNION ALL
SELECT 'géométrie hors zone Europe (lon -30..45, lat 25..75)', a.source_id, p.code
FROM archive.asset a JOIN archive.project p USING (project_id)
WHERE NOT ST_Within(a.geom, ST_MakeEnvelope(-30, 25, 45, 75, 4326))
UNION ALL
SELECT 'rejeté au chargement: ' || reason, source_id, project FROM qc.rejected;

SELECT check_name, count(*) FROM qc.v_issues GROUP BY check_name ORDER BY 2 DESC;
