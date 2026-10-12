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


DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_11 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_11 stored AS PARQUET AS

-- INT SUS PYG SUFI
WITH ULT_CONSOLIDADO_AJUSTES_IFRS AS (

SELECT

    proceso,
    tipo_cartera,
    fecha_hora_generacion,
    etl_generadora,
    aaaamm_ajuste,
    row_number()over (partition by proceso,tipo_cartera, etl_generadora
    order by fecha_hora_generacion  desc) as rn_cn
          
FROM {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1

    where
    proceso in ('Interes_Suspenso','Reversion_Castigos')
    and tipo_cartera='SUFI'
    and aaaamm_ajuste = CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) 
),

INT_SUS_SUFI AS (

SELECT

    T1.tipo_cartera as tipo_cartera,
    T1.tipo_prod as tipo_prod,
    T1.clasificacion as clasificacion,
    T1.aaaamm_ajuste as aaaamm_ajuste,
    T1.moneda as moneda,
    SUM(CAST(T1.VALOR_AJUSTE AS DECIMAL(18,2))) AS VALOR_AJUSTE_INT,
    SUM(CAST(T1.VALOR_AJUSTE_ME AS DECIMAL(18,2))) AS VALOR_AJUSTE_INT_ME    

    FROM {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1 T1
    INNER JOIN ULT_CONSOLIDADO_AJUSTES_IFRS T_ULT

    ON T1.fecha_hora_generacion = T_ULT.fecha_hora_generacion
    AND T1.etl_generadora = T_ULT.etl_generadora
    AND T1.PROCESO = T_ULT.proceso
    AND T1.TIPO_CARTERA = T_ULT.tipo_cartera
    AND T1.aaaamm_ajuste = T_ULT.aaaamm_ajuste
    AND year=year(now())
    AND month = month(now())
    WHERE 
    T_ULT.rn_cn = 1  
    AND T_ULT.PROCESO = 'Interes_Suspenso'
    
    GROUP BY T1.CLASIFICACION,T1.tipo_prod, T1.aaaamm_ajuste, T1.tipo_cartera, T1.moneda


),

CAS_SUFI AS (

SELECT

    T1.tipo_cartera as tipo_cartera,
    T1.tipo_prod as tipo_prod,
    T1.clasificacion as clasificacion,
    T1.aaaamm_ajuste as aaaamm_ajuste,
    T1.moneda as moneda,
    SUM(CAST(T1.VALOR_AJUSTE AS DECIMAL(18,2))) AS VALOR_AJUSTE_CAS,
    SUM(CAST(T1.VALOR_AJUSTE_ME AS DECIMAL(18,2))) AS VALOR_AJUSTE_CAS_ME    

    FROM {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1 T1
    INNER JOIN ULT_CONSOLIDADO_AJUSTES_IFRS T_ULT

    ON T1.fecha_hora_generacion = T_ULT.fecha_hora_generacion
    AND T1.etl_generadora = T_ULT.etl_generadora
    AND T1.PROCESO = T_ULT.proceso
    AND T1.TIPO_CARTERA = T_ULT.tipo_cartera
    AND T1.aaaamm_ajuste = T_ULT.aaaamm_ajuste
    AND year=year(now())
    AND month = month(now())
    
    WHERE 
    T_ULT.rn_cn = 1  
    AND T_ULT.PROCESO = 'Reversion_Castigos'  
    
    GROUP BY T1.CLASIFICACION,T1.tipo_prod, T1.aaaamm_ajuste, T1.tipo_cartera, T1.moneda
    
)

SELECT 

'Interes_Suspenso_PyG' AS proceso,
'SUFI' AS tipo_cartera,
COALESCE(CAST(INT_SUS_SUFI.TIPO_PROD AS STRING),'') AS tipo_prod,
'COP' AS moneda,
COALESCE(CAST(INT_SUS_SUFI.CLASIFICACION AS STRING),'') AS clasificacion,
CAST(COALESCE(CAS_SUFI.VALOR_AJUSTE_CAS,0) + COALESCE(INT_SUS_SUFI.VALOR_AJUSTE_INT,0) AS DECIMAL(15,2)) AS valor_ajuste,
CAST(COALESCE(CAS_SUFI.VALOR_AJUSTE_CAS_ME,0) + COALESCE(INT_SUS_SUFI.VALOR_AJUSTE_INT_ME,0) AS DECIMAL(15,2)) AS valor_ajuste_me,
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
"int_suspenso_sufi_pyg" AS etl_generadora, 
DAY(CURRENT_DATE()) AS day,
MONTH(CURRENT_DATE()) AS month,    
YEAR(CURRENT_DATE()) AS year

FROM INT_SUS_SUFI 
LEFT JOIN CAS_SUFI
ON INT_SUS_SUFI.tipo_cartera = CAS_SUFI.tipo_cartera
AND INT_SUS_SUFI.tipo_prod = CAS_SUFI.tipo_prod
AND INT_SUS_SUFI.clasificacion = CAS_SUFI.clasificacion
AND INT_SUS_SUFI.aaaamm_ajuste = CAS_SUFI.aaaamm_ajuste 
INNER JOIN proceso_vspc_serv.temp_Maestro_contable_ajuste_IFRS MAESTRO 
ON 'Interes_Suspenso_PyG' = MAESTRO.proceso
AND 'SUFI' = MAESTRO.tipo_cartera
AND 'COP' = MAESTRO.moneda
AND INT_SUS_SUFI.clasificacion = MAESTRO.clasificacion
AND INT_SUS_SUFI.TIPO_PROD = MAESTRO.tipo_prod

;

--------------------------------- Query End ---------------------------------