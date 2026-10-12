# interfaz.py
"""
Ventana de credenciales con estilo Bancolombia (Tkinter) y mensaje final del proceso.
Si la ventana no se puede abrir (Tkinter/Pillow no disponibles), pide los datos por consola.
"""
from dataclasses import dataclass
from getpass import getpass
from pathlib import Path
from typing import Optional

try:
    import tkinter as tk
    from tkinter import font as tkfont
    from tkinter import messagebox
except ImportError:
    tk = None

# Paleta Bancolombia
AMARILLO = "#FDDA24"
AMARILLO_ACTIVO = "#F2CB05"
NEGRO = "#2C2A29"
GRIS_TEXTO = "#5C5B5A"
GRIS_FONDO = "#F4F4F4"
GRIS_BORDE = "#D3D3D3"
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
    if tk is not None:
        try:
            return _VentanaCredenciales(ruta_fondo, info, pedir_lz, texto_boton).mostrar()
        except Exception as e:
            print("⚠ No se pudo abrir la ventana de credenciales. Se usará modo consola.")
            print(f"Detalle técnico: {e}")
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
    ANCHO_MIN = 820
    ALTO_MIN = 560

    def __init__(self, ruta_fondo: Path, info: list[tuple[str, str]], pedir_lz: bool, texto_boton: str):
        self.secciones = [("nacional", "Nacional (AS/400)")]
        if pedir_lz:
            self.secciones.append(("lz", "LZ Nube"))
        self.texto_boton = texto_boton
        self.variables = {}
        self.entradas = {}
        self.resultado = None

        self.root = tk.Tk()
        self.root.title("Carga Nacional → LZ Nube")
        self.root.resizable(False, False)
        self.root.configure(bg=BLANCO)
        self.fuente = _elegir_fuente(self.root)

        tarjeta = self._construir_tarjeta(info)
        self._ubicar(tarjeta, ruta_fondo)

        self.root.bind("<Return>", lambda _e: self._aceptar())
        self.root.bind("<Escape>", lambda _e: self._cancelar())
        self.root.protocol("WM_DELETE_WINDOW", self._cancelar)

    def mostrar(self) -> Optional[tuple[Credenciales, Optional[Credenciales]]]:
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
    def _f(self, tamano: int, peso: str = "normal") -> tuple:
        return (self.fuente, tamano, peso)

    def _construir_tarjeta(self, info: list[tuple[str, str]]) -> "tk.Frame":
        tarjeta = tk.Frame(self.root, bg=BLANCO, highlightthickness=1, highlightbackground=GRIS_BORDE)
        tk.Frame(tarjeta, bg=AMARILLO, height=6).pack(fill="x")

        cuerpo = tk.Frame(tarjeta, bg=BLANCO, padx=36, pady=26)
        cuerpo.pack(fill="both", expand=True)

        tk.Label(cuerpo, text="Carga Nacional → LZ Nube", font=self._f(18, "bold"),
                 fg=NEGRO, bg=BLANCO).pack(anchor="w")
        tk.Label(cuerpo, text="Copia la tabla VISIONR.CEAUTOE de la Nacional a la LZ",
                 font=self._f(10), fg=GRIS_TEXTO, bg=BLANCO).pack(anchor="w", pady=(2, 16))

        # Origen / destino
        caja = tk.Frame(cuerpo, bg=GRIS_FONDO, padx=16, pady=12)
        caja.pack(fill="x")
        for fila, (etiqueta, valor) in enumerate(info):
            tk.Label(caja, text=etiqueta, font=self._f(9, "bold"), fg=GRIS_TEXTO,
                     bg=GRIS_FONDO).grid(row=fila, column=0, sticky="w", padx=(0, 18), pady=2)
            tk.Label(caja, text=valor, font=self._f(10), fg=NEGRO,
                     bg=GRIS_FONDO).grid(row=fila, column=1, sticky="w", pady=2)

        for clave, nombre in self.secciones:
            self._seccion(cuerpo, clave, nombre)

        self.lbl_error = tk.Label(cuerpo, text="", font=self._f(9), fg=ROJO, bg=BLANCO)
        self.lbl_error.pack(anchor="w", pady=(10, 0))

        botones = tk.Frame(cuerpo, bg=BLANCO)
        botones.pack(fill="x", pady=(6, 0))
        self._boton(botones, self.texto_boton, self._aceptar, AMARILLO, AMARILLO_ACTIVO).pack(side="right")
        self._boton(botones, "Cancelar", self._cancelar, BLANCO, GRIS_FONDO, borde=True).pack(side="right", padx=(0, 10))

        tk.Label(cuerpo, text="Las credenciales solo se usan en esta ejecución; no se guardan.",
                 font=self._f(8), fg=GRIS_TEXTO, bg=BLANCO).pack(anchor="w", pady=(18, 0))
        return tarjeta

    def _seccion(self, padre, clave: str, nombre: str) -> None:
        encabezado = tk.Frame(padre, bg=BLANCO)
        encabezado.pack(fill="x", pady=(20, 8))
        tk.Frame(encabezado, bg=AMARILLO, width=4, height=18).pack(side="left", padx=(0, 8))
        tk.Label(encabezado, text=f"Credenciales {nombre}", font=self._f(11, "bold"),
                 fg=NEGRO, bg=BLANCO).pack(side="left")

        fila = tk.Frame(padre, bg=BLANCO)
        fila.pack(fill="x")
        for columna in (0, 1):
            fila.columnconfigure(columna, weight=1, uniform="campos")
        self._campo(fila, "Usuario", f"{clave}_usuario", oculto=False).grid(row=0, column=0, sticky="ew", padx=(0, 8))
        self._campo(fila, "Contraseña", f"{clave}_password", oculto=True).grid(row=0, column=1, sticky="ew", padx=(8, 0))

    def _campo(self, padre, etiqueta: str, clave: str, oculto: bool) -> "tk.Frame":
        marco = tk.Frame(padre, bg=BLANCO)
        tk.Label(marco, text=etiqueta, font=self._f(9), fg=GRIS_TEXTO, bg=BLANCO).pack(anchor="w")

        borde = tk.Frame(marco, bg=BLANCO, highlightthickness=1,
                         highlightbackground=GRIS_BORDE, highlightcolor=GRIS_BORDE)
        borde.pack(fill="x", pady=(4, 0))
        variable = tk.StringVar()
        entrada = tk.Entry(borde, textvariable=variable, show="•" if oculto else "", width=22,
                           font=self._f(11), relief="flat", bd=0, bg=BLANCO, fg=NEGRO, insertbackground=NEGRO)
        entrada.pack(fill="x", padx=10, pady=8)
        # Borde oscuro mientras el campo tiene el foco
        entrada.bind("<FocusIn>", lambda _e: borde.configure(highlightbackground=NEGRO))
        entrada.bind("<FocusOut>", lambda _e: borde.configure(highlightbackground=GRIS_BORDE))

        self.variables[clave] = variable
        self.entradas[clave] = entrada
        return marco

    def _boton(self, padre, texto: str, comando, fondo: str, fondo_activo: str, borde: bool = False):
        contenedor = tk.Frame(padre, bg=NEGRO if borde else fondo)
        boton = tk.Button(contenedor, text=texto, command=comando, font=self._f(10, "bold"),
                          bg=fondo, fg=NEGRO, activebackground=fondo_activo, activeforeground=NEGRO,
                          relief="flat", bd=0, padx=22, pady=9, cursor="hand2")
        boton.pack(padx=1 if borde else 0, pady=1 if borde else 0)
        boton.bind("<Enter>", lambda _e: boton.configure(bg=fondo_activo))
        boton.bind("<Leave>", lambda _e: boton.configure(bg=fondo))
        return contenedor

    def _ubicar(self, tarjeta, ruta_fondo: Path) -> None:
        """Ajusta el tamaño de la ventana a la tarjeta, la centra y pinta el fondo."""
        self.root.update_idletasks()
        ancho = max(self.ANCHO_MIN, tarjeta.winfo_reqwidth() + 200)
        alto = max(self.ALTO_MIN, tarjeta.winfo_reqheight() + 120)
        x = max(0, (self.root.winfo_screenwidth() - ancho) // 2)
        y = max(0, (self.root.winfo_screenheight() - alto) // 2 - 20)
        self.root.geometry(f"{ancho}x{alto}+{x}+{y}")

        lienzo = tk.Canvas(self.root, width=ancho, height=alto, bg=BLANCO, highlightthickness=0)
        lienzo.place(x=0, y=0)
        self._imagen_fondo = _cargar_fondo(ruta_fondo, ancho, alto)  # se guarda para que no se borre
        if self._imagen_fondo is not None:
            lienzo.create_image(0, 0, image=self._imagen_fondo, anchor="nw")

        tarjeta.place(relx=0.5, rely=0.5, anchor="center")
        tarjeta.lift()

    # ---------------------------------------------------------------
    # Acciones
    # ---------------------------------------------------------------
    def _aceptar(self) -> None:
        credenciales = []
        for clave, nombre in self.secciones:
            usuario = self.variables[f"{clave}_usuario"].get().strip()
            password = self.variables[f"{clave}_password"].get()
            if not usuario or not password:
                self.lbl_error.configure(text=f"Ingresa usuario y contraseña de {nombre}.")
                self.entradas[f"{clave}_usuario" if not usuario else f"{clave}_password"].focus_set()
                return
            credenciales.append(Credenciales(usuario, password))

        self.resultado = (credenciales[0], credenciales[1] if len(credenciales) > 1 else None)
        self.root.destroy()

    def _cancelar(self) -> None:
        self.resultado = None
        self.root.destroy()


def _elegir_fuente(root) -> str:
    disponibles = set(tkfont.families(root))
    return next((fuente for fuente in FUENTES_PREFERIDAS if fuente in disponibles), "TkDefaultFont")


def _cargar_fondo(ruta: Path, ancho: int, alto: int):
    """Fondo con las cintas de Bancolombia ajustado a la ventana. Sin Pillow, queda blanco."""
    try:
        from PIL import Image, ImageOps, ImageTk

        imagen = ImageOps.fit(Image.open(ruta), (ancho, alto), method=Image.LANCZOS)
        return ImageTk.PhotoImage(imagen)
    except Exception:
        return None


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
