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

-------------------temp_base_cuentas_reclasificacion_ifrs---------------------

DROP TABLE IF EXISTS {zona_p}.temp_base_cuentas_reclasificacion_ifrs PURGE;
CREATE TABLE {zona_p}.temp_base_cuentas_reclasificacion_ifrs stored AS PARQUET AS

with ultima_i as(
select 
    ingestion_year as anio,
    ingestion_month as mes,
    ingestion_day as dia
from resultados_vspc_serv.base_cuentas_reclasificacion_ifrs
where
ingestion_year >= 2024
group by 1,2,3
order by 1 desc, 2 desc, 3 desc
limit 1
)

SELECT
cast(A.proceso as string) as proceso,
cast(A.moneda as string) as moneda,
cast(A.clasificacion as string) as clasificacion,
cast(A.tipo_cartera as string) as tipo_cartera,
cast(A.tipo_prod as string) as tipo_prod,
cast(A.cal_cartera as string) as cal_cartera,
cast(A.cuenta as string) as cuenta,
cast(A.ingestion_year as int) as ingestion_year,
cast(A.ingestion_month as int) as ingestion_month,
cast(A.ingestion_day as int) as ingestion_day,
cast(A.usuario as string) as usuario

from resultados_vspc_serv.base_cuentas_reclasificacion_ifrs A inner join ultima_i 
on A.ingestion_year = anio
AND A.ingestion_month = mes
AND A.ingestion_day = dia
;

---------------------temp_maestro_contable_ajuste_ifrs-----------------------------

DROP TABLE IF EXISTS {zona_p}.temp_maestro_contable_ajuste_ifrs PURGE;
CREATE TABLE {zona_p}.temp_maestro_contable_ajuste_ifrs stored AS PARQUET AS

with ultima_i as(
select 
    ingestion_year as anio,
    ingestion_month as mes,
    ingestion_day as dia
from resultados_vspc_serv.maestro_contable_ajuste_ifrs
where
ingestion_year >= 2025
group by 1,2,3
order by 1 desc, 2 desc, 3 desc
limit 1
)

SELECT
cast(A.proceso as string) as proceso,
cast(A.moneda as string) as moneda,
cast(A.clasificacion as string) as clasificacion,
cast(A.tipo_cartera as string) as tipo_cartera,
cast(A.tipo_prod as string) as tipo_prod,
cast(A.cal_cartera as string) as cal_cartera,
cast(A.cuenta_partida as string) as cuenta_partida,
cast(A.cuenta_contrapartida as string) as cuenta_contrapartida,
cast(A.clase_doc as string) as clase_doc,
cast(A.ingestion_year as int) as ingestion_year,
cast(A.ingestion_month as int) as ingestion_month,
cast(A.ingestion_day as int) as ingestion_day,
cast(A.usuario as string) as usuario

from resultados_vspc_serv.maestro_contable_ajuste_ifrs A inner join ultima_i 
on A.ingestion_year = anio
AND A.ingestion_month = mes
AND A.ingestion_day = dia
;

---------------------temp_maestro_contable_ajuste_ifrs-----------------------------

DROP TABLE IF EXISTS {zona_p}.temp_maestro_bin_clasif_ifrs PURGE;
CREATE TABLE {zona_p}.temp_maestro_bin_clasif_ifrs stored AS PARQUET AS

with ultima_i as(
select 
    ingestion_year as anio,
    ingestion_month as mes,
    ingestion_day as dia
from resultados_vspc_serv.maestro_bin_clasif_ifrs
where
ingestion_year >= 2024
group by 1,2,3
order by 1 desc, 2 desc, 3 desc
limit 1
)

SELECT

cast(A.bin_code as string) as bin_code,
cast(A.clasificacion as string) as clasificacion,
cast(A.ingestion_year as int) as ingestion_year,
cast(A.ingestion_month as int) as ingestion_month,
cast(A.ingestion_day as int) as ingestion_day,
cast(A.usuario as string) as usuario

from resultados_vspc_serv.maestro_bin_clasif_ifrs A inner join ultima_i 
on A.ingestion_year = anio
AND A.ingestion_month = mes
AND A.ingestion_day = dia
--------------------------------- Query End ---------------------------------

