# bitacora.py
"""
Log del proceso: se muestra en consola y queda en logs/carga_AAAAMMDD_HHMMSS.log
"""
import logging
import sys
from datetime import datetime
from pathlib import Path

NOMBRE_LOG = "carga"


def configurar_bitacora(carpeta: Path) -> Path:
    """Configura el log de consola + archivo y devuelve la ruta del archivo."""
    # Si la consola no soporta algún carácter (▶ ✔ tildes), se reemplaza en vez de fallar
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    carpeta.mkdir(parents=True, exist_ok=True)
    ruta = carpeta / f"carga_{datetime.now():%Y%m%d_%H%M%S}.log"
    formato = logging.Formatter("%(asctime)s | %(levelname)-7s | %(message)s", "%Y-%m-%d %H:%M:%S")

    log = logging.getLogger(NOMBRE_LOG)
    log.setLevel(logging.INFO)
    for handler in (logging.StreamHandler(sys.stdout), logging.FileHandler(ruta, encoding="utf-8")):
        handler.setFormatter(formato)
        log.addHandler(handler)
    return ruta


def miles(numero: int) -> str:
    """609571 -> '609.571'"""
    return f"{numero:,}".replace(",", ".")


def duracion(segundos: float) -> str:
    minutos, seg = divmod(int(round(segundos)), 60)
    return f"{minutos} min {seg:02d} s" if minutos else f"{seg} s"
