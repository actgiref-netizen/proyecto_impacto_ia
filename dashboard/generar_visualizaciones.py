#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PROYECTO FINAL: PIPELINE DE AUTOMATIZACIÓN GRÁFICA (DASHBOARD)
"""

import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

# 1. CONFIGURACIÓN DE CONEXIÓN REMOTA A AMAZON AURORA (AWS)
DB_USER = "postgres"
DB_PASS = "CEwXrsjk3cP17q2KIGodJbEk"  
DB_HOST = "aurora-mod4.cluster-c6nx3v5v7ubx.us-east-1.rds.amazonaws.com"
DB_PORT = "5432"
DB_NAME = "northwind"

def obtener_conexion():
    url_conexion = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(url_conexion)

def generar_reportes():
    print("Conectando con el almacén de datos en AWS Aurora...")
    engine = obtener_conexion()
    
    # Crear directorio de salida si no existe
    os.makedirs('dashboard/img', exist_ok=True)
    
    # -------------------------------------------------------------------------
    # VISTA 1: VOLUMEN DE DESPIDOS PROYECTADOS POR INDUSTRIA
    # -------------------------------------------------------------------------
    print("Generando Vista 1: Despidos por industria...")
    query_industria = """
        SELECT ind.nombre_ext, SUM(f.conteo_despidos) as total_despidos
        FROM public.fact_impacto_ia f
        JOIN public.dim_industria ind ON f.id_industria = ind.id_industria
        GROUP BY ind.nombre_ext
        ORDER BY total_despidos ASC;
    """
    df_ind = pd.read_sql(query_industria, engine)
    
    plt.figure(figsize=(10, 6))
    plt.barh(df_ind['nombre_ext'], df_ind['total_despidos'], color='#3a86c8', edgecolor='black')
    plt.title('Volumen de Despidos Proyectados por Sector Industrial (2030)', fontsize=12, fontweight='bold')
    plt.xlabel('Conteo Estimado de Desplazamientos Laborales')
    plt.ylabel('Sectores Industriales')
    plt.tight_layout()
    plt.savefig('dashboard/img/01_top_despidos_industria.png', dpi=150)
    plt.close()

    # -------------------------------------------------------------------------
    # VISTA 2: RELACIÓN EXPOSICIÓN VS AUTOMATIZACIÓN BASADO EN HABILIDADES
    # -------------------------------------------------------------------------
    print("Generando Vista 2: Análisis de dispersión de riesgo...")
    query_dispersion = """
        SELECT 
            f.id_exposicion_ia as exposicion, 
            f.probabilidad_automatizacion as automatizacion,
            f.nivel_habilidad_creatividad as creatividad
        FROM public.fact_impacto_ia f
        LIMIT 1000;
    """
    df_disp = pd.read_sql(query_dispersion, engine)
    
    plt.figure(figsize=(10, 6))
    scatter = plt.scatter(
        df_disp['exposicion'], 
        df_disp['automatizacion'], 
        c=df_disp['creatividad'], 
        cmap='plasma', 
        alpha=0.6, 
        edgecolors='none'
    )
    plt.title('Correlación: Exposición a la IA vs. Probabilidad de Automatización', fontsize=12, fontweight='bold')
    plt.xlabel('Índice de Exposición Tecnológica')
    plt.ylabel('Probabilidad de Automatización de Tareas')
    cbar = plt.colorbar(scatter)
    cbar.set_label('Requerimiento de Habilidad Creativa Humana', fontweight='bold')
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig('dashboard/img/02_dispersion_exposicion.png', dpi=150)
    plt.close()
    
    print("¡Proceso completado con éxito! Gráficos guardados en 'dashboard/img/'")

if __name__ == '__main__':
    generar_reportes()