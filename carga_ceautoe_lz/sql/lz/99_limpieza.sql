-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Borra la tabla temporal. Se ejecuta siempre al final, aunque
--              el proceso falle.
-------------------------------- Query Start --------------------------------
DROP TABLE IF EXISTS {zona_p}.{tabla_temporal} PURGE;
