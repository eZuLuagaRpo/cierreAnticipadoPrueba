# main.py
"""
Proceso principal: pide credenciales, conecta a la Nacional y a la LZ y carga cada tabla
de "cargas" (config.json), por ejemplo VISIONR.CEAUTOE y VISIONR.CEAUTOEDT, hacia {zona_r}.
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
from carga import Resumen, ejecutar_cargas

log = logging.getLogger(NOMBRE_LOG)


def main() -> int:
    ruta_log = configurar_bitacora(configuracion.RUTA_LOGS)
    log.info("=== Se inicia la carga Nacional -> LZ Nube ===")
    con_nal = con_lz = None
    try:
        # 0) Configuración
        config = configuracion.cargar_config()
        zona_r = config["parametros_lz"]["zona_r"]
        cargas = config["cargas"]
        log.info("Destino: %s · Tablas: %s", zona_r, ", ".join(c["tabla_resultado"] for c in cargas))

        # 1) Ventana de credenciales
        info = [
            ("Nacional", f"DSN {config['nacional']['dsn']}"),
            ("Origen", "  ·  ".join(c["tabla_origen"] for c in cargas)),
            ("Destino", zona_r),
            ("Tablas", "  ·  ".join(c["tabla_resultado"] for c in cargas)),
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

        # 3) Carga de cada tabla
        resumenes = ejecutar_cargas(con_nal, con_lz, config)

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
    fallidas = [r for r in resumenes if r.error]
    sin_datos = [r for r in resumenes if not r.error and r.filas_extraidas == 0]

    lineas = [_linea_resumen(r) for r in resumenes] + ["", f"Duración: {tiempo}"]
    if fallidas:
        lineas += ["", f"Detalle en el log:\n{ruta_log}"]
        log.error("=== Proceso finalizado con %s de %s tablas fallidas (%s) ===", len(fallidas), len(resumenes), tiempo)
        interfaz.mostrar_resultado("error", "Carga con errores", "\n".join(lineas))
        return 1
    if sin_datos:
        log.warning("=== Proceso finalizado; %s tabla(s) sin datos en origen (%s) ===", len(sin_datos), tiempo)
        interfaz.mostrar_resultado("advertencia", "Carga finalizada con advertencias", "\n".join(lineas))
        return 0
    log.info("=== Proceso finalizado exitosamente (%s) ===", tiempo)
    interfaz.mostrar_resultado("info", "Carga finalizada", "\n".join(lineas))
    return 0


def _linea_resumen(r: Resumen) -> str:
    if r.error:
        return f"✖ {r.origen} → {r.destino}\n    {r.error}"
    if r.filas_extraidas == 0:
        return f"⚠ {r.origen} → {r.destino}\n    La Nacional no devolvió filas; la tabla no se modificó."
    texto = f"✔ {r.origen} → {r.destino}\n    {miles(r.filas_cargadas)} filas cargadas"
    if r.fechas_nulas:
        texto += f" · {miles(r.fechas_nulas)} con fecha_efectiva vacía o inválida"
    return texto


if __name__ == "__main__":
    sys.exit(main())
