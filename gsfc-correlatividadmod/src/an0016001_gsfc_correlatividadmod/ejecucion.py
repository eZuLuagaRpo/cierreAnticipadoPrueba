"""
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia de Servicios para los Clientes
-----------------------------------------------------------------------------
-- Fecha Creación: 20250814
-- Última Fecha Modificación: 20250814
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Script de ejecución de la rutina
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
"""

from .etl import Etl
from orquestador2.orquestador2 import Orchestrator
import os
from importlib import resources
from pathlib import Path
import pandas as pd
from datetime import datetime
import json
import warnings
import logging

warnings.simplefilter(action='ignore', category=UserWarning)
logger = logging.getLogger(__name__)

def ejecutar(fecha: str = ""):
    """
    Función que define la secuencia lógica requerida para 
    la ejecución de los componentes que integran la base calendarizable
    """
    base_path: Path
    if __package__:
        try:
            
            base_path = Path(resources.files(__package__))
        except (ModuleNotFoundError, AttributeError, TypeError) as e:
            
            logger.debug("Fallo resolviendo resources.files(%r): %s. Usando __file__.", __package__, e)
            base_path = Path(__file__).resolve().parent
    else:
        base_path = Path(__file__).resolve().parent

    if "src" in base_path.parts:
        project_root = Path(*base_path.parts[:base_path.parts.index("src")])
    else:
        project_root = base_path

    logs_path = str(project_root / "logs_calendarizacion")

    warnings.resetwarnings()

    try:
        if not os.path.exists("logs/"):
            logger.info("No existía la carpeta de logs, se está creando.")
            os.mkdir("logs/")

        if not os.path.exists(logs_path):
            logger.info("No existía la carpeta de logs para calendarización, se está creando.")
            os.mkdir(logs_path)

        nom_proyecto = "an0016001_gsfc_correlatividadmod"
        steps = [Etl()]
        orquestador = Orchestrator(nom_proyecto, steps)
        orquestador.ejecutar()

    except (FileNotFoundError, FileExistsError, PermissionError) as e:
        logger.exception("Error creando o accediendo carpetas: %s", e)
        raise
    except RuntimeError as e:
        logger.exception("Error en el orquestador: %s", e)
        raise
    except ValueError as e:
        logger.exception("Valor inválido: %s", e)
        raise


if __name__ == '__main__':
    """
    Condición que permite obtener parámetros y ejecutar 
    la lógica del presente archivo(archivo principal) 
    """
    ejecutar()