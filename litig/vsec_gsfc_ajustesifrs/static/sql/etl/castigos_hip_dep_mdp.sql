-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Entorno al Servicio de Funciones Corporativas
-----------------------------------------------------------------------------
-- Fecha Creación: 20240511
-- Última Fecha Modificación: 20240511
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Extraccion de información contable de castigos de la tabla
-- RESULTADOS_FCR.FCR_BKV_CASTIGOS_ENDEUDAMIENTO
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- RESULTADOS_FCR.FCR_BKV_CASTIGOS_ENDEUDAMIENTO
--------------------------------- RESULTADOS --------------------------------
-- PROCESO.CONSOLIDADO_AJUSTE_IFRS
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

-- ESTO ES SOLO UNA CONSULTA DE MUESTRA, SE DEBEN COLOCAR TODAS LAS CONSULTAS
-- Y PARÁMETROS ASOCIADOS A LA RUTINA

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_4 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_4 stored AS PARQUET AS
-- Castigos consolidades 
WITH T1 AS (
    SELECT
        'Reversion_Castigos' AS Proceso,
        'OBLIGACION' AS REF1,
        year,
        month,
        day,
        CASE 
            WHEN Cod_Aplicacion = '4' THEN 'Hipotecario'
            WHEN Cod_Aplicacion = 'D' THEN 'Depositos'
            WHEN Cod_Aplicacion IN ('K', 'M', 'V') THEN 'Medios de pago'
            ELSE 'ND'
        END AS Tipo_cartera,
        CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(F_Inicio_Castigo AS STRING), 'yyyyMMdd') + 86400, 'yyyyMMdd') AS INT) AS F_TRX,
        --F_Inicio_Castigo AS F_TRX,
        Num_Producto AS REF2,
        CASE 
            WHEN Cod_Aplicacion IN ('K', 'M', 'V') THEN SUBSTRING(CAST(Num_Producto AS STRING), 1, 6) 
            ELSE 'ND'
        END AS BIN_CODE,
        CASE 
            WHEN Cod_Aplicacion = '4' THEN sld_inters_castig_incial
            WHEN Cod_Aplicacion IN ('D', 'K', 'M', 'V') THEN sld_int_cast_sin_causaci
            ELSE 0
        END AS VALOR_AJUSTE,
        CASE 
            WHEN LTRIM(RTRIM(Cod_moneda_DOLAR_PESO)) IN (NULL, '   ', '', '000') THEN 'COP'
            WHEN LTRIM(RTRIM(Cod_moneda_DOLAR_PESO)) = '001' THEN 'USD'
            ELSE 'ND'
        END AS MONEDA,
        tipo_deuda AS MOD_CREDITO,     
        Cod_Aplicacion,
        tipo_deuda
    FROM RESULTADOS_FCR.FCR_BKV_CASTIGOS_ENDEUDAMIENTO
    WHERE 
        year = {CASTIGOS[year]}
        AND month = {CASTIGOS[month]}
        AND day = {CASTIGOS[day]}
        AND Cod_Aplicacion IN ('4', 'D', 'K', 'M', 'V')        
        AND SUBSTRING(CAST(F_Inicio_Castigo AS STRING), 1, 6) = CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)

),

T_TEMP AS (
    SELECT
    T_CTAS.ctintrsusp,
    T_CTAS.cttarjeta
    FROM s_productos.TDC_TDCLIBRAMD_TDCFFCTASD T_CTAS
    INNER JOIN T1
    ON LPAD(CAST(T1.REF2 AS STRING), 19, '0') = LPAD(CAST(T_CTAS.cttarjeta AS STRING), 19, '0')
    AND SUBSTRING(CAST(T1.F_TRX AS STRING),1,4) = LPAD(CAST(T_CTAS.year AS STRING),4,'0')
    AND SUBSTRING(CAST(T1.F_TRX AS STRING),5,2) = LPAD(CAST(T_CTAS.month AS STRING),2,'0')
    AND SUBSTRING(CAST(T1.F_TRX AS STRING),7,2) = LPAD(CAST(T_CTAS.ingestion_day AS STRING),2,'0')
    WHERE 
    T_CTAS.year IN (year(now()), year(now()) - 1)
    AND T_CTAS.month IN (month(now()), month(now())-1)  
    AND T_CTAS.ctorganiza = 807
    ),

 T_CTAS_TEMP AS (
  SELECT
    ctorganiza,
    cttarjeta,
    YEAR,
    MONTH,
    ingestion_day
  FROM
    s_productos.TDC_TDCLIBRAMD_TDCFFCTASD
  WHERE
    YEAR IN (year(now()), year(now()) - 1)
    AND MONTH IN (month(now()), month(now())-1)  
),   

T3 AS (

    SELECT
        T1.Proceso,
        T1.REF1,
        T1.year,
        T1.month,
        T1.day,
        T1.Tipo_cartera,
        T1.F_TRX,
        T1.REF2,
        T1.BIN_CODE,
        
        CASE
          when T1.Tipo_cartera = 'Medios de pago' AND t1.VALOR_AJUSTE=0 then T1.VALOR_AJUSTE
          WHEN T1.Tipo_cartera = 'Medios de pago' AND T_CTAS.ctorganiza = 806 THEN T1.VALOR_AJUSTE - coalesce(T_TEMP.ctintrsusp,0)
          WHEN T1.Tipo_cartera = 'Medios de pago' AND T_CTAS.ctorganiza = 807 and t1.Cod_Aplicacion != 'V' THEN T_TEMP.ctintrsusp
          WHEN T1.Tipo_cartera = 'Medios de pago' AND t1.Cod_Aplicacion = 'V' THEN t1.VALOR_AJUSTE
          when T1.Tipo_cartera = 'Medios de pago' and T_CTAS.ctorganiza is NULL then t1.VALOR_AJUSTE
          WHEN T1.Tipo_cartera IN ('Hipotecario','Depositos') THEN T1.VALOR_AJUSTE
        END AS VALOR_AJUSTE,
        
        CASE
          WHEN T1.Tipo_cartera = 'Medios de pago' AND T_CTAS.ctorganiza = 806 THEN 'USD'
          WHEN T1.Tipo_cartera = 'Medios de pago' AND T_CTAS.ctorganiza = 807 THEN 'COP'
          WHEN T1.Tipo_cartera = 'Medios de pago' AND T_CTAS.ctorganiza IS NULL THEN T1.MONEDA
          WHEN T1.Tipo_cartera IN ('Hipotecario','Depositos') THEN T1.MONEDA
        END AS MONEDA,
        
        T1.tipo_deuda AS MOD_CREDITO,     
        T1.Cod_Aplicacion,
        T1.tipo_deuda,

        COALESCE(
            CASE
                WHEN T1.Cod_Aplicacion IN ('4', 'D') AND T1.tipo_deuda = '1' THEN 'Consumo'
                WHEN T1.Cod_Aplicacion IN ('4', 'D') AND T1.tipo_deuda = '2' THEN 'Comercial'
                WHEN T1.Cod_Aplicacion IN ('4', 'D') AND T1.tipo_deuda = '3' THEN 'Vivienda'
                WHEN T1.Cod_Aplicacion IN ('4', 'D') AND T1.tipo_deuda = '4' THEN 'Microcredito'
                WHEN T1.Cod_Aplicacion IN ('K', 'M', 'V') AND T2.CLASIFICACION = 'Empresarial' THEN 'Comercial'
                WHEN T1.Cod_Aplicacion IN ('K', 'M', 'V') AND T2.CLASIFICACION = 'Personal' THEN 'Consumo'
            END, 'ND'
        ) AS Clasificacion
        
    FROM T1
    LEFT JOIN proceso_vspc_serv.temp_maestro_bin_clasif_ifrs T2
      ON T1.BIN_CODE = T2.Bin_code
      AND T1.Tipo_cartera = 'Medios de pago'
    LEFT JOIN T_CTAS_TEMP T_CTAS
      ON LPAD(CAST(T1.REF2 AS STRING), 19, '0') = LPAD(CAST(T_CTAS.cttarjeta AS STRING), 19, '0')
      AND SUBSTRING(CAST(T1.F_TRX AS STRING),1,4) = LPAD(CAST(T_CTAS.year AS STRING),4,'0')
      AND SUBSTRING(CAST(T1.F_TRX AS STRING),5,2) = LPAD(CAST(T_CTAS.month AS STRING),2,'0')
      AND SUBSTRING(CAST(T1.F_TRX AS STRING),7,2) = LPAD(CAST(T_CTAS.ingestion_day AS STRING),2,'0')
      AND T1.Tipo_cartera = 'Medios de pago'
    LEFT JOIN T_TEMP
      ON LPAD(CAST(T1.REF2 AS STRING), 19, '0') = LPAD(CAST(T_TEMP.cttarjeta AS STRING), 19, '0')
      AND T1.Tipo_cartera = 'Medios de pago'   
)

SELECT 
    CAST(COALESCE(T3.PROCESO,'') AS STRING) AS proceso,
    CAST(COALESCE(T3.TIPO_CARTERA,'') AS STRING) AS tipo_cartera,
    '' AS tipo_prod,
    CAST(COALESCE(T3.MONEDA,'') AS STRING) AS moneda,
    CAST(COALESCE(T3.clasificacion,'') AS STRING) AS clasificacion,
    CAST(COALESCE(T3.valor_ajuste, 0) AS DECIMAL(15,2)) AS valor_ajuste,
    CAST(COALESCE(T3.valor_ajuste, 0) AS DECIMAL(15,2)) AS valor_ajuste_me,
    '' AS cal_cartera,
    '' AS Sucursal,
    CAST(COALESCE(CAST(T3.REF1 AS STRING),'') AS STRING) AS ref1,
    CAST(COALESCE(CAST(T3.REF2 AS STRING),'') AS STRING) AS ref2,
    '' AS ref3,
    CAST(COALESCE(T4.clase_doc,'') AS STRING) AS clase_doc,
    CAST(COALESCE(T4.cuenta_partida,'No asignada') AS STRING)  AS cuenta_partida,
    CAST(COALESCE(T4.cuenta_contrapartida,'No asignada') AS STRING) AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "castigos_hip_dep_mdp" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year 
    
    FROM T3
    LEFT JOIN proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs T4
    ON T3.PROCESO = T4.proceso
    AND T3.MONEDA = T4.moneda
    AND T3.clasificacion = T4.clasificacion
    AND T3.TIPO_CARTERA = T4.tipo_cartera
;
--------------------------------- Query End ---------------------------------