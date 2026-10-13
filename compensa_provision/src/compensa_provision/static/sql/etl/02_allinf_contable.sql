-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia Corporativa Grupo Bancolombia
-----------------------------------------------------------------------------
-- Fecha Creación: 20261013
-- Última Fecha Modificación: 20261013
-- Autores: emzulu
-- Últimos Autores: emzulu
-- Descripción: Extrae del maestro contable (ALLINF) las cuentas débito y
--              crédito de BankVision por código y concepto contable, de la
--              última ingestión disponible. La última ingestión la calcula
--              la tarea ultima_ingestion del orquestador a partir de la
--              llave ALLINF del diccionario tablas en static/config.json.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- {zona_s_apoyo_financiero}.ccsap_visionr_allinf
--------------------------------- RESULTADOS --------------------------------
-- {zona_p}.{indice}_allinf_contable
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_allinf_contable PURGE
;

CREATE TABLE {zona_p}.{indice}_allinf_contable STORED AS PARQUET AS
SELECT
  CAST(a.hatpgl AS STRING) AS codigo_contable,
  CAST(a.hatprc AS STRING) AS concepto_contable,
  CAST(a.hanoda AS STRING) AS bvl_cta_deb,
  CAST(a.hanoca AS STRING) AS bvl_cta_cre
FROM
  {zona_s_apoyo_financiero}.ccsap_visionr_allinf a
WHERE
  a.year = {ALLINF[year]}
  AND a.ingestion_month = {ALLINF[month]}
  AND a.ingestion_day = {ALLINF[day]}
;

COMPUTE INCREMENTAL STATS {zona_p}.{indice}_allinf_contable
;
--------------------------------- Query End ---------------------------------
