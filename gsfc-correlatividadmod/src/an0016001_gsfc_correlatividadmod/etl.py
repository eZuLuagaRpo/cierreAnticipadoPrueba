# -*- coding: utf-8 -*-

"""
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Vicepresidencia Corporativa Grupo Bancolombia
-----------------------------------------------------------------------------
-- Fecha Creación: 20260316
-- Última Fecha Modificación: 20260316
-- Autores: sanmolin
-- Últimos Autores: sanmolin
-- Descripción: Script de ejecución de la Etl
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
"""
# -*- coding: utf-8 -*-

from orquestador2.step import Step
import time
from importlib import resources
import json

class Etl(Step):
    """
    Clase que representa el paso de ejecución de ETL's integrado en 
    la base calendrizable.
    """

    def obtener_ruta(self):
        """
        Función que obtiene la ruta absoluta de la carpeta static
        contenida dentro del proyecto
        """
        return str(resources.files(__package__) / 'static')
    

    def fn_validar_ingestiones(self):
        """
        Función vacia definida como ejemplo dentro de la clase Etl
        """
        pass
                  

    def fn_ejecutar_etl(self):
        """
        Función que ejecuta secuencialmente cada una de las consultas 
        que fueron definidas dentro de la lista de rutas almancenadas
        en la variable archivos, que se encuentra establecida en el 
        diccionario ETL, que se encuentra estructurado dentro del archivo
        static\config.json.
        """ 

        self.log.print_encabezado()
        cfg = self.getStepConfig()
        self.params = self.getPayload()
        self.params.update(cfg)
        for file in self.list_sql_file:
            archivo = self.getSQLPath() + file
            self.hp.ejecutar_archivo(archivo, self.params)

    def ultima_ingestion(self):
        helper = self.getHelper()
        cfg = self.getStepConfig()
        self.params.update(cfg)
        #Descomentar cuando quiero ejecutar la extracción.
        self.params.update({tabla:helper.obtener_ultima_ingestion(ruta) for tabla,ruta in self.params["tablas"].items() if tabla not in self.params})
        self.setPayload(self.params)      
            
    def ejecutar(self):
        """
        Función heredada de la clase Step del orquestador 2, que define 
        los parámetros empleados dentro de los métodos establecidos dentro
        de la clase. Adcionalmente integra la ejecución de los métodos 
        definidos dentro de la lista de tareas que se encuentra dentro del
        diccionario ETL establecido en el archivo config.json
        """
        cfg = self.getStepConfig()
        self.setGlobalConfig(self.initGlobalConfiguration())
        self.params = self.getGlobalConfiguration()["parametros_lz"]
        self.params.update(cfg) 
        self.hp = self.getHelper()
        self.list_sql_file=self.getStepConfig()["archivos"]
        self.executeTasks()
        
        