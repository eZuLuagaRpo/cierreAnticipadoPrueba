# -*- coding: utf-8 -*-

"""
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Equipo VSEC SERVICIOS CORPORATIVOS
-----------------------------------------------------------------------------
-- Fecha Creación: 20261014
-- Última Fecha Modificación: 20261014
-- Autores: emzulu
-- Últimos Autores: emzulu
-- Descripción: Script de ejecución de los ETLs
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
"""
from orquestador2.step 	    import Step
from datetime	       		import datetime
from dateutil.relativedelta import relativedelta
import json
import os


class ExtractTransformLoad(Step):
    """
    Clase encargada de la ejecución de los ETLs
    necesarios para extraer y procesar la información
    de interés de la rutina.
    """

    @staticmethod
    def obtener_ruta():
        """
        Función encargada de identificar la
        carpeta static relacionada al paquete
        ------
        Return
        ------
        ruta_src : string
        Ruta static en el sistema o entorno de
        los recursos del paquete
        """
        return os.path.join(os.path.dirname(__file__), 'static')

    def obtener_params(self):
        """
        Función encargada de obtener los parámetros
        necesarios para la ejecución del paso.
        ------
        Return
        ------
        params : dictionary
        Parámetros necesarios para ejecutar el paso.
        """
        #PARAMETROS GENERALES DEL PASO
        params = self.getGlobalConfiguration()["parametros_lz"]
        now = datetime.today()
        params_default = {
            "kwargs_year"  : now.year,
            "kwargs_month" : now.month,
            "kwargs_day"   : now.day
        }
        params_default.update(self.kwa)
        now = datetime(
            params_default["kwargs_year"]
            , params_default["kwargs_month"]
            , params_default["kwargs_day"]
        )
        params_calc = {
            #FECHAS
            "f_corte_y"  : \
                str((now + relativedelta(months=-1)).year),
            "f_corte_m"  : \
                str((now + relativedelta(months=-1)).month),
            "f_corte_d"  : \
                str((now + relativedelta(months=-1)).day),
            "f_actual_y" : \
                str(now.year),
            "f_actual_m" : \
                str(now.month),
            "f_actual_d" : \
                str(now.day)
        }
        params.update(params_calc)
        params.update(self.kwa)
        params.pop("password", None)
        return params

    def ejecutar(self):
        """
        Función que ejecuta el paso de la clase.
        """
        self.log.info(json.dumps(
            self.obtener_params(), \
            indent = 4, sort_keys = True))
        self.executeTasks()

    def ejecutar_modulos(self):
        """
        Función que ejecuta los módulos de información.
        """
        self.executeFolder(self.getSQLPath() + \
            type(self).__name__, self.obtener_params())
