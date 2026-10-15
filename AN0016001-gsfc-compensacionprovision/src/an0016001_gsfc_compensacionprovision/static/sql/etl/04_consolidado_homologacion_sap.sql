-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Equipo VSEC SERVICIOS CORPORATIVOS
-----------------------------------------------------------------------------
-- Fecha Creación: 20261013
-- Última Fecha Modificación: 20261014
-- Autores: emzulu
-- Últimos Autores: emzulu
-- Descripción: Cruza el consolidado de montos con el maestro contable para
--              obtener las cuentas débito y crédito de BankVision, y las
--              homologa a sus cuentas equivalentes en SAP-FI.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- {zona_procesamiento}.{indice}_ceautoedt_base
-- {zona_procesamiento}.{indice}_allinf_contable
-- {zona_procesamiento}.{indice}_peq_bvl_sap
--------------------------------- RESULTADOS --------------------------------
-- {zona_procesamiento}.{indice}_consolidado_homologacion_sap
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

DROP TABLE IF EXISTS {zona_procesamiento}.{indice}_consolidado_homologacion_sap PURGE
;

CREATE TABLE {zona_procesamiento}.{indice}_consolidado_homologacion_sap STORED AS PARQUET TBLPROPERTIES ('transactional'='false') AS
SELECT
  CAST(base.concepto_contable AS STRING) AS concepto_contable,
  CAST(base.codigo_contable AS STRING) AS codigo_contable,
  CAST(base.monto_trx AS DECIMAL(38, 2)) AS monto_trx,
  CAST(allinf.bvl_cta_deb AS STRING) AS bvl_cta_deb,
  CAST(peq_deb.valor_dato_destino AS STRING) AS sap_cta_deb,
  CAST(allinf.bvl_cta_cre AS STRING) AS bvl_cta_cre,
  CAST(peq_cre.valor_dato_destino AS STRING) AS sap_cta_cre,
  DAY(CURRENT_DATE()) AS DAY,
  MONTH(CURRENT_DATE()) AS MONTH,
  YEAR(CURRENT_DATE()) AS YEAR
FROM
  {zona_procesamiento}.{indice}_ceautoedt_base base
  LEFT JOIN {zona_procesamiento}.{indice}_allinf_contable allinf ON base.codigo_contable = allinf.codigo_contable
  AND base.concepto_contable = allinf.concepto_contable
  LEFT JOIN {zona_procesamiento}.{indice}_peq_bvl_sap peq_deb ON allinf.bvl_cta_deb = peq_deb.valor_dato_origen
  LEFT JOIN {zona_procesamiento}.{indice}_peq_bvl_sap peq_cre ON allinf.bvl_cta_cre = peq_cre.valor_dato_origen
;

COMPUTE INCREMENTAL STATS {zona_procesamiento}.{indice}_consolidado_homologacion_sap
;
--------------------------------- Query End ---------------------------------
