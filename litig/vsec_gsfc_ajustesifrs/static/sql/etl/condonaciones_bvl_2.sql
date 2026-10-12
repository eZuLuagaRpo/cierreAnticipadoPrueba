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


DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_8 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_8 stored AS PARQUET AS
-- CONDONACIONES BVL

WITH 
    
  T2 AS (
  
  SELECT
    
    'Reversion_Condonaciones' AS PROCESO,
    'OBLIGACION' AS REF1,
    T1.REF2 AS REF2,
    'BVL' AS TIPO_CARTERA,
    
    CASE 
      WHEN T1.MOD_CRED = '1' THEN "Consumo"
      WHEN T1.MOD_CRED = '2' THEN "Comercial"
      WHEN T1.MOD_CRED = '3' THEN "Vivienda"
      WHEN T1.MOD_CRED = '4' THEN "Microcredito"
    END AS CLASIFICACION,
    
    CASE 
      WHEN T1.COD_REVERS_REAPLIC = 'R' THEN T1.VALOR_AJUSTE*-1
      ELSE T1.VALOR_AJUSTE
    END AS VALOR_AJUSTE,
    
     T1.NUM_REDESCUENTO,
     T1.F_TRX,
     T1.COD_TRX,
     T1.COD_REVERS_REAPLIC,
     T1.year,
     T1.month,
     T1.day,
     T1.MONEDA_HOMOLOGA
    
  FROM {zona_p}.temp_condonaciones_bvl T1
  WHERE SUBSTRING(CAST(T1.F_TRX AS STRING), 1, 6) = CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)
  
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
    FROM proceso_vspc_serv.temp_Maestro_contable_ajuste_IFRS
),

  RELACION AS (
    SELECT
      T2.REF2,
      RELACION_CLIENTE.llave_sistema
    
    FROM resultados_fcr.fcr_mdm_relacion_cliente_producto RELACION_CLIENTE
    RIGHT JOIN T2
      ON CAST(T2.REF2 AS STRING) = CAST(RELACION_CLIENTE.num_prod AS STRING)
    WHERE
      RELACION_CLIENTE.year = year(now())
      AND RELACION_CLIENTE.month = month(now())
      AND RELACION_CLIENTE.day = 1
      AND RELACION_CLIENTE.cod_prod = 'L'
      AND TRIM(RELACION_CLIENTE.tipo_relacion) IN ('D','T')
      
    GROUP BY T2.REF2, RELACION_CLIENTE.llave_sistema
    )

 SELECT 
 
    COALESCE(CAST(T2.PROCESO AS STRING),'') AS proceso,
    COALESCE(CAST(T2.TIPO_CARTERA AS STRING),'') AS tipo_cartera,
    '' AS tipo_prod,
    COALESCE(CAST(T2.MONEDA_HOMOLOGA AS STRING),'') AS moneda,
    COALESCE(CAST(T2.CLASIFICACION AS STRING),'') AS clasificacion,
    CAST(T2.VALOR_AJUSTE AS DECIMAL(15,2)) AS valor_ajuste,
    0 AS valor_ajuste_me,
    '' AS cal_cartera,
    '' AS Sucursal,
    COALESCE(CAST(T2.REF1 AS STRING),'') AS ref1,
    COALESCE(CAST(T2.REF2 AS STRING),'') AS ref2,
    COALESCE(CAST(LLAVERO.numeroid AS STRING),'') AS ref3,
    CAST(COALESCE(MAESTRO.clase_doc,'') AS STRING) AS clase_doc,
    COALESCE(CAST(MAESTRO.cuenta_partida AS STRING),'No asignada')  AS cuenta_partida,
    COALESCE(CAST(MAESTRO.cuenta_contrapartida AS STRING),'No asignada') AS cuenta_contrapartida,
    CONCAT(CAST(YEAR(CURRENT_DATE()) AS STRING), LPAD(CAST(MONTH(CURRENT_DATE()) AS STRING), 2, '0'), LPAD(CAST(DAY(CURRENT_DATE()) AS STRING), 2, '0')) AS fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING) AS aaaamm_ajuste,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)  AS fecha_ajuste,
    "condonaciones_bvl" AS etl_generadora, 
    DAY(CURRENT_DATE()) AS day,
    MONTH(CURRENT_DATE()) AS month,    
    YEAR(CURRENT_DATE()) AS year

    FROM T2
    LEFT JOIN MAESTRO
      ON T2.PROCESO = MAESTRO.proceso_maestro
      AND T2.MONEDA_HOMOLOGA = MAESTRO.moneda_homologa_maestro
      AND T2.CLASIFICACION = MAESTRO.clasificacion_maestro
      AND T2.TIPO_CARTERA = MAESTRO.tipo_de_cartera_maestro
    LEFT JOIN RELACION
      ON CAST(T2.REF2 AS STRING) = CAST(RELACION.REF2 AS STRING)
    LEFT JOIN resultados_fcr.fcr_mdm_llavero_clientes LLAVERO
      ON CAST(RELACION.llave_sistema AS STRING) = CAST(LLAVERO.llave_fuente AS STRING)
    
    WHERE  
    LLAVERO.year = year(now())
    AND LLAVERO.month = month(now())
    AND LLAVERO.day = 1   
 ;
--------------------------------- Query End ---------------------------------