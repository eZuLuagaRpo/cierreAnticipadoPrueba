
# main_rc1.py
"""
Proceso principal: orquesta el front para credenciales y ejecuta la lógica RC1.
"""

import sys
import traceback

from logic_rc1 import (
    calcular_fechas,
    conectar_nacional,
    cargar_cuentas,
    construir_resultado,
)

from rutas import (
    DSN_NACIONAL,
    RUTA_CUENTAS,
    RUTA_SALIDA,
    RUTA_FONDO,
)

from front_gui import solicitar_credenciales


def main():
    print("=== Se inicia procesamiento ===")
    try:
        # 0) Fechas y nombre de salida
        FECHA_DESDE, FECHA_HASTA, NOMBRE_SALIDA = calcular_fechas()
        print("FECHA_INICIO:", FECHA_DESDE, "FECHA_FIN:", FECHA_HASTA)
        print("Nombre de la salida:", NOMBRE_SALIDA)

        # 1) GUI: credenciales (sin mostrar contraseña), mostrando fechas y archivo
        usuario, password = solicitar_credenciales(
            background_path=RUTA_FONDO,
            fecha_desde=FECHA_DESDE,
            fecha_hasta=FECHA_HASTA,
            nombre_salida=NOMBRE_SALIDA,
        )

        # 2) Conexión Nacional
        con = conectar_nacional(DSN_NACIONAL, usuario, password)

        # 3) Cargar cuentas
        df_cuentas = cargar_cuentas(RUTA_CUENTAS)

        # 4) Ejecutar proceso RC1
        construir_resultado(
            con_nal=con,
            f_desde_texto=FECHA_DESDE,
            f_hasta_texto=FECHA_HASTA,
            df_cuentas=df_cuentas,
            ruta_salida=RUTA_SALIDA,
            nombre_salida=NOMBRE_SALIDA,
        )

        print("=== Proceso finalizado exitosamente ===")

    except Exception:
        print("✖ El proceso terminó con errores.")
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()