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


DROP TABLE IF EXISTS {zona_p}.temp_mora_balance_sufi_ant PURGE;
CREATE TABLE {zona_p}.temp_mora_balance_sufi_ant STORED AS PARQUET AS

WITH SIIL01_ANT AS (
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
        ingestion_month
    FROM s_productos.SUFI_SF7_SIIL01
    WHERE 
        year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
        AND ingestion_month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        AND ingestion_day = 1
        AND L01VSA > 0  
),

SIIF08_ANT AS (
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
        year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
        AND ingestion_month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        AND ingestion_day = 1
        AND S08GRU <> 5 
),

SIIL17_ANT AS (
    SELECT
        L17NPR AS REF2,
        SUM(L17IMP) AS INT_MORA_PAG,
        SUM(L17IMU) AS INT_MORA_POS,
        SUM(L17IMU - L17IMP) AS INT_MORA_BAL,
        year,
        month,
        day
    FROM s_productos.SUFI_SIIF1_SIIL17 T
    INNER JOIN {zona_p}.temp_fechas_no_hab_siil17_ant DIA_SIIL17
        ON T.day = DIA_SIIL17.dia
    WHERE 
        year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
        --AND day = 1--{mora_balance_sufi_d1_ant}
        AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        AND L17EST < 3
    GROUP BY 
        L17NPR, year, month, day
)

SELECT 
    SIIL01_ANT.REF2,
    SIIL01_ANT.NUM_PROD,
    SIIL01_ANT.COD_MONEDA,
    SIIL01_ANT.SALD_PRESTAMO,
    SIIL01_ANT.SUCURSAL,
    SIIL01_ANT.CAL_CARTERA,
    SIIL17_ANT.INT_MORA_PAG,
    SIIL17_ANT.INT_MORA_POS,
    SIIL17_ANT.INT_MORA_BAL,
    SIIF08_ANT.ESTADO_CRED,
    SIIF08_ANT.MOD_CRED,
    SIIF08_ANT.TIPO_PROD
    
FROM 
    SIIL01_ANT 
INNER JOIN 
    SIIL17_ANT ON SIIL01_ANT.REF2 = SIIL17_ANT.REF2
INNER JOIN 
    SIIF08_ANT ON SIIL01_ANT.NUM_PROD = SIIF08_ANT.NUM_PROD

;
