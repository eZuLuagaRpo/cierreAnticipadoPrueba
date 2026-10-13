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

DROP TABLE IF EXISTS {zona_p}.{indice}_info_correlatividades_modificado_ini purge;
CREATE TABLE {zona_p}.{indice}_info_correlatividades_modificado_ini stored AS PARQUET AS

select
    SUM(CASE WHEN trim(upper(proceso)) = 'CAPITAL MODIFICADO' AND trim(upper(sub_proceso)) = 'SALDO BALANCE' THEN acum_loc_ant ELSE 0 END) AS saldo_final_del_anio_anterior,
    SUM(CASE WHEN trim(upper(proceso)) = 'CAPITAL MODIFICADO' AND trim(upper(sub_proceso)) = 'SALDO BALANCE' THEN acum_loc_t ELSE 0 END) AS saldo_final_del_anio_actual,
    SUM(CASE WHEN trim(upper(proceso)) = 'CAPITAL MODIFICADO' AND trim(upper(sub_proceso)) = 'PYG' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS provisiones_del_anio_actual,
    SUM(CASE WHEN trim(upper(proceso)) = 'CAPITAL MODIFICADO' AND trim(upper(sub_proceso)) = 'CONDONACIONES' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS condonacion,
    SUM(CASE WHEN trim(upper(proceso)) = 'CAPITAL MODIFICADO' AND trim(upper(sub_proceso)) = 'RECUPERACION' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS recuperaciones_del_anio_actual,
    CAST(0 AS DECIMAL(38,2))  as interes_en_suspenso_castigado,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) as fecha_corte,
    'CAPITAL MODIFICADO' as proceso,
    'CORRELATIVIDADES MODIFICADO' as proceso_2
from {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod

union all 

select
    SUM(CASE WHEN trim(upper(proceso)) = 'INTERESES MODIFICADO' AND trim(upper(sub_proceso)) = 'SALDO BALANCE' THEN acum_loc_ant ELSE 0 END) AS saldo_final_del_anio_anterior,
    SUM(CASE WHEN trim(upper(proceso)) = 'INTERESES MODIFICADO' AND trim(upper(sub_proceso)) = 'SALDO BALANCE' THEN acum_loc_t ELSE 0 END) AS saldo_final_del_anio_actual,
    SUM(CASE WHEN trim(upper(proceso)) = 'INTERESES MODIFICADO' AND trim(upper(sub_proceso)) = 'PYG' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS provisiones_del_anio_actual,
    SUM(CASE WHEN trim(upper(proceso)) = 'INTERESES MODIFICADO' AND trim(upper(sub_proceso)) = 'CONDONACIONES' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS condonacion,
    SUM(CASE WHEN trim(upper(proceso)) = 'INTERESES MODIFICADO' AND trim(upper(sub_proceso)) = 'RECUPERACION' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS recuperaciones_del_anio_actual,  
    SUM(CASE WHEN trim(upper(proceso)) = 'INTERESES MODIFICADO' AND trim(upper(sub_proceso)) = 'INTERESES EN SUSPENSO' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS interes_en_suspenso_castigado,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) as fecha_corte,
    'INTERESES MODIFICADO' as proceso,
    'CORRELATIVIDADES MODIFICADO' as proceso_2
from {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod

union all 

select
    SUM(CASE WHEN trim(upper(proceso)) = 'OTROS MODIFICADO' AND trim(upper(sub_proceso)) = 'SALDO BALANCE' THEN acum_loc_ant ELSE 0 END) AS saldo_final_del_anio_anterior,
    SUM(CASE WHEN trim(upper(proceso)) = 'OTROS MODIFICADO' AND trim(upper(sub_proceso)) = 'SALDO BALANCE' THEN acum_loc_t ELSE 0 END) AS saldo_final_del_anio_actual,
    SUM(CASE WHEN trim(upper(proceso)) = 'OTROS MODIFICADO' AND trim(upper(sub_proceso)) = 'PYG' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS provisiones_del_anio_actual,
    SUM(CASE WHEN trim(upper(proceso)) = 'OTROS MODIFICADO' AND trim(upper(sub_proceso)) = 'CONDONACIONES' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS condonacion,
    SUM(CASE WHEN trim(upper(proceso)) = 'OTROS MODIFICADO' AND trim(upper(sub_proceso)) = 'RECUPERACION' THEN CASE WHEN cast(from_unixtime(unix_timestamp(now()), 'MM') as int) = 2 THEN acum_loc_t ELSE variacion END ELSE 0 END) AS recuperaciones_del_anio_actual,  
    CAST(0 AS DECIMAL(38,2)) as interes_en_suspenso_castigado,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyyMMdd') as STRING) as fecha_corte,
    'OTROS MODIFICADO' as proceso,
    'CORRELATIVIDADES MODIFICADO' as proceso_2
from {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod

;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_info_correlatividades_modificado_ini_2 purge;
CREATE TABLE {zona_p}.{indice}_info_correlatividades_modificado_ini_2 stored AS PARQUET AS

select
    t1.saldo_final_del_anio_anterior,
    t1.saldo_final_del_anio_actual,
    t1.provisiones_del_anio_actual,
    t1.condonacion + t2.capital_castigado_no_excento - t2.sld_cm_hipotecario as castigos_del_periodo,
    t1.recuperaciones_del_anio_actual,
    t2.capital_otros_ajustes as otros_ajustes,
    (t1.saldo_final_del_anio_actual - t1.saldo_final_del_anio_anterior)+(t1.provisiones_del_anio_actual + t1.recuperaciones_del_anio_actual - (t1.condonacion  + t2.capital_castigado_no_excento - t2.sld_cm_hipotecario) + t2.capital_otros_ajustes) as total,
    t1.proceso as correlatividad,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)  AS fecha_corte -- cambiar a 1 
from {zona_p}.{indice}_info_correlatividades_modificado_ini t1 inner join {zona_p}.{indice}_info_castigos_otros_a_mod t2
on t1.proceso_2 = t2.proceso 
where 
t1.proceso = 'CAPITAL MODIFICADO'

union all 

select
    t1.saldo_final_del_anio_anterior,
    t1.saldo_final_del_anio_actual,
    t1.provisiones_del_anio_actual,
    t1.condonacion + t2.interes_castigado_no_excento + t2.int_susp_leasing + t2.int_susp_sufi as castigos_del_periodo,
    t1.recuperaciones_del_anio_actual,
    t2.interes_otros_ajustes as otros_ajustes,
    (t1.saldo_final_del_anio_actual - t1.saldo_final_del_anio_anterior)+(t1.provisiones_del_anio_actual + t1.recuperaciones_del_anio_actual - (t1.condonacion + t2.interes_castigado_no_excento + t2.int_susp_leasing + t2.int_susp_sufi) + t2.interes_otros_ajustes) as total,
    t1.proceso as correlatividad,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)  AS fecha_corte -- cambiar a 1 
from {zona_p}.{indice}_info_correlatividades_modificado_ini t1 inner join {zona_p}.{indice}_info_castigos_otros_a_mod t2
on t1.proceso_2 = t2.proceso 
where 
t1.proceso = 'INTERESES MODIFICADO'

union all 

select
    t1.saldo_final_del_anio_anterior,
    t1.saldo_final_del_anio_actual,
    t1.provisiones_del_anio_actual,
    t1.condonacion + t2.otros_castigo as castigos_del_periodo,
    t1.recuperaciones_del_anio_actual,
    t2.otros_conceptos_ajustes as otros_ajustes,
    (t1.saldo_final_del_anio_actual - t1.saldo_final_del_anio_anterior)+(t1.provisiones_del_anio_actual + t1.recuperaciones_del_anio_actual - (t1.condonacion + t2.otros_castigo) + t2.otros_conceptos_ajustes) as total,
    t1.proceso as correlatividad,
    CAST(from_unixtime(unix_timestamp(date_sub(trunc(now(), 'MM'), interval 1 month)), 'yyyyMM') AS STRING)  AS fecha_corte -- cambiar a 1  
from {zona_p}.{indice}_info_correlatividades_modificado_ini t1 inner join {zona_p}.{indice}_info_castigos_otros_a_mod t2
on t1.proceso_2 = t2.proceso 
where 
t1.proceso = 'OTROS MODIFICADO'
;
-------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_info_correlatividades_modificado purge;
CREATE TABLE {zona_p}.{indice}_info_correlatividades_modificado stored AS PARQUET AS

select
    cast(year(now()) as smallint) as ingestion_year,
    cast(month(now()) as smallint) as ingestion_month,
    cast(day(now()) as smallint) as ingestion_day,
    saldo_final_del_anio_anterior,
    saldo_final_del_anio_actual,
    provisiones_del_anio_actual,
    castigos_del_periodo,
    recuperaciones_del_anio_actual,
    round(otros_ajustes, 2) as otros_ajustes,
    round(total, 2) as total,
    round(SUM(total) OVER (), 2)  as diferencia_final,
    correlatividad,
    fecha_corte
from {zona_p}.{indice}_info_correlatividades_modificado_ini_2 
