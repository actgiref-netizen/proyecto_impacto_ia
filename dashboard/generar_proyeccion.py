#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PROYECTO FINAL: GRÁFICO DE PROYECTO - IMPACTO DE LA IA EN EL EMPLEO (2030)
"""

import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

# 1. CREDENCIALES DE TU CLÚSTER EN AWS AURORA
DB_USER = "postgres"
DB_PASS = "CEwXrsjk3cP17q2KIGodJbEk"
DB_HOST =  "aurora-mod4-instance-1.c6nx3v5v7ubx.us-east-1.rds.amazonaws.com"
DB_PORT = "5432"
DB_NAME = "northwind"

def obtener_conexion():
    url_conexion = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(url_conexion)

def crear_grafico_proyeccion():
    print("🚀 Conectando a AWS Aurora para extraer la proyección...")
    engine = obtener_conexion()
    
    # Definir rutas absolutas para guardar el gráfico en la carpeta correcta
    ruta_actual = os.path.dirname(os.path.abspath(__file__))
    carpeta_img = os.path.join(ruta_actual, 'dashboard', 'img')
    os.makedirs(carpeta_img, exist_ok=True)
    
    # 2. QUERY ANALÍTICA: Extrae el cruce de datos real de tu modelo estrella
    query = """
        SELECT 
            ind.nombre_ext AS industria,
            SUM(f.conteo_despidos) AS total_despidos,
            ROUND(AVG(f.probabilidad_automatizacion) * 100, 2) AS porcentaje_automatizacion
        FROM public.fact_impacto_ia f
        JOIN public.dim_industria ind ON f.id_industria = ind.id_industria
        GROUP BY ind.nombre_ext
        ORDER BY total_despidos DESC;
    """
    
    # Leer los datos desde AWS a un DataFrame de Pandas
    df = pd.read_sql(query, engine)
    
    # 3. CONSTRUCCIÓN DEL GRÁFICO AVANZADO (Estilo Profesional)
    sns.set_theme(style="whitegrid")
    fig, ax1 = plt.subplots(figsize=(12, 7))
    
    # Gráfico de Barras: Volumen Total de Despidos Proyectados
    color_barras = '#1f77b4'
    ax1.set_xlabel('Sectores Industriales', fontsize=12, fontweight='bold', labelpad=15)
    ax1.set_ylabel('Volumen de Despidos Proyectados (Barras)', color=color_barras, fontsize=12, fontweight='bold')
    barras = ax1.bar(df['industria'], df['total_despidos'], color=color_barras, alpha=0.8, edgecolor='black', width=0.6)
    ax1.tick_params(axis='y', labelcolor=color_barras)
    ax1.set_xticklabels(df['industria'], rotation=30, ha='right', fontsize=10)
    
    # Añadir etiquetas de texto sobre las barras
    for barra in barras:
        height = barra.get_height()
        ax1.annotate(f'{int(height):,}',
                    xy=(barra.get_x() + barra.get_width() / 2, height),
                    xytext=(0, 3),  # 3 puntos de desfase vertical
                    textcoords="offset points",
                    ha='center', va='bottom', fontsize=9, fontweight='bold')

    # Crear un segundo eje Y para la línea de Probabilidad de Automatización
    ax2 = ax1.twinx()  
    color_linea = '#e377c2'
    ax2.set_ylabel('Promedio de Automatización % (Línea)', color=color_linea, fontsize=12, fontweight='bold')
    linea = ax2.plot(df['industria'], df['porcentaje_automatizacion'], color=color_linea, marker='o', linewidth=2.5, label='Riesgo de Automatización %')
    ax2.tick_params(axis='y', labelcolor=color_linea)
    ax2.yaxis.grid(False) # Evitar doble cuadrícula confusa
    
    # Añadir porcentaje sobre los marcadores de la línea
    for i, txt in enumerate(df['porcentaje_automatizacion']):
        ax2.annotate(f'{txt}%', (df['industria'].iloc[i], df['porcentaje_automatizacion'].iloc[i]),
                    xytext=(0, 10), textcoords='offset points', ha='center', fontsize=9, color='#7f7f7f', fontweight='bold')

    # Título y Ajustes Finales
    plt.title('PROYECTO METROPOLITANO 2030:\nImpacto de la Inteligencia Artificial en el Desplazamiento Laboral', 
              fontsize=14, fontweight='bold', pad=20)
    
    fig.tight_layout()
    
    # Guardar el gráfico en la ruta absoluta especificada
    ruta_salida = os.path.join(carpeta_img, '03_proyeccion_pregunta_inicial.png')
    plt.savefig(ruta_salida, dpi=200)
    plt.close()
    
    print(f"✅ ¡Gráfico de proyección generado con éxito!")
    print(f"📁 Archivo guardado en: {ruta_salida}")

if __name__ == '__main__':
    crear_grafico_proyeccion()