# Carga VISIONR.CEAUTOE y VISIONR.CEAUTOEDT → LZ Nube

Proceso de escritorio que extrae las tablas `VISIONR.CEAUTOE` y `VISIONR.CEAUTOEDT` de la Nacional (AS/400) y las carga en la LZ Nube (Impala CDP) en las tablas `{zona_r}.visionr_ceautoe` y `{zona_r}.visionr_ceautoedt`, particionadas por fecha de ingestión. Las dos tablas tienen la misma estructura y se extraen con la misma consulta.

El proceso solicita las credenciales de la Nacional en una ventana y, para cada tabla, carga la información completa en una tabla temporal por lotes, la pasa a la tabla final reemplazando únicamente la partición del día y valida el resultado. Las tablas a cargar se definen en la lista `cargas` de `config.json`.

## Contenido

1. [Requisitos](#requisitos)
2. [Estructura del proyecto](#estructura-del-proyecto)
3. [Ejecución](#ejecución)
4. [Configuración](#configuración)
5. [Flujo del proceso](#flujo-del-proceso)
6. [Tabla destino](#tabla-destino)
7. [Tabla temporal](#tabla-temporal)
8. [Conexiones](#conexiones)
9. [Módulos](#módulos)
10. [Archivos SQL](#archivos-sql)
11. [Reejecución](#reejecución)
12. [Validaciones y logs](#validaciones-y-logs)
13. [Rendimiento](#rendimiento)
14. [Solución de problemas](#solución-de-problemas)
15. [Mantenimiento](#mantenimiento)

---

## Requisitos

| Requisito | Detalle |
|---|---|
| Equipo | PC corporativo con acceso a la red del banco (o VPN) |
| Python | 3.9 o superior, 64 bits |
| DSN Nacional | DSN ODBC `NACIONALET01` configurado (IBM i Access) |
| DSN LZ | DSN ODBC `Impala-cdp-kudu` configurado (Cloudera ODBC Driver for Impala) con usuario y contraseña guardados |
| Usuario Nacional | Permiso de lectura sobre `VISIONR.CEAUTOE` y `VISIONR.CEAUTOEDT` |
| Usuario LZ | El usuario guardado en el DSN debe poder crear tablas e insertar en `zona_r` y `zona_p` |
| Librerías | `pyodbc==5.3.0`, `Pillow==11.3.0` (se instalan automáticamente desde `requirements.txt`) |

El bitness del DSN debe coincidir con el de Python: un Python de 64 bits solo ve los DSN creados en el administrador ODBC de 64 bits.

---

## Estructura del proyecto

```
carga_ceautoe_lz/
├── ejecutar.bat                 Ejecuta la carga completa
├── probar_conexiones.bat        Prueba las conexiones sin escribir datos
├── requirements.txt             Dependencias de Python
├── config/
│   └── config.json              DSNs, zonas, tablas a cargar y tamaño de lote
├── docs/
│   ├── documentacion.md         Este documento
│   └── flujo_del_codigo.md      Recorrido del código: llamadas, lectura de SQL y datos
├── img/
│   └── background.png           Fondo de la ventana de credenciales
├── logs/                        Logs de cada ejecución (se crea automáticamente)
├── sql/
│   ├── nacional/
│   │   └── consulta_origen.sql          Consulta de extracción en la Nacional (una por tabla de origen)
│   └── lz/
│       ├── 01_crear_tabla_resultado.sql
│       ├── 02_crear_tabla_temporal.sql
│       ├── 03_insertar_lote_temporal.sql
│       ├── 04_insertar_resultado.sql
│       ├── 05_validar_carga.sql
│       └── 99_limpieza.sql
└── src/
    ├── main.py                  Punto de entrada de la carga
    ├── probar_conexiones.py     Punto de entrada de la prueba de conexiones
    ├── interfaz.py              Ventana de credenciales y mensajes finales
    ├── carga.py                 Pasos de la carga
    ├── nacional.py              Conexión y lectura de la Nacional
    ├── lz.py                    Conexión y ejecución en la LZ
    ├── configuracion.py         Rutas, config.json y lectura de SQL
    └── bitacora.py              Log en consola y archivo
```

---

## Ejecución

### Carga completa

Ejecutar `ejecutar.bat` (doble clic). El archivo:

1. Se ubica en la carpeta del proyecto, sin importar desde dónde se invoque.
2. Crea el ambiente virtual `ambiente/` si no existe.
3. Activa el ambiente e instala las dependencias de `requirements.txt`.
4. Ejecuta `src/main.py`.
5. Deja la consola abierta al finalizar (`pause`) para revisar el resultado.

La ventana muestra el DSN de la Nacional, las tablas de origen, la zona destino, las tablas destino y la fecha de la partición. Se deben ingresar usuario y contraseña de la Nacional y presionar **Ejecutar carga** (o `Enter`). `Esc` o **Cancelar** terminan el proceso sin conectarse a nada.

Al finalizar se muestra un mensaje con el resultado de cada tabla (filas cargadas o error) y la duración total.

### Prueba de conexiones

Ejecutar `probar_conexiones.bat`. Abre la misma ventana y, con el botón **Probar conexiones**, realiza únicamente consultas de lectura:

| Conexión | Prueba | Resultado informado |
|---|---|---|
| Nacional | Conexión y `COUNT(*)` de la consulta de cada tabla de origen | Si conecta y si el usuario puede leer cada tabla (cantidad de filas) |
| LZ | Conexión, `SELECT user()` y `SHOW TABLES IN {zona_r} LIKE '{tabla_resultado}'` por cada tabla destino | Usuario con el que conecta el DSN, si la zona es accesible y si cada tabla destino ya existe |

Ambas conexiones se prueban aunque una falle. La prueba no valida permisos de creación de tablas; eso solo se comprueba en una carga real.

### Credenciales

Las credenciales ingresadas se usan únicamente en memoria durante la ejecución; no se guardan en disco ni se escriben en el log. El campo de contraseña incluye la opción **Mostrar / Ocultar**. Si la ventana no puede abrirse (Tkinter o Pillow no disponibles), el proceso las solicita por consola.

---

## Configuración

Archivo: `config/config.json`.

| Llave | Valor por defecto | Descripción |
|---|---|---|
| `nacional.dsn` | `NACIONALET01` | DSN ODBC de la Nacional |
| `lz.dsn` | `Impala-cdp-kudu` | DSN ODBC de la LZ |
| `lz.pedir_credenciales` | `false` | `false`: usa la autenticación guardada en el DSN. `true`: la ventana solicita también usuario y contraseña de la LZ |
| `parametros_lz.zona_r` | `proceso_vspc_serv` | Zona donde se crean las tablas finales |
| `parametros_lz.zona_p` | `proceso_vspc_serv` | Zona de trabajo donde se crean y se borran las tablas temporales |
| `cargas` | 2 entradas | Tablas a cargar, en el orden en que se procesan (ver abajo) |
| `carga.filas_por_lote` | `2000` | Filas enviadas a la LZ en cada `INSERT` a la temporal |

La llave `_notas` es informativa y el código no la lee.

### Tablas a cargar (`cargas`)

Cada entrada de la lista `cargas` define una tabla:

| Llave | Descripción | Valores actuales |
|---|---|---|
| `tabla_origen` | Tabla de la Nacional que se consulta | `VISIONR.CEAUTOE` · `VISIONR.CEAUTOEDT` |
| `tabla_resultado` | Nombre de la tabla final en `zona_r` | `visionr_ceautoe` · `visionr_ceautoedt` |
| `tabla_temporal` | Nombre de la tabla temporal en `zona_p` | `tmp_visionr_ceautoe` · `tmp_visionr_ceautoedt` |

Cada tabla se procesa de forma independiente: si una falla, la siguiente se procesa igual y el resumen final indica el resultado de cada una.

### Parámetros en los SQL

Para cada tabla, los archivos SQL reciben como parámetros las llaves de `parametros_lz` más las de su entrada en `cargas`: `{zona_r}`, `{zona_p}`, `{tabla_origen}`, `{tabla_resultado}` y `{tabla_temporal}`. Para agregar un parámetro común a todas las tablas se añade a `parametros_lz`; para uno propio de una tabla, a su entrada en `cargas`.

### Pruebas y producción

El ambiente se define únicamente con `zona_r`:

| Ambiente | `zona_r` |
|---|---|
| Pruebas | `proceso_vspc_serv` |
| Producción | `resultados_vspc_serv` |

`zona_p` permanece en `proceso_vspc_serv` en ambos casos. Las dos tablas van siempre a la misma `zona_r`. Los archivos SQL no deben modificarse para cambiar de ambiente: `{zona_r}` se usa en la creación, el insert final y la validación, y los tres deben apuntar a la misma zona.

---

## Flujo del proceso

```
┌─────────────────────────┐   lotes de filas_por_lote   ┌──────────────────────────────┐
│ Nacional (AS/400)       │ ──────────────────────────► │ {zona_p}.{tabla_temporal}    │
│ {tabla_origen}          │   INSERT INTO ... VALUES    │ todas las columnas STRING    │
└─────────────────────────┘                             └──────────────┬───────────────┘
                                                                       │ INSERT OVERWRITE
                                                                       │ partición del día
                                                                       ▼
                                                        ┌──────────────────────────────┐
                                                        │ {zona_r}.{tabla_resultado}   │
                                                        │ tipos finales · parquet      │
                                                        └──────────────────────────────┘
```

El flujo se repite para cada entrada de `cargas` (primero `VISIONR.CEAUTOE`, luego `VISIONR.CEAUTOEDT`).

Secuencia de `main.py`:

1. Lee `config/config.json` e inicia el log.
2. Muestra la ventana de credenciales.
3. Conecta a la Nacional y a la LZ. Ambas conexiones se abren antes de extraer datos para detectar fallas de conexión de inmediato; las dos tablas usan las mismas conexiones.
4. Para cada tabla de `cargas`, ejecuta los pasos de `carga.py`:

| Paso | Acción | Archivo SQL |
|---|---|---|
| 1/5 | Crea la tabla final si no existe | `01_crear_tabla_resultado.sql` |
| 2/5 | Borra y crea de nuevo la tabla temporal | `02_crear_tabla_temporal.sql` |
| 3/5 | Cuenta las filas de origen (solo para mostrar avance), valida las columnas de la consulta, lee la Nacional por lotes e inserta cada lote en la temporal | `consulta_origen.sql`, `03_insertar_lote_temporal.sql` |
| 4/5 | Pasa la temporal a la tabla final aplicando tipos; reemplaza solo la partición del día | `04_insertar_resultado.sql` |
| 5/5 | Compara las filas de la partición del día con las extraídas y cuenta fechas nulas | `05_validar_carga.sql` |
| Final | Borra la tabla temporal. Se ejecuta siempre, incluso si un paso anterior falla | `99_limpieza.sql` |

5. Cierra las conexiones y muestra el mensaje final con el resultado de cada tabla.

Si la Nacional no devuelve filas para una tabla, se omiten sus pasos 4 y 5: la partición del día de esa tabla no se modifica y el resumen lo indica con una advertencia.

Si una tabla falla en cualquier paso, se registra el error, se borra su temporal y se continúa con la siguiente. El proceso termina con error si al menos una tabla falló.

---

## Tabla destino

`{zona_r}.visionr_ceautoe` y `{zona_r}.visionr_ceautoedt`, formato parquet, `transactional=false`. Ambas tienen la misma estructura; el comentario de cada tabla indica su tabla de origen.

| Columna | Tipo | Campo AS/400 | Descripción |
|---|---|---|---|
| `cod_aplicacion` | `string` | `CEAP65` | Código de la aplicación origen que genera o registra la transacción contable |
| `concepto_contable` | `string` | `CECO65` | Concepto contable asociado al movimiento o transacción registrada |
| `codigo_contable` | `string` | `CECD65` | Código de la cuenta contable utilizada para el registro de la operación |
| `fecha_efectiva` | `date` | `CEFT65` | Fecha efectiva en la que se reconoce o contabiliza la transacción |
| `monto_trx` | `decimal(20,2)` | `CEMT65` | Valor monetario de la transacción en la moneda de origen |
| `oficina_contable` | `string` | `CESU65` | Código de la oficina o unidad contable responsable del registro |
| `oficina_origen` | `string` | `CENS65` | Código de la oficina donde se originó la transacción |
| `cod_moneda` | `string` | `CEFC65` | Código de la moneda de la transacción |
| `tasa_cambio` | `decimal(20,2)` | `CETC65` | Tasa de cambio aplicada para obtener el valor equivalente |
| `monto_equivalente` | `decimal(20,2)` | `CEME65` | Valor equivalente de la transacción después de la conversión |

Particiones:

| Columna | Tipo | Regla |
|---|---|---|
| `ingestion_year` | `smallint` | `YEAR(CURRENT_DATE())` |
| `ingestion_month` | `smallint` | `MONTH(CURRENT_DATE())` |
| `ingestion_day` | `smallint` | `DAY(CURRENT_DATE())` |

Las descripciones de columnas y particiones quedan registradas como `COMMENT` en la tabla.

### Transformaciones

| Dato | Transformación |
|---|---|
| Textos | Se eliminan los espacios a la derecha con los que el AS/400 rellena los campos. Los espacios a la izquierda se conservan |
| `fecha_efectiva` | Llega como número `AAAAMMDD` (ej. `20260930`) y se convierte con `CAST(TO_TIMESTAMP(fecha_efectiva, 'yyyyMMdd') AS DATE)`. Valores inválidos o vacíos quedan en `NULL` y se informan en la validación |
| Montos y tasa | Se convierten a `DECIMAL(20,2)` |
| Nulos | Los `NULL` del origen se conservan como `NULL` |

La fecha de las particiones se calcula con `CURRENT_DATE()` del servidor de Impala, no con la fecha del PC. La fecha que muestra la ventana corresponde al PC y es solo informativa.

---

## Tabla temporal

Una por tabla: `{zona_p}.tmp_visionr_ceautoe` y `{zona_p}.tmp_visionr_ceautoedt`, con las mismas columnas de la consulta, todas de tipo `string`. Cada una se crea al inicio de la carga de su tabla y se borra al terminarla con `DROP TABLE ... PURGE`.

Razones para usar una tabla intermedia:

- **Archivos pequeños:** cada `INSERT` en Impala genera al menos un archivo parquet. Insertar los lotes directamente en la tabla final dejaría cientos de archivos por partición diaria. Con la temporal, la tabla final recibe un único `INSERT`. Impala reparte ese `INSERT` entre las máquinas del clúster y cada una escribe su propio archivo en la partición, por lo que la cantidad de archivos por día depende del clúster (en las pruebas quedaron 49 archivos para 8 MB).
- **Carga todo o nada:** si el proceso falla durante la extracción o los lotes, la tabla final no se modifica.
- **Tipos en SQL:** los datos se envían como texto y las conversiones de tipo se hacen en `04_insertar_resultado.sql`, donde son visibles y modificables.

Si una ejecución termina sin poder borrar la temporal, la siguiente ejecución la elimina en el paso 2.

---

## Conexiones

### Nacional (AS/400)

```python
pyodbc.connect(f"DSN={dsn};UID={usuario};PWD={password}", autocommit=True)
```

Es la misma conexión usada por `EUC_RC1_modificado`. El usuario y la contraseña provienen de la ventana.

La lectura se hace con un cursor y `fetchmany(filas_por_lote)`, de modo que la tabla completa nunca se carga en memoria.

### LZ Nube (Impala)

```python
pyodbc.connect(f"DSN={dsn}", autocommit=True)
```

El driver de Cloudera completa la autenticación con el usuario y la contraseña guardados en la configuración del DSN. Es la misma conexión que realiza el paquete interno `helper` (`Helper._obtener_conexion`) usado por `orquestador2` cuando se ejecuta en un PC. Los parámetros `cdp_endpoint` y `username` de las configuraciones de `orquestador2` no intervienen en esta conexión.

Con `lz.pedir_credenciales = true`, la cadena pasa a ser `DSN={dsn};UID={usuario};PWD={password}` con los valores ingresados en la ventana.

Si cambia la contraseña de red del usuario guardado en el DSN, debe actualizarse en el administrador ODBC; de lo contrario la conexión a la LZ falla por autenticación.

---

## Módulos

### `main.py`

Punto de entrada de la carga. Configura el log, lee la configuración, muestra la ventana, abre las conexiones, invoca `ejecutar_cargas` y muestra el mensaje final con una línea por tabla (`_linea_resumen`). Cierra las conexiones en cualquier caso. Devuelve `0` si todas las tablas terminan bien o sin datos, y `1` si alguna falla o si se cancela.

### `probar_conexiones.py`

Punto de entrada de la prueba de conexiones. Ejecuta `_probar_nacional` (conteo de cada tabla de origen) y `_probar_lz` (estado de cada tabla destino) de forma independiente y muestra el resultado de ambas. No crea ni modifica objetos en ninguna base.

### `interfaz.py`

| Elemento | Descripción |
|---|---|
| `Credenciales` | Usuario y contraseña de una conexión |
| `solicitar_credenciales(ruta_fondo, info, pedir_lz, texto_boton)` | Muestra la ventana y devuelve `(credenciales_nacional, credenciales_lz)`; `credenciales_lz` es `None` si `pedir_lz` es `false`. Devuelve `None` si se cancela |
| `mostrar_resultado(tipo, titulo, mensaje)` | Mensaje final de tipo `info`, `advertencia` o `error` |

La ventana usa la paleta de Bancolombia (amarillo `#FDDA24`, negro `#2C2A29`, blanco) sobre `img/background.png`. Está construida sobre un único `Canvas`:

- La tarjeta, su sombra, el recuadro de información, los campos, los botones y el ícono se dibujan con Pillow. Las formas se dibujan a 4 veces su tamaño y se reducen, para obtener esquinas redondeadas con bordes suaves.
- Los campos de texto son `Entry` de Tkinter ubicados sobre las formas dibujadas.
- Los campos cambian de gris a blanco con borde oscuro al recibir el foco; los botones cambian de color al pasar el mouse.

| Elemento | Detalle |
|---|---|
| Medidas | Definidas como constantes de `_VentanaCredenciales` (`ANCHO_TARJETA`, `ALTO_CAMPO`, `RADIO_TARJETA`, etc.) en píxeles a escala 100 % |
| Escala de pantalla | El proceso se declara compatible con alta resolución (`SetProcessDpiAwareness`) y multiplica todas las medidas por la escala de Windows (125 %, 150 %, ...), por lo que la ventana se ve nítida y con las mismas proporciones |
| Alto de la ventana | Se ajusta al contenido; en pantallas bajas se reduce el margen vertical para que quepa |
| Fuente | Primera instalada en el orden `CIB Font Sans`, `Segoe UI`, `Arial` |
| Colores | Constantes al inicio de `interfaz.py` (`AMARILLO`, `NEGRO`, `GRIS_CAMPO`, `FONDO_INFO`, etc.) |

Sin Tkinter o sin Pillow, las credenciales se piden por consola.

### `carga.py`

Contiene los pasos de la carga.

| Elemento | Descripción |
|---|---|
| `ejecutar_cargas(con_nal, con_lz, config)` | Recorre `cargas` y carga cada tabla con `_cargar_tabla`. Si una tabla falla, registra el error y continúa. Devuelve una lista de `Resumen`, uno por tabla |
| `_cargar_tabla(con_nal, con_lz, params, filas_por_lote)` | Ejecuta los pasos 1 a 5 y la limpieza para una tabla |
| `parametros_carga(config, carga)` | Une `parametros_lz` con la entrada de `cargas` para formar los parámetros de los SQL de una tabla |
| `Resumen` | `origen`, `destino`, `filas_extraidas`, `filas_cargadas`, `fechas_nulas`, `error` (`None` si la tabla terminó bien) |
| `COLUMNAS_NACIONAL` | Columnas que debe devolver la consulta de la Nacional, en orden |
| `SQL_*` | Rutas de los archivos SQL usados en cada paso |

### `nacional.py`

| Función | Descripción |
|---|---|
| `conectar(dsn, usuario, password)` | Abre la conexión ODBC |
| `contar_filas(con, consulta)` | `COUNT(*)` sobre la consulta. Devuelve `None` si falla (solo afecta el avance mostrado) |
| `abrir_consulta(con, consulta)` | Ejecuta la consulta y devuelve el cursor |
| `columnas(cursor)` | Nombres de las columnas del resultado, en minúscula |
| `leer_por_lotes(cursor, filas_por_lote)` | Generador que entrega las filas por bloques |

### `lz.py`

| Función | Descripción |
|---|---|
| `conectar(dsn, usuario=None, password=None)` | Abre la conexión ODBC con el DSN y, si se indican, usuario y contraseña |
| `ejecutar(con, sentencias)` | Ejecuta una lista de sentencias y registra en el log un resumen de cada una |
| `consultar_fila(con, sentencia)` | Ejecuta una consulta y devuelve la primera fila |
| `insertar_lote(con, plantilla, filas)` | Construye el `VALUES` del lote y ejecuta el `INSERT` en la temporal |

Conversión de valores a literales de Impala:

| Valor de origen | Literal |
|---|---|
| `None` | `NULL` |
| Texto | `'texto'` sin espacios a la derecha |
| `Decimal` / `float` | Notación decimal fija, sin notación científica (`'1234.50'`) |
| `date` / `datetime` | `'AAAAMMDD'` |
| Otro | `str(valor)` |

En los textos se escapan `\`, `'`, saltos de línea y retornos de carro.

### `configuracion.py`

| Elemento | Descripción |
|---|---|
| `RAIZ`, `RUTA_CONFIG`, `RUTA_SQL`, `RUTA_FONDO`, `RUTA_LOGS` | Rutas calculadas desde la ubicación del código; no dependen del directorio de ejecución |
| `cargar_config()` | Lee `config/config.json` |
| `leer_sentencias(ruta, params)` | Lee un SQL, elimina comentarios, reemplaza parámetros y separa por `;` |
| `leer_plantilla_lote(ruta, params)` | Igual que la anterior, pero conserva el marcador `{valores}` y devuelve una sola sentencia |
| `MARCADOR_VALORES` | Marcador `{valores}` que se reemplaza con las filas de cada lote |

### `bitacora.py`

| Elemento | Descripción |
|---|---|
| `configurar_bitacora(carpeta)` | Configura el log `carga` en consola y en `logs/carga_AAAAMMDD_HHMMSS.log`; devuelve la ruta del archivo |
| `miles(numero)` | Formato con separador de miles: `609571` → `609.571` |
| `duracion(segundos)` | Formato legible: `492` → `8 min 12 s` |

---

## Archivos SQL

| Archivo | Sentencias | Parámetros |
|---|---|---|
| `nacional/consulta_origen.sql` | `SELECT` sobre la tabla de origen | `tabla_origen` |
| `lz/01_crear_tabla_resultado.sql` | `CREATE TABLE IF NOT EXISTS` | `zona_r`, `tabla_resultado`, `tabla_origen` |
| `lz/02_crear_tabla_temporal.sql` | `DROP TABLE IF EXISTS ... PURGE` y `CREATE TABLE` | `zona_p`, `tabla_temporal` |
| `lz/03_insertar_lote_temporal.sql` | `INSERT INTO ... VALUES` | `zona_p`, `tabla_temporal`, `valores` |
| `lz/04_insertar_resultado.sql` | `INSERT OVERWRITE ... PARTITION (...) SELECT` | `zona_r`, `tabla_resultado`, `zona_p`, `tabla_temporal` |
| `lz/05_validar_carga.sql` | `SELECT COUNT(*)` de la partición del día | `zona_r`, `tabla_resultado` |
| `lz/99_limpieza.sql` | `DROP TABLE IF EXISTS ... PURGE` | `zona_p`, `tabla_temporal` |

Reglas de escritura:

- Los archivos se leen en UTF-8 (con o sin BOM).
- Las líneas que comienzan con `--` se eliminan antes de ejecutar. Solo se deben usar comentarios de línea completa; no se admiten comentarios al final de una línea con código ni comentarios de bloque `/* */`.
- Las sentencias se separan por `;`. No se debe usar `;` dentro de textos o comentarios de las sentencias.
- Los parámetros se escriben entre llaves (`{zona_r}`). Si un archivo usa un parámetro que no existe en `parametros_lz` ni en la entrada de `cargas`, el proceso falla indicando el archivo y el parámetro.
- `03_insertar_lote_temporal.sql` debe contener una sola sentencia; el marcador `{valores}` se reemplaza con las filas de cada lote.
- El orden y los alias de las columnas de `consulta_origen.sql` deben coincidir con `COLUMNAS_NACIONAL` en `carga.py`.

---

## Reejecución

El insert final usa `INSERT OVERWRITE` con partición dinámica. Impala reemplaza únicamente las particiones que reciben datos; como todas las filas llevan la fecha del día, solo se reemplaza la partición del día y las particiones de otros días no se modifican. Lo descrito a continuación aplica a cada tabla por separado.

| Escenario | Resultado |
|---|---|
| Primera ejecución del día | Crea la partición del día |
| Segunda ejecución el mismo día | Reemplaza la partición del día con los datos nuevos; no se duplican filas |
| Ejecución en otro día | Crea una partición nueva; las anteriores se conservan |
| La Nacional no devuelve filas | No se ejecuta el insert final; la partición del día queda como estaba |
| Falla durante la extracción o los lotes | No se ejecuta el insert final; la tabla final no se modifica |
| Falla una tabla y la otra termina bien | La tabla exitosa queda cargada. Para completar, se vuelve a ejecutar el mismo día: la tabla que ya estaba cargada se reemplaza con los mismos datos y la fallida se carga |

---

## Validaciones y logs

### Validaciones

| Validación | Momento | Efecto si falla |
|---|---|---|
| Campos de la ventana completos | Al presionar el botón | Mensaje en la ventana; no continúa |
| Columnas de la consulta = `COLUMNAS_NACIONAL` | Antes de leer los lotes | Error en esa tabla; su tabla final no se modifica |
| Filas de la partición del día = filas extraídas | Paso 5 | Error en esa tabla con ambos conteos. Los datos ya quedaron cargados en la partición y deben revisarse |
| `fecha_efectiva` nula | Paso 5 | Advertencia con la cantidad de filas; no detiene el proceso |

Un error en una tabla no detiene la carga de las demás.

### Logs

Cada ejecución, tanto de la carga como de la prueba de conexiones, genera `logs/carga_AAAAMMDD_HHMMSS.log` con el mismo contenido que se muestra en consola. Ejemplo de una carga:

```
2026-10-12 08:00:05 | INFO    | === Se inicia la carga Nacional -> LZ Nube ===
2026-10-12 08:00:05 | INFO    | Destino: proceso_vspc_serv · Tablas: visionr_ceautoe, visionr_ceautoedt
2026-10-12 08:00:21 | INFO    | ▶ Conectando a Nacional (AS/400) con DSN NACIONALET01, usuario usuario1...
2026-10-12 08:00:22 | INFO    | ✔ Conexión a Nacional exitosa.
2026-10-12 08:00:22 | INFO    | ▶ Conectando a LZ Nube con DSN Impala-cdp-kudu (autenticación del DSN)...
2026-10-12 08:00:23 | INFO    | ✔ Conexión a LZ exitosa.
2026-10-12 08:00:23 | INFO    | === Tabla 1/2: VISIONR.CEAUTOE -> proceso_vspc_serv.visionr_ceautoe ===
2026-10-12 08:00:23 | INFO    | ▶ [1/5] Creando tabla destino proceso_vspc_serv.visionr_ceautoe (si no existe)...
...
2026-10-12 08:03:40 | INFO    |    Lote 120/305 · 240.000 filas en la temporal · faltan ~5 min 04 s
...
2026-10-12 08:09:06 | INFO    | ✔ Validación correcta: 609.571 filas en la partición de hoy de proceso_vspc_serv.visionr_ceautoe.
2026-10-12 08:09:07 | INFO    | ▶ Borrando tabla temporal proceso_vspc_serv.tmp_visionr_ceautoe...
2026-10-12 08:09:08 | INFO    | === Tabla 2/2: VISIONR.CEAUTOEDT -> proceso_vspc_serv.visionr_ceautoedt ===
...
2026-10-12 08:12:30 | INFO    | === Proceso finalizado exitosamente (12 min 09 s) ===
```

Las contraseñas no se registran en el log.

---

## Rendimiento

La cantidad de `INSERT` a la temporal de cada tabla es su total de filas de origen dividido entre `filas_por_lote`. Como referencia, con 609.571 filas y `filas_por_lote = 2000` se requieren unos 305 `INSERT`, entre 5 y 15 minutos según la carga del clúster. Las tablas se cargan una después de otra, por lo que el tiempo total es la suma de ambas.

`filas_por_lote` permite ajustar el balance:

- **Valores mayores** (ej. 5.000): menos sentencias y menos tiempo total, pero cada sentencia es más grande.
- **Valores menores** (ej. 1.000): sentencias más pequeñas, útil si Impala rechaza sentencias por tamaño o tiempo de análisis.

El consumo de memoria del PC depende del tamaño del lote, no del total de filas.

---

## Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| `No fue posible conectar a la Nacional` | Usuario o contraseña incorrectos, sin VPN o DSN inexistente | Verificar credenciales, conexión a la red del banco y que exista el DSN `NACIONALET01` |
| `No fue posible conectar a la LZ` | DSN inexistente o contraseña guardada en el DSN vencida | Verificar el DSN `Impala-cdp-kudu` en el administrador ODBC y actualizar la contraseña. Alternativamente, usar `pedir_credenciales: true` |
| `Data source name not found` | Nombre del DSN distinto al del config, o DSN creado en el administrador ODBC de otro bitness | Ajustar el nombre en `config.json` o crear el DSN en el administrador ODBC de 64 bits |
| `AuthorizationException` al crear o insertar | El usuario del DSN no tiene permisos en la zona | Solicitar permisos sobre `zona_r` / `zona_p` |
| `Las columnas de la consulta de la Nacional no coinciden` | Se modificó `consulta_origen.sql` | Alinear la consulta, `COLUMNAS_NACIONAL` y los SQL de la LZ (ver [Mantenimiento](#mantenimiento)) |
| `El conteo no coincide` | Ejecuciones simultáneas sobre la misma tabla o cambio de fecha en el servidor durante la ejecución | Volver a ejecutar; el `INSERT OVERWRITE` reemplaza la partición del día |
| Advertencia de `fecha_efectiva` vacía o inválida | Valores en `CEFT65` que no son fechas `AAAAMMDD` válidas (ej. `0`) | Revisar los registros en origen; el resto de la carga es válida |
| La ventana no abre y pide datos por consola | Tkinter o Pillow no disponibles en el Python del equipo | Ingresar las credenciales por consola, ejecutar desde el `.bat` (instala Pillow) o reinstalar Python con Tkinter |
| Tildes incorrectas en los comentarios de la tabla | Archivo SQL guardado en una codificación distinta de UTF-8 | Guardar el archivo en UTF-8 |
| Queda una tabla `tmp_visionr_...` en `zona_p` | Una ejecución se interrumpió antes de la limpieza | No requiere acción; la siguiente ejecución la elimina |
| El resumen muestra una tabla con ✖ y otra con ✔ | Falló solo una de las tablas (permisos sobre la tabla de origen, error de SQL, etc.) | Revisar el error de esa tabla en el log, corregir y volver a ejecutar el mismo día |

---

## Mantenimiento

### Agregar otra tabla de origen

Si la nueva tabla tiene las mismas columnas, basta con agregar una entrada en `cargas` de `config.json`:

```json
{
    "tabla_origen": "VISIONR.NUEVA",
    "tabla_resultado": "visionr_nueva",
    "tabla_temporal": "tmp_visionr_nueva"
}
```

Si tiene columnas distintas, requiere su propia consulta y sus propios SQL de la LZ.

### Agregar una columna

Los cambios aplican a todas las tablas de `cargas`, porque comparten la consulta y los SQL.

1. Agregar el campo con su alias en `sql/nacional/consulta_origen.sql`.
2. Agregar el alias en `COLUMNAS_NACIONAL` (`src/carga.py`), en la misma posición.
3. Agregar la columna como `string` en `02_crear_tabla_temporal.sql` y en la lista de columnas de `03_insertar_lote_temporal.sql`, en la misma posición.
4. Agregar la columna con su tipo y `comment` en `01_crear_tabla_resultado.sql`, antes de las particiones.
5. Agregar la columna con su conversión en el `SELECT` de `04_insertar_resultado.sql`, antes de las columnas de partición y en el mismo orden de la tabla final.
6. Si las tablas finales ya existen, `CREATE TABLE IF NOT EXISTS` no las modifica. Se debe agregar la columna manualmente en cada una:

   ```sql
   ALTER TABLE resultados_vspc_serv.visionr_ceautoe ADD COLUMNS (nueva_columna string COMMENT '...');
   ALTER TABLE resultados_vspc_serv.visionr_ceautoedt ADD COLUMNS (nueva_columna string COMMENT '...');
   ```

   Las columnas agregadas con `ALTER TABLE` quedan al final, antes de las particiones; el orden del `SELECT` en `04_insertar_resultado.sql` debe coincidir con ese orden.

### Cambiar un tipo de dato

1. Ajustar el tipo en `01_crear_tabla_resultado.sql` y la conversión en `04_insertar_resultado.sql`.
2. Si la tabla ya existe, cambiar el tipo con `ALTER TABLE ... CHANGE` o recrear la tabla. Recrear la tabla elimina las particiones históricas.

### Cambiar la consulta de origen

Se puede modificar libremente mientras devuelva las mismas columnas, con los mismos alias y en el mismo orden, y conserve `FROM {tabla_origen}`. Por ejemplo, agregar un `WHERE` no requiere cambios en otros archivos; el cambio aplica a todas las tablas de `cargas`.
