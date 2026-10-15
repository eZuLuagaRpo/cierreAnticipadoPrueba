# Flujo del código y funcionamiento de orquestador2

Este documento describe cómo se instala y se ejecuta la ETL `an0016001-gsfc-compensacionprovision` sobre la librería `orquestador2`: qué hace cada pieza, en qué orden se llaman y cómo llegan los argumentos, la configuración y los parámetros a los archivos SQL.

La descripción interna de `orquestador2` y del `helper` se basa en el código de referencia disponible en la raíz del repositorio (`orquestador2/` y `helper.py`). La versión instalada (`orquestador2>=1.4.0`) puede tener diferencias menores.

## Contenido

1. [Piezas de orquestador2](#piezas-de-orquestador2)
2. [Estructura del paquete](#estructura-del-paquete)
3. [Instalación](#instalación)
4. [Ejecución y argumentos](#ejecución-y-argumentos)
5. [Flujo completo de ejecución](#flujo-completo-de-ejecución)
6. [Configuración: static/config.json](#configuración-staticconfigjson)
7. [Parámetros en los SQL](#parámetros-en-los-sql)
8. [Última ingestión](#última-ingestión)
9. [Ejecución de un archivo SQL](#ejecución-de-un-archivo-sql)
10. [Conexión a la LZ](#conexión-a-la-lz)
11. [Logs](#logs)
12. [Reintentos y errores](#reintentos-y-errores)
13. [Cómo extender la ETL](#cómo-extender-la-etl)

---

## Piezas de orquestador2

`orquestador2` es la librería interna que estandariza las ETL calendarizables. Se instala como dependencia del paquete (`install_requires` en `setup.py`).

| Pieza | Origen | Responsabilidad |
|---|---|---|
| `Orchestrator` | `orquestador2.orquestador2` | Lee la configuración global, crea el `Helper` y el `Logger`, y ejecuta en orden la lista de pasos (`steps`) |
| `Step` | `orquestador2.step` | Clase base de un paso. Da acceso al `Helper`, al log y a la configuración, y ejecuta las tareas definidas en `config.json` |
| `Helper` | `helper.helper` (dependencia de orquestador2) | Conexión a Impala por ODBC, lectura y ejecución de archivos SQL, búsqueda de la última ingestión de una tabla, muestreo de datos en logs de compilación |
| `Logger` | `orquestador2.logger` | Log en consola y en archivo, con el plan de tareas y la duración de cada consulta |
| `Emailer`, `Sparky` | `orquestador2` | Envío de correos y ejecución de Spark. Esta ETL no los usa (`useSparky: false`) |

La división de trabajo es:

| El paquete define **qué** hacer | `orquestador2` resuelve **cómo** hacerlo |
|---|---|
| `config.json`: DSN, zonas, tareas, lista de SQL, tablas | Leer la configuración |
| `etl.py`: el paso y sus tareas | Conectarse a Impala |
| `static/sql/etl/*.sql`: las consultas | Ejecutar los SQL: quitar comentarios, reemplazar parámetros, separar sentencias, reintentar |
| `ejecucion.py`: argumentos y arranque | Escribir el log, medir tiempos, registrar errores |

---

## Estructura del paquete

La ETL es un paquete de Python instalable, porque así se despliega: se publica en Artifactory y el servidor de calendarización lo instala desde allí.

```
Desarrollo (PC)                  Azure DevOps / Artifactory              Servidor de calendarización
pip install -e .    ───────►   paquete publicado y versionado   ───────►   pip install an0016001-gsfc-compensacionprovision
                                 (setup.py, versioneer, .pypirc)            an0016001_gsfc_compensacionprovision
```

| Archivo | Función |
|---|---|
| `setup.py` | Nombre del paquete (`an0016001-gsfc-compensacionprovision`), descripción, autor, Python mínimo (`>=3.9.12`), dependencias (`orquestador2>=1.4.0`, `future_fstrings`) y comando de consola |
| `setup.cfg` | Configuración de versioneer |
| `versioneer.py`, `src/.../_version.py` | Calculan la versión del paquete a partir de los tags de git |
| `MANIFEST.in` | Incluye en el paquete los archivos que no son `.py`: `static/*.json`, `static/sql/etl/*.sql` y los archivos de versión |
| `.pypirc` | Repositorio de Artifactory donde se publica el paquete |
| `.editorconfig` | Reglas de formato: UTF-8, indentación de 4 espacios, líneas de máximo 69 caracteres en Python |
| `src/an0016001_gsfc_compensacionprovision/__init__.py` | Expone `ExtractTransformLoad` y `__version__` |
| `src/.../ejecucion.py` | Punto de entrada: lee los argumentos y ejecuta el `Orchestrator` |
| `src/.../etl.py` | Clase `ExtractTransformLoad(Step)`: el paso de la ETL |
| `src/.../static/config.json` | Configuración global y del paso |
| `src/.../static/sql/etl/` | Archivos SQL |

En el nombre del paquete se usan guiones (`an0016001-gsfc-compensacionprovision`) y en el del módulo de Python, guiones bajos (`an0016001_gsfc_compensacionprovision`), porque Python no admite guiones en nombres de módulos.

---

## Instalación

`ejecucion.py` importa el paso con el nombre del paquete:

```python
from an0016001_gsfc_compensacionprovision.etl import ExtractTransformLoad
```

Python solo encuentra `an0016001_gsfc_compensacionprovision` si el paquete está instalado. Por eso, antes de ejecutar, se instala desde la carpeta raíz del proyecto, preferiblemente en un ambiente virtual:

```bash
pip install -e .
```

| Efecto | Detalle |
|---|---|
| Registra el paquete en el ambiente de Python | Permite `python -m an0016001_gsfc_compensacionprovision.ejecucion` |
| Instala las dependencias de `setup.py` | `orquestador2` (y con él `helper`) se descarga de Artifactory |
| Crea el comando `an0016001_gsfc_compensacionprovision` | Equivale a `python -m an0016001_gsfc_compensacionprovision.ejecucion` |

### Instalación editable (`-e`)

| | `pip install .` | `pip install -e .` |
|---|---|---|
| Qué hace pip | Copia los archivos del paquete a `site-packages` | Registra un enlace a la carpeta `src/` del proyecto |
| Cambios en `.py`, `config.json` o `.sql` | No se reflejan hasta reinstalar | Se reflejan en la siguiente ejecución |

Solo es necesario volver a ejecutar `pip install -e .` en un ambiente nuevo, al cambiar `setup.py` (dependencias, nombre, comando) o al renombrar la carpeta del paquete.

El orquestador busca la carpeta `static/` junto al archivo `etl.py` que se está ejecutando. Con instalación editable es la carpeta del proyecto. En el servidor de calendarización el paquete se instala como copia, que solo contiene `config.json` y los `.sql` si `MANIFEST.in` los incluye; por eso `MANIFEST.in` debe listar `static/sql/etl/*.sql`.

---

## Ejecución y argumentos

Desde la carpeta raíz del proyecto:

```bash
python -m an0016001_gsfc_compensacionprovision.ejecucion [argumentos]
```

| Argumento | Uso | Efecto en esta ETL |
|---|---|---|
| (ninguno) | Ejecución normal | Log en `logs/` |
| `-lt est` | Log de estabilidad | Ejecución completa; log en `logs_calendarizacion/` |
| `-lt cmp -pl <1-100>` | Log de compilación | El `helper` procesa solo el porcentaje indicado de las tablas fuente de zona cruda o de resultados (ver [Logs](#logs)); log en `logs_calendarizacion/` |
| `-zp <zona>` | Zona de procesamiento | Reemplaza `zona_procesamiento`: las temporales se crean en esa zona. No cambia la zona de las tablas de origen |
| `-y <año> -m <mes> -d <día>` | Fecha de ejecución | Cambia los parámetros de fecha `{f_actual_*}` y `{f_corte_*}`. Los SQL actuales usan `YEAR(NOW())` / `MONTH(NOW())`, por lo que no los afecta |

Con `-lt est` o `-lt cmp`, `ejecucion.py` verifica que exista la carpeta `src/` en el directorio actual; si no existe, termina sin ejecutar.

---

## Flujo completo de ejecución

### Árbol de llamadas

```
python -m an0016001_gsfc_compensacionprovision.ejecucion [argumentos]
└── ejecucion.py (al cargarse el módulo)
    ├── argparse → kw = argumentos informados + log_path (+ log_type y porcentaje_limit si -lt est/cmp)
    ├── crea logs/ o logs_calendarizacion/ en el directorio actual
    ├── steps = [ExtractTransformLoad(**kw)]           el paso guarda kw en self.kwa
    └── main()
        └── Orchestrator("Orq 2 gsfc compensacionprovision", steps, **kw)
            │
            ├── __init__  ─────────────────────────────── preparación
            │   ├── __validateSteps(steps)                 cada paso debe heredar de Step
            │   └── __initializeSteps()
            │       ├── paso.initGlobalConfiguration()     lee static/config.json → bloque "global"
            │       ├── global.update(kw)                  los argumentos repisan la configuración global
            │       ├── __checkObligatoryKeys()            "dsn" es obligatorio
            │       ├── __resetParameters()                maxTries (1) y waitPeriod (600 s)
            │       ├── __initializeHelpers()
            │       │   ├── Logger(nombre, log_path, log_type)
            │       │   └── Helper(**global)               useSparky=false → conexión ODBC con global.dsn
            │       │                                      (recibe porcentaje_limit si es -lt cmp)
            │       └── paso.setModules(helper, None, log, emailer, config_file)
            │           └── setConfiguration()             bloque "ExtractTransformLoad" + kw
            │
            └── ejecutar()  ───────────────────────────── ejecución
                ├── registro de inicio
                ├── __reStarter(paso) → ExtractTransformLoad.ejecutar()
                │   ├── cfg = getStepConfig()                      bloque del paso
                │   ├── params = obtener_params() + cfg            ver "Parámetros en los SQL"
                │   ├── log de params en formato JSON
                │   ├── self.hp = helper ; self.list_sql_file = cfg["archivos"]
                │   └── executeTasks()                             ejecuta cfg["tareas"] en orden
                │       ├── ultima_ingestion()
                │       │   ├── helper.obtener_ultima_ingestion("s_apoyo_financiero.ccsap_visionr_allinf")
                │       │   ├── params["ALLINF"] = {"year": ..., "month": ..., "day": ...}
                │       │   └── setPayload(params)
                │       └── fn_ejecutar_etl()
                │           ├── params = getPayload() + cfg
                │           └── por cada archivo de cfg["archivos"]:
                │               └── helper.ejecutar_archivo(static/sql/ + archivo, params)
                └── registro de fin (en Linux también se inserta en resultados.ejecuciones_orquestador2)
```

### Paso a paso

**1. `ejecucion.py`** — Al cargarse el módulo, lee los argumentos y arma el diccionario `kw`, que siempre incluye `log_path` (carpeta de logs). Crea esa carpeta y el paso `ExtractTransformLoad(**kw)`; el paso guarda `kw` en `self.kwa`. Luego `main()` crea el `Orchestrator` con el nombre `"Orq 2 gsfc compensacionprovision"`, la lista de pasos y el mismo `kw`.

**2. Preparación del orquestador** — El `Orchestrator` pide al paso la configuración global: `Step.initGlobalConfiguration` abre `static/config.json`, ubicado junto al archivo donde está definida la clase del paso (`etl.py`), y devuelve el bloque `"global"`. Los valores de `kw` se agregan a esa configuración. Con ella:

- Verifica que exista `dsn`.
- Crea el `Logger` en la carpeta `log_path`.
- Como `useSparky` es `false`, crea un `Helper` con toda la configuración global; el `Helper` abre la conexión ODBC con `dsn` y, en logs de compilación, recibe `porcentaje_limit`.
- Entrega al paso el `Helper`, el log y su configuración: el bloque de `config.json` con el nombre de la clase (`"ExtractTransformLoad"`), más los valores de `kw`.

**3. `ExtractTransformLoad.ejecutar()`** — Reúne los parámetros con `obtener_params()` (ver [Parámetros en los SQL](#parámetros-en-los-sql)) y la configuración del paso, los escribe en el log en formato JSON, guarda el `Helper` y la lista `archivos`, y llama a `executeTasks()`. Esta función recorre `tareas` y ejecuta el método de la clase con ese nombre.

**4. Tarea `ultima_ingestion`** — Busca la última partición de cada tabla de `tablas`, la agrega a los parámetros y guarda los parámetros en el *payload* del paso.

**5. Tarea `fn_ejecutar_etl`** — Recupera los parámetros del *payload* y ejecuta, en el orden de la lista `archivos`, cada SQL con `helper.ejecutar_archivo`.

El *payload* es el mecanismo para pasar datos entre tareas. `fn_ejecutar_etl` depende de que `ultima_ingestion` lo haya llenado: si se quita `ultima_ingestion` de `tareas`, `getPayload()` devuelve `None` y la ejecución falla.

### Orden de ejecución de los SQL

Los SQL se ejecutan en el orden de la lista `archivos` de `config.json`; los números del nombre de cada archivo son solo una convención de lectura. Un archivo que no esté en la lista no se ejecuta.

La clase conserva el método `ejecutar_modulos` de la plantilla, que ejecuta todos los `.sql` de la carpeta `static/sql/ExtractTransformLoad/` en orden alfabético (`executeFolder`). No se usa: no está en `tareas` y esa carpeta no existe en este paquete.

---

## Configuración: static/config.json

```json
{
    "global": {
        "dsn": "Impala-cdp-kudu",
        "cdp_endpoint": "...",
        "username": "srv_svccdp03",
        "useSparky": false,
        "parametros_lz": {
            "nom_proyecto": "an0016001-gsfc-compensacionprovision",
            "indice": "temp",
            "zona_procesamiento": "proceso_vspc_finanzas",
            ...
        }
    },
    "ExtractTransformLoad": {
        "tareas":   [ { "nombre": "ultima_ingestion", "kwargs": [] }, { "nombre": "fn_ejecutar_etl", "kwargs": [] } ],
        "archivos": [ "etl/01_ceautoedt_base.sql", ..., "etl/999_limpieza.sql" ],
        "tablas":   { "ALLINF": "s_apoyo_financiero.ccsap_visionr_allinf" }
    }
}
```

| Llave | La usa | Para |
|---|---|---|
| `global.dsn` | `Orchestrator` → `Helper` | Conexión ODBC a Impala |
| `global.cdp_endpoint`, `global.username` | `Helper` (solo si no hay `dsn`) / Sparky | No intervienen en esta ETL |
| `global.useSparky` | `Orchestrator` | `false`: solo conexión a Impala, sin Spark |
| `global.parametros_lz` | `obtener_params` | Parámetros disponibles en todos los SQL |
| `ExtractTransformLoad` | `Step.setConfiguration` | Configuración del paso; el nombre del bloque debe ser igual al de la clase |
| `ExtractTransformLoad.tareas` | `Step.executeTasks` | Métodos del paso a ejecutar, en orden |
| `ExtractTransformLoad.archivos` | `fn_ejecutar_etl` | Archivos SQL a ejecutar, en orden, relativos a `static/sql/` |
| `ExtractTransformLoad.tablas` | `ultima_ingestion` | Tablas a las que se les busca la última ingestión; la llave es el nombre del parámetro |

---

## Parámetros en los SQL

`obtener_params()` arma los parámetros a partir de tres fuentes, y `ejecutar()` les agrega la configuración del paso:

| Fuente | Parámetros | Ejemplo |
|---|---|---|
| `global.parametros_lz` | `nom_proyecto`, `indice`, `zona_procesamiento`, `zona_ceautoedt`, `zona_s_apoyo_financiero`, `zona_s_productos` | `{zona_procesamiento}` → `proceso_vspc_finanzas` |
| Fechas calculadas (con la fecha actual o la de `-y -m -d`) | `f_actual_y`, `f_actual_m`, `f_actual_d` (fecha de ejecución) y `f_corte_y`, `f_corte_m`, `f_corte_d` (un mes atrás) | `{f_actual_m}` → `10` |
| Argumentos de ejecución (`kw`) | Los informados al ejecutar, por ejemplo `zona_procesamiento` con `-zp`; repisan los anteriores | `-zp proceso_pruebas` → `{zona_procesamiento}` → `proceso_pruebas` |
| Tarea `ultima_ingestion` | Una llave por tabla de `tablas` | `{ALLINF[year]}` → `2026` |

Antes de ejecutar un archivo, el `Helper` reemplaza los parámetros con `texto.format(**params)` de Python. Todo lo que esté entre llaves debe existir en los parámetros. Los SQL actuales usan:

| En el SQL | Se reemplaza por |
|---|---|
| `{zona_procesamiento}` | `proceso_vspc_finanzas` (o la zona de `-zp`) |
| `{indice}` | `temp` |
| `{zona_ceautoedt}` | `proceso_vspc_finanzas` |
| `{zona_s_apoyo_financiero}` | `s_apoyo_financiero` |
| `{zona_s_productos}` | `s_productos` |
| `{ALLINF[year]}`, `{ALLINF[month]}`, `{ALLINF[day]}` | Fecha de la última ingestión de ALLINF |

Los parámetros de fecha `{f_actual_*}` y `{f_corte_*}` están disponibles, pero los SQL actuales no los usan.

---

## Última ingestión

Recorrido del parámetro `ALLINF`, desde la configuración hasta Impala:

```
config.json "tablas"        →  qué tabla revisar      ALLINF = s_apoyo_financiero.ccsap_visionr_allinf
tarea ultima_ingestion      →  su partición más reciente, guardada en params["ALLINF"]
tarea fn_ejecutar_etl       →  entrega params a cada SQL
helper.ejecutar_archivo     →  reemplaza {ALLINF[year]}, {ALLINF[month]}, {ALLINF[day]}
Impala                      →  ejecuta el SQL con la fecha ya escrita
```

`helper.obtener_ultima_ingestion(tabla)`:

1. Ejecuta `SHOW TABLE STATS <tabla>`, que devuelve la lista de particiones sin leer los datos.
2. Identifica las columnas de partición que contienen `year`, `month` y `day` (en ALLINF: `year`, `ingestion_month`, `ingestion_day`).
3. Ordena las particiones de la más reciente a la más antigua y devuelve la primera como `{"year", "month", "day"}`.
4. Registra en el log la tabla, la duración y el resultado.

En `02_allinf_contable.sql`:

```sql
-- En el archivo
FROM {zona_s_apoyo_financiero}.ccsap_visionr_allinf a
WHERE a.year = {ALLINF[year]} AND a.ingestion_month = {ALLINF[month]} AND a.ingestion_day = {ALLINF[day]}

-- Lo que se ejecuta en Impala
FROM s_apoyo_financiero.ccsap_visionr_allinf a
WHERE a.year = 2026 AND a.ingestion_month = 10 AND a.ingestion_day = 3
```

`{ALLINF[year]}` funciona porque `params["ALLINF"]` es un diccionario y la sintaxis de `format` permite acceder a sus llaves. Por eso el orden de `tareas` importa: `ultima_ingestion` debe ir antes de `fn_ejecutar_etl`.

---

## Ejecución de un archivo SQL

`helper.ejecutar_archivo(ruta, params)` procesa cada archivo así:

```
archivo .sql
   │ 1. lectura (UTF-8)
   │ 2. _eliminar_comentarios: quita comentarios -- y /* */ y líneas vacías (respeta textos entre comillas)
   │ 3. texto.format(**params): reemplaza {zona_procesamiento}, {indice}, {ALLINF[year]}, ...
   │ 4. sqlparse.split: separa en sentencias por ;
   ▼
por cada sentencia:
   ├── registra la sentencia en el log
   ├── en logs de compilación: agrega TABLESAMPLE a las tablas fuente que aplique
   ├── _ejecutar_consulta → _reStarter → cursor.execute(sentencia)   (con reintentos)
   └── registra la duración
```

Ejemplo con `01_ceautoedt_base.sql`, que se convierte en tres sentencias ejecutadas en orden:

```sql
DROP TABLE IF EXISTS proceso_vspc_finanzas.temp_ceautoedt_base PURGE
CREATE TABLE proceso_vspc_finanzas.temp_ceautoedt_base STORED AS PARQUET TBLPROPERTIES ('transactional'='false') AS SELECT ... FROM proceso_vspc_finanzas.visionr_ceautoedt WHERE ...
COMPUTE INCREMENTAL STATS proceso_vspc_finanzas.temp_ceautoedt_base
```

Consideraciones al escribir SQL para el orquestador:

- Las llaves `{` `}` están reservadas para parámetros; no deben aparecer como texto literal en el SQL.
- Las sentencias se separan con `;`.
- Los comentarios del encabezado se eliminan antes de reemplazar parámetros, por lo que pueden mencionar `{zona_procesamiento}` u otros parámetros sin afectar la ejecución.
- Las tablas temporales se crean con `TBLPROPERTIES ('transactional'='false')`.

---

## Conexión a la LZ

El `Helper` se conecta con el DSN de `global.dsn` (`Helper._obtener_conexion`):

| Dónde se ejecuta | Cadena de conexión | Credenciales |
|---|---|---|
| PC (variable de entorno `MAQUINA` distinta de `CDP-PC`) | `DSN=<dsn>` | Las guardadas en la configuración del DSN en el administrador ODBC |
| Servidor de calendarización (`MAQUINA=CDP-PC`) | `DSN=<dsn>;uid=<OOZIE_CDP_USER>;pwd=<DECRYPT_USER>` | Variables de entorno del servidor |

`cdp_endpoint` y `username` no se usan cuando hay `dsn`. El `Helper` renueva la conexión si pasan más de 1.000 segundos sin usarla.

---

## Logs

| Ejecución | Carpeta | Contenido |
|---|---|---|
| Normal | `logs/` | Una ejecución completa: versión del orquestador, parámetros en JSON, plan de tareas, búsqueda de la última ingestión de ALLINF con su resultado, cada sentencia SQL con su duración, duración de cada tarea y registro final |
| `-lt est` | `logs_calendarizacion/` | Lo mismo, como evidencia de estabilidad para la calendarización |
| `-lt cmp -pl n` | `logs_calendarizacion/` | Lo mismo, como evidencia de compilación, procesando el `n` % de los datos |

En los logs de compilación, el `helper` agrega `TABLESAMPLE SYSTEM(n)` a las tablas fuente de zona cruda o de resultados en las consultas `CREATE`, `SELECT` y `WITH`, y lo registra como `TABLESAMPLE INYECTADO <tabla> <n>%`. A las tablas de zona de proceso no se les aplica y se registra una advertencia; en esta ETL es el caso de `visionr_ceautoedt` (mientras esté en `proceso_vspc_finanzas`) y de las temporales.

Para calendarizar se requieren 3 logs de estabilidad y 3 de compilación (ver [estado_y_pendientes.md](estado_y_pendientes.md#4-logs-de-calendarización)).

Fragmento esperado del log:

```
[INFO] - Ejecutando Paso ** ExtractTransformLoad **
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

| Nivel | Dónde | Comportamiento |
|---|---|---|
| Paso | `Orchestrator.__reStarter` | Si `ExtractTransformLoad.ejecutar()` falla, lo repite hasta `maxTries` veces, esperando `waitPeriod` segundos entre intentos. Valores por defecto: `maxTries = 1` (sin reintento) y `waitPeriod = 600`. Se configuran en `global` o, para el paso, con `maxTries` en el bloque `ExtractTransformLoad` |
| Sentencia | `Helper._reStarter` | Reintenta una sentencia hasta 3 veces ante errores de conexión o del clúster. No reintenta errores de sintaxis, de análisis ni de permisos (`ParseException`, `AnalysisException`, `AuthorizationException`), ni `INSERT INTO` |

Si una sentencia falla definitivamente, el error sube hasta el orquestador, que registra en el log el tipo de excepción, el mensaje y la traza, marca la ejecución con estado `ERROR` y vuelve a lanzar la excepción.

---

## Cómo extender la ETL

### Agregar un archivo SQL

1. Crear el archivo en `static/sql/etl/` siguiendo el encabezado de los demás.
2. Agregar su ruta (`etl/<archivo>.sql`) en `ExtractTransformLoad.archivos` de `static/config.json`, en la posición en que debe ejecutarse.
3. Si crea tablas temporales, usar `{zona_procesamiento}.{indice}_<nombre>`, `TBLPROPERTIES ('transactional'='false')`, y agregar su borrado en `999_limpieza.sql`.

`MANIFEST.in` ya incluye todos los `.sql` de `static/sql/etl/`.

### Agregar una tabla con última ingestión

1. Agregar una entrada en `ExtractTransformLoad.tablas`: `"NOMBRE": "zona.tabla"`.
2. Usar `{NOMBRE[year]}`, `{NOMBRE[month]}` y `{NOMBRE[day]}` en el SQL.

### Agregar un parámetro

1. Agregarlo en `global.parametros_lz`.
2. Usarlo en el SQL como `{parametro}`.

### Agregar una tarea

1. Crear el método en la clase `ExtractTransformLoad` (`etl.py`).
2. Agregarlo en `ExtractTransformLoad.tareas` con `{"nombre": "<metodo>", "kwargs": []}` en la posición en que debe ejecutarse.
