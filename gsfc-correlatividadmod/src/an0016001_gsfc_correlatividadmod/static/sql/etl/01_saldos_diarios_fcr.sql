-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia Corporativa Grupo Bancolombia
-----------------------------------------------------------------------------
-- Fecha Creación: 20250625
-- Última Fecha Modificación: 20250625
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Extraccion de informacion para CR1
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-----------------------INFORMACION CONSOLIDADO AJUSTES IFRS--------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_info_saldos_diarios_fcr_mod purge;
CREATE TABLE {zona_p}.{indice}_info_saldos_diarios_fcr_mod stored AS PARQUET AS

WITH FCR_T_FULL AS (
  SELECT
    T1.NRO_CUENTA_OPERATIVA AS REF2,
    T1.FECHA_CONTAB AS FECHA_CONTAB,
    T1.ACUM_ORIG AS ACUM_ORIG,
    T1.ACUM_LOC AS ACUM_LOC,
    T1.cronomarcador,
    ROW_NUMBER() OVER (
      PARTITION BY t1.mandante,
      t1.soc,
      t1.nro_cuenta_operativa,
      t1.moneda_origen,
      t1.ejercicio,
      t1.fecha_contab,
      t1.segmento,
      t1.ledger,
      t1.clase
      ORDER BY
        t1.cronomarcador DESC
    ) AS rn_cn

    from RESULTADOS_FCR.fcr_sap_saldos_diarios_banco  T1
    where
    T1.year IN (year(now()),year(now())-1)
    and T1.fecha_contab = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING)
    and T1.ejercicio = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS STRING)
    and T1.ledger = '0L' 
    and T1.segmento <> 'FULLIFRS00'
    and (t1.nro_cuenta_operativa LIKE '14%' OR t1.nro_cuenta_operativa LIKE '16%' OR t1.nro_cuenta_operativa LIKE '18%' OR t1.nro_cuenta_operativa LIKE '5170%' OR t1.nro_cuenta_operativa LIKE '5171%' OR t1.nro_cuenta_operativa LIKE '41%')
    -- and T1.cronomarcador < CAST(20260310000000 AS BIGINT) 
),
    
FCR_ANT_FULL AS (
  SELECT
    T1.NRO_CUENTA_OPERATIVA AS REF2,
    T1.FECHA_CONTAB AS FECHA_CONTAB,
    T1.ACUM_ORIG AS ACUM_ORIG,
    T1.ACUM_LOC AS ACUM_LOC,
      ROW_NUMBER() OVER (
      PARTITION BY t1.mandante,
      t1.soc,
      t1.nro_cuenta_operativa,
      t1.moneda_origen,
      t1.ejercicio,
      t1.fecha_contab,
      t1.segmento,
      t1.ledger,
      t1.clase
      ORDER BY
        t1.cronomarcador DESC
    ) AS rn_cn

    from RESULTADOS_FCR.fcr_sap_saldos_diarios_banco as T1
    
    where
    
    T1.year IN (year(now()),year(now())-1)
    and T1.fecha_contab = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -2))), 'yyyyMMdd') as STRING)
    and T1.ejercicio = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -2))), 'yyyy') as STRING)
    and T1.ledger = '0L'
    and T1.segmento <> 'FULLIFRS00'
    and (t1.nro_cuenta_operativa LIKE '14%' OR t1.nro_cuenta_operativa LIKE '16%' OR t1.nro_cuenta_operativa LIKE '18%' OR t1.nro_cuenta_operativa LIKE '5170%' OR t1.nro_cuenta_operativa LIKE '5171%' OR t1.nro_cuenta_operativa LIKE '41%')
    
),

FCR_T AS (
    SELECT 
    REF2,
    FECHA_CONTAB AS FECHA_CONTAB_T,
    SUM(ACUM_ORIG)  AS ACUM_ORIG_T,
    SUM(ACUM_LOC)  AS ACUM_LOC_T
    FROM FCR_T_FULL
    WHERE 
    rn_cn = 1 
    GROUP BY REF2, FECHA_CONTAB
),

FCR_ANT AS (
    SELECT 
    REF2,
    FECHA_CONTAB AS FECHA_CONTAB_ANT,
    SUM(ACUM_ORIG) AS ACUM_ORIG_ANT,
    SUM(ACUM_LOC) AS ACUM_LOC_ANT
    
    FROM FCR_ANT_FULL
    WHERE 
    rn_cn = 1 
    GROUP BY REF2,FECHA_CONTAB
),

var as (
select 
    t1.REF2 as num_cuenta,
    if(t1.ACUM_LOC_T is null, 0 ,t1.ACUM_LOC_T) as ACUM_LOC_T,
    if(t2.ACUM_LOC_ANT is null, 0 , t2.ACUM_LOC_ANT) as ACUM_LOC_ANT
from FCR_T t1 left join FCR_ANT t2
on t1.REF2 = t2.REF2
)

select 
    num_cuenta,
    ACUM_LOC_T,
    ACUM_LOC_ANT,
    ACUM_LOC_T - ACUM_LOC_ANT as variacion
from var
;

DROP TABLE IF EXISTS {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod purge;
CREATE TABLE {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod stored AS PARQUET AS

with m_cuentas as(
select 
  cuenta_cuif,
  proceso,
  sub_proceso
from resultados_vspc_serv.maestro_cuentas_correlatividad
where
year={MAESTRO_CUENTAS[year]}
and ingestion_month={MAESTRO_CUENTAS[month]}
and ingestion_day={MAESTRO_CUENTAS[day]}
)

select
    cast(year(now()) as smallint) as ingestion_year,
    cast(month(now()) as smallint) as ingestion_month,
    cast(day(now()) as smallint) as ingestion_day,
    num_cuenta,
    ACUM_LOC_T,
    ACUM_LOC_ANT,
    ACUM_LOC_T - ACUM_LOC_ANT as variacion,
    proceso,
    sub_proceso,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) as fecha_contab
from {zona_p}.{indice}_info_saldos_diarios_fcr_mod inner join m_cuentas
on cast(num_cuenta as bigint) = cast(cuenta_cuif as bigint)
;