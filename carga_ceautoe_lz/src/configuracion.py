# configuracion.py
"""
Rutas del proyecto, lectura de config/config.json y de los archivos SQL.
Los SQL usan parámetros como {zona_r} que se reemplazan con "parametros_lz" del config.
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
RUTA_CONFIG = RAIZ / "config" / "config.json"
RUTA_SQL = RAIZ / "sql"
RUTA_FONDO = RAIZ / "img" / "background.png"
RUTA_LOGS = RAIZ / "logs"

# Marcador que se reemplaza con las filas de cada lote en 03_insertar_lote_temporal.sql
MARCADOR_VALORES = "{valores}"


def cargar_config() -> dict:
    with open(RUTA_CONFIG, encoding="utf-8-sig") as archivo:
        return json.load(archivo)


def _leer_sin_comentarios(ruta_relativa: str) -> str:
    texto = (RUTA_SQL / ruta_relativa).read_text(encoding="utf-8-sig")
    lineas = [linea for linea in texto.splitlines() if not linea.strip().startswith("--")]
    return "\n".join(lineas)


def _reemplazar_parametros(texto: str, ruta_relativa: str, params: dict) -> str:
    try:
        return texto.format(**params)
    except KeyError as e:
        raise KeyError(
            f"El archivo sql/{ruta_relativa} usa el parámetro {e} que no está en config.json"
        ) from None


def leer_sentencias(ruta_relativa: str, params: dict) -> list[str]:
    """Lee un archivo SQL, reemplaza los parámetros y lo separa en sentencias por ';'."""
    texto = _reemplazar_parametros(_leer_sin_comentarios(ruta_relativa), ruta_relativa, params)
    return [sentencia.strip() for sentencia in texto.split(";") if sentencia.strip()]


def leer_plantilla_lote(ruta_relativa: str, params: dict) -> str:
    """Igual que leer_sentencias, pero deja el marcador {valores} para llenarlo en cada lote."""
    params_con_marcador = {**params, "valores": MARCADOR_VALORES}
    texto = _reemplazar_parametros(_leer_sin_comentarios(ruta_relativa), ruta_relativa, params_con_marcador)
    return texto.strip().rstrip(";")
