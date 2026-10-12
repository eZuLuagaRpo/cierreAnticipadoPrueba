# interfaz.py
"""
Ventana de credenciales con estilo Bancolombia y mensaje final del proceso.
La tarjeta, los campos, los botones y el ícono se dibujan con Pillow (esquinas
redondeadas y bordes suaves); los campos de texto son Entry de Tkinter encima.
Si la ventana no se puede abrir (sin Tkinter o sin Pillow), pide los datos por consola.
"""
from dataclasses import dataclass
from getpass import getpass
from pathlib import Path
from typing import Callable, Optional

try:
    import tkinter as tk
    from tkinter import font as tkfont
    from tkinter import messagebox
except ImportError:
    tk = None

try:
    from PIL import Image, ImageColor, ImageDraw, ImageFilter, ImageOps, ImageTk
except ImportError:
    Image = None

# Paleta Bancolombia
AMARILLO = "#FDDA24"
AMARILLO_ACTIVO = "#F2CB05"
NEGRO = "#2C2A29"
GRIS_TEXTO = "#6B6A69"
GRIS_CAMPO = "#F2F2F2"
GRIS_BORDE = "#D9D9D9"
GRIS_ACTIVO = "#F2F2F2"
FONDO_INFO = "#FFF8DC"
BLANCO = "#FFFFFF"
ROJO = "#D0021B"

# Se usa la primera fuente instalada en el equipo
FUENTES_PREFERIDAS = ("CIB Font Sans", "Segoe UI", "Arial")


@dataclass
class Credenciales:
    usuario: str
    password: str


def solicitar_credenciales(
    ruta_fondo: Path,
    info: list[tuple[str, str]],
    pedir_lz: bool,
    texto_boton: str = "Ejecutar carga",
) -> Optional[tuple[Credenciales, Optional[Credenciales]]]:
    """
    Pide las credenciales y devuelve (credenciales_nacional, credenciales_lz).
    credenciales_lz es None cuando pedir_lz es False.
    Devuelve None si el usuario cancela.
    """
    if tk is not None and Image is not None:
        try:
            return _VentanaCredenciales(ruta_fondo, info, pedir_lz, texto_boton).mostrar()
        except Exception as e:
            print("⚠ No se pudo abrir la ventana de credenciales. Se usará modo consola.")
            print(f"Detalle técnico: {e}")
    else:
        print("⚠ Tkinter o Pillow no están disponibles. Se usará modo consola.")
    return _pedir_por_consola(pedir_lz)


def mostrar_resultado(tipo: str, titulo: str, mensaje: str) -> None:
    """tipo: 'info', 'advertencia' o 'error'. El detalle siempre queda también en consola y log."""
    if tk is None:
        return
    try:
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        mostrar = {
            "info": messagebox.showinfo,
            "advertencia": messagebox.showwarning,
            "error": messagebox.showerror,
        }[tipo]
        mostrar(titulo, mensaje, parent=root)
        root.destroy()
    except Exception:
        pass


class _VentanaCredenciales:
    # Medidas en píxeles a escala 100 %; se multiplican por la escala de la pantalla
    ANCHO_MIN_VENTANA = 860
    MARGEN = 56
    ANCHO_TARJETA = 500
    RELLENO = 40
    RADIO_TARJETA = 22
    RADIO_CAMPO = 12
    ALTO_CAMPO = 44
    ALTO_BOTON = 44
    ICONO = 52

    def __init__(self, ruta_fondo: Path, info: list[tuple[str, str]], pedir_lz: bool, texto_boton: str):
        self.secciones = [("nacional", "Nacional (AS/400)")]
        if pedir_lz:
            self.secciones.append(("lz", "LZ Nube"))
        self.texto_boton = texto_boton
        self.variables = {}
        self.entradas = {}
        self.items = {}
        self.resultado = None
        self._imagenes = []   # referencias a las imágenes para que Tk no las libere
        self._formas = []     # (imagen, x, y) que se pintan sobre la tarjeta
        self._elementos = []  # funciones (ox, oy) que crean los elementos del lienzo

        _activar_alta_resolucion()
        self.root = tk.Tk()
        self.root.withdraw()  # se muestra cuando está armada
        self.root.title("Carga Nacional → LZ Nube")
        self.root.resizable(False, False)
        self.root.configure(bg=BLANCO)
        self.escala = max(1.0, self.root.winfo_fpixels("1i") / 96)
        self.fuentes = _crear_fuentes(self.root)

        self._construir(ruta_fondo, info)

        self.root.bind("<Return>", lambda _e: self._aceptar())
        self.root.bind("<Escape>", lambda _e: self._cancelar())
        self.root.protocol("WM_DELETE_WINDOW", self._cancelar)

    def mostrar(self) -> Optional[tuple[Credenciales, Optional[Credenciales]]]:
        self.root.deiconify()
        # Traer la ventana al frente (se abre desde la consola del .bat)
        self.root.lift()
        self.root.attributes("-topmost", True)
        self.root.after(400, lambda: self.root.attributes("-topmost", False))
        self.entradas["nacional_usuario"].focus_force()
        self.root.mainloop()
        return self.resultado

    # ---------------------------------------------------------------
    # Construcción
    # ---------------------------------------------------------------
    def _px(self, valor: float) -> int:
        return int(round(valor * self.escala))

    def _linea(self, fuente: str) -> int:
        return self.fuentes[fuente].metrics("linespace")

    def _foto(self, imagen) -> "ImageTk.PhotoImage":
        foto = ImageTk.PhotoImage(imagen)
        self._imagenes.append(foto)
        return foto

    def _construir(self, ruta_fondo: Path, info: list[tuple[str, str]]) -> None:
        """Calcula la posición de cada elemento dentro de la tarjeta, arma la ventana y los dibuja."""
        px = self._px
        ancho_t = px(self.ANCHO_TARJETA)
        x0 = px(self.RELLENO)
        interno = ancho_t - 2 * x0
        y = px(32)

        # Encabezado: ícono + título + subtítulo
        icono = px(self.ICONO)
        self._formas.append((_icono_candado(icono), x0, y))
        x_texto = x0 + icono + px(16)
        y_titulo = y + (icono - self._linea("titulo") - self._linea("subtitulo")) // 2
        self._texto(x_texto, y_titulo, "Carga Nacional → LZ Nube", "titulo", NEGRO)
        self._texto(x_texto, y_titulo + self._linea("titulo"), "Ingresa tus credenciales para continuar",
                    "subtitulo", GRIS_TEXTO)
        y += icono + px(24)

        y = self._panel_info(x0, y, interno, info) + px(24)

        for clave, nombre in self.secciones:
            y = self._seccion(x0, y, interno, clave, nombre) + px(12)

        self._texto(x0, y, "", "error", ROJO, nombre="error")
        y += self._linea("error") + px(12)

        y = self._botones(x0 + interno, y) + px(22)

        self._texto(ancho_t // 2, y, "Las credenciales solo se usan en esta ejecución y no se guardan.",
                    "pie", GRIS_TEXTO, ancla="n")
        alto_t = y + self._linea("pie") + px(26)

        self._armar_ventana(ruta_fondo, ancho_t, alto_t)

    def _armar_ventana(self, ruta_fondo: Path, ancho_t: int, alto_t: int) -> None:
        px = self._px
        pantalla_w, pantalla_h = self.root.winfo_screenwidth(), self.root.winfo_screenheight()
        ancho_v = max(px(self.ANCHO_MIN_VENTANA), ancho_t + 2 * px(self.MARGEN))
        # En pantallas bajas se reduce el margen vertical para que la ventana quepa
        margen_v = max(px(16), min(px(self.MARGEN), (pantalla_h - px(90) - alto_t) // 2))
        alto_v = alto_t + 2 * margen_v
        x = max(0, (pantalla_w - ancho_v) // 2)
        y = max(0, (pantalla_h - alto_v) // 2 - px(20))
        self.root.geometry(f"{ancho_v}x{alto_v}+{x}+{y}")

        ox, oy = (ancho_v - ancho_t) // 2, margen_v
        self.lienzo = tk.Canvas(self.root, width=ancho_v, height=alto_v, bg=BLANCO, highlightthickness=0, bd=0)
        self.lienzo.pack()
        base = self._imagen_base(ruta_fondo, ancho_v, alto_v, ox, oy, ancho_t, alto_t)
        self.lienzo.create_image(0, 0, image=self._foto(base), anchor="nw")
        for crear in self._elementos:
            crear(ox, oy)

        self.root.iconphoto(True, self._foto(_icono_candado(px(32))))

    def _imagen_base(self, ruta_fondo: Path, ancho_v: int, alto_v: int,
                     ox: int, oy: int, ancho_t: int, alto_t: int):
        """Fondo con las cintas de Bancolombia + sombra + tarjeta con sus formas fijas."""
        px = self._px
        base = Image.new("RGBA", (ancho_v, alto_v), BLANCO)
        try:
            # El PNG tiene transparencia: se pinta sobre blanco
            cintas = ImageOps.fit(Image.open(ruta_fondo).convert("RGBA"), (ancho_v, alto_v), method=Image.LANCZOS)
            base.alpha_composite(cintas)
        except Exception:
            pass

        sombra = Image.new("RGBA", base.size, (0, 0, 0, 0))
        ImageDraw.Draw(sombra).rounded_rectangle(
            (ox, oy + px(10), ox + ancho_t, oy + alto_t + px(10)),
            radius=px(self.RADIO_TARJETA), fill=(0, 0, 0, 50))
        base.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(px(18))))

        tarjeta = _redondeado(ancho_t, alto_t, px(self.RADIO_TARJETA), BLANCO)
        for imagen, x, y in self._formas:
            tarjeta.alpha_composite(imagen, (x, y))
        base.alpha_composite(tarjeta, (ox, oy))
        return base.convert("RGB")

    def _texto(self, x: int, y: int, texto: str, fuente: str, color: str,
               ancla: str = "nw", nombre: Optional[str] = None) -> None:
        def crear(ox: int, oy: int) -> None:
            item = self.lienzo.create_text(ox + x, oy + y, text=texto, font=self.fuentes[fuente],
                                           fill=color, anchor=ancla)
            if nombre:
                self.items[nombre] = item
        self._elementos.append(crear)

    def _panel_info(self, x: int, y: int, ancho: int, info: list[tuple[str, str]]) -> int:
        """Recuadro amarillo claro con origen, destino y partición. Devuelve la y final."""
        px = self._px
        relleno_v, relleno_h = px(14), px(18)
        alto_fila = max(self._linea("info_etiqueta"), self._linea("info_valor")) + px(4)
        alto = len(info) * alto_fila + 2 * relleno_v - px(4)
        self._formas.append((_redondeado(ancho, alto, px(14), FONDO_INFO), x, y))

        ancho_etiquetas = max(self.fuentes["info_etiqueta"].measure(e) for e, _ in info) + px(20)
        for i, (etiqueta, valor) in enumerate(info):
            centro = y + relleno_v + i * alto_fila + (alto_fila - px(4)) // 2
            self._texto(x + relleno_h, centro, etiqueta, "info_etiqueta", GRIS_TEXTO, ancla="w")
            self._texto(x + relleno_h + ancho_etiquetas, centro, valor, "info_valor", NEGRO, ancla="w")
        return y + alto

    def _seccion(self, x: int, y: int, ancho: int, clave: str, nombre: str) -> int:
        """Título de la sección con acento amarillo + campos de usuario y contraseña. Devuelve la y final."""
        px = self._px
        alto_titulo = self._linea("seccion")
        self._formas.append((_redondeado(px(4), px(16), px(2), AMARILLO), x, y + (alto_titulo - px(16)) // 2))
        self._texto(x + px(12), y, f"Credenciales {nombre}", "seccion", NEGRO)
        y += alto_titulo + px(12)

        separacion = px(16)
        ancho_campo = (ancho - separacion) // 2
        self._campo(x, y, ancho_campo, "Usuario", f"{clave}_usuario", oculto=False)
        self._campo(x + ancho_campo + separacion, y, ancho_campo, "Contraseña", f"{clave}_password", oculto=True)
        return y + self._linea("campo_etiqueta") + px(6) + px(self.ALTO_CAMPO)

    def _campo(self, x: int, y: int, ancho: int, etiqueta: str, clave: str, oculto: bool) -> None:
        """Campo redondeado gris; con el foco se vuelve blanco con borde oscuro."""
        px = self._px
        self._texto(x + px(2), y, etiqueta, "campo_etiqueta", GRIS_TEXTO)
        y_caja = y + self._linea("campo_etiqueta") + px(6)
        alto, radio, relleno = px(self.ALTO_CAMPO), px(self.RADIO_CAMPO), px(14)
        normal = self._foto(_redondeado(ancho, alto, radio, GRIS_CAMPO, fondo=BLANCO))
        con_foco = self._foto(_redondeado(ancho, alto, radio, BLANCO, borde=NEGRO, grosor=px(2), fondo=BLANCO))
        ancho_alternar = self.fuentes["enlace"].measure("Ocultar") + px(12) if oculto else 0
        variable = tk.StringVar(self.root)
        self.variables[clave] = variable

        def crear(ox: int, oy: int) -> None:
            lienzo = self.lienzo
            caja = lienzo.create_image(ox + x, oy + y_caja, image=normal, anchor="nw")
            entrada = tk.Entry(lienzo, textvariable=variable, show="•" if oculto else "",
                               font=self.fuentes["campo"], bd=0, relief="flat", highlightthickness=0,
                               bg=GRIS_CAMPO, fg=NEGRO, insertbackground=NEGRO)
            lienzo.create_window(ox + x + relleno, oy + y_caja + alto // 2, window=entrada, anchor="w",
                                 width=ancho - 2 * relleno - ancho_alternar)

            def al_enfocar(_e) -> None:
                lienzo.itemconfigure(caja, image=con_foco)
                entrada.configure(bg=BLANCO)

            def al_desenfocar(_e) -> None:
                lienzo.itemconfigure(caja, image=normal)
                entrada.configure(bg=GRIS_CAMPO)

            entrada.bind("<FocusIn>", al_enfocar)
            entrada.bind("<FocusOut>", al_desenfocar)
            lienzo.tag_bind(caja, "<Button-1>", lambda _e: entrada.focus_set())
            if oculto:
                self._alternar_visibilidad(entrada, ox + x + ancho - relleno, oy + y_caja + alto // 2)
            self.entradas[clave] = entrada

        self._elementos.append(crear)

    def _alternar_visibilidad(self, entrada: "tk.Entry", x_derecha: int, y_centro: int) -> None:
        """Enlace 'Mostrar' / 'Ocultar' dentro del campo de contraseña."""
        item = self.lienzo.create_text(x_derecha, y_centro, text="Mostrar", font=self.fuentes["enlace"],
                                       fill=GRIS_TEXTO, anchor="e")

        def alternar() -> None:
            visible = entrada.cget("show") == ""
            entrada.configure(show="•" if visible else "")
            self.lienzo.itemconfigure(item, text="Mostrar" if visible else "Ocultar")
            entrada.focus_set()

        self._interactivo(item, alternar,
                          al_entrar=lambda: self.lienzo.itemconfigure(item, fill=NEGRO),
                          al_salir=lambda: self.lienzo.itemconfigure(item, fill=GRIS_TEXTO))

    def _botones(self, x_derecha: int, y: int) -> int:
        """Botón secundario y principal alineados a la derecha. Devuelve la y final."""
        px = self._px
        relleno = px(28)
        ancho_principal = self.fuentes["boton"].measure(self.texto_boton) + 2 * relleno
        ancho_cancelar = self.fuentes["boton"].measure("Cancelar") + 2 * relleno
        x_principal = x_derecha - ancho_principal
        self._boton(x_principal - px(12) - ancho_cancelar, y, ancho_cancelar, "Cancelar", self._cancelar, False)
        self._boton(x_principal, y, ancho_principal, self.texto_boton, self._aceptar, True)
        return y + px(self.ALTO_BOTON)

    def _boton(self, x: int, y: int, ancho: int, texto: str, comando: Callable[[], None], principal: bool) -> None:
        """Botón tipo píldora: amarillo el principal, blanco con borde el secundario."""
        px = self._px
        alto = px(self.ALTO_BOTON)
        radio = alto // 2
        if principal:
            normal = self._foto(_redondeado(ancho, alto, radio, AMARILLO, fondo=BLANCO))
            encima = self._foto(_redondeado(ancho, alto, radio, AMARILLO_ACTIVO, fondo=BLANCO))
        else:
            grosor = max(1, px(1))
            normal = self._foto(_redondeado(ancho, alto, radio, BLANCO, borde=GRIS_BORDE, grosor=grosor, fondo=BLANCO))
            encima = self._foto(_redondeado(ancho, alto, radio, GRIS_ACTIVO, borde=NEGRO, grosor=grosor, fondo=BLANCO))

        def crear(ox: int, oy: int) -> None:
            fondo = self.lienzo.create_image(ox + x, oy + y, image=normal, anchor="nw")
            # El texto no recibe eventos; los maneja la imagen de fondo
            self.lienzo.create_text(ox + x + ancho // 2, oy + y + alto // 2, text=texto,
                                    font=self.fuentes["boton"], fill=NEGRO, state="disabled")
            self._interactivo(fondo, comando,
                              al_entrar=lambda: self.lienzo.itemconfigure(fondo, image=encima),
                              al_salir=lambda: self.lienzo.itemconfigure(fondo, image=normal))

        self._elementos.append(crear)

    def _interactivo(self, item: int, al_click: Callable[[], None],
                     al_entrar: Callable[[], None], al_salir: Callable[[], None]) -> None:
        """Cursor de mano, efecto al pasar el mouse y acción al hacer clic sobre un elemento del lienzo."""
        def entrar(_e) -> None:
            self.lienzo.configure(cursor="hand2")
            al_entrar()

        def salir(_e) -> None:
            self.lienzo.configure(cursor="")
            al_salir()

        self.lienzo.tag_bind(item, "<Enter>", entrar)
        self.lienzo.tag_bind(item, "<Leave>", salir)
        self.lienzo.tag_bind(item, "<ButtonRelease-1>", lambda _e: al_click())

    # ---------------------------------------------------------------
    # Acciones
    # ---------------------------------------------------------------
    def _aceptar(self) -> None:
        credenciales = []
        for clave, nombre in self.secciones:
            usuario = self.variables[f"{clave}_usuario"].get().strip()
            password = self.variables[f"{clave}_password"].get()
            if not usuario or not password:
                self.lienzo.itemconfigure(self.items["error"], text=f"Ingresa usuario y contraseña de {nombre}.")
                self.entradas[f"{clave}_usuario" if not usuario else f"{clave}_password"].focus_set()
                return
            credenciales.append(Credenciales(usuario, password))

        self.resultado = (credenciales[0], credenciales[1] if len(credenciales) > 1 else None)
        self.root.destroy()

    def _cancelar(self) -> None:
        self.resultado = None
        self.root.destroy()


def _activar_alta_resolucion() -> None:
    """Evita que Windows muestre la ventana borrosa en pantallas con escala mayor a 100 %."""
    try:
        import ctypes
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass


def _crear_fuentes(root) -> dict:
    disponibles = set(tkfont.families(root))
    familia = next((f for f in FUENTES_PREFERIDAS if f in disponibles), "TkDefaultFont")

    def fuente(tamano: int, peso: str = "normal") -> "tkfont.Font":
        return tkfont.Font(root=root, family=familia, size=tamano, weight=peso)

    return {
        "titulo": fuente(16, "bold"),
        "subtitulo": fuente(10),
        "info_etiqueta": fuente(9, "bold"),
        "info_valor": fuente(10),
        "seccion": fuente(11, "bold"),
        "campo_etiqueta": fuente(9),
        "campo": fuente(11),
        "enlace": fuente(9, "bold"),
        "boton": fuente(10, "bold"),
        "error": fuente(9),
        "pie": fuente(8),
    }


def _redondeado(ancho: int, alto: int, radio: int, relleno: str,
                borde: Optional[str] = None, grosor: int = 0, fondo: Optional[str] = None):
    """
    Rectángulo con esquinas redondeadas y bordes suaves (se dibuja a 4x y se reduce).
    fondo: color detrás de las esquinas; None = transparente.
    """
    factor = 4
    color_fondo = ImageColor.getrgb(fondo) + (255,) if fondo else ImageColor.getrgb(relleno) + (0,)
    imagen = Image.new("RGBA", (ancho * factor, alto * factor), color_fondo)
    radio = min(radio * factor, (min(ancho, alto) * factor) // 2 - 1)
    ImageDraw.Draw(imagen).rounded_rectangle(
        (0, 0, ancho * factor - 1, alto * factor - 1), radius=radio, fill=relleno,
        outline=borde, width=grosor * factor if borde else 0)
    return imagen.resize((ancho, alto), Image.LANCZOS)


def _icono_candado(diametro: int):
    """Círculo amarillo con un candado negro, con fondo transparente."""
    factor = 4
    d = diametro * factor
    imagen = Image.new("RGBA", (d, d), ImageColor.getrgb(AMARILLO) + (0,))
    dibujo = ImageDraw.Draw(imagen)
    dibujo.ellipse((0, 0, d - 1, d - 1), fill=AMARILLO)

    cx = d / 2
    ancho_c, alto_c, arriba_c = d * 0.40, d * 0.30, d * 0.46
    dibujo.rounded_rectangle((cx - ancho_c / 2, arriba_c, cx + ancho_c / 2, arriba_c + alto_c),
                             radius=int(d * 0.06), fill=NEGRO)
    radio_a, grosor = d * 0.125, int(d * 0.055)
    arriba_a = arriba_c - radio_a - d * 0.07
    dibujo.arc((cx - radio_a, arriba_a, cx + radio_a, arriba_a + 2 * radio_a), 180, 360, fill=NEGRO, width=grosor)
    dibujo.rectangle((cx - radio_a, arriba_a + radio_a, cx - radio_a + grosor, arriba_c + 1), fill=NEGRO)
    dibujo.rectangle((cx + radio_a - grosor, arriba_a + radio_a, cx + radio_a, arriba_c + 1), fill=NEGRO)
    radio_ojo = d * 0.035
    centro_ojo = arriba_c + alto_c * 0.45
    dibujo.ellipse((cx - radio_ojo, centro_ojo - radio_ojo, cx + radio_ojo, centro_ojo + radio_ojo), fill=AMARILLO)
    return imagen.resize((diametro, diametro), Image.LANCZOS)


def _pedir_por_consola(pedir_lz: bool) -> Optional[tuple[Credenciales, Optional[Credenciales]]]:
    nombres = ["Nacional (AS/400)"] + (["LZ Nube"] if pedir_lz else [])
    credenciales = []
    for nombre in nombres:
        usuario = input(f"Usuario {nombre}: ").strip()
        password = getpass(f"Contraseña {nombre}: ")
        if not usuario or not password:
            print("✖ Usuario/Contraseña no pueden estar vacíos.")
            return None
        credenciales.append(Credenciales(usuario, password))
    return credenciales[0], (credenciales[1] if pedir_lz else None)
