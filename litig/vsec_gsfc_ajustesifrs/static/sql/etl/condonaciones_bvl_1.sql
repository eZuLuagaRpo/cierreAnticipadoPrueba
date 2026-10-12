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

DROP TABLE IF EXISTS {zona_p}.temp_condonaciones_bvl PURGE;
CREATE TABLE {zona_p}.temp_condonaciones_bvl stored AS PARQUET AS
    
WITH TRM AS (
select
    value as valor_trm,
    complementaryinformation as fecha_vigente
from s_apoyo_corporativo.mdm_rdm_hub_pkg_tasas
WHERE 
datatypereference LIKE "%TASA_TRM%"
and year = year(now())
and ingestion_month= month(now())
and ingestion_day= 1
and complementaryinformation = CONCAT(
  CAST(YEAR(now()) AS STRING), '-',
  LPAD(CAST(MONTH(now()) AS STRING), 2, '0'), '-',
  '01'
)
limit 1
)

SELECT

    LHSIH.num_oblig AS REF2,
    LHSIH.num_redescuento AS NUM_REDESCUENTO,
    
    CASE 
        WHEN LHSIH.cod_revers_reaplic = 'R' THEN LHSIH.f_revers_reaplic
        ELSE LHSIH.f_trx
    END AS F_TRX,

    CASE
        WHEN COALESCE(FCR_MAESTRO.COD_MONEDA, '') = '' THEN LHSIH.mnt_trx
        WHEN FCR_MAESTRO.COD_MONEDA = '001' THEN CAST(LHSIH.mnt_trx AS DECIMAL(15,2))*CAST(TRM.valor_trm AS DECIMAL(15,2))
    END AS VALOR_AJUSTE,
    
    --LHSIH.LHAMTR AS VALOR_AJUSTE,
    LHSIH.cod_trx AS COD_TRX,
    LHSIH.cod_revers_reaplic AS COD_REVERS_REAPLIC,
    LHSIH.year,
    LHSIH.month,
    LHSIH.day,
    FCR_MAESTRO.COD_TIPO_OBLIG AS MOD_CRED,
    
    CASE
        WHEN COALESCE(FCR_MAESTRO.COD_MONEDA, '') = '' THEN 'COP'
        WHEN FCR_MAESTRO.COD_MONEDA = '001' THEN 'USD'
    END AS MONEDA_HOMOLOGA
        
    FROM resultados_fcr.fcr_bkv_historico_trx_prestamos LHSIH
    INNER JOIN resultados_fcr.fcr_bkv_maestro_prestamos FCR_MAESTRO 
    --INNER JOIN proceso_vspc_serv.fcr_bkv_maestro_prestamos_hist FCR_MAESTRO    
    ON
        cast(LHSIH.num_oblig as bigint) = cast(FCR_MAESTRO.NUM_OBLIG as bigint)
        AND LHSIH.num_redescuento = FCR_MAESTRO.NUM_REDESCUENTO
    INNER JOIN TRM
    ON CONCAT(CAST(YEAR(now()) AS STRING), '-', LPAD(CAST(MONTH(now()) AS STRING), 2, '0'), '-', '01')  = TRM.fecha_vigente
        
    WHERE 
        LHSIH.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
        AND LHSIH.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        AND LHSIH.day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)
        AND LHSIH.cod_trx IN (3044,7044)
        AND LHSIH.cod_revers_reaplic <> 'L'
        AND FCR_MAESTRO.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
        AND FCR_MAESTRO.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
        AND FCR_MAESTRO.day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)

;