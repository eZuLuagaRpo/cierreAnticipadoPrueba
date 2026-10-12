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


--------------------------------- resultados_vspc_serv.base_cuentas_reclasificacion_ifrs ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_1 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_1 stored AS PARQUET AS

SELECT
"resultados_vspc_serv.base_cuentas_reclasificacion_ifrs" as tabla,
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

from resultados_vspc_serv.base_cuentas_reclasificacion_ifrs
where 
ingestion_year >= 2024
;   	


--------------------------------- resultados_vspc_serv.maestro_contable_ajuste_ifrs ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_2 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_2 stored AS PARQUET AS

SELECT
"resultados_vspc_serv.maestro_contable_ajuste_ifrs" as tabla,
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

from resultados_vspc_serv.maestro_contable_ajuste_ifrs
where 
ingestion_year >= 2024
;
--------------------------------- resultados_vspc_serv.maestro_bin_clasif_ifrs ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_3 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_3 stored AS PARQUET AS

SELECT
"resultados_vspc_serv.maestro_bin_clasif_ifrs" as tabla,
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

from resultados_vspc_serv.maestro_bin_clasif_ifrs
where 
ingestion_year >= 2024
;

--------------------------------- resultados_vspc_serv.lista_plan_reest_castigos ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_4 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_4 stored AS PARQUET AS

SELECT
"resultados_vspc_serv.lista_plan_reest_castigos" as tabla,
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

from resultados_vspc_serv.lista_plan_reest_castigos
where 
ingestion_year >= 2024
;

--------------------------------- resultados_vspc_serv.maestro_eventos_reest_castigos ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_5 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_5 stored AS PARQUET AS

SELECT
"resultados_vspc_serv.maestro_eventos_reest_castigos" as tabla,
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

from resultados_vspc_serv.maestro_eventos_reest_castigos
where 
ingestion_year >= 2024

;

