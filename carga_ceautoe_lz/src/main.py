# main.py
"""
Proceso principal: pide credenciales, conecta a la Nacional y a la LZ y ejecuta la carga
de VISIONR.CEAUTOE hacia {zona_r}.visionr_ceautoe.
"""
import logging
import sys
import time
from datetime import date

import configuracion
import interfaz
import lz
import nacional
from bitacora import NOMBRE_LOG, configurar_bitacora, duracion, miles
from carga import ejecutar_carga

log = logging.getLogger(NOMBRE_LOG)


def main() -> int:
    ruta_log = configurar_bitacora(configuracion.RUTA_LOGS)
    log.info("=== Se inicia la carga Nacional -> LZ Nube ===")
    con_nal = con_lz = None
    try:
        # 0) Configuración
        config = configuracion.cargar_config()
        params = config["parametros_lz"]
        destino = f"{params['zona_r']}.{params['tabla_resultado']}"
        log.info("Destino: %s", destino)

        # 1) Ventana de credenciales
        info = [
            ("Origen", f"VISIONR.CEAUTOE  (DSN {config['nacional']['dsn']})"),
            ("Destino", destino),
            ("Partición", f"{date.today():%d/%m/%Y}  ·  se reemplaza si ya existe"),
        ]
        credenciales = interfaz.solicitar_credenciales(
            configuracion.RUTA_FONDO, info, pedir_lz=config["lz"]["pedir_credenciales"]
        )
        if credenciales is None:
            log.warning("✖ Proceso cancelado por el usuario.")
            return 1
        cred_nal, cred_lz = credenciales
        inicio = time.time()

        # 2) Conexiones (las dos antes de extraer, para fallar rápido)
        con_nal = nacional.conectar(config["nacional"]["dsn"], cred_nal.usuario, cred_nal.password)
        con_lz = lz.conectar(
            config["lz"]["dsn"],
            cred_lz.usuario if cred_lz else None,
            cred_lz.password if cred_lz else None,
        )

        # 3) Carga
        resumen = ejecutar_carga(con_nal, con_lz, config)

    except Exception as e:
        log.exception("✖ El proceso terminó con errores.")
        interfaz.mostrar_resultado("error", "Carga con errores", f"{e}\n\nDetalle en el log:\n{ruta_log}")
        return 1
    finally:
        for con in (con_nal, con_lz):
            if con is not None:
                try:
                    con.close()
                except Exception:
                    pass

    tiempo = duracion(time.time() - inicio)
    if resumen.filas_extraidas == 0:
        log.info("=== Proceso finalizado sin datos (%s) ===", tiempo)
        interfaz.mostrar_resultado("advertencia", "Carga sin datos",
                                   "La Nacional no devolvió filas.\nLa tabla destino no se modificó.")
        return 0

    lineas = [
        f"Destino: {resumen.destino}",
        f"Filas extraídas de la Nacional: {miles(resumen.filas_extraidas)}",
        f"Filas cargadas en la LZ: {miles(resumen.filas_cargadas)}",
        f"Duración: {tiempo}",
    ]
    if resumen.fechas_nulas:
        lineas.append(f"Filas con fecha_efectiva vacía o inválida: {miles(resumen.fechas_nulas)}")
    log.info("=== Proceso finalizado exitosamente (%s) ===", tiempo)
    interfaz.mostrar_resultado("info", "Carga finalizada", "\n".join(lineas))
    return 0


if __name__ == "__main__":
    sys.exit(main())
