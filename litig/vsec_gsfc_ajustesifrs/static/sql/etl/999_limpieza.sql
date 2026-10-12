-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Entorno al Servicio de Funciones Corporativas
-----------------------------------------------------------------------------
-- Fecha Creación: 20250721
-- Última Fecha Modificación: 20250721
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Depuración de las tablas temporales asociadas al paso
--              o a toda la rutina según aplique.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------
-- TEMPORALES QUE DEBAN SER DEPURADAS
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_1 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_2 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_3 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_4 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_5 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_6 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_7 PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_condonaciones_bvl PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_8 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_1 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_55 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_2 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_3 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_4 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_5 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_6 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_7 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_8 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_9 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_10 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_11 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_12 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_13 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_14 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_15 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_16 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_17 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_control_fuentes_ajustesifrs_18 PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_ajustes_ifrs_int_sus_bvl_pyg PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_cond_int_sus_bvl_pyg PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_9 PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_int_suspenso_sufi_ant PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_10 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_11 PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_mora_balance_sufi_ant PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_12 PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_lista_plan_reest_castigos PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_maestro_eventos_reest_castigos PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_base_cuentas_reclasificacion_ifrs PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_maestro_contable_ajuste_ifrs PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_maestro_bin_clasif_ifrs PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_fechas_no_hab_siil17_act PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_fechas_no_hab_siil17_ant PURGE;
DROP TABLE IF EXISTS {zona_p}.temp_validacion_siil17_antPURGE;
DROP TABLE IF EXISTS {zona_p}.temp_validacion_siil17_act PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ajuste_ifrs_2 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_1 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_2 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_3 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ctr_fuentes_4 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ctr_fuentes PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_u_consolidado_ajuste_ifrs_1 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_99 PURGE;
DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_ajuste_ifrs_100 PURGE;
--------------------------------- Query End ---------------------------------