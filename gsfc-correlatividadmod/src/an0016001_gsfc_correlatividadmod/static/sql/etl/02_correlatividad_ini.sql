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
DROP TABLE IF EXISTS {zona_p}.{indice}_info_castigos_excentos_mod purge;
CREATE TABLE {zona_p}.{indice}_info_castigos_excentos_mod stored AS PARQUET AS

with mes_cast_exce as(
select 
    sum(capital_castigado) as capital_castigado,
    SUM(case when codigo_aplicacion not in ('P', '4') then COALESCE(interes_castigado, 0) else 0 end) AS interes_castigado,
    sum(otros_concepto_castigado) as otros_concepto_castigado,
    sum(interes_sin_causacion_castigado) as interes_sin_causacion_castigado,
    plan
from resultados_vspc_serv.consolidado_castigos_full
where
year={CASTIGOS[year]}
and ingestion_month={CASTIGOS[month]}
and ingestion_day={CASTIGOS[day]}
group by 5
),

castigos_excentos as(
select
    sum(capital_castigado) as capital_castigado_excento,
    sum(interes_castigado) as interes_castigado_excento,
    sum(otros_concepto_castigado) as otros_castigado_excento,
    'CORRELATIVIDADES MODIFICADO' as proceso
from resultados_vspc_serv.ceplex_conciliacion_castigos t1 inner join mes_cast_exce t2
on trim(cexcpl) = trim(plan)
where
t1.ingestion_year={CPLEX[year]}
and t1.ingestion_month={CPLEX[month]}
and t1.ingestion_day={CPLEX[day]}
),

castigos_no_excentos as(
select
    sum(capital_castigado) as capital_castigado_no_excento,
    sum(interes_castigado) as interes_castigado_no_excento,
    sum(otros_concepto_castigado) as otros_castigado_no_excento,
    'CORRELATIVIDADES MODIFICADO' as proceso
from mes_cast_exce t1 left join resultados_vspc_serv.ceplex_conciliacion_castigos t2
on trim(cexcpl) = trim(plan)
and t2.ingestion_year={CPLEX[year]}
and t2.ingestion_month={CPLEX[month]}
and t2.ingestion_day={CPLEX[day]}
where
trim(cexcpl) is null
group by 4
)

select 
    capital_castigado_excento,
    capital_castigado_no_excento,
    interes_castigado_excento,
    interes_castigado_no_excento,
    otros_castigado_excento,
    otros_castigado_no_excento,
    t1.proceso
from castigos_excentos t1 left join castigos_no_excentos t2
on t1.proceso = t2.proceso
;
-------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS {zona_p}.{indice}_info_cm_hipotecario_mod purge;
CREATE TABLE {zona_p}.{indice}_info_cm_hipotecario_mod stored AS PARQUET AS

with castigos_hipotecario as(
select
  numcred as obligacion,
  fecicastig,
  year(date_add(fecicastig,1)) as anio_castigo_ingestion,
  month(date_add(fecicastig,1)) as mes_castigo_ingestion,
  day(date_add(fecicastig,1)) as dia_castigo_ingestion,
  year(fecicastig) as anio_ant_castigo_ingestion,
  month(fecicastig) as mes_ant_castigo_ingestion,
  day(fecicastig) as dia_ant_castigo_ingestion
from resultados_vspc_cartera.fco_datos_basicos_y_saldos_spvh_hist
where
year=year(now())
and month=month(now())
and day=01
and trim(upper(carcastig)) = 'X'
and fecicastig between add_months(trunc(now(), 'MM'), -1) and last_day(add_months(now(), -1))
),

slds_castigo as(
select
  numcred as obligacion,
  salcapcas as sld_capital_castigado,
  anio_ant_castigo_ingestion,
  mes_ant_castigo_ingestion,
  dia_ant_castigo_ingestion
from resultados_vspc_cartera.fco_datos_basicos_y_saldos_spvh_hist inner join castigos_hipotecario
on year = anio_castigo_ingestion
and month = mes_castigo_ingestion
and day = dia_castigo_ingestion
and numcred = obligacion
),

detalle_castigos_hip as(
select
  t1.numcred,
  t1.codmoneda,
  salcapsus as sld_cm_antes_del_castigo,
  salcapvig as sld_cap_antes_del_castigo,
  sld_capital_castigado,
  (sld_capital_castigado - salcapvig - salcapsus) + salcapsus as cm_capital
from resultados_vspc_cartera.fco_datos_basicos_y_saldos_spvh_hist t1 inner join slds_castigo
on year = anio_ant_castigo_ingestion
and month = mes_ant_castigo_ingestion
and day = dia_ant_castigo_ingestion
and numcred = obligacion
)

select 
round(sum(cm_capital),2)  as sld_cm_hipotecario,
'CORRELATIVIDADES MODIFICADO' as proceso_3
from detalle_castigos_hip
where 
trim(upper(codmoneda)) = 'UVR'
;
-------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS {zona_p}.{indice}_info_inte_suspe_sufi purge;
CREATE TABLE {zona_p}.{indice}_info_inte_suspe_sufi stored AS PARQUET AS

with consol_ajuste_ifrs AS (
  SELECT
    proceso,
    fecha_hora_generacion,
    etl_generadora,
    ROW_NUMBER() OVER (
      PARTITION BY proceso,
      etl_generadora
      ORDER BY
        fecha_hora_generacion desc
    ) AS rn_cn
  FROM
    resultados_vspc_serv.consolidado_ajuste_ifrs
  WHERE
  YEAR = {AJUSTES_IFRS[year]}
  AND MONTH = {AJUSTES_IFRS[month]}
  AND DAY = {AJUSTES_IFRS[day]}
  GROUP BY
    1,2,3
)

SELECT
  coalesce(SUM(A.valor_ajuste),0) as int_susp_sufi,
  'CORRELATIVIDADES MODIFICADO' as proceso_2
FROM
  resultados_vspc_serv.consolidado_ajuste_ifrs A
  LEFT JOIN consol_ajuste_ifrs B 
  ON A.fecha_hora_generacion = B.fecha_hora_generacion
  AND A.etl_generadora = B.etl_generadora
  AND A.proceso = B.proceso
  AND A.proceso = "Reversion_Castigos"
  AND A.tipo_cartera = "SUFI"
  AND A.tipo_prod = "Leasing"
WHERE
  YEAR = {AJUSTES_IFRS[year]}
  AND MONTH = {AJUSTES_IFRS[month]}
  AND DAY = {AJUSTES_IFRS[day]}
  AND B.rn_cn = 1
;
-------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_info_castigos_otros_a_mod_1 purge;
CREATE TABLE {zona_p}.{indice}_info_castigos_otros_a_mod_1 stored AS PARQUET AS

with maestro_prestamos as (
select
  num_oblig
from resultados_fcr.fcr_bkv_historico_trx_prestamos
where 
year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
and month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
and day = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'dd') AS int)
and cast(cod_trx as int) = 3263
and cod_revers_reaplic = ' '
and from_unixtime(unix_timestamp(cast(f_efectiva as string), 'yyyyMMdd'), 'yyyy-MM-dd')
      BETWEEN date_sub(trunc(now(), 'MM'), interval 1 month)
      AND last_day(now() - interval 1 month)
),

otros_ajustes as(
select
    sum(t2.CE121)*-1 as capital_otros_ajustes,
    sum(t2.CE221)*-1 as interes_otros_ajustes,
    sum(t3.CEM575)*-1 as otros_conceptos_ajustes,
    'CORRELATIVIDADES MODIFICADO' as proceso
from maestro_prestamos t1 left join s_riesgos.bkv_visionr_cenie t2
on cast(num_oblig as bigint) = cast(CEAC21 as bigint)
and t2.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
and t2.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
and t2.day = 11
left join s_riesgos.bkv_visionr_ceoco t3
on cast(num_oblig as bigint) = cast(CEAC75 as bigint)
and t3.year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
and t3.month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
and t3.day = 11
),

saldos_leasing as (
select
    cast(capital_castigado as DECIMAL(38,2)) as capital_castigado,
    cast(interes_castigado as DECIMAL(38,2)) as interes_castigado,
    cast(otros_concepto_castigado as DECIMAL(38,2)) as otros_concepto_castigado,
    cast(interes_en_suspenso_castigado as DECIMAL(38,2)) as interes_en_suspenso_castigado,
    codigo_aplicacion,
    proceso
from resultados_leasing.informe_castigos_leasing
where
year={LEASING[year]}
and ingestion_month={LEASING[month]}
and ingestion_day={LEASING[day]}
),

ao_lf as(
SELECT
    SUM(CASE WHEN proceso = 'COLGAAP' THEN cast(capital_castigado as bigint) ELSE 0 END) - SUM(CASE WHEN proceso = 'IFRS' THEN cast(capital_castigado as bigint) ELSE 0 END) AS CAP_AO_LF,
    SUM(CASE WHEN proceso = 'COLGAAP' THEN cast(interes_castigado as bigint) ELSE 0 END) - SUM(CASE WHEN proceso = 'IFRS' THEN cast(interes_castigado as bigint) ELSE 0 END) AS INT_AO_LF,
    SUM(CASE WHEN proceso = 'COLGAAP' THEN cast(otros_concepto_castigado as bigint) ELSE 0 END) - SUM(CASE WHEN proceso = 'IFRS' THEN cast(otros_concepto_castigado as bigint) ELSE 0 END) AS OTROS_AO_LF,
    SUM(CASE WHEN proceso = 'IFRS' AND codigo_aplicacion = 3 THEN cast(interes_en_suspenso_castigado as bigint) ELSE 0 END) AS INT_SUSP_LEASING,
    'CORRELATIVIDADES MODIFICADO' as proceso
FROM saldos_leasing
)

SELECT
    cast(year(now()) as smallint) as ingestion_year,
    cast(month(now()) as smallint) as ingestion_month,
    cast(day(now()) as smallint) as ingestion_day,
    coalesce(cast(capital_castigado_excento as decimal (38,2)),0) as capital_castigado_excento,
    coalesce(cast(capital_castigado_no_excento as decimal (38,2)),0) as capital_castigado_no_excento,
    coalesce(cast(interes_castigado_excento as decimal (38,2)),0) as interes_castigado_excento,
    coalesce(cast(interes_castigado_no_excento as decimal (38,2)),0) as interes_castigado_no_excento,
    (coalesce(cast(otros_castigado_excento as decimal (38,2)),0) + coalesce(cast(otros_castigado_no_excento as decimal (38,2)),0)) as otros_castigo,
    coalesce(cast(capital_otros_ajustes as decimal (38,2)),0) as capital_otros_ajustes,
    coalesce(cast(interes_otros_ajustes as decimal (38,2)),0) as interes_otros_ajustes,
    coalesce(cast(otros_conceptos_ajustes as decimal (38,2)),0) as otros_conceptos_ajustes,
    coalesce(cast(sld_cm_hipotecario as decimal (38,2)),0) as sld_cm_hipotecario,
    coalesce(cast(cap_ao_lf as decimal (38,2)),0) as cap_ao_lf,
    coalesce(cast(int_ao_lf as decimal (38,2)),0) as int_ao_lf,
    coalesce(cast(otros_ao_lf as decimal (38,2)),0) as otros_ao_lf,
    cast(int_susp_leasing as decimal (38,2)) as int_susp_leasing,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)  AS fecha_corte, -- cambiar a 1 
    t1.proceso
FROM otros_ajustes t1 inner join ao_lf t2
on trim(upper(t1.proceso)) = trim(upper(t2.proceso))
inner join {zona_p}.{indice}_info_castigos_excentos_mod t4
on trim(upper(t2.proceso)) = trim(upper(t4.proceso))
inner join {zona_p}.{indice}_info_cm_hipotecario_mod t5
on trim(upper(t4.proceso)) = trim(upper(t5.proceso_3))
;

DROP TABLE IF EXISTS {zona_p}.{indice}_info_ventas_otros_apli purge;
CREATE TABLE {zona_p}.{indice}_info_ventas_otros_apli stored AS PARQUET AS

WITH t2_agg AS (
    SELECT 
        cast(CEAC21 as bigint) as prestamo,
        CEAP21 as aplicativo,
        sum(CE121) as CE121,
        sum(CE221) as CE221
    FROM s_riesgos.bkv_visionr_cenie
    WHERE year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
      AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
      AND day = 11
    GROUP BY cast(CEAC21 as bigint), CEAP21
),

t3_agg AS (
    SELECT 
        cast(CEAC75 as bigint) as prestamo,
        CEAP75 as aplicativo,
        sum(CEM575) as CEM575
    FROM s_riesgos.bkv_visionr_ceoco
    WHERE year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS int)
      AND month = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'MM') AS int)
      AND day = 11
    GROUP BY cast(CEAC75 as bigint), CEAP75
)

SELECT
    sum(t2.CE121)*-1 as capital_otros_ajustes,
    sum(t2.CE221)*-1 as interes_otros_ajustes,
    sum(t3.CEM575)*-1 as otros_conceptos_ajustes,
    'CORRELATIVIDADES MODIFICADO' as proceso
FROM resultados_vspc_serv.ventas_otros_aplicativos t1
LEFT JOIN t2_agg t2
    ON cast(t1.prestamo as bigint) = t2.prestamo
    and trim(upper(t1.aplicativo)) = trim(upper(t2.aplicativo))
LEFT JOIN t3_agg t3
    ON cast(t1.prestamo as bigint) = t3.prestamo
    and trim(upper(t1.aplicativo)) = trim(upper(t3.aplicativo))
where
year = {OTRAS_VENTAS[year]}
and concat(cast(year(add_months(cast(concat(cast(ingestion_year as string), '-',lpad(cast(ingestion_month as string), 2, '0'),'-01') as timestamp),-1)) as string),
    lpad(cast(month(add_months(cast(concat(cast(ingestion_year as string), '-',lpad(cast(ingestion_month as string), 2, '0'),'-01') as timestamp), -1)) as string), 2, '0')) =
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMM') as STRING)
;
-------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_info_castigos_otros_a_mod purge;
CREATE TABLE {zona_p}.{indice}_info_castigos_otros_a_mod stored AS PARQUET AS

SELECT
    ingestion_year,
    ingestion_month,
    ingestion_day,
    capital_castigado_excento,
    capital_castigado_no_excento,
    interes_castigado_excento,
    interes_castigado_no_excento,
    otros_castigo,
    t1.capital_otros_ajustes + coalesce(cast(t3.capital_otros_ajustes as decimal (38,2)),0) as capital_otros_ajustes,
    t1.interes_otros_ajustes + coalesce(cast(t3.interes_otros_ajustes as decimal (38,2)),0) as interes_otros_ajustes,
    t1.otros_conceptos_ajustes + coalesce(cast(t3.otros_conceptos_ajustes as decimal (38,2)),0) as otros_conceptos_ajustes,
    sld_cm_hipotecario,
    cap_ao_lf,
    int_ao_lf,
    otros_ao_lf,
    int_susp_leasing,
    cast(int_susp_sufi as decimal (38,2)) as int_susp_sufi,
    fecha_corte, -- cambiar a 1 
    t1.proceso
FROM {zona_p}.{indice}_info_castigos_otros_a_mod_1 t1 inner join {zona_p}.{indice}_info_inte_suspe_sufi t2
  on trim(upper(t1.proceso)) = trim(upper(t2.proceso_2))
inner join {zona_p}.{indice}_info_ventas_otros_apli t3
  on trim(upper(t1.proceso)) = trim(upper(t3.proceso))