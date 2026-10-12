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

-------------------temp_lista_plan_reest_castigos---------------------

DROP TABLE IF EXISTS {zona_p}.temp_lista_plan_reest_castigos PURGE;
CREATE TABLE {zona_p}.temp_lista_plan_reest_castigos stored AS PARQUET AS

with ultima_i as(
select 
    ingestion_year as anio,
    ingestion_month as mes,
    ingestion_day as dia
from resultados_vspc_serv.lista_plan_reest_castigos
where
ingestion_year >= 2025
group by 1,2,3
order by 1 desc, 2 desc, 3 desc
limit 1
)
SELECT
cast(A.plan as string) as plan,
cast(A.ingestion_year as int) as ingestion_year,
cast(A.ingestion_month as int) as ingestion_month,
cast(A.ingestion_day as int) as ingestion_day,
cast(A.usuario as string) as usuario

from resultados_vspc_serv.lista_plan_reest_castigos A inner join ultima_i 
on A.ingestion_year = anio
AND A.ingestion_month = mes
AND A.ingestion_day = dia
;

---------------------maestro_eventos_reest_castigos-----------------------------

DROP TABLE IF EXISTS {zona_p}.temp_maestro_eventos_reest_castigos PURGE;
CREATE TABLE {zona_p}.temp_maestro_eventos_reest_castigos stored AS PARQUET AS

with ultima_i as(
select 
    ingestion_year as anio,
    ingestion_month as mes,
    ingestion_day as dia
from resultados_vspc_serv.maestro_eventos_reest_castigos
where
ingestion_year >= 2025
group by 1,2,3
order by 1 desc, 2 desc, 3 desc
limit 1
)

SELECT
cast(A.gl as string) as gl,
cast(A.record as string) as record,
cast(A.evento as string) as evento,
cast(A.ingestion_year as int) as ingestion_year,
cast(A.ingestion_month as int) as ingestion_month,
cast(A.ingestion_day as int) as ingestion_day,
cast(A.usuario as string) as usuario

from resultados_vspc_serv.maestro_eventos_reest_castigos A inner join ultima_i 
on A.ingestion_year = anio
AND A.ingestion_month = mes
AND A.ingestion_day = dia
;

--------------------------------- Query End ---------------------------------

