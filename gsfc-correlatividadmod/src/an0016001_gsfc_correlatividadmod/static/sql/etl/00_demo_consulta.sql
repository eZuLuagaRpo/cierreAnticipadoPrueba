-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia Corporativa Grupo Bancolombia
-----------------------------------------------------------------------------
-- Fecha Creación: 20260316
-- Última Fecha Modificación: 20260316
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Depuración de las tablas temporales asociadas al paso
--              o a toda la rutina según aplique.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- resultados_vspc_clientes.master_customer_data
--------------------------------- RESULTADOS --------------------------------
-- proceso.temporal_ads_package_gen
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

-- ESTO ES SOLO UNA CONSULTA DE MUESTRA, SE DEBEN COLOCAR TODAS LAS CONSULTAS
-- Y PARÁMETROS ASOCIADOS A LA RUTINA
create table if not exists {zona_r}.saldo_cuentas_correlatividad_mod 
(
ingestion_year	smallint
,ingestion_month	smallint
,ingestion_day	smallint
,num_cuenta	string
,acum_loc_t	decimal(38,2)
,acum_loc_ant	decimal(38,2)
,variacion	decimal(38,2)
,proceso	string
,sub_proceso	string
,fecha_contab	string

)
partitioned by (year smallint)
stored as parquet tblproperties('transactional'='false')
;
---------------------------------------------------------------------------

create table if not exists {zona_r}.correlatividad_modificado
(
ingestion_year	smallint
,ingestion_month	smallint
,ingestion_day	smallint
,saldo_final_del_anio_anterior	decimal(38,2)
,saldo_final_del_anio_actual	decimal(38,2)
,provisiones_del_anio_actual	decimal(38,2)
,castigos_del_periodo	decimal(38,2)
,recuperaciones_del_anio_actual	decimal(38,2)
,otros_ajustes	double
,total	decimal(35,2)
,diferencia_final	decimal(35,2)
,correlatividad	string
,fecha_corte	string
)
partitioned by (year smallint)
stored as parquet tblproperties('transactional'='false')
;
----------------------------------------------------------------------------------------------
create table if not exists {zona_r}.correlatividad_mod_detalle
(
ingestion_year	smallint
,ingestion_month	smallint
,ingestion_day	smallint
,capital_castigado_excento	decimal(38,2)
,capital_castigado_no_excento	decimal(38,2)
,interes_castigado_excento	decimal(38,2)
,interes_castigado_no_excento	decimal(38,2)
,otros_castigo	decimal(38,2)
,capital_otros_ajustes	double
,interes_otros_ajustes	double
,otros_conceptos_ajustes	double
,cap_ao_lf	bigint
,int_ao_lf	bigint
,otros_ao_lf	bigint
,correcion_m_hip decimal(38,2)
,int_susp_leasing	bigint
,int_susp_sufi	bigint
,fecha_corte	string
,proceso	string
)
partitioned by (year smallint)
stored as parquet tblproperties('transactional'='false')
;
--------------------------------- Query End ---------------------------------