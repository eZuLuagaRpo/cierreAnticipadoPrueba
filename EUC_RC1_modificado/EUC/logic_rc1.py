# logic_rc1.py
"""
Lógica del proceso RC1 Modificado:
- Parámetros y fechas dinámicas
- Conexión ODBC a AS/400 (Nacional)
- Carga de cuentas
- Consultas con CTEs (DEBITOS/CREDITOS)
- Unión desde DataFrames, agregado, cruce y exportación a Excel
"""
import os
import sys
import traceback
import pyodbc
import pandas as pd
from datetime import date, timedelta
# -----------------------------
# Fechas dinámicas
# -----------------------------
def calcular_fechas() -> tuple[str, str, str]:
    """Devuelve (fecha_desde, fecha_hasta, nombre_salida) según mes inmediatamente anterior."""
    hoy = date.today()
    primer_dia_mes_actual = hoy.replace(day=1)
    ultimo_dia_mes_anterior = primer_dia_mes_actual - timedelta(days=1)
    primer_dia_mes_anterior = ultimo_dia_mes_anterior.replace(day=1)
    fecha_desde = primer_dia_mes_anterior.strftime("%Y%m%d")
    fecha_hasta = ultimo_dia_mes_anterior.strftime("%Y%m%d")
    nombre_salida = f"RC1_Modificado_{fecha_hasta}.xlsx"
    return fecha_desde, fecha_hasta, nombre_salida
# -----------------------------
# Conexión ODBC
# -----------------------------
def conectar_nacional(dsn: str, usuario: str, password: str) -> pyodbc.Connection:
    print("▶ Conectando a Nacional (AS/400)...")
    try:
        con = pyodbc.connect(f"DSN={dsn};UID={usuario};PWD={password}", autocommit=True)
        print("✔ Conexión exitosa.")
        return con
    except pyodbc.Error as e:
        print("✖ Error de conexión ODBC. Verifica credenciales, DSN y VPN.")
        print(f"Problema técnico: {e}")
        sys.exit(1)
# -----------------------------
# Cargar cuentas
# -----------------------------
def cargar_cuentas(path: str) -> pd.DataFrame:
    if not os.path.isfile(path):
        print(f"✖ No se encontró el archivo de cuentas en: {path}")
        sys.exit(1)
    print(f"▶ Leyendo archivo de cuentas: {path}")
    # Forzamos texto para evitar enteros/float que luego terminan con '.0'
    df_cuentas = pd.read_excel(path, engine="openpyxl", dtype=str)
    if "Cuentas" not in df_cuentas.columns:
        print("✖ El archivo de cuentas debe tener una columna llamada 'Cuentas'.")
        sys.exit(1)
    # Normalizamos desde la lectura
    df_cuentas["Cuentas"] = (
        df_cuentas["Cuentas"].astype(str).str.strip().str.replace(r"\.0$", "", regex=True)
    )
    print(f"✔ Cuentas cargadas. Registros: {len(df_cuentas)}")
    return df_cuentas
# -----------------------------
# Utilidad para ejecutar consultas
# -----------------------------
def ejecutar_query(con_nal: pyodbc.Connection, sql: str, params: tuple = ()) -> pd.DataFrame:
    try:
        df = pd.read_sql_query(sql, con_nal, params=params)
        # Normalizamos nombres de columnas a minúsculas
        df.columns = [str(c).strip().lower() for c in df.columns]
        return df
    except Exception:
        print("✖ Error ejecutando la consulta SQL.")
        traceback.print_exc()
        raise
# -----------------------------
# Consultas (CTEs)
# -----------------------------
def consultarDEBITOS(con_nal: pyodbc.Connection, f_desde: int, f_hasta: int) -> pd.DataFrame:
    sql = """

WITH CELTR_AGG AS (
SELECT
        LPAD(CHAR(ceac31), 19, '0') as ceac31,
        ceap31,
        cecd31,
        cegl31,
        cert31,
        SUM(ceat31) AS monto_total
    FROM VISIONR.CELTR
    WHERE cedt31 BETWEEN ? AND ?
    GROUP BY ceac31, cecd31, cegl31, cert31, ceap31
),
ALLINF_FILTER AS (
    SELECT
        CHAR(hanoda) as hanoda,
        hatpgl,
        hatprc
    FROM VISIONR.ALLINF
    WHERE SUBSTR(CHAR(hanoda), 1, 1) IN ('4', '5')
),
CENIE_FILTER AS (
    SELECT
        LPAD(CHAR(ceac21), 19, '0') as ceac21,
        cecl21,
        ceca21,
        cepl21,
        ceap21,
        cens21,
        cemd21
    FROM (
        SELECT
            LPAD(CHAR(ceac21), 19, '0') as ceac21,
            cecl21,
            ceca21,
            cepl21,
            ceap21,
            cens21,
            cemd21,
            ROW_NUMBER() OVER (
                PARTITION BY ceac21
                ORDER BY
                    CEAP21,
                    CECL21,
                    CESK21,
                    CESI21,
                    CERC21,
                    CE1T21,
                    CEKR21,
                    CEQC21,
                    CEQO21,
                    CEKQ21,
                    CEPR21,
                    CE1P21,
                    CEKC21,
                    CE1U21,
                    CEUP21,
                    CEKH21,
                    CEPL21,
                    CEMD21
            ) AS rn
        FROM VISIONR.CENIE
        WHERE cetr21 = 1
    ) x
    WHERE rn = 1
)
SELECT
    CHAR(a.hanoda) AS cuenta,
    b.cecl21 AS clasificacion,
    b.ceca21 AS calificacion,
    b.cepl21 AS codigo_plan,
    CASE
        WHEN b.ceap21 = '3'
          OR (b.ceap21 = 'C' AND b.cens21 = 470)
          OR b.cemd21 = 'LEV'
        THEN 'CON_LEASING'
        ELSE 'SIN_LEASING'
    END AS leasing,
    SUM(
            CASE
                WHEN c.monto_total IS NULL THEN 0
                WHEN cecd31 = 'C' AND SUBSTR(CHAR(hanoda), 1, 1) ='5' THEN c.monto_total
                ELSE -c.monto_total
            END
        ) AS monto_total
FROM CELTR_AGG c
INNER JOIN ALLINF_FILTER a
    ON a.hatpgl = c.cegl31
   AND a.hatprc = c.cert31
LEFT JOIN CENIE_FILTER b
    ON b.ceac21 = c.ceac31
GROUP BY
    a.hanoda,
    b.cecl21,
    b.ceca21,
    b.cepl21,
    CASE
        WHEN b.ceap21 = '3'
          OR (b.ceap21 = 'C' AND b.cens21 = 470)
          OR b.cemd21 = 'LEV'
        THEN 'CON_LEASING'
        ELSE 'SIN_LEASING'
    END
    """
    print(f"▶ Ejecutando consultarDEBITOS: cedt31 BETWEEN {f_desde} AND {f_hasta}")
    df_debitos = ejecutar_query(con_nal, sql, params=(f_desde, f_hasta))
    print(f"✔ DEBITOS consultados. Registros: {len(df_debitos)}")
    return df_debitos
def consultarCREDITOS(con_nal: pyodbc.Connection, f_desde: int, f_hasta: int) -> pd.DataFrame:
    sql = """
WITH CELTR_AGG AS (
    SELECT
        LPAD(CHAR(ceac31), 19, '0') as ceac31,
        ceap31,
        cecd31,
        cegl31,
        cert31,
        SUM(ceat31) AS monto_total
    FROM VISIONR.CELTR
    WHERE cedt31 BETWEEN ? AND ?
    GROUP BY ceac31, cecd31, cegl31, cert31, ceap31
),
ALLINF_FILTER AS (
    SELECT
        CHAR(hanoca) as hanoca,
        hatpgl,
        hatprc
    FROM VISIONR.ALLINF
    WHERE SUBSTR(CHAR(hanoca), 1, 1) IN ('4', '5')
),
CENIE_FILTER AS (
    SELECT
        LPAD(CHAR(ceac21), 19, '0') as ceac21,
        cecl21,
        ceca21,
        cepl21,
        ceap21,
        cens21,
        cemd21
    FROM (
        SELECT
            LPAD(CHAR(ceac21), 19, '0') as ceac21,
            cecl21,
            ceca21,
            cepl21,
            ceap21,
            cens21,
            cemd21,
            ROW_NUMBER() OVER (
                PARTITION BY ceac21
                ORDER BY
                    CEAP21,
                    CECL21,
                    CESK21,
                    CESI21,
                    CERC21,
                    CE1T21,
                    CEKR21,
                    CEQC21,
                    CEQO21,
                    CEKQ21,
                    CEPR21,
                    CE1P21,
                    CEKC21,
                    CE1U21,
                    CEUP21,
                    CEKH21,
                    CEPL21,
                    CEMD21
            ) AS rn
        FROM VISIONR.CENIE
        WHERE cetr21 = 1
    ) x
    WHERE rn = 1
)
SELECT
    CHAR(a.hanoca) AS cuenta,
    b.cecl21 AS clasificacion,
    b.ceca21 AS calificacion,
    b.cepl21 AS codigo_plan,
    CASE
        WHEN b.ceap21 = '3'
          OR (b.ceap21 = 'C' AND b.cens21 = 470)
          OR b.cemd21 = 'LEV'
        THEN 'CON_LEASING'
        ELSE 'SIN_LEASING'
    END AS leasing,
    SUM(
            CASE
                WHEN c.monto_total IS NULL THEN 0
                WHEN cecd31 = 'C' AND SUBSTR(CHAR(hanoca), 1, 1) ='5' THEN c.monto_total
                ELSE -c.monto_total
            END
        ) AS monto_total
FROM CELTR_AGG c
INNER JOIN ALLINF_FILTER a
    ON a.hatpgl = c.cegl31
   AND a.hatprc = c.cert31
LEFT JOIN CENIE_FILTER b
    ON b.ceac21 = c.ceac31
GROUP BY
    a.hanoca,
    b.cecl21,
    b.ceca21,
    b.cepl21,
    CASE
        WHEN b.ceap21 = '3'
          OR (b.ceap21 = 'C' AND b.cens21 = 470)
          OR b.cemd21 = 'LEV'
        THEN 'CON_LEASING'
        ELSE 'SIN_LEASING'
    END
    """
    print(f"▶ Ejecutando consultarCREDITOS: cedt31 BETWEEN {f_desde} AND {f_hasta}")
    df_creditos = ejecutar_query(con_nal, sql, params=(f_desde, f_hasta))
    print(f"✔ CREDITOS consultados. Registros: {len(df_creditos)}")
    return df_creditos
# -----------------------------
# Construcción de resultado
# -----------------------------
def construir_resultado(
    con_nal: pyodbc.Connection,
    f_desde_texto: str,
    f_hasta_texto: str,
    df_cuentas: pd.DataFrame,
    ruta_salida: str,
    nombre_salida: str
) -> str:
    """Orquesta la ejecución, construye y guarda el Excel. Devuelve la ruta completa del archivo."""
    # Fechas a enteros para DB2 (YYYYMMDD)
    try:
        f_desde = int(f_desde_texto)
        f_hasta = int(f_hasta_texto)
    except ValueError:
        print("✖ Las fechas deben estar en formato YYYYMMDD (numérico).")
        sys.exit(1)
    print("▶ Ejecutando consultarDEBITOS y consultarCREDITOS...")
    df_debitos = consultarDEBITOS(con_nal, f_desde, f_hasta)
    df_creditos = consultarCREDITOS(con_nal, f_desde, f_hasta)
    # Validación y normalización
    for df in (df_debitos, df_creditos):
        expected_cols = ["cuenta", "clasificacion", "calificacion", "codigo_plan", "leasing", "monto_total"]
        missing = [c for c in expected_cols if c not in df.columns]
        if missing:
            print(f"✖ Faltan columnas en un dataframe: {missing}")
            print("Columnas reales:", list(df.columns))
            sys.exit(1)
        for col in ["cuenta", "clasificacion", "calificacion", "codigo_plan", "leasing"]:
            df[col] = df[col].astype(str).str.strip()
    print("▶ Unión (concat) de DEBITOS + CREDITOS...")
    df_union = pd.concat([df_debitos, df_creditos], ignore_index=True)
    print("▶ Agregando (GROUP BY por todos los campos, sum monto_total)...")
    group_cols = ["cuenta", "clasificacion", "calificacion", "codigo_plan", "leasing"]
    df_agregado = df_union.groupby(group_cols, as_index=False, dropna=False)["monto_total"].sum()
    print("▶ Cruzando resultado con archivo de cuentas (solo trim)...")
    cuentas_list = df_cuentas["Cuentas"].unique().tolist()
    df_agregado["cuenta"] = (
        df_agregado["cuenta"].astype(str).str.strip().str.replace(r"\.0$", "", regex=True)
    )
    print("▶ Diagnóstico rápido de cuentas (normalizado):")
    print("Ejemplo cuentas query:", df_agregado["cuenta"].head(5).tolist())
    print("Ejemplo cuentas archivo:", cuentas_list[:5])
    df_final = df_agregado[df_agregado["cuenta"].isin(cuentas_list)].copy()
    print(f"✔ Cruce completado. Registros finales: {len(df_final)}")
    # Guardado
    os.makedirs(ruta_salida, exist_ok=True)
    full_path = os.path.join(ruta_salida, nombre_salida)
    print(f"▶ Guardando resultado en: {full_path}")
    with pd.ExcelWriter(full_path, engine="openpyxl") as writer:
        df_final.to_excel(writer, sheet_name="RC1", index=False)
    print("✔ Archivo generado correctamente.")
    return full_path
