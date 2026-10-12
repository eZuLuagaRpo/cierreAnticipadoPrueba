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


DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_3 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_3 stored AS PARQUET AS

WITH T1 AS (

  SELECT

  'Reversion_Castigos' AS PROCESO,
  'BVL' AS TIPO_CARTERA,
  CAST(LHISD.num_oblig AS STRING) AS REF2,
  LHISD.f_trx AS F_TRX,
  LHISD.mnt_trx AS VALOR_AJUSTE,
  'COP' AS MONEDA_HOMOLOGA,
  'OBLIGACION' AS REF1,

  CASE 
      WHEN CAST(FCR_MAESTRO.COD_TIPO_OBLIG AS TINYINT) = 1 THEN "Consumo"
      WHEN CAST(FCR_MAESTRO.COD_TIPO_OBLIG AS TINYINT) = 2 THEN "Comercial"
      WHEN CAST(FCR_MAESTRO.COD_TIPO_OBLIG AS TINYINT) = 3 THEN "Vivienda"
      WHEN CAST(FCR_MAESTRO.COD_TIPO_OBLIG AS TINYINT) = 4 THEN "Microcredito"
  END AS CLASIFICACION,
  
  LHISD.cod_trx AS COD_TRX,
  LHISD.cod_orig_trx AS COD_ORIG_TRX,
  
  LHISD.year,
  LHISD.month,	
  LHISD.day	
  
  from resultados_fcr.fcr_bkv_detalle_trx_prestamos LHISD
  INNER JOIN resultados_fcr.fcr_bkv_maestro_prestamos FCR_MAESTRO 
  --INNER JOIN proceso_vspc_serv.fcr_bkv_maestro_prestamos_hist FCR_MAESTRO

  ON  cast(LHISD.num_oblig as bigint) = cast(FCR_MAESTRO.NUM_OBLIG as bigint)
  AND LHISD.num_redescuento = FCR_MAESTRO.NUM_REDESCUENTO
  WHERE  
  LHISD.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
  AND LHISD.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
  AND LHISD.day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)
  AND SUBSTRING(CAST(LHISD.f_trx AS STRING), 1, 6) = CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)
  AND LHISD.cod_orig_trx = 'CAS'
  AND LHISD.cod_trx = 1200
  AND FCR_MAESTRO.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
  AND FCR_MAESTRO.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
  AND FCR_MAESTRO.day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)
  ),
  
  MAESTRO AS (
    SELECT 
        proceso AS proceso_maestro,
        moneda AS moneda_homologa_maestro,	
        clasificacion AS clasificacion_maestro,	
        tipo_cartera AS tipo_de_cartera_maestro,	
        tipo_prod AS tipo_de_producto_maestro,	
        cal_cartera AS calificacion_maestro,	
        clase_doc AS clase_doc,	
        cuenta_partida,	
        cuenta_contrapartida
    FROM proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs
)

 SELECT 

    CAST(COALESCE(T1.PROCESO,'') AS STRING) AS proceso,
    CAST(COALESCE(T1.TIPO_CARTERA,'') AS STRING) AS tipo_cartera,
    '' AS tipo_prod,
    CAST(COALESCE(T1.MONEDA_HOMOLOGA,'') AS STRING) AS moneda,
    CAST(COALESCE(T1.CLASIFICACION,'') AS STRING) AS clasificacion,
    CAST(COALESCE(T1.VALOR_AJUSTE,0) AS DECIMAL(15,2)) AS valor_ajuste,
    CAST(0 AS DECIMAL(15,2)) valor_ajuste_me,
    '' AS cal_cartera,
    '' AS Sucursal,
    CAST(COALESCE(T1.REF1,'') AS STRING) AS ref1,
    CAST(COALESCE(T1.REF2,'') AS STRING) AS ref2,
    '' AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    CAST(COALESCE(MAESTRO.Cuenta_partida,'No asignada') AS STRING) AS cuenta_partida,
    CAST(COALESCE(MAESTRO.Cuenta_contrapartida,'No asignada') AS STRING) AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "castigos_bvl" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year
    
    FROM T1
    LEFT JOIN MAESTRO
    ON
    T1.PROCESO = MAESTRO.proceso_maestro
    AND T1.MONEDA_HOMOLOGA = MAESTRO.moneda_homologa_maestro
    AND T1.CLASIFICACION = MAESTRO.clasificacion_maestro
    AND T1.TIPO_CARTERA = MAESTRO.tipo_de_cartera_maestro  
;
--------------------------------- Query End ---------------------------------