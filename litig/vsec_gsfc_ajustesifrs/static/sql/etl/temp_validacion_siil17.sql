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

DROP TABLE IF EXISTS {zona_p}.temp_validacion_siil17_ant PURGE;
CREATE TABLE {zona_p}.temp_validacion_siil17_ant stored AS PARQUET AS

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
        AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        AND L17EST < 3
    GROUP BY 
        L17NPR, year, month, day
;

DROP TABLE IF EXISTS {zona_p}.temp_validacion_siil17_act PURGE;
CREATE TABLE {zona_p}.temp_validacion_siil17_act stored AS PARQUET AS

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
        L17EST < 3
        AND year = year(now())
        AND month = month(now())
    GROUP BY 
        L17NPR, year, month, day
    
;