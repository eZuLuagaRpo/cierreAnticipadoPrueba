-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--------------------------------- ---------------------------------

INSERT INTO {zona_r}.saldo_cuentas_correlatividad_mod 
PARTITION(year)

SELECT
    ingestion_year,
    ingestion_month,
    ingestion_day,
    num_cuenta,
    acum_loc_t,
    acum_loc_ant,
    variacion,
    proceso,
    sub_proceso,
    fecha_contab,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS smallint) as year
FROM {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod
WHERE
trim(upper(proceso)) like '%MODIFICADO%'
;
COMPUTE INCREMENTAL STATS {zona_r}.saldo_cuentas_correlatividad_mod PARTITION (year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS smallint))
;
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
INSERT INTO {zona_r}.correlatividad_mod_detalle
PARTITION(year)

SELECT
    ingestion_year,
    ingestion_month,
    ingestion_day,
    capital_castigado_excento,
    capital_castigado_no_excento,
    interes_castigado_excento,
    interes_castigado_no_excento,
    otros_castigo,
    capital_otros_ajustes,
    interes_otros_ajustes,
    otros_conceptos_ajustes,
    cast(cap_ao_lf as bigint) as cap_ao_lf,
    cast(int_ao_lf as bigint) as int_ao_lf,
    cast(otros_ao_lf as bigint) as otros_ao_lf,
    sld_cm_hipotecario as correcion_m_hip,
    cast(int_susp_leasing as bigint) as int_susp_leasing,
    cast(int_susp_sufi as bigint) as int_susp_sufi,
    fecha_corte,
    proceso,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS smallint) as year
FROM {zona_p}.{indice}_info_castigos_otros_a_mod
;
COMPUTE INCREMENTAL STATS {zona_r}.correlatividad_mod_detalle PARTITION (year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS smallint))
;
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
INSERT INTO {zona_r}.correlatividad_modificado
PARTITION(year)

SELECT
    ingestion_year,
    ingestion_month,
    ingestion_day,
    saldo_final_del_anio_anterior,
    saldo_final_del_anio_actual,
    provisiones_del_anio_actual,
    castigos_del_periodo,
    recuperaciones_del_anio_actual,
    otros_ajustes,
    cast(total as decimal (35,2)) as total,
    cast(diferencia_final as decimal (35,2)) as diferencia_final,
    correlatividad,
    fecha_corte,
    CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS smallint) as year
FROM {zona_p}.{indice}_info_correlatividades_modificado
;
COMPUTE INCREMENTAL STATS {zona_r}.correlatividad_modificado PARTITION (year = CAST(from_unixtime(unix_timestamp(last_day(add_months(trunc(now(), 'MM'), -1))), 'yyyy') AS smallint))
;