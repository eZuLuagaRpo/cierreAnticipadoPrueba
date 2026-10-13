-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia Corporativa Grupo Bancolombia
-----------------------------------------------------------------------------
-- Fecha Creación: 20261013
-- Última Fecha Modificación: 20261013
-- Autores: emzulu
-- Últimos Autores: emzulu
-- Descripción: Consolida el monto de las transacciones del mes actual de
--              VISIONR.CEAUTOEDT por concepto y código contable.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- {zona_ceautoedt}.visionr_ceautoedt
--------------------------------- RESULTADOS --------------------------------
-- {zona_p}.{indice}_ceautoedt_base
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_ceautoedt_base PURGE
;

CREATE TABLE {zona_p}.{indice}_ceautoedt_base STORED AS PARQUET AS
SELECT
  CAST(concepto_contable AS STRING) AS concepto_contable,
  CAST(codigo_contable AS STRING) AS codigo_contable,
  CAST(SUM(monto_trx) AS DECIMAL(38, 2)) AS monto_trx
FROM
  {zona_ceautoedt}.visionr_ceautoedt
WHERE
  ingestion_year = YEAR(NOW())
  AND ingestion_month = MONTH(NOW())
GROUP BY
  CAST(concepto_contable AS STRING),
  CAST(codigo_contable AS STRING)
;

COMPUTE INCREMENTAL STATS {zona_p}.{indice}_ceautoedt_base
;
--------------------------------- Query End ---------------------------------
