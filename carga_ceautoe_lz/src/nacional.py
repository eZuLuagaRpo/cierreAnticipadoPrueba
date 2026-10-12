# nacional.py
"""
Conexión a la Nacional (AS/400) por ODBC y lectura de la consulta por lotes.
Misma conexión que usa EUC_RC1_modificado (DSN + usuario + contraseña).
"""
import logging
from typing import Iterator, Optional

import pyodbc

from bitacora import NOMBRE_LOG

log = logging.getLogger(NOMBRE_LOG)


def conectar(dsn: str, usuario: str, password: str) -> pyodbc.Connection:
    log.info("▶ Conectando a Nacional (AS/400) con DSN %s, usuario %s...", dsn, usuario)
    try:
        con = pyodbc.connect(f"DSN={dsn};UID={usuario};PWD={password}", autocommit=True)
    except pyodbc.Error as e:
        raise ConnectionError(
            f"No fue posible conectar a la Nacional (DSN {dsn}).\n"
            f"Verifica usuario, contraseña, DSN y VPN.\n\nDetalle: {e}"
        ) from e
    log.info("✔ Conexión a Nacional exitosa.")
    return con


def contar_filas(con: pyodbc.Connection, consulta: str) -> Optional[int]:
    """Cuenta las filas que devolverá la consulta. Solo se usa para mostrar el avance."""
    try:
        cursor = con.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM (\n{consulta}\n) AS origen")
        total = int(cursor.fetchone()[0])
        cursor.close()
        return total
    except pyodbc.Error as e:
        log.warning("⚠ No se pudo contar las filas de origen (solo afecta el avance mostrado): %s", e)
        return None


def abrir_consulta(con: pyodbc.Connection, consulta: str) -> pyodbc.Cursor:
    cursor = con.cursor()
    cursor.execute(consulta)
    return cursor


def columnas(cursor: pyodbc.Cursor) -> list[str]:
    return [str(descripcion[0]).strip().lower() for descripcion in cursor.description]


def leer_por_lotes(cursor: pyodbc.Cursor, filas_por_lote: int) -> Iterator[list]:
    """Entrega las filas de a bloques para no tener toda la tabla en memoria."""
    while True:
        filas = cursor.fetchmany(filas_por_lote)
        if not filas:
            return
        yield filas
