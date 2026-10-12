-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Entorno al Servicio de Funciones Corporativas
-----------------------------------------------------------------------------
-- Fecha Creación: 20240511
-- Última Fecha Modificación: 20240511
-- Autores: sanmolin 
-- Últimos Autores: sanmolin
-- Descripción: Extraccion de información contable de castigos de la tabla
-- RESULTADOS_FCR.FCR_BKV_DETALLE_TRANSACCIONES_PRESTAMOS

-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- RESULTADOS_FCR.FCR_BKV_DETALLE_TRANSACCIONES_PRESTAMOS
--------------------------------- RESULTADOS --------------------------------
-- S_APOYO_FINANCIERO.CONSOLIDADO_AJUSTE_IFRS
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

-- ESTO ES SOLO UNA CONSULTA DE MUESTRA, SE DEBEN COLOCAR TODAS LAS CONSULTAS
-- Y PARÁMETROS ASOCIADOS A LA RUTINA


--------------------------------- s_productos.su1_sufsdaas_siif08 ant	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_10 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_10 stored AS PARQUET AS

SELECT
"s_productos.su1_sufsdaas_siif08 anterior" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from s_productos.su1_sufsdaas_siif08
where 
ingestion_year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
AND ingestion_month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
and ingestion_day = 1

;  


--------------------------------- s_productos.su1_sufsdaas_siif08 act	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_11 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_11 stored AS PARQUET AS

SELECT
"s_productos.su1_sufsdaas_siif08 actual" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from s_productos.su1_sufsdaas_siif08
where 
ingestion_year = year(now())
and ingestion_month = month(now())
and ingestion_day = 1

;  


--------------------------------- s_productos.sufi_siif1_siil17 ant	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_12 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_12 stored AS PARQUET AS

SELECT
"s_productos.sufi_siif1_siil17 anterior" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from {zona_p}.temp_validacion_siil17_ant
;  


--------------------------------- s_productos.sufi_siif1_siil17 actual	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_13 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_13 stored AS PARQUET AS

SELECT
"s_productos.sufi_siif1_siil17 actual" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from {zona_p}.temp_validacion_siil17_act

;  

--------------------------------- s_productos.bvl_visionr_lltr	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_14 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_14 stored AS PARQUET AS

SELECT
"s_productos.bvl_visionr_lltr" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from s_productos.bvl_visionr_lltr
where 
year = year(now())
and ingestion_month = month(now())
and ingestion_day = 1

;  


	
	
	

