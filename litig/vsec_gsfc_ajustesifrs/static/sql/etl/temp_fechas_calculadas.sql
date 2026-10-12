-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Entorno al Servicio de Funciones Corporativas
-----------------------------------------------------------------------------
-- Fecha Creación: 20240511
-- Última Fecha Modificación: 20240511
-- Autores: jgranda
-- Últimos Autores: jgranda
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

DROP TABLE IF EXISTS {zona_p}.temp_fechas_no_hab_siil17_act PURGE;
CREATE TABLE {zona_p}.temp_fechas_no_hab_siil17_act stored AS PARQUET AS
    
-- CALCULO FECHAS INGESTION SUFI SIIL17

WITH dias_todos(dia) AS (
VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
       (11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
       (21), (22), (23), (24), (25), (26), (27), (28), (29), (30) 
),
       
NO_HAB AS (
select 
    CAST(SUBSTRING(valor_dato_referencia,9,2) AS INT) as dia_no_hab
from s_apoyo_corporativo.mdm_rdm_hub_pkg_datos_referencia
WHERE 
categoria = "CALENDARIO"
and tipo_dato_referencia LIKE "%DIAS_NO_HABILES%"
and descripcion_corta = CAST(year(now()) AS STRING)
and descripcion_larga = LPAD(CAST(month(now())AS STRING), 2, '0') 
and year = year(now())
and month = month(now())
and day = 1
)


SELECT 
    dia 
FROM dias_todos
LEFT join NO_HAB
on dia_no_hab = dia
WHERE (dia_no_hab is null)
ORDER BY dia
limit 1
;
--------------------------------- Query End ---------------------------------

DROP TABLE IF EXISTS {zona_p}.temp_fechas_no_hab_siil17_ant PURGE;
CREATE TABLE {zona_p}.temp_fechas_no_hab_siil17_ant stored AS PARQUET AS
    
-- CALCULO FECHAS INGESTION SUFI SIIL17

WITH dias_todos(dia) AS (
VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
       (11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
       (21), (22), (23), (24), (25), (26), (27), (28), (29), (30) 
),
       
NO_HAB AS (
select 
    CAST(SUBSTRING(valor_dato_referencia,9,2) AS INT) as dia_no_hab
from s_apoyo_corporativo.mdm_rdm_hub_pkg_datos_referencia
WHERE 
categoria = "CALENDARIO"
and tipo_dato_referencia LIKE "%DIAS_NO_HABILES%"
and descripcion_corta = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS STRING)
and descripcion_larga = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS STRING)
and year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
and month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
and day = 1
)

SELECT 
    dia 
FROM dias_todos
LEFT join NO_HAB
on dia_no_hab = dia
WHERE (dia_no_hab is null)
ORDER BY dia
limit 1
;