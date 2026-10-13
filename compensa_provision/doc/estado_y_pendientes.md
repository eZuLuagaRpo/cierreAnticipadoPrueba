# Estado del desarrollo y pendientes

Estado de la ETL `compensa_provision` al 13/10/2026: qué está construido, qué decisiones se tomaron y qué falta ajustar, con los archivos donde se hace cada ajuste.

Para entender cómo se ejecuta el código ver [flujo_orquestador2.md](flujo_orquestador2.md).

## Contenido

1. [Resumen](#resumen)
2. [Lo construido](#lo-construido)
3. [Decisiones tomadas](#decisiones-tomadas)
4. [Pendientes](#pendientes)
5. [Detalle de cada pendiente](#detalle-de-cada-pendiente)

---

## Resumen

| Aspecto | Estado |
|---|---|
| Estructura del paquete (orquestador2) | Completa, replicada de `gsfc-correlatividadmod` |
| Lógica de negocio (query del usuario funcional) | Completa, en 4 archivos SQL |
| Tablas temporales | Completas, en `proceso_vspc_finanzas` con prefijo `temp_` |
| Tabla final en zona de resultados | **Pendiente de definición** |
| Nombre definitivo del paquete (código AN) | **Pendiente**; se usa `compensa_provision` de forma provisional |
| Primera ejecución en el PC corporativo | **Pendiente** |
| Logs de calendarización (3 `cmp_` y 3 `est_`) | **Pendiente**; requiere ejecuciones reales |

La construcción de los SQL se verificó fuera de la LZ: se simuló el procesamiento que hace el orquestador (eliminación de comentarios, reemplazo de parámetros y separación de sentencias) y todas las sentencias se generan correctamente. No se ha ejecutado contra Impala.

---

## Lo construido

```
compensa_provision/
├── .pypirc · setup.py · setup.cfg · MANIFEST.in · versioneer.py · README.md
├── doc/
│   ├── estado_y_pendientes.md         Este documento
│   └── flujo_orquestador2.md          Funcionamiento del código y del orquestador
├── logs_calendarizacion/              Evidencias de calendarización (vacía)
└── src/compensa_provision/
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

| Archivo SQL | Genera | A partir de |
|---|---|---|
| `01_ceautoedt_base.sql` | `temp_ceautoedt_base` | `proceso_vspc_finanzas.visionr_ceautoedt` (mes actual) |
| `02_allinf_contable.sql` | `temp_allinf_contable` | `s_apoyo_financiero.ccsap_visionr_allinf` (última ingestión) |
| `03_peq_bvl_sap.sql` | `temp_peq_bvl_sap` | `s_productos.peqc_pequiv_vw_cache_peq` (día 1 del mes, BVG → SAP-FI) |
| `04_consolidado_homologacion_sap.sql` | `temp_consolidado_homologacion_sap` | Las tres temporales anteriores |
| `999_limpieza.sql` | — | Borra `temp_ceautoedt_base`, `temp_allinf_contable` y `temp_peq_bvl_sap` |

Salida actual de la rutina: `proceso_vspc_finanzas.temp_consolidado_homologacion_sap`.

---

## Decisiones tomadas

| Tema | Decisión | Dónde se refleja |
|---|---|---|
| Origen de la lógica | Query validada por el usuario funcional, sin cambios en reglas, filtros ni cruces | `static/sql/etl/01` a `04` |
| Nombres de zonas | Parametrizados en vez de fijos en el SQL | `config.json` → `parametros_lz` |
| Prefijo de temporales | `temp` (la query original usaba `tmp_`) | `config.json` → `indice` |
| Última versión del maestro ALLINF | Mecanismo `ultima_ingestion` del orquestador en lugar del CTE `ultima_version` de la query original. Ambos toman la partición más reciente; el del orquestador consulta solo metadatos y registra en el log la fecha usada | `config.json` → `Etl.tablas.ALLINF`; `02_allinf_contable.sql` |
| Suma mensual de `visionr_ceautoedt` | Se suman todas las particiones del mes. Es correcto porque la carga de CEAUTOEDT se ejecuta una sola vez al mes | `01_ceautoedt_base.sql` |
| Salida mientras no exista tabla final | `temp_consolidado_homologacion_sap`; la limpieza no la borra | `999_limpieza.sql` |
| Documentación | Sin imágenes en `doc/`; las tablas se documentan en texto | `README.md` |
| Autor | Emanuel Zuluaga Restrepo — emzulu@bancolombia.com.co | `setup.cfg`, encabezados (`emzulu`) |
| Entry point | Apunta a `ejecucion:ejecutar` (en el ejemplo apuntaba a una función `main` inexistente) | `setup.cfg` |

---

## Pendientes

| # | Pendiente | Archivos a modificar | Depende de |
|---|---|---|---|
| 1 | Primera ejecución y validación contra la query original | `static/config.json` (DSN local, si aplica) | Acceso al PC corporativo |
| 2 | Tabla final en zona de resultados | Nuevos `00_crear_tablas_resultado.sql` y `05_insert_resultados.sql`; `static/config.json`; `999_limpieza.sql`; `README.md` | Definición de nombre, zona y particionamiento |
| 3 | Nombre definitivo del paquete | `src/compensa_provision/` (carpeta), `setup.py`, `setup.cfg`, `MANIFEST.in`, `_version.py`, `ejecucion.py`, `static/config.json`, `README.md` | Código AN asignado |
| 4 | Logs de calendarización | `logs_calendarizacion/` | Pendientes 1 a 3 resueltos; procedimiento del equipo |
| 5 | Grupo de incidentes | `README.md` | Definición del grupo responsable |

---

## Detalle de cada pendiente

### 1. Primera ejecución y validación

**Ejecución en el PC corporativo**

```bash
pip install -e .
python -m compensa_provision.ejecucion
```

`global.dsn` en `static/config.json` tiene el valor de la plantilla (`Impala-cdp-kudu`). Si el DSN de Impala del equipo tiene otro nombre (por ejemplo `IMPALA_PROD`), se cambia para la prueba local. En la calendarización se usa el DSN del servidor.

**Validación contra la query original**

Si la query original y la ETL se ejecutan con los mismos datos (mismo mes y misma versión de ALLINF), sus salidas deben coincidir:

```sql
SELECT 'query_original' AS origen, COUNT(*) AS filas, SUM(monto_trx) AS total
FROM proceso_vspc_finanzas.tmp_consolidado_homologacion_sap
UNION ALL
SELECT 'etl', COUNT(*), SUM(monto_trx)
FROM proceso_vspc_finanzas.temp_consolidado_homologacion_sap;
```

En el log de la ejecución, la línea `Buscando fechas para s_apoyo_financiero.ccsap_visionr_allinf ... resultado: {...}` indica qué versión de ALLINF se usó.

### 2. Tabla final en zona de resultados

Requiere definir:

| Definición | Opciones / observaciones |
|---|---|
| Nombre de la tabla | — |
| Zona | `resultados_...` del equipo |
| Particionamiento | La salida ya calcula `year`, `month` y `day` (fecha de ejecución) |
| Reejecución | `INSERT INTO` acumula si se ejecuta dos veces (es lo que usa el ejemplo); `INSERT OVERWRITE` reemplaza la partición del día |

Cambios a realizar una vez definido:

| Archivo | Cambio |
|---|---|
| `static/sql/etl/00_crear_tablas_resultado.sql` (nuevo) | `CREATE TABLE IF NOT EXISTS {zona_r}.<tabla_final>` con columnas, particiones y `tblproperties('transactional'='false')` |
| `static/sql/etl/05_insert_resultados.sql` (nuevo) | `INSERT ... PARTITION (...) SELECT ... FROM {zona_p}.{indice}_consolidado_homologacion_sap` y `COMPUTE INCREMENTAL STATS` de la tabla final |
| `static/config.json` | Agregar `"zona_r"` a `parametros_lz`. Agregar `etl/00_crear_tablas_resultado.sql` al inicio de `archivos` y `etl/05_insert_resultados.sql` antes de `etl/999_limpieza.sql` |
| `static/sql/etl/999_limpieza.sql` | Agregar `DROP TABLE IF EXISTS {zona_p}.{indice}_consolidado_homologacion_sap PURGE;` |
| `README.md` | Documentar la tabla final en "Tablas generadas" y retirarla de "Estado actual" |

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
FROM {zona_p}.{indice}_consolidado_homologacion_sap
;
COMPUTE INCREMENTAL STATS {zona_r}.<tabla_final>
;
```

### 3. Nombre definitivo del paquete

El ejemplo sigue la convención `an<código>-gsfc-<nombre>` para el paquete y `an<código>_gsfc_<nombre>` para la carpeta de código. Al recibir el código AN se reemplaza `compensa_provision` / `compensa-provision` en:

| Archivo | Ubicación | Valor actual |
|---|---|---|
| `src/compensa_provision/` | Nombre de la carpeta | `compensa_provision` |
| `setup.py` | `name` | `compensa-provision` |
| `setup.cfg` | `[versioneer] versionfile_source` y `versionfile_build` | `src/compensa_provision/_version.py`, `compensa_provision/_version.py` |
| `setup.cfg` | `[metadata] name` | `compensa-provision` |
| `setup.cfg` | `[options.entry_points] console_scripts` | `compensa_provision = compensa_provision.ejecucion:ejecutar` |
| `MANIFEST.in` | Rutas de los `include` | `src/compensa_provision/...` |
| `src/.../_version.py` | `cfg.versionfile_source` (línea 46) | `src/compensa_provision/_version.py` |
| `src/.../ejecucion.py` | `nom_proyecto` | `compensa_provision` |
| `src/.../static/config.json` | `parametros_lz.nom_proyecto` | `compensa-provision` |
| `README.md` y `doc/` | Comando de ejecución y nombre del log | `python -m compensa_provision.ejecucion` |

`nom_proyecto` de `ejecucion.py` define el nombre de los archivos de log (`aaaammdd_hhmmss_<nom_proyecto>.log`).

### 4. Logs de calendarización

Se requieren 3 logs de compilación (`cmp_`) y 3 de estabilidad (`est_`) en `logs_calendarizacion/`. En la ETL de ejemplo, los 6 archivos son logs de ejecuciones completas y exitosas tomados de `logs/` y renombrados con el prefijo correspondiente (`cmp_aaaammdd_hhmmss_<nombre>.log`).

El orquestador acepta el parámetro `log_type` (`''`, `'cmp'`, `'est'`) al crear el `Orchestrator`; la ETL de ejemplo no lo usa en `ejecucion.py`. Está por confirmar con el equipo cuál de las dos formas se usa y qué diferencia se espera entre una ejecución de compilación y una de estabilidad.

Conviene generarlos después de resolver los pendientes 1 a 3, para que reflejen la versión final del paquete.

### 5. Grupo de incidentes

El README de la ETL de ejemplo termina con el grupo responsable del manejo de incidentes. Se agrega al final de `README.md` cuando se defina.
