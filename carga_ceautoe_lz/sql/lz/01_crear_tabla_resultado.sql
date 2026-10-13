-----------------------------------------------------------------------------
-- Fecha Creación: 20261012
-- Autores: Emanuel Zuluaga
-- Descripción: Crea la tabla final en la LZ si todavía no existe.
-------------------------------- Query Start --------------------------------
create table if not exists {zona_r}.{tabla_resultado}
(
    cod_aplicacion      string          comment 'Código de la aplicación origen que genera o registra la transacción contable.',
    concepto_contable   string          comment 'Concepto contable asociado al movimiento o transacción registrada.',
    codigo_contable     string          comment 'Código de la cuenta contable utilizada para el registro de la operación.',
    fecha_efectiva      date            comment 'Fecha efectiva en la que se reconoce o contabiliza la transacción.',
    monto_trx           decimal(20,2)   comment 'Valor monetario de la transacción registrada en la moneda de origen.',
    oficina_contable    string          comment 'Código de la oficina o unidad contable responsable del registro contable.',
    oficina_origen      string          comment 'Código de la oficina donde se originó la transacción.',
    cod_moneda          string          comment 'Código de la moneda en la que se realizó la transacción.',
    tasa_cambio         decimal(20,2)   comment 'Tasa de cambio aplicada para convertir el valor de la transacción a moneda equivalente.',
    monto_equivalente   decimal(20,2)   comment 'Valor equivalente de la transacción después de la conversión de moneda.'
)
partitioned by (
    ingestion_year      smallint        comment 'Año de ingestión de la información.',
    ingestion_month     smallint        comment 'Mes de ingestión de la información.',
    ingestion_day       smallint        comment 'Día de ingestión de la información.'
)
comment 'Copia de {tabla_origen} de la Nacional (AS/400).'
stored as parquet tblproperties('transactional'='false')
;
