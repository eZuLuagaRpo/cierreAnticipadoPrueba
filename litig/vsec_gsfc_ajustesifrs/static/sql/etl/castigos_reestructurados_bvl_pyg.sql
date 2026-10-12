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
-- CASTIGADOS REESTRUCTURADOS BVL  

----PENDIENTE CREAR INSERT 
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_5 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_5 stored AS PARQUET AS

WITH T AS (
SELECT
    "Castigados_reestructurados_PyG" as proceso,
    tipo_cartera,
    tipo_prod,
    moneda,
    clasificacion,
    valor_ajuste,
    ref2    
  FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_6 CAI
  WHERE
    trim(CAI.proceso) = "Castigados_reestructurados"
    AND trim(CAI.tipo_prod) IN ("Pago_abono_interes_suspenso","Pago_abono_interes")
  )

SELECT 
    CAST(coalesce(T.proceso,"") AS STRING) proceso,
    CAST(coalesce(T.tipo_cartera,"") AS STRING) AS tipo_cartera,
    CAST(coalesce(T.tipo_prod,"") AS STRING) AS tipo_prod,
    COALESCE(CAST(T.MONEDA AS STRING),'') AS moneda,
    COALESCE(CAST(T.CLASIFICACION AS STRING),'') AS clasificacion,
    CAST(coalesce(T.VALOR_AJUSTE,0) AS DECIMAL(15,2)) AS valor_ajuste,
    CAST(coalesce(T.VALOR_AJUSTE,0) AS DECIMAL(15,2)) AS valor_ajuste_me,
    '' AS cal_cartera,
    '' AS Sucursal,
    'OBLIGACION' AS ref1,
    CAST(coalesce(T.ref2,"") AS STRING) AS ref2,
    '' AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    COALESCE(CAST(MAESTRO.Cuenta_partida AS STRING),'No asignada') AS cuenta_partida,
    COALESCE(CAST(MAESTRO.Cuenta_contrapartida AS STRING),'No asignada') AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "castigos_reestructurados_bvl_pyg" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year

    FROM T
    LEFT JOIN proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs MAESTRO
    ON T.PROCESO = MAESTRO.proceso
    AND T.tipo_prod = MAESTRO.tipo_prod
    AND T.MONEDA = MAESTRO.moneda
    AND T.clasificacion = MAESTRO.clasificacion
    AND T.TIPO_CARTERA = MAESTRO.tipo_cartera
;

--------------------------------- Query End ---------------------------------