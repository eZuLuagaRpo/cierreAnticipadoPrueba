-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Crea de cero la tabla temporal donde se reciben los lotes de
--              la Nacional. Todo es texto; los tipos se aplican al pasar a la
--              tabla final (04_insertar_resultado.sql).
-------------------------------- Query Start --------------------------------
DROP TABLE IF EXISTS {zona_p}.{tabla_temporal} PURGE;

create table {zona_p}.{tabla_temporal}
(
    cod_aplicacion      string,
    concepto_contable   string,
    codigo_contable     string,
    fecha_efectiva      string,
    monto_trx           string,
    oficina_contable    string,
    oficina_origen      string,
    cod_moneda          string,
    tasa_cambio         string,
    monto_equivalente   string
)
stored as parquet tblproperties('transactional'='false')
;
