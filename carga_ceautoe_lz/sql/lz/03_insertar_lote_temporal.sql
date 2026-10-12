-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Inserta un lote de filas de la Nacional en la tabla temporal.
--              El programa reemplaza el marcador de valores con las filas
--              de cada lote. Debe ser una sola sentencia.
-------------------------------- Query Start --------------------------------
INSERT INTO {zona_p}.{tabla_temporal}
(
    cod_aplicacion,
    concepto_contable,
    codigo_contable,
    fecha_efectiva,
    monto_trx,
    oficina_contable,
    oficina_origen,
    cod_moneda,
    tasa_cambio,
    monto_equivalente
)
VALUES
{valores}
