# Flujo del código

Este documento describe cómo se ejecuta el código de principio a fin: qué archivo inicia el proceso, qué funciones se llaman y en qué orden, cómo se leen los archivos SQL, cómo viajan la configuración, las conexiones y los datos entre módulos, y cómo se manejan los errores.

Para la descripción funcional del proceso (requisitos, configuración, tabla destino, solución de problemas) ver [documentacion.md](documentacion.md).

## Contenido

1. [Resumen](#resumen)
2. [Mapa de módulos](#mapa-de-módulos)
3. [Punto de entrada](#punto-de-entrada)
4. [Flujo de la carga](#flujo-de-la-carga)
5. [Lectura de archivos SQL](#lectura-de-archivos-sql)
6. [Recorrido de los datos](#recorrido-de-los-datos)
7. [Configuración, conexiones y log entre módulos](#configuración-conexiones-y-log-entre-módulos)
8. [Manejo de errores](#manejo-de-errores)
9. [Flujo de la prueba de conexiones](#flujo-de-la-prueba-de-conexiones)
10. [Flujo de la ventana de credenciales](#flujo-de-la-ventana-de-credenciales)
11. [Índice de funciones](#índice-de-funciones)

---

## Resumen

1. `ejecutar.bat` prepara el ambiente de Python y ejecuta `src/main.py`.
2. `main.py` configura el log, lee `config/config.json` y abre la ventana de credenciales (`interfaz.py`).
3. Con las credenciales, `main.py` abre la conexión a la Nacional (`nacional.py`) y a la LZ (`lz.py`).
4. `main.py` entrega las dos conexiones y la configuración a `carga.ejecutar_cargas`, que recorre la lista `cargas` (`VISIONR.CEAUTOE`, `VISIONR.CEAUTOEDT`) y ejecuta los pasos de la carga para cada tabla.
5. Cada paso toma un archivo de `sql/`, lo lee con `configuracion.py` (quita comentarios, reemplaza `{parámetros}` y separa sentencias) y lo ejecuta con `nacional.py` o `lz.py`. Los mismos archivos SQL sirven para todas las tablas; cambian solo los parámetros (`{tabla_origen}`, `{tabla_resultado}`, `{tabla_temporal}`).
6. Los datos pasan de la Nacional a la LZ por lotes: `nacional.leer_por_lotes` entrega bloques de filas y `lz.insertar_lote` los convierte en un `INSERT ... VALUES` sobre la tabla temporal.
7. Al terminar cada tabla, `carga.py` borra su temporal. Al final, `main.py` cierra las conexiones e `interfaz.py` muestra el resultado de cada tabla.

---

## Mapa de módulos

### Responsabilidad de cada archivo

| Capa | Archivo | Responsabilidad |
|---|---|---|
| Entrada | `main.py` | Orquesta la carga completa: log, configuración, ventana, conexiones, carga y mensaje final |
| Entrada | `probar_conexiones.py` | Orquesta la prueba de conexiones (solo lectura) |
| Orquestación | `carga.py` | Recorre las tablas de `cargas`, define los pasos de la carga y el orden de los archivos SQL |
| Acceso a datos | `nacional.py` | Conexión a la Nacional y lectura de la consulta |
| Acceso a datos | `lz.py` | Conexión a la LZ, ejecución de sentencias y armado de los `INSERT` por lotes |
| Soporte | `configuracion.py` | Rutas del proyecto, lectura de `config.json` y de los archivos SQL |
| Soporte | `bitacora.py` | Log en consola y archivo, formato de números y duraciones |
| Interfaz | `interfaz.py` | Ventana de credenciales y mensaje final |

### Dependencias (quién importa a quién)

```
┌──────────────────────────────────────────────────────────────┐
│ Entrada          main.py  ·  probar_conexiones.py            │
├──────────────────────────────────────────────────────────────┤
│ Orquestación     carga.py                                    │
│ Interfaz         interfaz.py                                 │
├──────────────────────────────────────────────────────────────┤
│ Acceso a datos   nacional.py  ·  lz.py                       │
├──────────────────────────────────────────────────────────────┤
│ Soporte          configuracion.py  ·  bitacora.py            │
└──────────────────────────────────────────────────────────────┘
  Cada capa usa únicamente módulos de las capas inferiores.
```

| Archivo | Importa del proyecto |
|---|---|
| `main.py` | `configuracion`, `interfaz`, `lz`, `nacional`, `bitacora` (`NOMBRE_LOG`, `configurar_bitacora`, `duracion`, `miles`), `carga` (`Resumen`, `ejecutar_cargas`) |
| `probar_conexiones.py` | `configuracion`, `interfaz`, `lz`, `nacional`, `bitacora` (`NOMBRE_LOG`, `configurar_bitacora`, `miles`), `carga` (`SQL_CONSULTA_NACIONAL`, `parametros_carga`) |
| `carga.py` | `lz`, `nacional`, `bitacora` (`NOMBRE_LOG`, `duracion`, `miles`), `configuracion` (`leer_sentencias`, `leer_plantilla_lote`) |
| `lz.py` | `bitacora` (`NOMBRE_LOG`), `configuracion` (`MARCADOR_VALORES`) |
| `nacional.py` | `bitacora` (`NOMBRE_LOG`) |
| `configuracion.py` | — |
| `bitacora.py` | — |
| `interfaz.py` | — |

Las dependencias van en un solo sentido: los módulos de entrada usan a los de orquestación, estos a los de acceso a datos, y todos a los de soporte. `nacional.py` y `lz.py` no se conocen entre sí; solo `carga.py` los usa juntos.

---

## Punto de entrada

### `ejecutar.bat`

```bat
cd /d "%~dp0"                         :: se ubica en la carpeta del proyecto
IF NOT EXIST .\ambiente\Scripts\activate ( python -m venv ambiente )
call .\ambiente\Scripts\activate
pip install -r requirements.txt
python .\src\main.py
pause
```

### Cómo funcionan los `import` entre archivos

`src/` no es un paquete instalado. Los `import` funcionan porque Python, al ejecutar `python src\main.py`, agrega automáticamente la carpeta del script (`src/`) a la lista de rutas de búsqueda (`sys.path`). Por eso `main.py` puede escribir:

```python
import configuracion
from carga import Resumen, ejecutar_cargas
```

y Python encuentra `src/configuracion.py` y `src/carga.py`.

### Cómo se ubican las carpetas del proyecto

`configuracion.py` calcula la raíz a partir de su propia ubicación, no del directorio desde el que se ejecuta:

```python
RAIZ = Path(__file__).resolve().parent.parent   # .../carga_ceautoe_lz
RUTA_CONFIG = RAIZ / "config" / "config.json"
RUTA_SQL = RAIZ / "sql"
RUTA_FONDO = RAIZ / "img" / "background.png"
RUTA_LOGS = RAIZ / "logs"
```

`__file__` es `.../carga_ceautoe_lz/src/configuracion.py`; `.parent` es `src/` y `.parent.parent` es `carga_ceautoe_lz/`. Todas las demás rutas se construyen desde ahí.

---

## Flujo de la carga

### Árbol de llamadas

```
ejecutar.bat
└── main.main()
    ├── bitacora.configurar_bitacora(RUTA_LOGS)                       → ruta del archivo de log
    ├── configuracion.cargar_config()                                 → dict con config.json
    ├── interfaz.solicitar_credenciales(RUTA_FONDO, info, pedir_lz)   → (cred_nacional, cred_lz) o None
    ├── nacional.conectar(dsn, usuario, password)                     → conexión Nacional
    ├── lz.conectar(dsn, usuario?, password?)                         → conexión LZ
    ├── carga.ejecutar_cargas(con_nal, con_lz, config)                → [Resumen, Resumen]
    │   └── por cada entrada de config["cargas"]:
    │       ├── params = parametros_carga(config, carga)              → parametros_lz + entrada de cargas
    │       └── _cargar_tabla(con_nal, con_lz, params, filas_por_lote) → Resumen (o Resumen con error)
    │           ├── [1/5] lz.ejecutar(con_lz, leer_sentencias("lz/01_crear_tabla_resultado.sql"))
    │           ├── [2/5] lz.ejecutar(con_lz, leer_sentencias("lz/02_crear_tabla_temporal.sql"))
    │           ├── [3/5] _cargar_temporal(con_nal, con_lz, params, filas_por_lote)
    │           │   ├── leer_sentencias("nacional/consulta_origen.sql")[0]     → consulta con FROM {tabla_origen}
    │           │   ├── leer_plantilla_lote("lz/03_insertar_lote_temporal.sql") → INSERT con {valores}
    │           │   ├── nacional.contar_filas(con_nal, consulta)              → total (para el avance)
    │           │   ├── nacional.abrir_consulta(con_nal, consulta)            → cursor
    │           │   ├── nacional.columnas(cursor)                             → se compara con COLUMNAS_NACIONAL
    │           │   └── por cada lote de nacional.leer_por_lotes(cursor, filas_por_lote):
    │           │       └── lz.insertar_lote(con_lz, plantilla, lote)
    │           ├── [4/5] lz.ejecutar(con_lz, leer_sentencias("lz/04_insertar_resultado.sql"))
    │           ├── [5/5] lz.consultar_fila(con_lz, leer_sentencias("lz/05_validar_carga.sql")[0])
    │           └── (siempre) _borrar_temporal → lz.ejecutar(con_lz, leer_sentencias("lz/99_limpieza.sql"))
    ├── (siempre) cierre de con_nal y con_lz
    └── interfaz.mostrar_resultado("info" | "advertencia" | "error", líneas de _linea_resumen)
```

### Paso a paso

**1. Log** — `bitacora.configurar_bitacora` crea `logs/carga_AAAAMMDD_HHMMSS.log` y conecta el logger `carga` a la consola y a ese archivo.

**2. Configuración** — `configuracion.cargar_config` devuelve el contenido de `config.json` como diccionario. `main` arma con él el texto de la ventana (DSN, tablas de origen, zona destino, tablas destino, partición).

**3. Credenciales** — `interfaz.solicitar_credenciales` muestra la ventana y devuelve una tupla `(Credenciales, Credenciales o None)`. Si el usuario cancela devuelve `None` y `main` termina.

**4. Conexiones** — `main` abre las dos conexiones antes de extraer datos, para que una falla de conexión se detecte de inmediato. Los objetos de conexión se guardan en `con_nal` y `con_lz` y se usan para todas las tablas.

**5. Carga** — `main` llama a `carga.ejecutar_cargas(con_nal, con_lz, config)`. Esta función recorre `config["cargas"]` y, para cada tabla, arma sus parámetros con `parametros_carga` y llama a `_cargar_tabla`. La llamada está dentro de un `try ... except`: si una tabla falla, el error se registra en el log y en su `Resumen`, y se continúa con la siguiente.

Dentro de `_cargar_tabla`:

| Paso | Código | Conexión | Archivo SQL |
|---|---|---|---|
| 1 | `lz.ejecutar(...)` | LZ | `lz/01_crear_tabla_resultado.sql` |
| 2 | `lz.ejecutar(...)` | LZ | `lz/02_crear_tabla_temporal.sql` |
| 3 | `_cargar_temporal(...)` | Nacional y LZ | `nacional/consulta_origen.sql`, `lz/03_insertar_lote_temporal.sql` |
| 4 | `lz.ejecutar(...)` | LZ | `lz/04_insertar_resultado.sql` |
| 5 | `lz.consultar_fila(...)` | LZ | `lz/05_validar_carga.sql` |
| Limpieza | `_borrar_temporal(...)` | LZ | `lz/99_limpieza.sql` |

Los pasos 3 a 5 están dentro de un `try ... finally`; la limpieza está en el `finally`, por lo que se ejecuta aunque alguno falle. Si el paso 3 devuelve 0 filas, la función retorna antes del paso 4 (la limpieza igual se ejecuta).

`ejecutar_cargas` devuelve una lista con un `Resumen` por tabla: `origen`, `destino`, `filas_extraidas`, `filas_cargadas`, `fechas_nulas` y `error` (`None` si la tabla terminó bien).

**6. Cierre** — `main` cierra las dos conexiones en un `finally` y muestra el mensaje final con una línea por tabla, armada por `_linea_resumen`. El mensaje es de error si alguna tabla falló, de advertencia si alguna no tuvo datos y de información si todas terminaron bien.

---

## Lectura de archivos SQL

Toda la lectura de SQL pasa por `configuracion.py`. Ningún otro módulo abre archivos `.sql`.

### Dónde se definen las rutas

Las rutas de los archivos están como constantes al inicio de `carga.py`, relativas a la carpeta `sql/`:

```python
SQL_CONSULTA_NACIONAL = "nacional/consulta_origen.sql"
SQL_CREAR_TABLA_RESULTADO = "lz/01_crear_tabla_resultado.sql"
SQL_CREAR_TABLA_TEMPORAL = "lz/02_crear_tabla_temporal.sql"
SQL_INSERTAR_LOTE_TEMPORAL = "lz/03_insertar_lote_temporal.sql"
SQL_INSERTAR_RESULTADO = "lz/04_insertar_resultado.sql"
SQL_VALIDAR_CARGA = "lz/05_validar_carga.sql"
SQL_LIMPIEZA = "lz/99_limpieza.sql"
```

### Funciones de lectura

```
leer_sentencias(ruta_relativa, params)                 leer_plantilla_lote(ruta_relativa, params)
        │                                                        │
        ├── _leer_sin_comentarios(ruta_relativa)                 ├── _leer_sin_comentarios(ruta_relativa)
        │      lee RUTA_SQL / ruta_relativa (UTF-8)              │
        │      quita las líneas que empiezan con --              │
        │                                                        │
        ├── _reemplazar_parametros(texto, ruta, params)          ├── _reemplazar_parametros(texto, ruta,
        │      texto.format(**params)                            │        params + {"valores": "{valores}"})
        │                                                        │
        └── separa por ";" → lista de sentencias                 └── una sola sentencia, con {valores} intacto
```

| Función | Entrada | Salida | Uso |
|---|---|---|---|
| `leer_sentencias` | ruta relativa a `sql/` y diccionario de parámetros | `list[str]`, una sentencia por elemento, sin `;` | Todos los archivos excepto `03` |
| `leer_plantilla_lote` | ruta relativa a `sql/` y diccionario de parámetros | `str` con el marcador `{valores}` | Solo `03_insertar_lote_temporal.sql` |

### Ejemplo de transformación

Archivo `sql/lz/02_crear_tabla_temporal.sql` (resumido):

```sql
-----------------------------------------------------------------------------
-- Descripción: Crea de cero la tabla temporal ...
-------------------------------- Query Start --------------------------------
DROP TABLE IF EXISTS {zona_p}.{tabla_temporal} PURGE;

create table {zona_p}.{tabla_temporal}
(
    cod_aplicacion      string,
    ...
)
stored as parquet tblproperties('transactional'='false')
;
```

Con los parámetros de la primera tabla (`zona_p = "proceso_vspc_serv"`, `tabla_temporal = "tmp_visionr_ceautoe"`), `leer_sentencias` devuelve:

```python
[
    "DROP TABLE IF EXISTS proceso_vspc_serv.tmp_visionr_ceautoe PURGE",
    "create table proceso_vspc_serv.tmp_visionr_ceautoe\n(\n    cod_aplicacion      string,\n ... tblproperties('transactional'='false')",
]
```

Con los de la segunda tabla, el mismo archivo produce las sentencias sobre `tmp_visionr_ceautoedt`.

Luego `lz.ejecutar` recorre la lista y ejecuta cada sentencia por separado, porque el driver ODBC de Impala ejecuta una sentencia por llamada.

### De dónde salen los parámetros

Los parámetros de cada tabla son el bloque `parametros_lz` de `config.json` más su entrada en la lista `cargas`. `carga.parametros_carga` los une:

```python
def parametros_carga(config, carga):
    return {**config["parametros_lz"], **carga}
```

Para la primera tabla el resultado es:

```python
{
    "zona_r": "proceso_vspc_serv",
    "zona_p": "proceso_vspc_serv",
    "tabla_origen": "VISIONR.CEAUTOE",
    "tabla_resultado": "visionr_ceautoe",
    "tabla_temporal": "tmp_visionr_ceautoe",
}
```

Ese diccionario se pasa a cada llamada de `leer_sentencias` o `leer_plantilla_lote` de esa tabla. Un `{nombre}` en un archivo SQL se reemplaza por `params["nombre"]`. Si el nombre no existe, `_reemplazar_parametros` lanza un `KeyError` que indica el archivo y el parámetro.

### Consulta de la Nacional

`consulta_origen.sql` se lee con la misma función. Su único parámetro es `{tabla_origen}` en el `FROM`, por lo que el mismo archivo produce la consulta de cada tabla:

```python
consulta = leer_sentencias(SQL_CONSULTA_NACIONAL, params)[0]
# primera tabla:  SELECT CEAP65 as cod_aplicacion, ... FROM VISIONR.CEAUTOE
# segunda tabla:  SELECT CEAP65 as cod_aplicacion, ... FROM VISIONR.CEAUTOEDT
```

Ese texto se usa dos veces en `_cargar_temporal`:

| Uso | Función | Sentencia enviada al AS/400 |
|---|---|---|
| Contar filas | `nacional.contar_filas` | `SELECT COUNT(*) FROM (<consulta>) AS origen` |
| Leer datos | `nacional.abrir_consulta` | `<consulta>` tal cual |

---

## Recorrido de los datos

Recorrido de una fila desde el AS/400 hasta la tabla final:

```
AS/400 ──► pyodbc ──► nacional.leer_por_lotes ──► lz.insertar_lote ──► temporal ──► 04_insertar_resultado ──► tabla final
           Row          lista de Row (lote)         INSERT ... VALUES     STRING       CAST + particiones        tipos finales
```

### 1. Lectura por lotes (`nacional.py`)

`abrir_consulta` ejecuta la consulta y devuelve el cursor sin traer filas. `leer_por_lotes` es un generador: cada vez que el `for` de `_cargar_temporal` pide un lote, llama a `cursor.fetchmany(filas_por_lote)` y entrega esa lista. Solo hay un lote en memoria a la vez.

```python
for numero, lote in enumerate(nacional.leer_por_lotes(cursor, filas_por_lote), start=1):
    lz.insertar_lote(con_lz, plantilla, lote)
```

### 2. Conversión a texto SQL (`lz.py`)

`insertar_lote` convierte cada valor con `_literal`, que usa `_a_texto`:

| Valor recibido de pyodbc | `_a_texto` | `_literal` |
|---|---|---|
| `'CA   '` (texto) | `'CA'` (sin espacios a la derecha) | `'CA'` |
| `Decimal('20260930')` | `'20260930'` | `'20260930'` |
| `Decimal('1234.50')` | `'1234.50'` | `'1234.50'` |
| `None` | — | `NULL` |
| `"O'Brien"` | `"O'Brien"` | `'O\'Brien'` (comilla escapada) |

Ejemplo para un lote de dos filas:

```python
lote = [
    ('CA   ', '001', '4105', Decimal('20260930'), Decimal('1234.50'), '120', '120', 'COP', Decimal('1.00'), Decimal('1234.50')),
    ('CB   ', '002', '5105', Decimal('20260930'), Decimal('-80.00'),  '345', '345', 'USD', Decimal('4100.25'), Decimal('-328020.00')),
]
```

se convierte en:

```sql
('CA', '001', '4105', '20260930', '1234.50', '120', '120', 'COP', '1.00', '1234.50'),
('CB', '002', '5105', '20260930', '-80.00', '345', '345', 'USD', '4100.25', '-328020.00')
```

Ese texto reemplaza el marcador `{valores}` de la plantilla:

```python
cursor.execute(plantilla.replace(MARCADOR_VALORES, valores))
```

y queda una sentencia `INSERT INTO proceso_vspc_serv.tmp_visionr_ceautoe (...) VALUES (...), (...)`.

Se usa `str.replace` y no `str.format` porque los datos pueden contener `{` o `}`, que `format` interpretaría como parámetros.

### 3. Tipos finales (`04_insertar_resultado.sql`)

En la temporal todo es texto. El paso 4 aplica los tipos y agrega las particiones:

```sql
CAST(TO_TIMESTAMP(fecha_efectiva, 'yyyyMMdd') AS DATE) AS fecha_efectiva,
CAST(monto_trx AS DECIMAL(20,2)) AS monto_trx,
...
CAST(YEAR(CURRENT_DATE()) AS SMALLINT) AS ingestion_year,
```

---

## Configuración, conexiones y log entre módulos

### Configuración

`config.json` se lee una sola vez, en `main`, y el diccionario se pasa como parámetro. Ningún otro módulo vuelve a leer el archivo.

| Llave | La usa | Para |
|---|---|---|
| `nacional.dsn` | `main` → `nacional.conectar` | Conexión a la Nacional |
| `lz.dsn` | `main` → `lz.conectar` | Conexión a la LZ |
| `lz.pedir_credenciales` | `main` → `interfaz.solicitar_credenciales` | Mostrar o no los campos de la LZ |
| `parametros_lz` | `carga.parametros_carga` → `leer_sentencias` / `leer_plantilla_lote` | Parámetros comunes a todas las tablas (`{zona_r}`, `{zona_p}`) |
| `cargas` | `carga.ejecutar_cargas` (recorre la lista), `main` (ventana), `probar_conexiones` | Tablas a cargar y sus parámetros propios (`{tabla_origen}`, `{tabla_resultado}`, `{tabla_temporal}`) |
| `carga.filas_por_lote` | `carga.ejecutar_cargas` → `nacional.leer_por_lotes` | Tamaño de cada lote |

### Conexiones

Las conexiones se crean en `main` y se pasan como parámetro a quien las necesita. Las funciones de `nacional.py` y `lz.py` reciben la conexión como primer argumento (`con`) y no guardan estado propio.

```
main.main()
  con_nal = nacional.conectar(...)
  con_lz  = lz.conectar(...)
  │
  └── carga.ejecutar_cargas(con_nal, con_lz, config)
        └── _cargar_tabla(con_nal, con_lz, ...)   ← una vez por tabla, con las mismas conexiones
              ├── nacional.contar_filas(con_nal, ...)
              ├── nacional.abrir_consulta(con_nal, ...)
              ├── lz.ejecutar(con_lz, ...)
              ├── lz.insertar_lote(con_lz, ...)
              └── lz.consultar_fila(con_lz, ...)
  (finally) con_nal.close(); con_lz.close()
```

Quien abre las conexiones (`main`) es quien las cierra. Las dos tablas se cargan con las mismas conexiones, una después de otra.

### Log

Cada módulo obtiene el mismo logger por nombre al importarse:

```python
from bitacora import NOMBRE_LOG     # "carga"
log = logging.getLogger(NOMBRE_LOG)
```

`logging.getLogger` devuelve siempre el mismo objeto para el mismo nombre. `main` llama a `configurar_bitacora` una vez al inicio y le agrega las salidas (consola y archivo); desde ese momento todos los `log.info(...)` de `main`, `carga`, `nacional` y `lz` terminan en el mismo archivo.

---

## Manejo de errores

Los errores no se capturan en los módulos de acceso a datos. Hay dos niveles donde se manejan:

- **Por tabla** (`carga.ejecutar_cargas`): un error durante la carga de una tabla se registra en el log y en el `Resumen` de esa tabla, y se continúa con la siguiente.
- **General** (`main`): los errores fuera de la carga de tablas (configuración, conexiones) detienen el proceso.

```
nacional.py / lz.py / configuracion.py
        │  lanzan la excepción
        ▼
carga._cargar_tabla     ── finally: _borrar_temporal (no oculta el error original)
        │
        ▼
carga.ejecutar_cargas   ── except: log.exception(...) + Resumen(error=...) → sigue con la siguiente tabla
        │
        ▼
main.main               ── alguna tabla con error → mostrar_resultado("error", ...) → return 1

main.main  ── except (config, conexiones): log.exception(...) + mostrar_resultado("error", ...) → return 1
           └─ finally: cierra las conexiones
```

| Excepción | Origen | Causa |
|---|---|---|
| `ConnectionError` | `nacional.conectar`, `lz.conectar` | Falla de conexión. El mensaje incluye el DSN y una sugerencia |
| `KeyError` | `configuracion._reemplazar_parametros` | Un SQL usa un parámetro que no está en `config.json` |
| `ValueError` | `carga._cargar_temporal` | Las columnas de la consulta no coinciden con `COLUMNAS_NACIONAL` (error por tabla) |
| `RuntimeError` | `carga._cargar_tabla` | El conteo de la partición no coincide con las filas extraídas (error por tabla) |
| `pyodbc.Error` | `nacional.py`, `lz.py` | Error de SQL o de permisos en la base de datos (error por tabla si ocurre durante su carga) |

Casos que no detienen el proceso:

| Caso | Dónde | Comportamiento |
|---|---|---|
| Falla el `COUNT(*)` de la Nacional | `nacional.contar_filas` | Devuelve `None`, registra una advertencia; el avance se muestra sin total |
| Falla el borrado de la temporal | `carga._borrar_temporal` | Registra una advertencia; la siguiente ejecución la borra |
| Fechas inválidas | `carga._cargar_tabla` (paso 5) | Registra una advertencia con la cantidad |
| Falla una tabla | `carga.ejecutar_cargas` | Se registra el error y se carga la siguiente tabla |

---

## Flujo de la prueba de conexiones

`probar_conexiones.bat` ejecuta `src/probar_conexiones.py`. Reutiliza las mismas funciones de conexión y lectura de SQL, pero solo ejecuta consultas de lectura.

```
probar_conexiones.bat
└── probar_conexiones.main()
    ├── bitacora.configurar_bitacora(RUTA_LOGS)
    ├── configuracion.cargar_config()
    ├── interfaz.solicitar_credenciales(..., texto_boton="Probar conexiones")
    ├── _probar_nacional(config, cred_nal)
    │   ├── nacional.conectar(dsn, usuario, password)
    │   └── por cada entrada de config["cargas"]:
    │       ├── configuracion.leer_sentencias("nacional/consulta_origen.sql", parametros_carga(...))[0]
    │       └── nacional.contar_filas(con, consulta)   → SELECT COUNT(*) FROM (<consulta>) AS origen
    ├── _probar_lz(config, cred_lz)
    │   ├── lz.conectar(dsn, usuario?, password?)
    │   ├── lz.consultar_fila(con, "SELECT user()")
    │   └── por cada entrada de config["cargas"]:
    │       └── lz.consultar_fila(con, "SHOW TABLES IN {zona_r} LIKE '{tabla_resultado}'")
    └── interfaz.mostrar_resultado("info" | "error", ...)
```

Diferencias con la carga:

- Cada prueba captura sus propios errores y devuelve `(ok, texto)`, para que una falla no impida probar la otra conexión.
- Cada prueba abre y cierra su propia conexión.
- No usa `carga.ejecutar_cargas`; de `carga.py` solo toma la constante `SQL_CONSULTA_NACIONAL` y la función `parametros_carga`, para leer la misma consulta que usa la carga con los mismos parámetros.

---

## Flujo de la ventana de credenciales

`interfaz.solicitar_credenciales` es la única función que usan `main` y `probar_conexiones`. El resto del módulo es interno.

```
solicitar_credenciales(ruta_fondo, info, pedir_lz, texto_boton)
├── sin Tkinter o sin Pillow → _pedir_por_consola(pedir_lz)
└── _VentanaCredenciales(...)
    ├── __init__
    │   ├── _activar_alta_resolucion()        escala de Windows (125 %, 150 %)
    │   ├── tk.Tk() oculto
    │   ├── _crear_fuentes(root)
    │   └── _construir(ruta_fondo, info)      calcula la posición de cada elemento
    │       ├── encabezado          → _formas (ícono) y _elementos (textos)
    │       ├── _panel_info         → _formas (recuadro) y _elementos (textos)
    │       ├── _seccion × n        → _campo × 2 (usuario, contraseña)
    │       ├── texto de error
    │       ├── _botones            → _boton × 2 (Cancelar, principal)
    │       └── _armar_ventana
    │           ├── tamaño y posición de la ventana
    │           ├── _imagen_base    fondo + sombra + tarjeta + _formas (Pillow)
    │           └── ejecuta cada función de _elementos sobre el Canvas
    └── mostrar()
        ├── root.mainloop()                   espera la acción del usuario
        │   ├── Enter / botón principal → _aceptar → valida → _terminar(credenciales)
        │   └── Esc / Cancelar / cerrar → _cancelar → _terminar(None)
        ├── _destruir()                       destruye la ventana fuera de los eventos
        └── return resultado
```

La construcción se hace en dos fases porque el tamaño de la ventana depende del alto de la tarjeta:

1. `_construir` recorre los elementos de arriba hacia abajo, calcula sus posiciones relativas a la tarjeta y los registra en dos listas: `_formas` (imágenes fijas que se pintan con Pillow) y `_elementos` (funciones que crean textos, campos y botones en el Canvas).
2. Con el alto final, `_armar_ventana` define el tamaño de la ventana, pinta la imagen base y ejecuta las funciones de `_elementos` con el desplazamiento de la tarjeta.

`_terminar` no destruye la ventana; solo guarda el resultado y sale del `mainloop`. La destrucción ocurre después, en `_destruir`, fuera de cualquier evento de Tk, y la bandera `_cerrando` evita que los efectos de foco y hover modifiquen la ventana mientras se cierra.

---

## Índice de funciones

| Función | Archivo | La llama | Descripción |
|---|---|---|---|
| `main` | `main.py` | `ejecutar.bat` | Orquesta la carga |
| `main` | `probar_conexiones.py` | `probar_conexiones.bat` | Orquesta la prueba de conexiones |
| `_linea_resumen` | `main.py` | `main.main` | Texto del resultado de una tabla para el mensaje final |
| `_probar_nacional` | `probar_conexiones.py` | `probar_conexiones.main` | Conecta y cuenta las filas de cada tabla de origen |
| `_probar_lz` | `probar_conexiones.py` | `probar_conexiones.main` | Conecta, consulta el usuario, la zona y cada tabla destino |
| `ejecutar_cargas` | `carga.py` | `main.main` | Recorre `cargas` y carga cada tabla; aísla los errores por tabla |
| `parametros_carga` | `carga.py` | `ejecutar_cargas`, `_probar_nacional` | Une `parametros_lz` con la entrada de una tabla |
| `_cargar_tabla` | `carga.py` | `ejecutar_cargas` | Pasos 1 a 5 y limpieza de una tabla |
| `_cargar_temporal` | `carga.py` | `_cargar_tabla` | Paso 3: Nacional → temporal por lotes |
| `_tiempo_restante` | `carga.py` | `_cargar_temporal` | Estimación del tiempo restante |
| `_borrar_temporal` | `carga.py` | `_cargar_tabla` | Ejecuta `99_limpieza.sql` |
| `conectar` | `nacional.py` | `main`, `_probar_nacional` | Conexión ODBC a la Nacional |
| `contar_filas` | `nacional.py` | `_cargar_temporal`, `_probar_nacional` | `COUNT(*)` sobre la consulta |
| `abrir_consulta` | `nacional.py` | `_cargar_temporal` | Ejecuta la consulta y devuelve el cursor |
| `columnas` | `nacional.py` | `_cargar_temporal` | Nombres de columnas del cursor |
| `leer_por_lotes` | `nacional.py` | `_cargar_temporal` | Generador de lotes con `fetchmany` |
| `conectar` | `lz.py` | `main`, `_probar_lz` | Conexión ODBC a la LZ |
| `ejecutar` | `lz.py` | `_cargar_tabla`, `_borrar_temporal` | Ejecuta una lista de sentencias |
| `consultar_fila` | `lz.py` | `_cargar_tabla`, `_probar_lz` | Ejecuta una consulta y devuelve la primera fila |
| `insertar_lote` | `lz.py` | `_cargar_temporal` | Arma y ejecuta el `INSERT ... VALUES` de un lote |
| `_literal`, `_a_texto` | `lz.py` | `insertar_lote` | Convierte valores a literales de Impala |
| `_resumir` | `lz.py` | `ejecutar` | Resumen de la sentencia para el log |
| `cargar_config` | `configuracion.py` | `main`, `probar_conexiones.main` | Lee `config.json` |
| `leer_sentencias` | `configuracion.py` | `carga`, `_probar_nacional` | Lee un SQL y lo separa en sentencias |
| `leer_plantilla_lote` | `configuracion.py` | `_cargar_temporal` | Lee el SQL de inserción por lotes |
| `_leer_sin_comentarios` | `configuracion.py` | `leer_sentencias`, `leer_plantilla_lote` | Lee el archivo y quita comentarios |
| `_reemplazar_parametros` | `configuracion.py` | `leer_sentencias`, `leer_plantilla_lote` | Reemplaza `{parámetros}` |
| `configurar_bitacora` | `bitacora.py` | `main`, `probar_conexiones.main` | Configura el log |
| `miles`, `duracion` | `bitacora.py` | `main`, `carga`, `probar_conexiones` | Formato de números y tiempos |
| `solicitar_credenciales` | `interfaz.py` | `main`, `probar_conexiones.main` | Ventana de credenciales |
| `mostrar_resultado` | `interfaz.py` | `main`, `probar_conexiones.main` | Mensaje final |
