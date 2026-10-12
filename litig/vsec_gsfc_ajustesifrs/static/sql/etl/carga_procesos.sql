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


--CREATE TABLE {zona_r}.consolidado_ajuste_ifrs
--PARTITIONED by (year)
--STORED AS PARQUET TBLPROPERTIES ('transactional'='false') AS

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_2 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_2 stored AS PARQUET AS

WITH 

CARGA AS (
    SELECT 
        T1.proceso, 
        T1.tipo_cartera, 
        T1.moneda, 
        T1.clasificacion, 
        T1.valor_ajuste AS valor_ajuste, 
        T1.valor_ajuste AS valor_ajuste_me
    FROM proceso_vspc_serv.carga_procesos_ajustes_ifrs T1
    UNION ALL
    SELECT 
        T2.proceso_afectacion as proceso, 
        T2.tipo_cartera, 
        T2.moneda, 
        T2.clasificacion, 
        -1*CAST(T2.valor_ajuste AS DECIMAL(15,2)) AS valor_ajuste, 
        -1*CAST(T2.valor_ajuste AS DECIMAL(15,2)) AS valor_ajuste_me
    FROM proceso_vspc_serv.carga_procesos_ajustes_ifrs T2
)

SELECT

    CAST(COALESCE(CARGA.proceso,'') AS STRING) AS proceso,
    CAST(COALESCE(CARGA.tipo_cartera,'') AS STRING) AS tipo_cartera,
    "" AS tipo_prod,
    CAST(COALESCE(CARGA.moneda,'') AS STRING) AS moneda,
    CAST(COALESCE(CARGA.clasificacion,'') AS STRING) AS clasificacion,
    CAST(COALESCE(CARGA.valor_ajuste,0) AS DECIMAL(15,2)) AS valor_ajuste,
    CAST(COALESCE(CARGA.valor_ajuste_me,0) AS DECIMAL(15,2)) AS valor_ajuste_me,
    "" AS cal_cartera,
    "" AS Sucursal,
    "CARGA AJUSTE" AS ref1,
    "" AS ref2,
    "" AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    CAST(COALESCE(MAESTRO.cuenta_partida,'No asignada') AS STRING) AS cuenta_partida,
    CAST(COALESCE(MAESTRO.cuenta_contrapartida,'No asignada') AS STRING) AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "carga_procesos" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year

    FROM CARGA
    INNER JOIN proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs MAESTRO
    ON COALESCE(CARGA.MONEDA,'') = COALESCE(MAESTRO.moneda,'')
    AND COALESCE(CARGA.PROCESO,'') = COALESCE(MAESTRO.proceso,'')
    AND COALESCE(CARGA.CLASIFICACION,'') = COALESCE(MAESTRO.clasificacion,'')
    AND COALESCE(CARGA.tipo_cartera) = COALESCE(MAESTRO.tipo_cartera,'')

;

------------------------- Query End---------------------------------
