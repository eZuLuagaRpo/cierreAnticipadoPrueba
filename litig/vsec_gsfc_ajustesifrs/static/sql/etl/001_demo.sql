-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Entorno al Servicio de Funciones Corporativas
-----------------------------------------------------------------------------
-- Fecha Creación: 20240511
-- Última Fecha Modificación: 20240511
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Extraccion de información contable de castigos de la tabla
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

-- ESTO ES SOLO UNA CONSULTA DE MUESTRA, SE DEBEN COLOCAR TODAS LAS CONSULTAS

create table if not exists {zona_r}.consolidado_ajuste_ifr
(
proceso string,
tipo_cartera string,
tipo_prod string,
moneda string,
clasificacion string,
valor_ajuste decimal(15,2),
valor_ajuste_me decimal(15,2),
cal_cartera string,
sucursal string,
ref1 string,
ref2 string,
ref3 string,
clase_doc string,
cuenta_partida string,
cuenta_contrapartida string,
fecha_proceso string,
fecha_hora_generacion string,
aaaamm_ajuste string,
fecha_ajuste string,
etl_generadora string
)
partitioned by (year smallint, month smallint, day smallint)
stored as parquet tblproperties('transactional'='false')
;

create table if not exists {zona_r}.control_fuentes_ajustesifrs
(
tabla string,
conteo bigint,
validacion string,
fecha_proceso string,
fecha_hora_generacion string,
aaaamm_ajuste string,
fecha_ajuste string
)
partitioned by (year smallint, month smallint, day smallint)
stored as parquet tblproperties('transactional'='false')