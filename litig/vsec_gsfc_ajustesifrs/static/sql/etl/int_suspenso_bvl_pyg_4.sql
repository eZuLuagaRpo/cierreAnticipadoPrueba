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


DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_9 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_9 stored AS PARQUET AS
-- INT SUS PYG BVL

SELECT 

    'Interes_Suspenso_PyG' AS proceso,
    'BVL' AS tipo_cartera,
    '' AS tipo_prod,
    COALESCE(CAST(AJUSTES_IFRS.MONEDA AS STRING),'') AS moneda,
    COALESCE(CAST(AJUSTES_IFRS.CLASIFICACION AS STRING),'') AS clasificacion,
    CAST(coalesce(AJUSTES_IFRS.VALOR_AJUSTE_INT,0) - coalesce(COND_BVL.VALOR_AJUSTE_COND,0) - coalesce(CAS_BVL.VALOR_AJUSTE_CAS,0) AS DECIMAL(15,2)) AS valor_ajuste,
    CAST(coalesce(AJUSTES_IFRS.VALOR_AJUSTE_INT_ME,0) - coalesce(COND_BVL.VALOR_AJUSTE_COND_ME,0) - coalesce(CAS_BVL.VALOR_AJUSTE_CAS_ME,0) AS DECIMAL(15,2)) AS valor_ajuste_me,
    '' AS cal_cartera,
    '' AS Sucursal,
    'RESULTADO' AS ref1,
    '' AS ref2,
    '' AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    COALESCE(CAST(MAESTRO.Cuenta_partida AS STRING),'No asignada') AS cuenta_partida,
    COALESCE(CAST(MAESTRO.Cuenta_contrapartida AS STRING),'No asignada') AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "int_suspenso_bvl_pyg" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year
    
    FROM proceso_vspc_serv.temp_ajustes_ifrs_int_sus_bvl_pyg AJUSTES_IFRS
    LEFT JOIN proceso_vspc_serv.temp_cond_int_sus_bvl_pyg COND_BVL
    ON AJUSTES_IFRS.TIPO_CARTERA = COND_BVL.TIPO_CARTERA
    AND AJUSTES_IFRS.CLASIFICACION = COND_BVL.CLASIFICACION
    AND AJUSTES_IFRS.aaaamm_ajuste = COND_BVL.aaaamm_ajuste 
    AND AJUSTES_IFRS.MONEDA = COND_BVL.MONEDA 
    LEFT JOIN proceso_vspc_serv.temp_castigos_int_sus_bvl_pyg CAS_BVL
    ON AJUSTES_IFRS.TIPO_CARTERA = CAS_BVL.TIPO_CARTERA
    AND AJUSTES_IFRS.CLASIFICACION = CAS_BVL.CLASIFICACION
    AND AJUSTES_IFRS.aaaamm_ajuste = CAS_BVL.aaaamm_ajuste 
    AND AJUSTES_IFRS.MONEDA = CAS_BVL.MONEDA
    INNER JOIN proceso_vspc_serv.temp_Maestro_contable_ajuste_IFRS MAESTRO 
    ON 'Interes_Suspenso_PyG' = MAESTRO.proceso
    AND 'BVL'= MAESTRO.tipo_cartera
    AND AJUSTES_IFRS.MONEDA = MAESTRO.moneda
    AND AJUSTES_IFRS.CLASIFICACION = MAESTRO.clasificacion
;



--------------------------------- Query End ---------------------------------