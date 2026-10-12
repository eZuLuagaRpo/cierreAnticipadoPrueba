-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
---------------------------------Insumo int en suspenso ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_99 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_99 stored AS PARQUET AS

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_1

union all 

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_2

union all 

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_3

union all 

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_8
;

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_100 PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs_100 stored AS PARQUET AS

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_7

union all 

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_10

union all 

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_12

;

DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1 PURGE;
CREATE TABLE {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1 stored AS PARQUET AS

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_99

union all 

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
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    etl_generadora,
    year,
    month,
    day
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_100
;