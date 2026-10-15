# Estado del desarrollo y pendientes

Estado de la ETL `an0016001-gsfc-compensacionprovision` al 14/10/2026: qué está construido, de dónde viene cada parte, qué decisiones se tomaron y qué falta ajustar, con los archivos donde se hace cada ajuste.

Para entender cómo se ejecuta el código ver [flujo_orquestador2.md](flujo_orquestador2.md).

## Contenido

1. [Resumen](#resumen)
2. [Historia](#historia)
3. [Lo construido](#lo-construido)
4. [Origen de cada parte](#origen-de-cada-parte)
5. [Decisiones tomadas](#decisiones-tomadas)
6. [Pendientes](#pendientes)
7. [Detalle de cada pendiente](#detalle-de-cada-pendiente)

---

## Resumen

| Aspecto | Estado |
|---|---|
| Estructura del paquete (plantilla oficial del orquestador) | Completa |
| Nombre del paquete | Definido: `an0016001-gsfc-compensacionprovision` |
| Lógica de negocio (query del usuario funcional) | Completa, en 4 archivos SQL |
| Tablas temporales | Completas, en `proceso_vspc_finanzas` con prefijo `temp_` y `transactional=false` |
| Generación de logs de calendarización | Resuelta con argumentos de `ejecucion.py` (`-lt est`, `-lt cmp -pl n`) |
| Primera ejecución de esta versión en el PC corporativo | **Pendiente** |
| Tabla final en zona de resultados | **Pendiente de definición** |
| README | **Pendiente**: tiene las secciones de la plantilla sin llenar |
| Logs de calendarización (3 `est_` y 3 `cmp_`) | **Pendiente**; requiere ejecuciones reales |

El flujo de esta versión se verificó fuera de la LZ: se ejecutó la clase `ExtractTransformLoad` con el orquestador y el `helper` simulados, con y sin el argumento `-zp`, y todas las sentencias SQL se generan correctamente. No se ha ejecutado contra Impala.

---

## Historia

| Fecha | Versión | Carpeta | Estado |
|---|---|---|---|
| 13/10/2026 | Primera versión, sobre la estructura de la ETL de ejemplo `gsfc-correlatividadmod` | `compensa_provision/` | Probada en el PC corporativo con resultado correcto. Se conserva como referencia hasta validar la versión actual |
| 14/10/2026 | Versión actual, sobre la plantilla oficial del orquestador | `AN0016001-gsfc-compensacionprovision/` | Pendiente de primera ejecución |

La lógica (archivos SQL, tareas y configuración) es la misma de la primera versión. La única diferencia funcional es que las tablas temporales ahora se crean con `TBLPROPERTIES ('transactional'='false')`.

---

## Lo construido

```
AN0016001-gsfc-compensacionprovision/
├── .editorconfig · .pypirc · setup.py · setup.cfg · MANIFEST.in · versioneer.py · README.md
├── doc/
│   ├── estado_y_pendientes.md         Este documento
│   └── flujo_orquestador2.md          Funcionamiento del código y del orquestador
└── src/an0016001_gsfc_compensacionprovision/
    ├── __init__.py · _version.py · ejecucion.py · etl.py
    └── static/
        ├── config.json
        └── sql/etl/
            ├── 01_ceautoedt_base.sql
            ├── 02_allinf_contable.sql
            ├── 03_peq_bvl_sap.sql
            ├── 04_consolidado_homologacion_sap.sql
            └── 999_limpieza.sql
```

Las carpetas `logs/` y `logs_calendarizacion/` las crea `ejecucion.py` en el directorio desde donde se ejecuta.

| Archivo SQL | Genera | A partir de |
|---|---|---|
| `01_ceautoedt_base.sql` | `temp_ceautoedt_base` | `proceso_vspc_finanzas.visionr_ceautoedt` (mes actual) |
| `02_allinf_contable.sql` | `temp_allinf_contable` | `s_apoyo_financiero.ccsap_visionr_allinf` (última ingestión) |
| `03_peq_bvl_sap.sql` | `temp_peq_bvl_sap` | `s_productos.peqc_pequiv_vw_cache_peq` (día 1 del mes, BVG → SAP-FI) |
| `04_consolidado_homologacion_sap.sql` | `temp_consolidado_homologacion_sap` | Las tres temporales anteriores |
| `999_limpieza.sql` | — | Borra `temp_ceautoedt_base`, `temp_allinf_contable` y `temp_peq_bvl_sap` |

Salida actual de la rutina: `proceso_vspc_finanzas.temp_consolidado_homologacion_sap`.

---

## Origen de cada parte

| Archivo | Origen | Cambios respecto al origen |
|---|---|---|
| `setup.py`, `setup.cfg`, `versioneer.py`, `_version.py`, `.pypirc`, `.editorconfig`, `__init__.py` | Plantilla | Ninguno |
| `ejecucion.py` | Plantilla | Ninguno |
| `README.md` | Plantilla | Ninguno (pendiente) |
| `MANIFEST.in` | Plantilla | Ruta de los SQL: `static/sql/ExtractTransformLoad/` → `static/sql/etl/` |
| `etl.py` | Plantilla + primera versión | Se conserva la clase `ExtractTransformLoad` y sus métodos (`obtener_ruta`, `obtener_params`, `ejecutar_modulos`). Se agregan `ultima_ingestion` y `fn_ejecutar_etl` de la primera versión, y `ejecutar` se ajusta para reunir los parámetros de `obtener_params` con la configuración del paso |
| `static/config.json` | Primera versión | Estructura de la primera versión. El bloque del paso se llama `ExtractTransformLoad` (nombre de la clase), `zona_p` pasa a `zona_procesamiento` y `nom_proyecto` toma el nombre definitivo |
| `static/sql/etl/*.sql` | Primera versión | `{zona_p}` → `{zona_procesamiento}`, `TBLPROPERTIES ('transactional'='false')` en las 4 temporales y encabezados con el formato de la plantilla |
| `static/sql/ExtractTransformLoad/` (consultas de muestra de la plantilla) | Plantilla | Eliminada |

---

## Decisiones tomadas

| Tema | Decisión | Dónde se refleja |
|---|---|---|
| Uso de la plantilla | Se usa como base: se conservan los archivos de empaquetado y `ejecucion.py`; la configuración y la lógica vienen de la primera versión, ya probada | Todo el paquete |
| Origen de la lógica | Query validada por el usuario funcional, sin cambios en reglas, filtros ni cruces | `static/sql/etl/01` a `04` |
| Orden de ejecución de los SQL | Lista `archivos` del config (no el orden alfabético de una carpeta) | `config.json` → `ExtractTransformLoad.archivos` |
| Nombre del parámetro de zona de las temporales | `zona_procesamiento`, para que el argumento `-zp` de `ejecucion.py` pueda cambiarla | `config.json`; todos los SQL |
| Prefijo de temporales | `temp` mediante `indice` (`{zona_procesamiento}.{indice}_nombre`); no se usa el `prefijo: "tmp_"` de la plantilla | `config.json` → `indice` |
| Propiedad `transactional` | Temporales con `TBLPROPERTIES ('transactional'='false')`, estándar de la plantilla (en la primera versión faltaba) | `01` a `04` |
| Última versión del maestro ALLINF | Tarea `ultima_ingestion` (en lugar del CTE `ultima_version` de la query original). Toma la partición más reciente consultando solo metadatos y registra en el log la fecha usada | `etl.py`; `config.json` → `tablas.ALLINF`; `02_allinf_contable.sql` |
| Fechas en los SQL | `YEAR(NOW())` / `MONTH(NOW())`, como la query validada. Los argumentos `-y -m -d` de `ejecucion.py` no las afectan | `01`, `03`, `04` |
| Suma mensual de `visionr_ceautoedt` | Se suman todas las particiones del mes; es correcto porque la carga de CEAUTOEDT se ejecuta una sola vez al mes | `01_ceautoedt_base.sql` |
| Salida mientras no exista tabla final | `temp_consolidado_homologacion_sap`; la limpieza no la borra | `999_limpieza.sql` |
| DSN | `Impala-cdp-kudu` con `useSparky: false` | `config.json` → `global` |
| Método `ejecutar_modulos` de la plantilla | Se conserva sin uso; no está en `tareas` | `etl.py` |

---

## Pendientes

| # | Pendiente | Archivos a modificar | Depende de |
|---|---|---|---|
| 1 | Primera ejecución de esta versión y validación | `static/config.json` (DSN local, si aplica) | Acceso al PC corporativo |
| 2 | Tabla final en zona de resultados | Nuevos `00_crear_tablas_resultado.sql` y `05_insert_resultados.sql`; `static/config.json`; `999_limpieza.sql` | Definición de nombre, zona y particionamiento |
| 3 | README | `README.md` | Pendientes 1 y 2 |
| 4 | Logs de calendarización | Ninguno (se generan con `ejecucion.py`) | Pendientes 1 y 2 resueltos |
| 5 | Alcance de CEAUTOE | `setup.py` (descripción) o SQL | Confirmación del usuario funcional |
| 6 | Retiro de la primera versión | Carpeta `compensa_provision/` | Pendiente 1 validado |

---

## Detalle de cada pendiente

### 1. Primera ejecución y validación

Desde la carpeta raíz del proyecto (la que contiene `src/`), preferiblemente en un ambiente virtual:

```bash
pip install -e .
python -m an0016001_gsfc_compensacionprovision.ejecucion
```

`global.dsn` tiene `Impala-cdp-kudu`. Si el DSN de Impala del equipo tiene otro nombre (por ejemplo `IMPALA_PROD`), se cambia para la prueba local.

**Validación.** La salida debe coincidir con la de la primera versión (`compensa_provision`) si ambas se ejecutan con los mismos datos (mismo mes y misma versión de ALLINF). Como ambas generan las mismas tablas, se ejecuta una y se guardan los totales, y luego la otra:

```sql
SELECT COUNT(*) AS filas, SUM(monto_trx) AS total,
       COUNT(sap_cta_deb) AS con_sap_deb, COUNT(sap_cta_cre) AS con_sap_cre
FROM proceso_vspc_finanzas.temp_consolidado_homologacion_sap;
```

En el log, la línea `Buscando fechas para s_apoyo_financiero.ccsap_visionr_allinf ... resultado: {...}` indica qué versión de ALLINF se usó en cada ejecución.

### 2. Tabla final en zona de resultados

Requiere definir:

| Definición | Opciones / observaciones |
|---|---|
| Nombre de la tabla | — |
| Zona | `resultados_...` del equipo |
| Particionamiento | La salida ya calcula `year`, `month` y `day` (fecha de ejecución) |
| Reejecución | `INSERT INTO` acumula si se ejecuta dos veces; `INSERT OVERWRITE` reemplaza la partición |

Cambios a realizar una vez definido:

| Archivo | Cambio |
|---|---|
| `static/sql/etl/00_crear_tablas_resultado.sql` (nuevo) | `CREATE TABLE IF NOT EXISTS {zona_r}.<tabla_final>` con columnas, particiones y `tblproperties('transactional'='false')` |
| `static/sql/etl/05_insert_resultados.sql` (nuevo) | `INSERT ... PARTITION (...) SELECT ... FROM {zona_procesamiento}.{indice}_consolidado_homologacion_sap` y `COMPUTE INCREMENTAL STATS` de la tabla final |
| `static/config.json` | Agregar `"zona_r"` a `parametros_lz`. Agregar `etl/00_crear_tablas_resultado.sql` al inicio de `archivos` y `etl/05_insert_resultados.sql` antes de `etl/999_limpieza.sql` |
| `static/sql/etl/999_limpieza.sql` | Agregar `DROP TABLE IF EXISTS {zona_procesamiento}.{indice}_consolidado_homologacion_sap PURGE;` |

Propuesta de estructura, sujeta a la definición anterior:

```sql
-- 00_crear_tablas_resultado.sql
create table if not exists {zona_r}.<tabla_final>
(
    concepto_contable     string,
    codigo_contable       string,
    monto_trx             decimal(38,2),
    bvl_cta_deb           string,
    sap_cta_deb           string,
    bvl_cta_cre           string,
    sap_cta_cre           string
)
partitioned by (year smallint, month smallint, day smallint)
stored as parquet tblproperties('transactional'='false')
;
```

```sql
-- 05_insert_resultados.sql
INSERT OVERWRITE {zona_r}.<tabla_final>
PARTITION (year, month, day)
SELECT
    concepto_contable,
    codigo_contable,
    monto_trx,
    bvl_cta_deb,
    sap_cta_deb,
    bvl_cta_cre,
    sap_cta_cre,
    CAST(year AS smallint) AS year,
    CAST(month AS smallint) AS month,
    CAST(day AS smallint) AS day
FROM {zona_procesamiento}.{indice}_consolidado_homologacion_sap
;
COMPUTE INCREMENTAL STATS {zona_r}.<tabla_final>
;
```

### 3. README

El `README.md` tiene la estructura estándar de la plantilla. Falta:

| Sección | Qué completar |
|---|---|
| Prerrequisitos | Alinear con `setup.py`: el README menciona `orquestador2>=1.2.2` y `setup.py` exige `orquestador2>=1.4.0` |
| Insumos y resultados | Reemplazar las filas de ejemplo (`_zone_x_`, `_table_y_`) por los insumos (`visionr_ceautoedt`, `ccsap_visionr_allinf`, `peqc_pequiv_vw_cache_peq`) y la tabla final con su descripción y tipo de ingestión |

### 4. Logs de calendarización

Se requieren 3 logs de estabilidad y 3 de compilación. Se generan desde la carpeta raíz del proyecto (`ejecucion.py` valida que exista `src/` en el directorio actual):

```bash
python -m an0016001_gsfc_compensacionprovision.ejecucion -lt est
python -m an0016001_gsfc_compensacionprovision.ejecucion -lt cmp -pl 10
```

| Tipo | Argumentos | Qué cambia en la ejecución |
|---|---|---|
| Estabilidad | `-lt est` | Ejecución completa; el log queda en `logs_calendarizacion/` |
| Compilación | `-lt cmp -pl <1-100>` | El `helper` agrega `TABLESAMPLE SYSTEM(<pl>)` a las tablas fuente de zona cruda o de resultados, para procesar solo ese porcentaje de los datos. A las tablas de zona de proceso (como `visionr_ceautoedt` en `proceso_vspc_finanzas` y las temporales) no se les aplica y se registra una advertencia. El log queda en `logs_calendarizacion/` |

Conviene generarlos después de resolver los pendientes 1 y 2, para que reflejen la versión final.

### 5. Alcance de CEAUTOE

La descripción del paquete en `setup.py` (y en el README) dice *"Consolida movimientos de CEAUTOEDT y CEAUTOE..."*, pero la query del usuario funcional solo usa `visionr_ceautoedt`. Si la ETL debe incluir CEAUTOE, se requiere su regla en un SQL nuevo o en `01_ceautoedt_base.sql`; si no, se ajusta la descripción.

### 6. Retiro de la primera versión

Cuando esta versión quede validada, la carpeta `compensa_provision/` deja de ser necesaria. Su documentación (`compensa_provision/doc/`) describe la plantilla anterior.
