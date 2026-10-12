# carga.py
"""
Pasos de la carga Nacional -> LZ Nube:
  1. Crea la tabla final {zona_r}.{tabla_resultado} si no existe.
  2. Crea de cero la tabla temporal {zona_p}.{tabla_temporal}.
  3. Lee la Nacional por lotes y los inserta en la temporal.
  4. INSERT OVERWRITE de la temporal a la tabla final (solo la partición de hoy).
  5. Valida que la partición de hoy tenga las mismas filas que se extrajeron.
  Siempre, aunque algo falle: borra la tabla temporal.
"""
import logging
import math
import time
from dataclasses import dataclass

import lz
import nacional
from bitacora import NOMBRE_LOG, duracion, miles
from configuracion import leer_plantilla_lote, leer_sentencias

log = logging.getLogger(NOMBRE_LOG)

SQL_CONSULTA_NACIONAL = "nacional/consulta_ceautoe.sql"
SQL_CREAR_TABLA_RESULTADO = "lz/01_crear_tabla_resultado.sql"
SQL_CREAR_TABLA_TEMPORAL = "lz/02_crear_tabla_temporal.sql"
SQL_INSERTAR_LOTE_TEMPORAL = "lz/03_insertar_lote_temporal.sql"
SQL_INSERTAR_RESULTADO = "lz/04_insertar_resultado.sql"
SQL_VALIDAR_CARGA = "lz/05_validar_carga.sql"
SQL_LIMPIEZA = "lz/99_limpieza.sql"

# Columnas (alias) que debe devolver la consulta de la Nacional, en este orden
COLUMNAS_NACIONAL = [
    "cod_aplicacion",
    "concepto_contable",
    "codigo_contable",
    "fecha_efectiva",
    "monto_trx",
    "oficina_contable",
    "oficina_origen",
    "cod_moneda",
    "tasa_cambio",
    "monto_equivalente",
]


@dataclass
class Resumen:
    destino: str
    filas_extraidas: int
    filas_cargadas: int
    fechas_nulas: int


def ejecutar_carga(con_nal, con_lz, config: dict) -> Resumen:
    params = config["parametros_lz"]
    filas_por_lote = int(config["carga"]["filas_por_lote"])
    destino = f"{params['zona_r']}.{params['tabla_resultado']}"
    temporal = f"{params['zona_p']}.{params['tabla_temporal']}"

    log.info("▶ [1/5] Creando tabla destino %s (si no existe)...", destino)
    lz.ejecutar(con_lz, leer_sentencias(SQL_CREAR_TABLA_RESULTADO, params))

    log.info("▶ [2/5] Preparando tabla temporal %s...", temporal)
    lz.ejecutar(con_lz, leer_sentencias(SQL_CREAR_TABLA_TEMPORAL, params))

    try:
        filas_extraidas = _cargar_temporal(con_nal, con_lz, params, filas_por_lote)
        if filas_extraidas == 0:
            log.warning("⚠ La Nacional no devolvió filas. No se modifica la tabla destino.")
            return Resumen(destino, 0, 0, 0)

        log.info("▶ [4/5] Cargando %s (solo se reemplaza la partición de hoy)...", destino)
        lz.ejecutar(con_lz, leer_sentencias(SQL_INSERTAR_RESULTADO, params))

        log.info("▶ [5/5] Validando la partición de hoy...")
        fila = lz.consultar_fila(con_lz, leer_sentencias(SQL_VALIDAR_CARGA, params)[0])
        filas_cargadas, fechas_nulas = int(fila[0]), int(fila[1] or 0)
        if filas_cargadas != filas_extraidas:
            raise RuntimeError(
                f"El conteo no coincide: se extrajeron {miles(filas_extraidas)} filas de la Nacional "
                f"y la partición de hoy en {destino} tiene {miles(filas_cargadas)}."
            )
        if fechas_nulas:
            log.warning("⚠ %s filas quedaron con fecha_efectiva vacía o inválida en el origen.", miles(fechas_nulas))
        log.info("✔ Validación correcta: %s filas en la partición de hoy.", miles(filas_cargadas))
        return Resumen(destino, filas_extraidas, filas_cargadas, fechas_nulas)
    finally:
        _borrar_temporal(con_lz, params, temporal)


def _cargar_temporal(con_nal, con_lz, params: dict, filas_por_lote: int) -> int:
    consulta = leer_sentencias(SQL_CONSULTA_NACIONAL, params)[0]
    plantilla = leer_plantilla_lote(SQL_INSERTAR_LOTE_TEMPORAL, params)

    total = nacional.contar_filas(con_nal, consulta)
    lotes_totales = math.ceil(total / filas_por_lote) if total else None
    log.info(
        "▶ [3/5] Leyendo la Nacional y cargando la temporal (%s filas, lotes de %s)...",
        miles(total) if total is not None else "?", miles(filas_por_lote),
    )

    cursor = nacional.abrir_consulta(con_nal, consulta)
    columnas = nacional.columnas(cursor)
    if columnas != COLUMNAS_NACIONAL:
        raise ValueError(
            "Las columnas de la consulta de la Nacional no coinciden con las esperadas.\n"
            f"Esperadas: {COLUMNAS_NACIONAL}\nRecibidas: {columnas}"
        )

    filas_extraidas = 0
    inicio = time.time()
    for numero, lote in enumerate(nacional.leer_por_lotes(cursor, filas_por_lote), start=1):
        lz.insertar_lote(con_lz, plantilla, lote)
        filas_extraidas += len(lote)
        log.info("   Lote %s · %s filas en la temporal%s",
                 f"{numero}/{lotes_totales}" if lotes_totales else numero,
                 miles(filas_extraidas), _tiempo_restante(inicio, numero, lotes_totales))
    cursor.close()

    log.info("✔ Temporal cargada: %s filas en %s.", miles(filas_extraidas), duracion(time.time() - inicio))
    return filas_extraidas


def _tiempo_restante(inicio: float, lotes_hechos: int, lotes_totales) -> str:
    if not lotes_totales or lotes_hechos >= lotes_totales:
        return ""
    restante = (time.time() - inicio) / lotes_hechos * (lotes_totales - lotes_hechos)
    return f" · faltan ~{duracion(restante)}"


def _borrar_temporal(con_lz, params: dict, temporal: str) -> None:
    log.info("▶ Borrando tabla temporal %s...", temporal)
    try:
        lz.ejecutar(con_lz, leer_sentencias(SQL_LIMPIEZA, params))
    except Exception as e:
        # No se oculta el error original del proceso; la próxima ejecución la borra igual
        log.warning("⚠ No se pudo borrar la tabla temporal %s: %s", temporal, e)
