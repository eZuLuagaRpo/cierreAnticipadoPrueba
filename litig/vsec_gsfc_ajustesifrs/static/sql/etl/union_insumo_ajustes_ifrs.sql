-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
---------------------------------Insumo int en suspenso ---------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ajuste_ifrs_2 PURGE;
CREATE TABLE {zona_p}.{indice}_u_consolidado_ajuste_ifrs_2 stored AS PARQUET AS

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
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_4

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
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_5

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
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_6

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
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_9 
;

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ajuste_ifrs stored AS PARQUET AS
 
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
FROM {zona_p}.{indice}_consolidado_ajuste_ifrs_11

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
FROM {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1

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
FROM {zona_p}.{indice}_u_consolidado_ajuste_ifrs_2
;