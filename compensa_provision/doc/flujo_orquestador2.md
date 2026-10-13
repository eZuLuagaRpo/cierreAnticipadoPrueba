# Flujo del código y funcionamiento de orquestador2

Este documento describe cómo se ejecuta la ETL `compensa_provision` sobre la librería `orquestador2`: qué hace cada pieza, en qué orden se llaman y cómo llegan la configuración y los parámetros a los archivos SQL.

La descripción de `orquestador2` y del `helper` se basa en el código de referencia disponible en la raíz del repositorio (`orquestador2/` y `helper.py`). La versión instalada en el ambiente de ejecución puede tener diferencias menores.

## Contenido

1. [Piezas de orquestador2](#piezas-de-orquestador2)
2. [Estructura del paquete](#estructura-del-paquete)
3. [Flujo completo de ejecución](#flujo-completo-de-ejecución)
4. [Configuración: static/config.json](#configuración-staticconfigjson)
5. [Parámetros en los SQL](#parámetros-en-los-sql)
6. [Ejecución de un archivo SQL](#ejecución-de-un-archivo-sql)
7. [Conexión a la LZ](#conexión-a-la-lz)
8. [Logs](#logs)
9. [Reintentos y errores](#reintentos-y-errores)
10. [Cómo extender la ETL](#cómo-extender-la-etl)

---

## Piezas de orquestador2

`orquestador2` es la librería interna que estandariza las ETL calendarizables. Se instala como dependencia del paquete (`install_requires = orquestador2>=1.2.5`).

| Pieza | Origen | Responsabilidad |
|---|---|---|
| `Orchestrator` | `orquestador2.orquestador2` | Lee la configuración global, crea el `Helper` y el `Logger`, y ejecuta en orden la lista de pasos (`steps`) |
| `Step` | `orquestador2.step` | Clase base de un paso. Da acceso al `Helper`, al log, a la configuración y ejecuta las tareas definidas en `config.json` |
| `Helper` | `helper.helper` (dependencia de orquestador2) | Conexión a Impala por ODBC, lectura y ejecución de archivos SQL, búsqueda de la última ingestión de una tabla |
| `Logger` | `orquestador2.logger` | Log en consola y en `logs/`, con el plan de tareas y la duración de cada consulta |
| `Emailer`, `Sparky` | `orquestador2` | Envío de correos y ejecución de Spark. Esta ETL no los usa (`useSparky: false`) |

En esta ETL solo hay código propio en dos archivos:

| Archivo | Contenido |
|---|---|
| `ejecucion.py` | Crea el `Orchestrator` con un único paso (`Etl`) y lo ejecuta |
| `etl.py` | Clase `Etl(Step)` con las tareas `ultima_ingestion` y `fn_ejecutar_etl` |

Todo lo demás (conexión, lectura de SQL, log, reintentos) lo resuelven `orquestador2` y el `Helper`, guiados por `static/config.json`.

---

## Estructura del paquete

La ETL es un paquete de Python instalable. Cada archivo de la raíz cumple una función en su construcción y publicación:

| Archivo | Función |
|---|---|
| `setup.py` | Construye el paquete; obtiene la versión con versioneer |
| `setup.cfg` | Nombre, autor, Python mínimo (`>=3.9.12`), dependencia `orquestador2`, ubicación del código (`src/`), archivos de datos incluidos y punto de entrada |
| `MANIFEST.in` | Incluye en el paquete los archivos que no son `.py`: `config.json`, los `.sql` y los archivos de versión |
| `versioneer.py`, `src/.../_version.py` | Calculan la versión del paquete a partir de los tags de git |
| `.pypirc` | Repositorio de Artifactory donde se publica el paquete |
| `src/compensa_provision/__init__.py` | Expone `Etl` y `__version__` |

El código vive en `src/compensa_provision/`. La carpeta `static/` va dentro del paquete porque el orquestador la busca junto al módulo de cada paso (ver [Flujo completo de ejecución](#flujo-completo-de-ejecución)).

---

## Flujo completo de ejecución

### Árbol de llamadas

```
python -m compensa_provision.ejecucion
└── ejecucion.ejecutar()
    ├── crea logs/ (directorio actual) y logs_calendarizacion/ (raíz del proyecto)
    └── Orchestrator("compensa_provision", [Etl()])
        │
        ├── __init__  ─────────────────────────────── preparación
        │   ├── __validateSteps(steps)                 cada paso debe heredar de Step
        │   └── __initializeSteps()
        │       ├── Etl.initGlobalConfiguration()      lee static/config.json → bloque "global"
        │       ├── __checkObligatoryKeys()            "dsn" es obligatorio
        │       ├── __resetParameters()                maxTries (1) y waitPeriod (600 s)
        │       ├── __initializeHelpers()
        │       │   ├── Logger(nombre)                 log en logs/
        │       │   └── Helper(**global)               useSparky=false → conexión ODBC con global.dsn
        │       └── Etl.setModules(helper, None, log, emailer, config_file)
        │           └── setConfiguration()             lee static/config.json → bloque "Etl"
        │
        └── ejecutar()  ───────────────────────────── ejecución
            ├── registro de inicio
            ├── por cada paso (solo Etl):
            │   ├── Etl.setPayload(payload anterior)   None para el primer paso
            │   ├── __reStarter(Etl)                   → Etl.ejecutar(), con reintentos
            │   │   └── Etl.ejecutar()
            │   │       ├── params = global.parametros_lz + bloque "Etl"
            │   │       ├── self.hp = helper ; self.list_sql_file = Etl.archivos
            │   │       └── executeTasks()             ejecuta Etl.tareas en orden
            │   │           ├── ultima_ingestion()
            │   │           │   ├── helper.obtener_ultima_ingestion("s_apoyo_financiero.ccsap_visionr_allinf")
            │   │           │   ├── params["ALLINF"] = {"year": ..., "month": ..., "day": ...}
            │   │           │   └── setPayload(params)
            │   │           └── fn_ejecutar_etl()
            │   │               ├── params = getPayload() + bloque "Etl"
            │   │               └── por cada archivo de Etl.archivos:
            │   │                   └── helper.ejecutar_archivo(static/sql/ + archivo, params)
            │   └── estadísticas del paso
            └── registro de fin (en Linux también se inserta en resultados.ejecuciones_orquestador2)
```

### Paso a paso

**1. `ejecucion.ejecutar()`** — Crea las carpetas de logs y el `Orchestrator` con el nombre del proyecto (`nom_proyecto`) y la lista de pasos. Esta ETL tiene un solo paso: `Etl()`.

**2. Preparación del orquestador** — Al crearse, el `Orchestrator` pide al primer paso la configuración global. `Step.initGlobalConfiguration` abre `static/config.json` y devuelve el bloque `"global"`. Para ubicar la carpeta `static/`, `Step.getFolderPath` toma la carpeta del archivo donde está definida la clase del paso (`src/compensa_provision/etl.py` → `src/compensa_provision/static/`).

Con la configuración global, el orquestador:

- Verifica que exista `dsn`.
- Crea el `Logger` y el `Emailer`.
- Como `useSparky` es `false`, crea un `Helper` con todo el bloque `"global"`. El `Helper` abre la conexión ODBC con `dsn`.
- Entrega a cada paso el `Helper`, el log y su propia configuración: el bloque del `config.json` con el mismo nombre de la clase, `"Etl"`.

**3. Ejecución del paso** — `Orchestrator.ejecutar()` llama a `Etl.ejecutar()`, que:

- Une los parámetros: `global.parametros_lz` + bloque `"Etl"`.
- Guarda el `Helper` en `self.hp` y la lista `archivos` en `self.list_sql_file`.
- Llama a `executeTasks()`, que recorre `Etl.tareas` y ejecuta el método de la clase con ese nombre (`getattr(self, nombre)()`).

**4. Tarea `ultima_ingestion`** — Para cada tabla del diccionario `Etl.tablas`, consulta su última partición con `helper.obtener_ultima_ingestion`. Agrega el resultado a los parámetros con la misma llave del diccionario y los guarda en el *payload* del paso.

**5. Tarea `fn_ejecutar_etl`** — Recupera los parámetros del *payload* y ejecuta en orden cada archivo de `Etl.archivos` con `helper.ejecutar_archivo`.

El *payload* es el mecanismo para pasar datos entre tareas y entre pasos. `fn_ejecutar_etl` depende de que `ultima_ingestion` lo haya llenado: si se quita `ultima_ingestion` de `tareas`, `getPayload()` devuelve `None` y la ejecución falla.

---

## Configuración: static/config.json

```json
{
    "global": {
        "dsn": "Impala-cdp-kudu",
        "cdp_endpoint": "...",
        "username": "srv_svccdp03",
        "useSparky": false,
        "parametros_lz": { "nom_proyecto": "...", "indice": "temp", "zona_p": "...", ... }
    },
    "Etl": {
        "tareas":   [ { "nombre": "ultima_ingestion", "kwargs": [] }, { "nombre": "fn_ejecutar_etl", "kwargs": [] } ],
        "archivos": [ "etl/01_ceautoedt_base.sql", ..., "etl/999_limpieza.sql" ],
        "tablas":   { "ALLINF": "s_apoyo_financiero.ccsap_visionr_allinf" }
    }
}
```

| Llave | La usa | Para |
|---|---|---|
| `global.dsn` | `Orchestrator` → `Helper` | Conexión ODBC a Impala |
| `global.cdp_endpoint`, `global.username` | `Helper` (solo si no hay `dsn`) / Sparky | No intervienen en esta ETL; se conservan de la plantilla |
| `global.useSparky` | `Orchestrator` | `false`: solo conexión a Impala, sin Spark |
| `global.parametros_lz` | `Etl.ejecutar` | Parámetros disponibles en todos los SQL |
| `Etl.tareas` | `Step.executeTasks` | Métodos de `Etl` a ejecutar, en orden |
| `Etl.archivos` | `Etl.fn_ejecutar_etl` | Archivos SQL a ejecutar, en orden, relativos a `static/sql/` |
| `Etl.tablas` | `Etl.ultima_ingestion` | Tablas a las que se les busca la última ingestión; la llave es el nombre del parámetro |

`parametros_lz` actuales:

| Parámetro | Valor | Uso en SQL |
|---|---|---|
| `nom_proyecto` | `compensa-provision` | — |
| `indice` | `temp` | Prefijo de las temporales: `{zona_p}.{indice}_...` |
| `zona_p` | `proceso_vspc_finanzas` | Zona de las temporales |
| `zona_ceautoedt` | `proceso_vspc_finanzas` | Zona de `visionr_ceautoedt` |
| `zona_s_apoyo_financiero` | `s_apoyo_financiero` | Zona del maestro ALLINF |
| `zona_s_productos` | `s_productos` | Zona de la tabla de equivalencias |

---

## Parámetros en los SQL

Antes de ejecutar un archivo, el `Helper` reemplaza los parámetros con `texto.format(**params)` de Python. Todo lo que esté entre llaves debe existir en `params`.

| En el SQL | Se reemplaza por | Origen |
|---|---|---|
| `{zona_p}` | `proceso_vspc_finanzas` | `parametros_lz.zona_p` |
| `{indice}` | `temp` | `parametros_lz.indice` |
| `{zona_ceautoedt}` | `proceso_vspc_finanzas` | `parametros_lz.zona_ceautoedt` |
| `{ALLINF[year]}` | Año de la última ingestión de ALLINF, ej. `2026` | Tarea `ultima_ingestion` |
| `{ALLINF[month]}` | Mes de la última ingestión, ej. `10` | Tarea `ultima_ingestion` |
| `{ALLINF[day]}` | Día de la última ingestión, ej. `3` | Tarea `ultima_ingestion` |

Ejemplo, `02_allinf_contable.sql`:

```sql
-- En el archivo
FROM {zona_s_apoyo_financiero}.ccsap_visionr_allinf a
WHERE a.year = {ALLINF[year]} AND a.ingestion_month = {ALLINF[month]} AND a.ingestion_day = {ALLINF[day]}

-- Lo que se ejecuta en Impala
FROM s_apoyo_financiero.ccsap_visionr_allinf a
WHERE a.year = 2026 AND a.ingestion_month = 10 AND a.ingestion_day = 3
```

`{ALLINF[year]}` funciona porque `params["ALLINF"]` es un diccionario (`{"year": 2026, "month": 10, "day": 3}`) y la sintaxis de `format` permite acceder a sus llaves.

### Cómo se calcula la última ingestión

`helper.obtener_ultima_ingestion(tabla)`:

1. Ejecuta `SHOW TABLE STATS <tabla>`, que devuelve la lista de particiones sin leer los datos.
2. Identifica las columnas de partición que contienen `year`, `month` y `day` (en ALLINF: `year`, `ingestion_month`, `ingestion_day`).
3. Ordena las particiones de la más reciente a la más antigua y devuelve la primera como `{"year", "month", "day"}`.
4. Registra en el log la tabla, la duración y el resultado.

---

## Ejecución de un archivo SQL

`helper.ejecutar_archivo(ruta, params)` procesa cada archivo así:

```
archivo .sql
   │ 1. lectura (UTF-8)
   │ 2. _eliminar_comentarios: quita comentarios -- y /* */ y líneas vacías (respeta textos entre comillas)
   │ 3. texto.format(**params): reemplaza {zona_p}, {indice}, {ALLINF[year]}, ...
   │ 4. sqlparse.split: separa en sentencias por ;
   ▼
por cada sentencia:
   ├── registra la sentencia en el log
   ├── _ejecutar_consulta → _reStarter → cursor.execute(sentencia)   (con reintentos)
   └── registra la duración
```

Ejemplo con `01_ceautoedt_base.sql`, que se convierte en tres sentencias ejecutadas en orden:

```sql
DROP TABLE IF EXISTS proceso_vspc_finanzas.temp_ceautoedt_base PURGE
CREATE TABLE proceso_vspc_finanzas.temp_ceautoedt_base STORED AS PARQUET AS SELECT ... FROM proceso_vspc_finanzas.visionr_ceautoedt WHERE ...
COMPUTE INCREMENTAL STATS proceso_vspc_finanzas.temp_ceautoedt_base
```

Consideraciones al escribir SQL para el orquestador:

- Las llaves `{` `}` están reservadas para parámetros; no deben aparecer como texto literal en el SQL.
- Las sentencias se separan con `;`.
- Los comentarios del encabezado se eliminan antes de reemplazar parámetros, por lo que pueden mencionar `{zona_p}` u otros parámetros sin afectar la ejecución.

---

## Conexión a la LZ

El `Helper` se conecta con el DSN de `global.dsn` (`Helper._obtener_conexion`):

| Dónde se ejecuta | Cadena de conexión | Credenciales |
|---|---|---|
| PC (variable de entorno `MAQUINA` distinta de `CDP-PC`) | `DSN=<dsn>` | Las guardadas en la configuración del DSN en el administrador ODBC |
| Servidor de calendarización (`MAQUINA=CDP-PC`) | `DSN=<dsn>;uid=<OOZIE_CDP_USER>;pwd=<DECRYPT_USER>` | Variables de entorno del servidor |

Es la misma conexión que usa `carga_ceautoe_lz` en el PC. `cdp_endpoint` y `username` no se usan cuando hay `dsn`.

El `Helper` renueva la conexión si pasan más de 1.000 segundos sin usarla (`refresh_time`).

---

## Logs

| Archivo | Contenido |
|---|---|
| `logs/aaaammdd_hhmmss_compensa_provision.log` | Una ejecución completa: versión del orquestador, plan de tareas, búsqueda de la última ingestión de ALLINF con su resultado, cada sentencia SQL ejecutada con su duración, duración de cada tarea y del paso, y registro final de la ejecución |
| `logs_calendarizacion/cmp_...log` y `est_...log` | Evidencias para calendarizar: 3 ejecuciones de compilación y 3 de estabilidad (ver [estado_y_pendientes.md](estado_y_pendientes.md#4-logs-de-calendarización)) |

Fragmento esperado del log:

```
[INFO] - Ejecutando Paso ** Etl **
[INFO] - Inicia la ejecucion de la tarea ultima_ingestion
[INFO] - Buscando fechas para s_apoyo_financiero.ccsap_visionr_allinf
[INFO] - Finalizo la busqueda, duracion: 00:03.2, resultado: {'year': 2026, 'month': 10, 'day': 3}
[INFO] - Inicia la ejecucion de la tarea fn_ejecutar_etl
[INFO] - Inicia la ejecucion de la siguiente consulta:
            DROP TABLE IF EXISTS proceso_vspc_finanzas.temp_ceautoedt_base PURGE
[INFO] - Finalizó la ejecucion del query, duracion: 00:00.5
...
[INFO] - Finalizó Orquestador Satisfactoriamente
```

---

## Reintentos y errores

Hay dos niveles de reintento:

| Nivel | Dónde | Comportamiento |
|---|---|---|
| Paso | `Orchestrator.__reStarter` | Si `Etl.ejecutar()` falla, lo repite hasta `maxTries` veces, esperando `waitPeriod` segundos entre intentos. Valores por defecto: `maxTries = 1` (sin reintento) y `waitPeriod = 600`. Se configuran en `global` o, para el paso, en el bloque `Etl` (`maxTries`) |
| Sentencia | `Helper._reStarter` | Reintenta una sentencia hasta 3 veces ante errores de conexión o del clúster. No reintenta errores de sintaxis, de análisis ni de permisos (`ParseException`, `AnalysisException`, `AuthorizationException`), ni `INSERT INTO` |

Si una sentencia falla definitivamente, el error sube hasta el orquestador, que registra en el log el tipo de excepción, el mensaje y la traza, marca la ejecución con estado `ERROR` y vuelve a lanzar la excepción.

---

## Cómo extender la ETL

### Agregar un archivo SQL

1. Crear el archivo en `static/sql/etl/` siguiendo el encabezado de los demás.
2. Agregar su ruta (`etl/<archivo>.sql`) en `Etl.archivos` de `static/config.json`, en la posición en que debe ejecutarse.
3. Si crea tablas temporales, agregar su borrado en `999_limpieza.sql`.

### Agregar una tabla con última ingestión

1. Agregar una entrada en `Etl.tablas`: `"NOMBRE": "zona.tabla"`.
2. Usar `{NOMBRE[year]}`, `{NOMBRE[month]}` y `{NOMBRE[day]}` en el SQL.

### Agregar un parámetro

1. Agregarlo en `global.parametros_lz`.
2. Usarlo en el SQL como `{parametro}`.

### Agregar una tarea

1. Crear el método en la clase `Etl` (`etl.py`).
2. Agregarlo en `Etl.tareas` con `{"nombre": "<metodo>", "kwargs": []}` en la posición en que debe ejecutarse.
