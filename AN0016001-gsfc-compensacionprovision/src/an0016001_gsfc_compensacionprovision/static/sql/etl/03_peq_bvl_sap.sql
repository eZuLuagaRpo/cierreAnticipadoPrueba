-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Equipo VSEC SERVICIOS CORPORATIVOS
-----------------------------------------------------------------------------
-- Fecha Creación: 20261013
-- Última Fecha Modificación: 20261014
-- Autores: emzulu
-- Últimos Autores: emzulu
-- Descripción: Obtiene las equivalencias únicas de cuentas de BankVision
--              (BVG) hacia SAP-FI, de la ingestión del día 1 del mes actual.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- {zona_s_productos}.peqc_pequiv_vw_cache_peq
--------------------------------- RESULTADOS --------------------------------
-- {zona_procesamiento}.{indice}_peq_bvl_sap
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

DROP TABLE IF EXISTS {zona_procesamiento}.{indice}_peq_bvl_sap PURGE
;

CREATE TABLE {zona_procesamiento}.{indice}_peq_bvl_sap STORED AS PARQUET TBLPROPERTIES ('transactional'='false') AS
SELECT
  CAST(valor_dato_origen AS STRING) AS valor_dato_origen,
  CAST(valor_dato_destino AS STRING) AS valor_dato_destino
FROM
  {zona_s_productos}.peqc_pequiv_vw_cache_peq
WHERE
  YEAR = YEAR(NOW())
  AND ingestion_month = MONTH(NOW())
  AND ingestion_day = 1
  AND codigo_aplicacion_origen = 'BVG'
  AND codigo_aplicacion_destino = 'SAP-FI'
GROUP BY
  CAST(valor_dato_origen AS STRING),
  CAST(valor_dato_destino AS STRING)
;

COMPUTE INCREMENTAL STATS {zona_procesamiento}.{indice}_peq_bvl_sap
;
--------------------------------- Query End ---------------------------------
