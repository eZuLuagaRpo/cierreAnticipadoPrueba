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


--------------------------------- resultados_fcr.fcr_sap_saldos_diarios_banco	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_55 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_55 stored AS PARQUET AS

SELECT
"resultados_fcr.fcr_sap_saldos_diarios_banco" as tabla,
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

from resultados_fcr.fcr_sap_saldos_diarios_banco	
where 
year={SALDOS_DIARIOS[year]}
and month={SALDOS_DIARIOS[month]}
and day={SALDOS_DIARIOS[day]}

;   	

--------------------------------- s_productos.tdc_tdclibramd_tdcffctasd	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_6 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_6 stored AS PARQUET AS

SELECT
"s_productos.tdc_tdclibramd_tdcffctasd" as tabla,
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

from s_productos.tdc_tdclibramd_tdcffctasd
where 
(year = year(now()) and month = month(now())) 
or (year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int) 
and month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int))

;   	

--------------------------------- resultados_fcr.fcr_bkv_castigos_endeudamiento	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_7 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_7 stored AS PARQUET AS

SELECT
"resultados_fcr.fcr_bkv_castigos_endeudamiento" as tabla,
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

from resultados_fcr.fcr_bkv_castigos_endeudamiento
where 
year = {CASTIGOS[year]} 
and month = {CASTIGOS[month]} 
and day= {CASTIGOS[day]}
;   	
--------------------------------- resultados_fcr.fcr_bkv_historico_trx_prestamos	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_8 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_8 stored AS PARQUET AS

SELECT
"resultados_fcr.fcr_bkv_historico_trx_prestamos" as tabla,
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

from resultados_fcr.fcr_bkv_historico_trx_prestamos
where 
year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
AND day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)

;   	


--------------------------------- resultados_fcr.fcr_bkv_maestro_prestamos	 ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_9 PURGE;
CREATE TABLE {zona_p}.{indice}_control_fuentes_ajustesifrs_9 stored AS PARQUET AS

SELECT
"resultados_fcr.fcr_bkv_maestro_prestamos" as tabla,
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

from resultados_fcr.fcr_bkv_maestro_prestamos
where 
year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
AND day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)
;   
	
	
  	
