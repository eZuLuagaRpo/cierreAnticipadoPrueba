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


DROP TABLE IF EXISTS {zona_p}.temp_cond_int_sus_bvl_pyg PURGE;
CREATE TABLE {zona_p}.temp_cond_int_sus_bvl_pyg stored AS PARQUET AS

-- CONDONACIONES INT SUS BVL PYG

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
    proceso in ('Reversion_Condonaciones')
    and tipo_cartera='BVL'
    and aaaamm_ajuste = CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)
)


SELECT

    CAST(T1.tipo_cartera AS STRING) as tipo_cartera,
    CAST(T1.clasificacion AS STRING) as clasificacion,
    CAST(T1.aaaamm_ajuste AS STRING) as aaaamm_ajuste,
    CAST(T1.moneda AS STRING) as moneda,
    SUM(CAST(T1.VALOR_AJUSTE AS DECIMAL(15,2))) AS VALOR_AJUSTE_COND,
    SUM(CAST(T1.VALOR_AJUSTE_ME AS DECIMAL(15,2))) AS VALOR_AJUSTE_COND_ME    

    FROM {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1 T1
    INNER JOIN ULT_CONSOLIDADO_AJUSTES_IFRS T_ULT

    ON T1.fecha_hora_generacion = T_ULT.fecha_hora_generacion
    AND T1.etl_generadora = T_ULT.etl_generadora
    AND T1.PROCESO = T_ULT.proceso
    AND T1.TIPO_CARTERA = T_ULT.tipo_cartera
    AND T1.aaaamm_ajuste = T_ULT.aaaamm_ajuste
    
    WHERE T_ULT.rn_cn = 1  
    
    GROUP BY T1.CLASIFICACION, T1.aaaamm_ajuste, T1.tipo_cartera, T1.moneda

;



--------------------------------- Query End ---------------------------------