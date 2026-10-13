-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia Corporativa Grupo Bancolombia
-----------------------------------------------------------------------------
-- Fecha Creación: 20250613
-- Última Fecha Modificación: 20250613
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Depuración de las tablas temporales asociadas al paso
--              o a toda la rutina según aplique.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-- proceso.temporal_ads_package_gen 
--------------------------------- RESULTADOS --------------------------------
-- 
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------

-- ESTO ES SOLO UNA CONSULTA DE MUESTRA, SE DEBEN COLOCAR TODAS LAS TABLAS
-- TEMPORALES QUE DEBAN SER DEPURADAS
DROP TABLE IF EXISTS {zona_p}.{indice}_info_saldos_diarios_fcr_mod purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_saldos_diarios_fcr_correlatividades_mod purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_castigos_excentos_mod purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_cm_hipotecario_mod purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_inte_suspe_sufi purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_castigos_otros_a_mod_1 purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_ventas_otros_apli purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_castigos_otros_a_mod purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_correlatividades_modificado_ini purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_correlatividades_modificado_ini_2 purge;
DROP TABLE IF EXISTS {zona_p}.{indice}_info_correlatividades_modificado purge;
--------------------------------- Query End ---------------------------------