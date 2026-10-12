-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Consulta de la Nacional (AS/400) cuyo resultado se lleva a la LZ.
--              Se usa tal cual fue entregada y probada. El orden y los alias
--              de las columnas deben coincidir con la tabla temporal de la LZ.
-------------------------------- Query Start --------------------------------
SELECT
    CEAP65 as cod_aplicacion,
    CECO65 as concepto_contable,
    CECD65 as codigo_contable,
    CEFT65 as fecha_efectiva,
    CEMT65 as monto_trx,
    CESU65 as oficina_contable,
    CENS65 as oficina_origen,
    CEFC65 as cod_moneda,
    CETC65 as tasa_cambio,
    CEME65 as monto_equivalente
FROM VISIONR.CEAUTOE
