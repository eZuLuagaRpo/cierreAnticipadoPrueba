# probar_conexiones.py
"""
Prueba solo las conexiones, sin crear ni insertar nada:
- Nacional: conecta y cuenta las filas de la consulta de cada tabla de origen de "cargas".
- LZ: conecta, muestra con qué usuario quedó conectado y si la zona destino
  es accesible (y si cada tabla destino ya existe).
"""
import logging
import sys

import configuracion
import interfaz
import lz
import nacional
from bitacora import NOMBRE_LOG, configurar_bitacora, miles
from carga import SQL_CONSULTA_NACIONAL, parametros_carga

log = logging.getLogger(NOMBRE_LOG)


def main() -> int:
    ruta_log = configurar_bitacora(configuracion.RUTA_LOGS)
    log.info("=== Prueba de conexiones (no se escribe nada) ===")
    config = configuracion.cargar_config()

    info = [
        ("Nacional", f"DSN {config['nacional']['dsn']}"),
        ("LZ Nube", f"DSN {config['lz']['dsn']}"),
        ("Tablas", "  ·  ".join(c["tabla_origen"] for c in config["cargas"])),
        ("Modo", "Solo prueba de conexiones · no se escribe nada"),
    ]
    credenciales = interfaz.solicitar_credenciales(
        configuracion.RUTA_FONDO, info,
        pedir_lz=config["lz"]["pedir_credenciales"], texto_boton="Probar conexiones",
    )
    if credenciales is None:
        log.warning("✖ Prueba cancelada por el usuario.")
        return 1
    cred_nal, cred_lz = credenciales

    # Se prueban las dos aunque una falle, para ver el estado de ambas
    resultados = [_probar_nacional(config, cred_nal), _probar_lz(config, cred_lz)]
    todo_ok = all(ok for ok, _ in resultados)
    for _, texto in resultados:
        log.info(texto)

    mensaje = "\n\n".join(texto for _, texto in resultados) + f"\n\nDetalle en el log:\n{ruta_log}"
    if todo_ok:
        log.info("=== Conexiones exitosas ===")
        interfaz.mostrar_resultado("info", "Prueba de conexiones", mensaje)
        return 0
    log.error("=== Falló al menos una conexión ===")
    interfaz.mostrar_resultado("error", "Prueba de conexiones", mensaje)
    return 1


def _probar_nacional(config: dict, cred: interfaz.Credenciales) -> tuple[bool, str]:
    dsn = config["nacional"]["dsn"]
    con = None
    try:
        con = nacional.conectar(dsn, cred.usuario, cred.password)
    except Exception as e:
        log.exception("✖ Falló la prueba de la Nacional")
        return False, f"✖ Nacional (DSN {dsn}): {e}"

    try:
        ok, lineas = True, [f"✔ Nacional (DSN {dsn}): conexión exitosa."]
        for carga in config["cargas"]:
            origen = carga["tabla_origen"]
            consulta = configuracion.leer_sentencias(SQL_CONSULTA_NACIONAL, parametros_carga(config, carga))[0]
            total = nacional.contar_filas(con, consulta)
            if total is None:
                ok = False
                lineas.append(f"✖ {origen}: no se pudo leer (revisa permisos sobre la tabla; el detalle está en el log).")
            else:
                lineas.append(f"    {origen}: {miles(total)} filas.")
        return ok, "\n".join(lineas)
    except Exception as e:
        log.exception("✖ Falló la prueba de la Nacional")
        return False, f"✖ Nacional (DSN {dsn}): {e}"
    finally:
        _cerrar(con)


def _probar_lz(config: dict, cred) -> tuple[bool, str]:
    dsn = config["lz"]["dsn"]
    zona = config["parametros_lz"]["zona_r"]
    con = None
    try:
        con = lz.conectar(dsn, cred.usuario if cred else None, cred.password if cred else None)
        usuario = lz.consultar_fila(con, "SELECT user()")[0]
        texto = f"✔ LZ Nube (DSN {dsn}): conexión exitosa.\n    Usuario conectado: {usuario}."
    except Exception as e:
        log.exception("✖ Falló la prueba de la LZ")
        _cerrar(con)
        return False, f"✖ LZ Nube (DSN {dsn}): {e}"

    try:
        lineas = [texto, f"    Zona destino {zona}: accesible."]
        for carga in config["cargas"]:
            tabla = carga["tabla_resultado"]
            existe = lz.consultar_fila(con, f"SHOW TABLES IN {zona} LIKE '{tabla}'") is not None
            estado = "ya existe" if existe else "aún no existe (se crea en la primera carga)"
            lineas.append(f"    Tabla {tabla}: {estado}.")
        return True, "\n".join(lineas)
    except Exception as e:
        log.exception("✖ No se pudo consultar la zona destino")
        return False, texto + f"\n✖ Pero no se pudo consultar la zona destino {zona}: {e}"
    finally:
        _cerrar(con)


def _cerrar(con) -> None:
    if con is not None:
        try:
            con.close()
        except Exception:
            pass


if __name__ == "__main__":
    sys.exit(main())
