"""
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Entorno al Servicio de Funciones Corporativas
-----------------------------------------------------------------------------
-- Fecha Creación: 20250718
-- Última Fecha Modificación: 20250718
-- Autores: sanmolin,davmosqu
-- Últimos Autores: sanmolin,davmosqu
-- Descripción: Script de ejecución de la rutina
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
"""
from .etl import Etl
from orquestador2.orquestador2 import Orchestrator
import os
import sys
import pkg_resources
import pandas as pd
from datetime import datetime
import json
import warnings
warnings.simplefilter(action='ignore', category=UserWarning)

# Rutinas CDP, cambiar por texto 'CDP-PC'


def ejecutar(fecha=""):
    """
    Función que define la secuencia lógica requerida para 
    la ejecución de los componentes que integran 
    la base calendarizable
    """
    ruta = pkg_resources.resource_filename(__name__, 'static/')
    path = pkg_resources.resource_filename(__name__, "")
    logs_path = os.path.join(path.split("src")[0], "logs_calendarizacion")


    warnings.resetwarnings()
   
    try:
        if not os.path.exists("logs/"):
            print("No existía la carpeta de logs, se está creando.")
            os.mkdir("logs/")
        if not os.path.exists(logs_path):
            print("No existía la carpeta de logs para calendarización, se está creando.")
            os.mkdir(logs_path)
        nom_proyecto = "vsec-gsfc-ajustesifrs"
        steps = [Etl()]
        orquestador = Orchestrator(nom_proyecto, steps)
        orquestador.ejecutar()
    except Exception as  e:
        print("error ejecucion : {}".format(e))
           


if __name__ == '__main__':
    """
    Condición que permite obtener parámetros y ejecutar 
    la lógica del presente archivo(archivo principal) 
    """

    ejecutar()