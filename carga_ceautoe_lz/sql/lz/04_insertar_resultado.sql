-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Pasa los datos de la temporal a la tabla final aplicando los
--              tipos. INSERT OVERWRITE con partición dinámica: solo se
--              reemplaza la partición de hoy; los demás días no se tocan.
-------------------------------- Query Start --------------------------------
INSERT OVERWRITE TABLE {zona_r}.{tabla_resultado}
PARTITION (ingestion_year, ingestion_month, ingestion_day)

SELECT
    cod_aplicacion,
    concepto_contable,
    codigo_contable,
    CAST(TO_TIMESTAMP(fecha_efectiva, 'yyyyMMdd') AS DATE) AS fecha_efectiva,
    CAST(monto_trx AS DECIMAL(20,2)) AS monto_trx,
    oficina_contable,
    oficina_origen,
    cod_moneda,
    CAST(tasa_cambio AS DECIMAL(20,2)) AS tasa_cambio,
    CAST(monto_equivalente AS DECIMAL(20,2)) AS monto_equivalente,
    CAST(YEAR(CURRENT_DATE()) AS SMALLINT) AS ingestion_year,
    CAST(MONTH(CURRENT_DATE()) AS SMALLINT) AS ingestion_month,
    CAST(DAY(CURRENT_DATE()) AS SMALLINT) AS ingestion_day
FROM {zona_p}.{tabla_temporal}
;
