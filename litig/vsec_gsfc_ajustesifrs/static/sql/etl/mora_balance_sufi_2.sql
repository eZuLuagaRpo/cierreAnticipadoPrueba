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


DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_12 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_12 stored AS PARQUET AS

WITH SIIL01_T AS (
    SELECT
        L01NPR AS REF2,
        L01NPO AS NUM_PROD,
        
        CASE
          WHEN L01MON = 0 THEN 'COP'
          ELSE NULL
        END AS COD_MONEDA,

        L01VSA AS SALD_PRESTAMO,
        L01AGE AS SUCURSAL,
        NULLIF(TRIM(L01CCA), '') AS CAL_CARTERA,
        year,
        ingestion_month,
        ingestion_day
    FROM s_productos.SUFI_SF7_SIIL01
    WHERE 
        year = year(now())
        AND ingestion_month = month(now())
        AND ingestion_day = 1
        AND L01VSA > 0 
),

SIIF08_T AS (
    SELECT
        S08NTR AS NUM_PROD,
        S08GRU AS ESTADO_CRED,
        CASE 
            WHEN S08ICC = 'C' THEN 'Comercial'
            WHEN S08ICC = 'P' THEN 'Consumo'
        END AS MOD_CRED,
        CASE 
            WHEN S08TPD = 6 THEN 'Leasing' 
            ELSE 'Ordinario'
        END AS TIPO_PROD,
        year,
        ingestion_month,
        ingestion_day
    FROM s_productos.SU1_SUFSDAAS_SIIF08
    WHERE 
        
        year = year(now())  
        AND ingestion_month = month(now())
        AND ingestion_day = 1
        AND S08GRU <> 5
),

SIIL17_T AS (
    SELECT
        L17NPR AS REF2,
        SUM(L17IMP) AS INT_MORA_PAG,
        SUM(L17IMU) AS INT_MORA_POS,
        SUM(L17IMU - L17IMP) AS INT_MORA_BAL,
        year,
        month,
        day
    FROM s_productos.SUFI_SIIF1_SIIL17 T
    INNER JOIN {zona_p}.temp_fechas_no_hab_siil17_act DIA_SIIL17
        ON T.day = DIA_SIIL17.dia
    WHERE 
        year = year(now())
        --AND day = 1--{mora_balance_sufi_d1_act}
        AND month = month(now())
        AND L17EST < 3
    GROUP BY 
        L17NPR, year, month, day
),

T2_T AS (
    SELECT 
        SIIL01_T.REF2,
        SIIL01_T.NUM_PROD,
        SIIL01_T.COD_MONEDA,
        SIIL01_T.SALD_PRESTAMO,
        SIIL01_T.SUCURSAL,
        SIIL01_T.CAL_CARTERA,
        SIIL17_T.INT_MORA_PAG,
        SIIL17_T.INT_MORA_POS,
        SIIL17_T.INT_MORA_BAL,
        SIIF08_T.ESTADO_CRED,
        SIIF08_T.MOD_CRED,
        SIIF08_T.TIPO_PROD

    FROM 
        SIIL01_T 
    INNER JOIN 
        SIIL17_T ON SIIL01_T.REF2 = SIIL17_T.REF2
    INNER JOIN 
        SIIF08_T ON SIIL01_T.NUM_PROD = SIIF08_T.NUM_PROD
 )

SELECT
      
    'Mora_Balance' AS proceso,
    'SUFI' AS tipo_cartera,
    COALESCE(CAST(T2_T.TIPO_PROD AS STRING), CAST(T2_ANT.TIPO_PROD AS STRING), '') AS tipo_prod,
    COALESCE(CAST(T2_T.COD_MONEDA AS STRING), CAST(T2_ANT.COD_MONEDA AS STRING), '') AS moneda,
    COALESCE(CAST(T2_T.MOD_CRED AS STRING), CAST(T2_ANT.MOD_CRED AS STRING), '') AS clasificacion,
    CAST(COALESCE(COALESCE(T2_T.INT_MORA_BAL, 0) - COALESCE(T2_ANT.INT_MORA_BAL, 0)) AS DECIMAL(15,2))  AS valor_ajuste,
    0 AS valor_ajuste_me,
    COALESCE(CAST(T2_T.CAL_CARTERA AS STRING), CAST(T2_ANT.CAL_CARTERA AS STRING),'A') AS cal_cartera,
    COALESCE(CAST(T2_T.SUCURSAL AS STRING), CAST(T2_ANT.SUCURSAL AS STRING),'') AS sucursal,
    'OBLIGACION' AS ref1,
    COALESCE(CAST(T2_T.REF2 AS STRING), CAST(T2_ANT.REF2 AS STRING),'') AS ref2,
    COALESCE(CAST(T2_T.REF2 AS STRING), CAST(T2_ANT.REF2 AS STRING),'') AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    COALESCE(CAST(MAESTRO.CUENTA_PARTIDA AS STRING),'No asignada') AS cuenta_partida,
    COALESCE(CAST(MAESTRO.CUENTA_CONTRAPARTIDA AS STRING),'No asignada') AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "mora_balance_sufi_2" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year
    
FROM
    T2_T
FULL OUTER JOIN proceso_vspc_serv.temp_mora_balance_sufi_ant T2_ANT 
    ON T2_T.REF2 = T2_ANT.REF2
    AND T2_T.TIPO_PROD = T2_ANT.TIPO_PROD
    AND T2_T.CAL_CARTERA = T2_ANT.CAL_CARTERA
    AND T2_T.MOD_CRED = T2_ANT.MOD_CRED
INNER JOIN proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs MAESTRO 
    ON 'Mora_Balance' = MAESTRO.PROCESO
    AND 'SUFI' = MAESTRO.tipo_cartera
    AND COALESCE(T2_T.COD_MONEDA, T2_ANT.COD_MONEDA,'') = COALESCE(MAESTRO.moneda,'') 
    AND COALESCE(T2_T.MOD_CRED, T2_ANT.MOD_CRED,'') = COALESCE(MAESTRO.CLASIFICACION,'')
    AND COALESCE(T2_T.TIPO_PROD, T2_ANT.TIPO_PROD,'') = COALESCE(MAESTRO.tipo_prod,'')
    --AND COALESCE(T2_T.CAL_CARTERA, T2_ANT.CAL_CARTERA,'A') = COALESCE(MAESTRO.cal_cartera,'')

;
