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

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_6 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_6 stored AS PARQUET AS

WITH consolidado AS (
  SELECT
    FCR.COD_TIPO_OBLIG AS MOD_CRED,
    FCR.TIPO_PLAN AS TIPO_PLAN,
    FCR.NUM_OBLIG AS REF2,
    CASE
      WHEN COALESCE(FCR.COD_MONEDA, '') = '' THEN 'COP'
      WHEN FCR.COD_MONEDA = '001' THEN 'USD'
    END AS COD_MONEDA
  FROM
    resultados_fcr.fcr_bkv_maestro_prestamos FCR
    --proceso_vspc_serv.fcr_bkv_maestro_prestamos_hist FCR
    INNER JOIN {zona_p}.temp_lista_plan_reest_castigos PLANES ON FCR.TIPO_PLAN = PLANES.plan
  WHERE
  FCR.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
  AND FCR.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
  AND FCR.day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)
    --AND (fcr.f_nota >= CAST({rees_bvl_aaaammdd1_mes_ant} AS INT) OR num_oblig IN (1260103415, 4800026954, 5980085514))
),

T AS (
SELECT
  CASE 
    WHEN consolidado.MOD_CRED = '1' THEN "Consumo"
    WHEN consolidado.MOD_CRED = '2' THEN "Comercial"
    WHEN consolidado.MOD_CRED = '3' THEN "Vivienda"
    WHEN consolidado.MOD_CRED = '4' THEN "Microcredito"
  END AS CLASIFICACION,
  consolidado.tipo_plan,
  consolidado.ref2,
  consolidado.cod_moneda as moneda,
  LLTR.LLRCTY AS LLRCTY,
  CAST(LLTR.LLNOGL AS STRING) AS LLNOGL,
  EVENTOS.evento AS EVENTO,
  'Castigados_reestructurados' as proceso,
  'BVL' AS tipo_cartera,
  SUM(LLTR.LLAMTR) AS VALOR_AJUSTE  
  FROM consolidado
  INNER JOIN s_productos.bvl_visionr_lltr LLTR
  ON consolidado.ref2 = LLTR.LLNOAC
  INNER JOIN {zona_p}.temp_maestro_eventos_reest_castigos EVENTOS
  ON LLTR.LLRCTY = EVENTOS.record AND CAST(LLTR.LLNOGL  AS STRING) = EVENTOS.gl
  WHERE
  LLTR.lldttr BETWEEN CAST(from_unixtime(unix_timestamp(add_months(trunc(now(), 'MM'), -1)), 'yyyyMMdd') AS int) and CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as int)
  and (((LLTR.ingestion_day BETWEEN 2 AND 31)  AND LLTR.ingestion_month = (month(now())-1) AND LLTR.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int))
        OR (LLTR.ingestion_day = 1 AND LLTR.ingestion_month = month(now()) AND LLTR.year = year(now())))   
  GROUP BY 1,2,3,4,5,6,7,8,9)

SELECT 
    CAST(coalesce(T.proceso,"") AS STRING) proceso,
    CAST(coalesce(T.tipo_cartera,"") AS STRING) AS tipo_cartera,
    CAST(coalesce(T.evento,"") AS STRING) AS tipo_prod,
    COALESCE(CAST(T.MONEDA AS STRING),'') AS moneda,
    COALESCE(CAST(T.CLASIFICACION AS STRING),'') AS clasificacion,
    CAST(coalesce(T.VALOR_AJUSTE,0) AS DECIMAL(15,2)) AS valor_ajuste,
    CAST(coalesce(T.VALOR_AJUSTE,0) AS DECIMAL(15,2)) AS valor_ajuste_me,
    '' AS cal_cartera,
    '' AS Sucursal,
    'OBLIGACION' AS ref1,
    CAST(coalesce(T.ref2,0) AS STRING) AS ref2,
    '' AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    COALESCE(CAST(MAESTRO.Cuenta_partida AS STRING),'No asignada') AS cuenta_partida,
    COALESCE(CAST(MAESTRO.Cuenta_contrapartida AS STRING),'No asignada') AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "castigos_reestructurados_bvl" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year

    FROM T
    LEFT JOIN proceso_vspc_serv.temp_maestro_contable_ajuste_ifrs MAESTRO
    ON T.PROCESO = MAESTRO.proceso
    AND T.evento = MAESTRO.tipo_prod
    AND T.MONEDA = MAESTRO.moneda
    AND T.clasificacion = MAESTRO.clasificacion
    AND T.TIPO_CARTERA = MAESTRO.tipo_cartera
;



--------------------------------- Query End ---------------------------------