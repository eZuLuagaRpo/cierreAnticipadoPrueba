-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Cuenta las filas de la partición de hoy para compararlas con
--              lo extraído de la Nacional, y cuántas quedaron sin fecha
--              (fecha_efectiva vacía o inválida en el origen).
-------------------------------- Query Start --------------------------------
SELECT
    COUNT(*) AS filas_cargadas,
    SUM(CASE WHEN fecha_efectiva IS NULL THEN 1 ELSE 0 END) AS fechas_nulas
FROM {zona_r}.{tabla_resultado}
WHERE ingestion_year = YEAR(CURRENT_DATE())
  AND ingestion_month = MONTH(CURRENT_DATE())
  AND ingestion_day = DAY(CURRENT_DATE())
;
