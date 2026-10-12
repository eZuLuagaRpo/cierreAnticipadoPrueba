-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--------------------------------- ---------------------------------

INSERT INTO {zona_r}.consolidado_ajuste_ifrs 
PARTITION(year, month, day)

SELECT
    proceso,
    tipo_cartera,
    tipo_prod,
    moneda,
    clasificacion,
    valor_ajuste,    
    valor_ajuste_me,
    cal_cartera,
    sucursal,
    ref1,
    ref2,
    ref3,
    clase_doc,
    cuenta_partida,
    cuenta_contrapartida,
    fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    cast(year(now()) as smallint) as year,
    cast(month(now()) as smallint) as month,
    cast(day(now()) as smallint) as day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs
;

---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
INSERT INTO {zona_r}.control_fuentes_ajustesifrs 
PARTITION(year, month , day)

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    CAST(CURRENT_TIMESTAMP() AS STRING) AS fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste, 
    cast(year(now()) as smallint) as year,
    cast(month(now()) as smallint) as month,
    cast(day(now()) as smallint) as day
FROM {zona_p}.{indice}_consolidado_ctr_fuentes
;
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
