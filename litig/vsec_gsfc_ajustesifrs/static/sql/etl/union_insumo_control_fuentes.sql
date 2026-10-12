-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_1 PURGE;
CREATE TABLE {zona_p}.{indice}_u_consolidado_ctr_fuentes_1 stored AS PARQUET AS

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_1

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_2

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_3

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_4

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_5
;

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_2 PURGE;
CREATE TABLE {zona_p}.{indice}_u_consolidado_ctr_fuentes_2 stored AS PARQUET AS

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_55

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_6

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_7

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_8

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year  
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_9
;

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_3 PURGE;
CREATE TABLE {zona_p}.{indice}_u_consolidado_ctr_fuentes_3 stored AS PARQUET AS

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year   
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_10

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_11

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_12

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_13

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_14
;

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_4 PURGE;
CREATE TABLE {zona_p}.{indice}_u_consolidado_ctr_fuentes_4 stored AS PARQUET AS

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_15

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_16

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_17

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_control_fuentes_ajustesifrs_18
;

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ctr_fuentes PURGE;
CREATE TABLE {zona_p}.{indice}_consolidado_ctr_fuentes stored AS PARQUET AS

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year
FROM {zona_p}.{indice}_u_consolidado_ctr_fuentes_1

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_u_consolidado_ctr_fuentes_2

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_u_consolidado_ctr_fuentes_3

union all 

SELECT
    tabla,
    conteo,
    validacion,
    fecha_proceso,
    fecha_hora_generacion,
    aaaamm_ajuste,
    fecha_ajuste,
    day,
    month,    
    year 
FROM {zona_p}.{indice}_u_consolidado_ctr_fuentes_4
;