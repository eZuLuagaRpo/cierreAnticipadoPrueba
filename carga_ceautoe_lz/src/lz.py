# lz.py
"""
Conexión a la LZ Nube (Impala CDP) por ODBC y ejecución de sentencias.
Se conecta igual que helper.Helper._obtener_conexion (el que usa orquestador2/litig)
en un PC: pyodbc.connect("DSN=...", autocommit=True), con la autenticación guardada
en el DSN. Si se pasan usuario y contraseña, se agregan como uid/pwd, igual que
hace el helper cuando corre en el servidor de calendarización.
"""
import logging
from datetime import date
from decimal import Decimal
from typing import Optional, Sequence

import pyodbc

from bitacora import NOMBRE_LOG
from configuracion import MARCADOR_VALORES

log = logging.getLogger(NOMBRE_LOG)


def conectar(dsn: str, usuario: Optional[str] = None, password: Optional[str] = None) -> pyodbc.Connection:
    cadena = f"DSN={dsn}"
    if usuario:
        cadena += f";UID={usuario};PWD={password}"
        log.info("▶ Conectando a LZ Nube con DSN %s, usuario %s...", dsn, usuario)
    else:
        log.info("▶ Conectando a LZ Nube con DSN %s (autenticación del DSN)...", dsn)

    try:
        con = pyodbc.connect(cadena, autocommit=True)
    except pyodbc.Error as e:
        ayuda = "" if usuario else (
            "\nSi el DSN no tiene credenciales guardadas, cambia \"pedir_credenciales\" a true "
            "en config/config.json para ingresarlas en la ventana."
        )
        raise ConnectionError(f"No fue posible conectar a la LZ (DSN {dsn}).{ayuda}\n\nDetalle: {e}") from e
    log.info("✔ Conexión a LZ exitosa.")
    return con


def ejecutar(con: pyodbc.Connection, sentencias: Sequence[str]) -> None:
    cursor = con.cursor()
    for sentencia in sentencias:
        log.info("   SQL: %s", _resumir(sentencia))
        cursor.execute(sentencia)
    cursor.close()


def consultar_fila(con: pyodbc.Connection, sentencia: str) -> pyodbc.Row:
    cursor = con.cursor()
    cursor.execute(sentencia)
    fila = cursor.fetchone()
    cursor.close()
    return fila


def insertar_lote(con: pyodbc.Connection, plantilla: str, filas: Sequence[Sequence]) -> None:
    """Llena la plantilla INSERT ... VALUES {valores} con las filas del lote y la ejecuta."""
    valores = ",\n".join("(" + ", ".join(_literal(valor) for valor in fila) + ")" for fila in filas)
    cursor = con.cursor()
    cursor.execute(plantilla.replace(MARCADOR_VALORES, valores))
    cursor.close()


def _literal(valor) -> str:
    """Convierte un valor de la Nacional en un literal de texto de Impala (o NULL)."""
    if valor is None:
        return "NULL"
    texto = _a_texto(valor)
    texto = texto.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r")
    return f"'{texto}'"


def _a_texto(valor) -> str:
    if isinstance(valor, str):
        # El AS/400 rellena los campos de texto con espacios a la derecha
        return valor.rstrip()
    if isinstance(valor, (Decimal, float)):
        # Sin notación científica: 1E+2 -> '100'
        return format(valor, "f")
    if isinstance(valor, date):
        # Por si alguna fecha llega como tipo fecha y no como número AAAAMMDD
        return valor.strftime("%Y%m%d")
    return str(valor)


def _resumir(sentencia: str, largo: int = 110) -> str:
    texto = " ".join(sentencia.split())
    return texto if len(texto) <= largo else texto[:largo] + "..."
