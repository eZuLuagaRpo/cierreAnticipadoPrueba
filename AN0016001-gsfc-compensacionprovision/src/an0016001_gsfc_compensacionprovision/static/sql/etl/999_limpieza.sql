-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Equipo VSEC SERVICIOS CORPORATIVOS
-----------------------------------------------------------------------------
-- Fecha Creación: 20261013
-- Última Fecha Modificación: 20261014
-- Autores: emzulu
-- Últimos Autores: emzulu
-- Descripción: Depuración de las tablas temporales intermedias de la rutina.
--              {zona_procesamiento}.{indice}_consolidado_homologacion_sap no se borra
--              porque por ahora es la salida de la rutina. Cuando exista la
--              tabla final en zona de resultados, se debe agregar aquí.
-----------------------------------------------------------------------------
---------------------------------- INSUMOS ----------------------------------
--
--------------------------------- RESULTADOS --------------------------------
--
-----------------------------------------------------------------------------
-------------------------------- Query Start --------------------------------
DROP TABLE IF EXISTS {zona_procesamiento}.{indice}_ceautoedt_base PURGE;
DROP TABLE IF EXISTS {zona_procesamiento}.{indice}_allinf_contable PURGE;
DROP TABLE IF EXISTS {zona_procesamiento}.{indice}_peq_bvl_sap PURGE;
--------------------------------- Query End ---------------------------------
