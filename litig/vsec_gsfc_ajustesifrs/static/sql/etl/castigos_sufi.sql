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


DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_7 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_7 stored AS PARQUET AS
    
-- CASTIGOS SUFI

WITH FCR_CAST AS (
    SELECT 
        Cod_Aplicacion AS COD_APLIC,
        F_Inicio_Castigo AS F_TRX,
        LPAD(CAST(Num_Producto AS STRING), 17, '0') AS REF2,
        year,
        month

    FROM RESULTADOS_FCR.FCR_BKV_CASTIGOS_ENDEUDAMIENTO
    WHERE 
        Cod_Aplicacion = '7' 
        AND SUBSTRING(CAST(F_Inicio_Castigo AS STRING), 1, 6) = CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)
        AND year = year(now())
        AND month = month(now())
        AND day = 2
    ),     
    
    SIIL01 AS (
    SELECT
        L01NPR AS REF2,
        L01NPO AS NUM_PROD,
        
        CASE
          WHEN L01MON = 0 THEN 'COP'
          ELSE 'ND'
        END AS COD_MONEDA,

        L01AGE AS SUCURSAL,

        year,
        ingestion_month
    FROM s_productos.sufi_sf7_siil01
    WHERE 
        ingestion_day = 1
        AND year = year(now())
        AND ingestion_month = month(now())
    ),
    
    SIIF08 AS (
      SELECT
        S08NTR AS NUM_PROD,
        CASE
          WHEN S08ICC = 'C' THEN 'Comercial'
          WHEN S08ICC = 'P' THEN 'Consumo'
        END AS CLASIFICACION,
        CASE
          WHEN S08TPD  = 6 THEN 'Leasing'
          WHEN S08TPD <> 6 THEN 'Ordinario'
        END AS TIPO_PROD
            
        FROM s_productos.SU1_SUFSDAAS_SIIF08
        WHERE 
            S08GRU = 5
            AND ingestion_day = 1
            AND year = year(now())
            AND ingestion_month = month(now())
    ),


    SIIL17 AS (
        SELECT
            L17NPR AS REF2,
            sum(l17ICC) AS INT_CORR_CAU,
            sum(l17ICP) AS INT_CORR_PAG,
            year,
            month,
            day
        FROM s_productos.sufi_siif1_siil17 T
        INNER JOIN {zona_p}.temp_fechas_no_hab_siil17_ant DIA_SIIL17
        ON T.day = DIA_SIIL17.dia
        WHERE 
            L17EST >= 3
            --AND day = 1--{castigos_sufi_d1_ant}
            AND year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
            AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        GROUP BY L17NPR, year,month,day

        
    ),
    
    MAESTRO AS (
        SELECT 

        proceso,
        moneda,
        clasificacion,
        tipo_cartera,
        clase_doc,
        tipo_prod,
        cal_cartera,
        cuenta_partida,
        cuenta_contrapartida

        from  proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs
    ),
        
    
    T1 AS (
        SELECT 
        
            'Reversion_Castigos' AS PROCESO,
            'SUFI' as TIPO_CARTERA,
            'OBLIGACION' as REF1,
            SIIF08.TIPO_PROD,
            SIIF08.CLASIFICACION,
            FCR_CAST.REF2,
            FCR_CAST.F_TRX,
            FCR_CAST.COD_APLIC,
            FCR_CAST.year as YEAR_FCR,
            FCR_CAST.month as MONTH_FCR,
            SIIL01.NUM_PROD,
            SIIL01.COD_MONEDA AS MONEDA_HOMOLOGADA,
            SIIL01.SUCURSAL,
            SIIL01.year as YEAR_SIIL01,
            SIIL01.ingestion_month  as MONTH_SIIL01
          
        FROM SIIL01 
        INNER JOIN FCR_CAST
        ON SIIL01.REF2 = FCR_CAST.REF2
        INNER JOIN SIIF08 
        ON SIIL01.NUM_PROD = SIIF08.NUM_PROD
    ),

    T2 AS (
        SELECT 
            
            T1.REF2,
            T1.F_TRX,
            T1.COD_APLIC,
            T1.YEAR_FCR,
            T1.MONTH_FCR,
            T1.NUM_PROD,
            T1.MONEDA_HOMOLOGADA,
            T1.YEAR_SIIL01,
            T1.MONTH_SIIL01,
            T1.TIPO_CARTERA,
            T1.PROCESO,
            T1.CLASIFICACION,
            T1.TIPO_PROD,
            T1.REF1,
            T1.SUCURSAL,
            SIIL17.INT_CORR_CAU,
            SIIL17.INT_CORR_PAG,
            SIIL17.INT_CORR_CAU - SIIL17.INT_CORR_PAG AS VALOR_AJUSTE,
            SIIL17.year AS YEAR_SIIL17,
            SIIL17.month AS MONTH_SIIL17,
            SIIL17.day AS DAY_SIIL17
        FROM 
            T1
        INNER JOIN 
            SIIL17 ON T1.REF2 = SIIL17.REF2
    )
    

    SELECT
      CAST(COALESCE(T2.PROCESO,'') AS STRING) AS proceso,
      CAST(COALESCE(T2.TIPO_CARTERA,'') AS STRING) AS tipo_cartera,
      CAST(COALESCE(T2.TIPO_PROD,'') AS STRING) AS tipo_prod,
      CAST(COALESCE(T2.MONEDA_HOMOLOGADA,'') AS STRING) AS moneda,
      CAST(COALESCE(T2.CLASIFICACION,'') AS STRING) AS clasificacion,
      CAST(T2.VALOR_AJUSTE AS DECIMAL(15,2)) AS valor_ajuste,
      0 AS valor_ajuste_me,
      '' AS cal_cartera,
      COALESCE(CAST(T2.SUCURSAL AS STRING),'') AS Sucursal,
      COALESCE(CAST(T2.REF1 AS STRING),'') AS ref1,
      COALESCE(CAST(T2.REF2 AS STRING),'') AS ref2,
      '' AS ref3,
      CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
      CAST(COALESCE(MAESTRO.cuenta_partida,'No asignada') AS STRING)  AS cuenta_partida,
      CAST(COALESCE(MAESTRO.cuenta_contrapartida,'No asignada') AS STRING) AS cuenta_contrapartida,
      CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
      CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
      CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
      CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
      "castigos_sufi" AS etl_generadora, 
      DAY(CURRENT_DATE()) AS day,
      MONTH(CURRENT_DATE()) AS month,    
      YEAR(CURRENT_DATE()) AS year
      
      FROM T2
      INNER JOIN MAESTRO 
          ON T2.PROCESO = MAESTRO.proceso
          AND T2.TIPO_CARTERA = MAESTRO.tipo_cartera
          AND T2.MONEDA_HOMOLOGADA = MAESTRO.moneda 
          AND T2.CLASIFICACION = MAESTRO.clasificacion
          AND T2.TIPO_PROD = MAESTRO.tipo_prod
;
--------------------------------- Query End ---------------------------------