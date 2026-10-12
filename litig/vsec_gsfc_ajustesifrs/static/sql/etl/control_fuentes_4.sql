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


--------------------------------- s_productos.sufi_sf7_siil01 ant	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_15 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_15 stored AS PARQUET AS

SELECT
"s_productos.sufi_sf7_siil01 anterior" as tabla,
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

from s_productos.sufi_sf7_siil01
where 
ingestion_year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
and ingestion_month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
and ingestion_day = 1
;

--------------------------------- s_productos.sufi_sf7_siil01 act	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_16 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_16 stored AS PARQUET AS

SELECT
"s_productos.sufi_sf7_siil01 actual" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from s_productos.sufi_sf7_siil01
where 
ingestion_year = year(now())
and ingestion_month = month(now())
and ingestion_day = 1
;  

--------------------------------- s_apoyo_corporativo.mdm_rdm_hub_pkg_tasas	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_17 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_17 stored AS PARQUET AS

SELECT
"s_apoyo_corporativo.mdm_rdm_hub_pkg_tasas" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from s_apoyo_corporativo.mdm_rdm_hub_pkg_tasas
where 
year = year(now()) 
and ingestion_month = month(now())
and ingestion_day= 1
; 

--------------------------------- s_apoyo_corporativo.mdm_rdm_hub_pkg_datos_referencia ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_18 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_18 stored AS PARQUET AS

SELECT
"s_apoyo_corporativo.mdm_rdm_hub_pkg_datos_referencia" as tabla,
count(*) as conteo,
CASE
  WHEN count(*)>0 THEN "OK"
  WHEN count(*)=0 THEN "ND"
END AS validacion,
CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) AS fecha_ajuste,
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year  

from s_apoyo_corporativo.mdm_rdm_hub_pkg_datos_referencia
where 
year = year(now())
and month = month(now()) 
and day = 1

;  


	

	
	