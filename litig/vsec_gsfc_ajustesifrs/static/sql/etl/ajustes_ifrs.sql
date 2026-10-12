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

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_1 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_1 stored AS PARQUET AS
    
WITH FCR_T_FULL AS (
  SELECT
    T1.NRO_CUENTA_OPERATIVA AS REF2,
    T1.FECHA_CONTAB AS FECHA_CONTAB,
    T1.ACUM_ORIG AS ACUM_ORIG,
    T1.ACUM_LOC AS ACUM_LOC,
    
    row_number()over (partition by T1.mandante, T1.soc, 
        T1.nro_cuenta_operativa, T1.moneda_origen, T1.ejercicio, T1.fecha_contab, T1.segmento, T1.ledger, 
        T1.clase, BASE.proceso, BASE.moneda, BASE.clasificacion, BASE.tipo_cartera, BASE.tipo_prod,
        BASE.cal_cartera  order by T1.cronomarcador desc) as rn_cn,
        
    BASE.proceso, 
    BASE.moneda,
    BASE.clasificacion,
    BASE.tipo_cartera, 
    BASE.tipo_prod, 
    BASE.cal_cartera, 
    BASE.cuenta

    from RESULTADOS_FCR.fcr_sap_saldos_diarios_banco  T1
    
    inner join 
    proceso_vspc_serv.temp_base_cuentas_reclasificacion_IFRS BASE 
    on T1.NRO_CUENTA_OPERATIVA = BASE.CUENTA
    
    where
    T1.year IN (year(now()),year(now())-1)
    and T1.fecha_contab = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)
    and T1.ejercicio = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS STRING)
    and T1.soc = '1000'
    and T1.ledger = '0L'  
    -- and T1.cronomarcador < CAST(20250804000000 AS BIGINT) 
),
    
FCR_ANT_FULL AS (
  SELECT
    T1.NRO_CUENTA_OPERATIVA AS REF2,
    T1.FECHA_CONTAB AS FECHA_CONTAB,
    T1.ACUM_ORIG AS ACUM_ORIG,
    T1.ACUM_LOC AS ACUM_LOC,
    
    row_number()over (partition by T1.mandante, T1.soc, 
        T1.nro_cuenta_operativa, T1.moneda_origen, T1.ejercicio, T1.fecha_contab, T1.segmento, T1.ledger, 
        T1.clase, BASE.proceso, BASE.moneda, BASE.clasificacion, BASE.tipo_cartera, BASE.tipo_prod,
        BASE.cal_cartera  order by T1.cronomarcador desc) as rn_cn,
        
    BASE.proceso, 
    BASE.moneda,
    BASE.clasificacion,
    BASE.tipo_cartera, 
    BASE.tipo_prod, 
    BASE.cal_cartera, 
    BASE.cuenta

    from RESULTADOS_FCR.fcr_sap_saldos_diarios_banco as T1
    
    inner join 
    proceso_vspc_serv.temp_Base_cuentas_Reclasificacion_IFRS BASE 
    on T1.NRO_CUENTA_OPERATIVA = BASE.CUENTA
    
    where
    
    T1.year IN (year(now()),year(now())-1)
    and T1.fecha_contab = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -2))), 'yyyyMMdd') as STRING)
    and T1.ejercicio = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -2))), 'yyyy') as STRING)
    and T1.soc = '1000'
    and T1.ledger = '0L'
    
),

FCR_T AS (
    SELECT 
    PROCESO,
    REF2,
    MONEDA,
    CLASIFICACION,
    TIPO_CARTERA,
    TIPO_PROD,
    CAL_CARTERA,
    FECHA_CONTAB AS FECHA_CONTAB_T,
    SUM(ACUM_ORIG)  AS ACUM_ORIG_T,
    SUM(ACUM_LOC)  AS ACUM_LOC_T
    
    FROM FCR_T_FULL
    WHERE 
    rn_cn = 1 
    GROUP BY REF2, FECHA_CONTAB, MONEDA, PROCESO, CLASIFICACION, TIPO_CARTERA, TIPO_PROD, CAL_CARTERA
),

FCR_ANT AS (
    SELECT 
    PROCESO,
    REF2,
    MONEDA,
    CLASIFICACION,
    TIPO_CARTERA,
    TIPO_PROD,
    CAL_CARTERA,
    FECHA_CONTAB AS FECHA_CONTAB_ANT,
    SUM(ACUM_ORIG) AS ACUM_ORIG_ANT,
    SUM(ACUM_LOC) AS ACUM_LOC_ANT
    
    FROM FCR_ANT_FULL
    WHERE 
    rn_cn = 1 
    GROUP BY REF2, FECHA_CONTAB, MONEDA, PROCESO, CLASIFICACION, TIPO_CARTERA, TIPO_PROD, CAL_CARTERA
)

    SELECT

    CAST(COALESCE(FCR_T.PROCESO,'') AS STRING) AS proceso,
    CAST(COALESCE(FCR_T.TIPO_CARTERA,'') AS STRING) AS tipo_cartera,
    CAST(COALESCE(FCR_T.TIPO_PROD,'') AS STRING) AS tipo_prod,
    CAST(COALESCE(FCR_T.MONEDA,'') AS STRING) AS moneda,
    CAST(COALESCE(FCR_T.CLASIFICACION,'') AS STRING) AS clasificacion,

    CASE
      WHEN FCR_T.PROCESO = 'Interes_Suspenso' AND FCR_T.MONEDA = 'USD' AND FCR_T.TIPO_CARTERA = 'Medios de pago' THEN CAST(-1*(COALESCE(FCR_T.ACUM_ORIG_T,0) - COALESCE(FCR_ANT.ACUM_ORIG_ANT,0)) AS DECIMAL(15,2))
      ELSE CAST(-1*(COALESCE(FCR_T.ACUM_LOC_T,0) - COALESCE(FCR_ANT.ACUM_LOC_ANT,0)) AS DECIMAL(15,2))    END AS valor_ajuste,    
    
    CASE
      WHEN FCR_T.PROCESO = 'Interes_Suspenso' AND FCR_T.MONEDA = 'USD' AND FCR_T.TIPO_CARTERA = 'Medios de pago' THEN CAST(-1*(COALESCE(FCR_T.ACUM_ORIG_T,0) - COALESCE(FCR_ANT.ACUM_ORIG_ANT,0)) AS DECIMAL(15,2))
      ELSE CAST(-1*(COALESCE(FCR_T.ACUM_LOC_T,0) - COALESCE(FCR_ANT.ACUM_LOC_ANT,0)) AS DECIMAL(15,2))    END AS valor_ajuste_me,

    CAST(COALESCE(FCR_T.cal_cartera,'') AS STRING) AS cal_cartera,
    "" AS Sucursal,
    "CUENTA" AS ref1,
    CAST(COALESCE(FCR_T.REF2,'') AS STRING) AS ref2,
    "" AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    CAST(COALESCE(MAESTRO.cuenta_partida,'No asignada') AS STRING) AS cuenta_partida,
    CAST(COALESCE(MAESTRO.cuenta_contrapartida,'No asignada') AS STRING) AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)  AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "ajustes_ifrs" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year   
    
    FROM 
    FCR_T 

    LEFT JOIN FCR_ANT
    ON COALESCE(FCR_T.REF2,'') = COALESCE(FCR_ANT.REF2,'')
    AND COALESCE(FCR_T.MONEDA,'') = COALESCE(FCR_ANT.MONEDA,'')
    AND COALESCE(FCR_T.PROCESO,'') = COALESCE(FCR_ANT.PROCESO,'')
    AND COALESCE(FCR_T.CLASIFICACION,'') = COALESCE(FCR_ANT.CLASIFICACION,'')
    AND COALESCE(FCR_T.TIPO_CARTERA,'') = COALESCE(FCR_ANT.TIPO_CARTERA,'')
    AND COALESCE(FCR_T.TIPO_PROD,'') = COALESCE(FCR_ANT.TIPO_PROD,'')
    AND COALESCE(FCR_T.CAL_CARTERA,'') = COALESCE(FCR_ANT.CAL_CARTERA,'')

    INNER JOIN proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs MAESTRO
    ON COALESCE(FCR_T.MONEDA,'') = COALESCE(MAESTRO.moneda,'')
    AND COALESCE(FCR_T.PROCESO,'') = COALESCE(MAESTRO.proceso,'')
    AND COALESCE(FCR_T.CLASIFICACION,'') = COALESCE(MAESTRO.clasificacion,'')
    AND COALESCE(FCR_T.TIPO_CARTERA,'') = COALESCE(MAESTRO.tipo_cartera,'')
    AND COALESCE(FCR_T.TIPO_PROD,'') = COALESCE(MAESTRO.tipo_prod,'')
    AND COALESCE(FCR_T.CAL_CARTERA,'') = COALESCE(MAESTRO.cal_cartera,'')
;
--------------------------------- Query End ---------------------------------

