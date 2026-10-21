-- 03 : vues d'exploitation
CREATE OR REPLACE VIEW archive.v_asset_detail AS
SELECT a.asset_id, p.code AS project, t.label AS type, a.source_id, a.name,
       s.label AS status, a.operator, a.diameter_mm, a.install_year,
       round((ST_Length(a.geom::geography) / 1000)::numeric, 1) AS length_km, a.geom
FROM archive.asset a
JOIN archive.project p USING (project_id)
JOIN ref.asset_type t USING (asset_type_id)
JOIN ref.status s USING (status_code);

CREATE OR REPLACE VIEW archive.v_project_summary AS
SELECT project, type, status, count(*) AS n_assets, sum(length_km) AS total_km
FROM archive.v_asset_detail GROUP BY project, type, status ORDER BY project, type, status;
