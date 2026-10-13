# Introducción

Esta ETL consolida los movimientos contables del mes registrados en `VISIONR.CEAUTOEDT` por concepto y código contable, y los asocia con las cuentas débito y crédito de BankVision definidas en el maestro contable (ALLINF). Posteriormente homologa esas cuentas de BankVision a sus cuentas equivalentes en SAP-FI.

# Objetivo

Generar, para cada concepto y código contable, el monto consolidado del mes junto con sus cuentas débito y crédito en BankVision y en SAP-FI, de forma trazable y repetible, con base en la definición validada por el usuario funcional.

# Impactos técnicos

La rutina se ejecuta una vez al mes y se construye sobre la estructura de `orquestador2` para poder ser calendarizada.

# Estado actual

La rutina finaliza en la tabla temporal `{zona_p}.temp_consolidado_homologacion_sap`. Están pendientes:

| Pendiente | Impacto en el código |
|---|---|
| Tabla final en zona de resultados | Agregar `00_crear_tablas_resultado.sql` (creación) y `05_insert_resultados.sql` (inserción y estadísticas), registrarlos en `archivos` de `static/config.json`, agregar `zona_r` a `parametros_lz` y agregar el borrado de `temp_consolidado_homologacion_sap` en `999_limpieza.sql` |
| Nombre definitivo del paquete (código AN) | Renombrar `src/compensa_provision` y actualizar el nombre en `setup.py`, `setup.cfg`, `MANIFEST.in`, `_version.py` (`versionfile_source`), `ejecucion.py` (`nom_proyecto`) y `static/config.json` (`nom_proyecto`) |
| Logs de calendarización | Ejecutar la rutina y ubicar 3 logs de compilación (`cmp_`) y 3 de estabilidad (`est_`) en `logs_calendarizacion/` |

# Fuentes

| Fuente | Campos usados | Filtros |
|---|---|---|
| `proceso_vspc_finanzas.visionr_ceautoedt` | `concepto_contable`, `codigo_contable`, `monto_trx` | `ingestion_year = YEAR(NOW())`, `ingestion_month = MONTH(NOW())` |
| `s_apoyo_financiero.ccsap_visionr_allinf` | `hatpgl`, `hatprc`, `hanoda`, `hanoca` | Última ingestión disponible (`year`, `ingestion_month`, `ingestion_day`), calculada por el orquestador |
| `s_productos.peqc_pequiv_vw_cache_peq` | `valor_dato_origen`, `valor_dato_destino` | `YEAR = YEAR(NOW())`, `ingestion_month = MONTH(NOW())`, `ingestion_day = 1`, `codigo_aplicacion_origen = 'BVG'`, `codigo_aplicacion_destino = 'SAP-FI'` |

`visionr_ceautoedt` es cargada desde la Nacional (AS/400) por el proceso de carga de `VISIONR.CEAUTOEDT` a la LZ.

# Tablas generadas

Todas se crean en `{zona_p}` con el prefijo `{indice}` (`proceso_vspc_finanzas.temp_...`).

### temp_ceautoedt_base

Monto de las transacciones del mes actual agrupado por concepto y código contable.

| Campo | Tipo | Regla | Descripción |
|---|---|---|---|
| `concepto_contable` | `STRING` | `CAST(concepto_contable AS STRING)` | Concepto contable asociado al movimiento o a la parametrización contable |
| `codigo_contable` | `STRING` | `CAST(codigo_contable AS STRING)` | Código de la cuenta o clasificación contable utilizada para relacionar la información |
| `monto_trx` | `DECIMAL(38,2)` | `CAST(SUM(monto_trx) AS DECIMAL(38,2))` | Valor monetario de las transacciones, consolidado por concepto y código contable |

### temp_allinf_contable

Cuentas débito y crédito de BankVision por código y concepto contable, de la última versión del maestro contable.

| Campo | Tipo | Origen | Descripción |
|---|---|---|---|
| `codigo_contable` | `STRING` | `hatpgl` | Código contable del maestro de información contable |
| `concepto_contable` | `STRING` | `hatprc` | Concepto contable del maestro de información contable |
| `bvl_cta_deb` | `STRING` | `hanoda` | Cuenta débito de BankVision asociada al código y concepto contable |
| `bvl_cta_cre` | `STRING` | `hanoca` | Cuenta crédito de BankVision asociada al código y concepto contable |

### temp_peq_bvl_sap

Equivalencias únicas de cuentas de BankVision (BVG) hacia SAP-FI.

| Campo | Tipo | Descripción |
|---|---|---|
| `valor_dato_origen` | `STRING` | Cuenta de BankVision que se busca homologar |
| `valor_dato_destino` | `STRING` | Cuenta equivalente en SAP-FI |

### temp_consolidado_homologacion_sap

Salida actual de la rutina.

| Campo | Tipo | Regla | Descripción |
|---|---|---|---|
| `concepto_contable` | `STRING` | `base.concepto_contable` | Concepto contable del consolidado |
| `codigo_contable` | `STRING` | `base.codigo_contable` | Código contable del consolidado |
| `monto_trx` | `DECIMAL(38,2)` | `base.monto_trx` | Monto consolidado del mes |
| `bvl_cta_deb` | `STRING` | `allinf.bvl_cta_deb` | Cuenta débito de BankVision |
| `sap_cta_deb` | `STRING` | `peq_deb.valor_dato_destino` | Cuenta débito homologada en SAP-FI |
| `bvl_cta_cre` | `STRING` | `allinf.bvl_cta_cre` | Cuenta crédito de BankVision |
| `sap_cta_cre` | `STRING` | `peq_cre.valor_dato_destino` | Cuenta crédito homologada en SAP-FI |
| `day` | `INT` | `DAY(CURRENT_DATE())` | Día de ejecución del proceso |
| `month` | `INT` | `MONTH(CURRENT_DATE())` | Mes de ejecución del proceso |
| `year` | `INT` | `YEAR(CURRENT_DATE())` | Año de ejecución del proceso |

# Reglas de cruce

| Orden | Tabla principal | Tabla secundaria | Regla | Tipo |
|---|---|---|---|---|
| 1 | `temp_ceautoedt_base` | `temp_allinf_contable` | `codigo_contable` y `concepto_contable` iguales | `LEFT JOIN`: conserva todos los montos y agrega las cuentas de BankVision cuando existen |
| 2 | Resultado anterior | `temp_peq_bvl_sap` (`peq_deb`) | `allinf.bvl_cta_deb = peq_deb.valor_dato_origen` | `LEFT JOIN`: homologa la cuenta débito a SAP-FI |
| 3 | Resultado anterior | `temp_peq_bvl_sap` (`peq_cre`) | `allinf.bvl_cta_cre = peq_cre.valor_dato_origen` | `LEFT JOIN`: homologa la cuenta crédito a SAP-FI |

El detalle completo de fuentes, filtros y reglas está en la hoja de vida de la rutina (`Hoja_de_vida_compensa_provision.xlsx`).

# Componentes

### .pypirc
Archivo de configuración con la información necesaria para que Azure DevOps despliegue en Artifactory la librería.

### MANIFEST.in
Determina cuáles archivos componen el paquete y deben incluirse: `.sql`, `.json` y archivos de versionamiento.

### versioneer.py
Librería que maneja automáticamente las versiones del paquete a partir de git.

### setup.cfg
Configuración del paquete: nombre, autor, versión mínima de Python, dependencias (`orquestador2`), ubicación del código (`src`), archivos de datos incluidos y punto de entrada.

### setup.py
Indica a `pip` cómo construir el paquete y obtiene la versión con versioneer.

### src/compensa_provision/

| Archivo | Función |
|---|---|
| `ejecucion.py` | Desencadena la ejecución: crea las carpetas `logs/` y `logs_calendarizacion/` y ejecuta el `Orchestrator` con el paso `Etl` |
| `etl.py` | Clase `Etl` (paso del orquestador). Ejecuta las tareas definidas en `static/config.json`: `ultima_ingestion` y `fn_ejecutar_etl` |
| `__init__.py` | Expone la clase `Etl` y la versión del paquete |
| `_version.py` | Archivo de versioneer para obtener la versión del paquete |
| `static/config.json` | Configuración general: conexión, parámetros de zonas, tareas, archivos SQL a ejecutar en orden y tablas para última ingestión |

### src/compensa_provision/static/sql/etl/

| Archivo | Función |
|---|---|
| `01_ceautoedt_base.sql` | Consolida por concepto y código contable el monto de las transacciones del mes actual de `visionr_ceautoedt` |
| `02_allinf_contable.sql` | Extrae del maestro contable la última versión de las cuentas débito y crédito de BankVision |
| `03_peq_bvl_sap.sql` | Obtiene las equivalencias de cuentas BankVision → SAP-FI del día 1 del mes actual |
| `04_consolidado_homologacion_sap.sql` | Cruza los resultados anteriores y genera el consolidado homologado |
| `999_limpieza.sql` | Borra las tablas temporales intermedias |

# Flujo de ejecución

1. `ejecucion.ejecutar()` crea el `Orchestrator` con el paso `Etl`.
2. El orquestador lee el bloque `global` de `static/config.json`, se conecta a la LZ con el DSN configurado e inicia el log.
3. `Etl.ejecutar()` reúne los parámetros de `parametros_lz` con el bloque `Etl` y ejecuta las tareas en orden:
   - `ultima_ingestion`: consulta la última partición de cada tabla del diccionario `tablas` y la deja disponible como parámetro. Para `ALLINF` genera `{ALLINF[year]}`, `{ALLINF[month]}` y `{ALLINF[day]}`, usados en `02_allinf_contable.sql`.
   - `fn_ejecutar_etl`: ejecuta en orden los archivos de `archivos`, reemplazando los parámetros (`{zona_p}`, `{indice}`, etc.).

# Parámetros

`static/config.json` → `global.parametros_lz`:

| Parámetro | Valor | Uso |
|---|---|---|
| `nom_proyecto` | `compensa-provision` | Nombre del proyecto |
| `indice` | `temp` | Prefijo de las tablas temporales |
| `zona_p` | `proceso_vspc_finanzas` | Zona donde se crean las tablas temporales |
| `zona_ceautoedt` | `proceso_vspc_finanzas` | Zona de la tabla `visionr_ceautoedt` |
| `zona_s_apoyo_financiero` | `s_apoyo_financiero` | Zona del maestro contable ALLINF |
| `zona_s_productos` | `s_productos` | Zona de la tabla de equivalencias |

`static/config.json` → `Etl.tablas`: tablas a las que se les calcula la última ingestión. Si cambia la zona de ALLINF, se debe actualizar tanto `zona_s_apoyo_financiero` como la ruta en `tablas`.

# Ejecución

El paquete se instala como librería y se ejecuta el módulo `ejecucion`:

```bash
pip install -e .
python -m compensa_provision.ejecucion
```

Requiere `orquestador2` (se instala como dependencia desde Artifactory) y el DSN configurado en `global.dsn`.

# Log y manejo de errores

La rutina genera en la carpeta `logs/` un archivo `aaaammdd_hhmmss_compensa_provision.log` con las sentencias ejecutadas, la hora de inicio y la duración de cada tarea y consulta. La búsqueda de la última ingestión de ALLINF queda registrada con la fecha encontrada.

La carpeta `logs_calendarizacion/` contiene las evidencias para la calendarización: 3 logs de compilación (`cmp_aaaammdd_hhmmss_compensa_provision.log`) y 3 logs de estabilidad (`est_aaaammdd_hhmmss_compensa_provision.log`).
