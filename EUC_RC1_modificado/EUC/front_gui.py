
# front.py
"""
Interfaz de usuario para ingresar las credenciales de AS/400
Muestra rango de fechas y nombre de archivo de salida.
"""

import sys
from getpass import getpass  # fallback consola

def solicitar_credenciales(
    background_path: str,
    fecha_desde: str,
    fecha_hasta: str,
    nombre_salida: str,
) -> tuple[str, str]:
    """
    Abre una ventana para pedir Usuario y Contraseña del AS/400 y muestra:
    - Rango de fechas: fecha_desde — fecha_hasta
    - Archivo de salida: nombre_salida

    Si hay error de GUI (Tkinter/Pillow), hace fallback a input por consola.
    """
    try:
        import tkinter as tk
        from tkinter import messagebox
        from PIL import Image, ImageTk  # pillow

        # Ventana base
        root = tk.Tk()
        root.title("Consulta Nacional (AS/400) • RC1 Modificado")
        root.geometry("640x400")
        root.resizable(False, False)

        # Fondo
        try:
            img = Image.open(background_path)
            img = img.resize((640, 400), Image.LANCZOS)
            bg_img = ImageTk.PhotoImage(img)
            canvas = tk.Canvas(root, width=640, height=400, highlightthickness=0)
            canvas.pack(fill="both", expand=True)
            canvas.create_image(0, 0, image=bg_img, anchor="nw")
        except Exception:
            canvas = tk.Canvas(root, width=640, height=400, highlightthickness=0, bg="#ffffff")
            canvas.pack(fill="both", expand=True)

        # Panel central
        panel_w, panel_h = 520, 220
        panel_x, panel_y = (640 - panel_w) // 2, (400 - panel_h) // 2
        panel = tk.Frame(root, bg="#f7f7f7", bd=0)
        panel.place(x=panel_x, y=panel_y, width=panel_w, height=panel_h)

        # Encabezado
        titulo = tk.Label(
            panel,
            text="Proceso: Consulta Nacional (AS/400)\nReporte RC1 segmento modificado",
            bg="#f7f7f7", fg="#333333", font=("Segoe UI", 10, "bold"), justify="center"
        )
        titulo.pack(pady=(10, 6))

        # Sub-encabezado: fechas y archivo
        info = tk.Label(
            panel,
            text=f"Rango de fechas: {fecha_desde} — {fecha_hasta}\nArchivo de salida: {nombre_salida}",
            bg="#f7f7f7", fg="#444444", font=("Segoe UI", 9), justify="center"
        )
        info.pack(pady=(0, 8))

        # Campos
        usuario_var = tk.StringVar()
        password_var = tk.StringVar()

        fila = tk.Frame(panel, bg="#f7f7f7")
        fila.pack(pady=(8, 4), fill="x", padx=24)
        tk.Label(fila, text="Usuario AS400:", bg="#f7f7f7", fg="#333333", width=16, anchor="w").pack(side="left")
        usuario_entry = tk.Entry(fila, textvariable=usuario_var)
        usuario_entry.pack(side="left", fill="x", expand=True)

        fila2 = tk.Frame(panel, bg="#f7f7f7")
        fila2.pack(pady=(4, 4), fill="x", padx=24)
        tk.Label(fila2, text="Contraseña AS400:", bg="#f7f7f7", fg="#333333", width=16, anchor="w").pack(side="left")
        password_entry = tk.Entry(fila2, textvariable=password_var, show="•")
        password_entry.pack(side="left", fill="x", expand=True)

        # Botones
        btns = tk.Frame(panel, bg="#f7f7f7")
        btns.pack(pady=(8, 8))
        def on_submit():
            usuario = usuario_var.get().strip()
            password = password_var.get()
            if not usuario or not password:
                messagebox.showerror("Campos vacíos", "Usuario/Contraseña no pueden estar vacíos.")
                return
            root.usuario = usuario
            root.password = password
            root.destroy()

        def on_cancel():
            if messagebox.askyesno("Cancelar", "¿Deseas cancelar el proceso?"):
                root.usuario, root.password = None, None
                root.destroy()

        tk.Button(btns, text="Continuar", command=on_submit, width=14, bg="#0078d4", fg="white").pack(side="left", padx=6)
        tk.Button(btns, text="Cancelar", command=on_cancel, width=12).pack(side="left", padx=6)

        usuario_entry.focus_set()
        root.mainloop()

        usuario = getattr(root, "usuario", None)
        password = getattr(root, "password", None)

        if not usuario or not password:
            print("✖ Usuario/Contraseña no proporcionados. Proceso cancelado.")
            sys.exit(1)
        return usuario, password

    except Exception as e:
        # Fallback a consola
        print("⚠ No se pudo levantar la GUI de credenciales. Se usará modo consola.")
        print(f"Detalle técnico: {e}")
        usuario = input("Usuario AS400: ").strip()
        password = getpass("Contraseña AS400: ")
        if not usuario or not password:
            print("✖ Usuario/Contraseña no pueden estar vacíos.")
            sys.exit(1)
        return usuario, password
