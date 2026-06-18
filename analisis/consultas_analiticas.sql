-- ============================================================================
-- PROYECTO FINAL: CONSULTAS ANALÍTICAS AVANZADAS (MODELO DIMENSIONAL)
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- CONSULTA 1: PUESTOS CON MAYOR RIESGO POR SECTOR (CTE + Función de Ventana)
-- Muestra el Top 3 de roles más vulnerables usando DENSE_RANK() particionado.
-- ----------------------------------------------------------------------------
WITH ranking_automatizacion AS (
    SELECT 
        ind.nombre_ext AS nombre_ext,
        pue.titulo_puesto,
        f.probabilidad_automatizacion,
        DENSE_RANK() OVER(
            PARTITION BY f.id_industria 
            ORDER BY f.probabilidad_automatizacion DESC
        ) as rank_riesgo
    FROM public.fact_impacto_ia f
    JOIN public.dim_industria ind ON f.id_industria = ind.id_industria
    JOIN public.dim_puesto_trabajo pue ON f.id_puesto = pue.id_puesto
)
SELECT nombre_ext, titulo_puesto, probabilidad_automatizacion
FROM ranking_automatizacion
WHERE rank_riesgo <= 3
ORDER BY nombre_ext, probabilidad_automatizacion DESC;

-- ----------------------------------------------------------------------------
-- CONSULTA 2: ANÁLISIS MACRO DE DESPIDOS ACUMULADOS Y EXPOSICIÓN PROMEDIO
-- Agrupa métricas a nivel sectorial para identificar vulnerabilidades globales.
-- ----------------------------------------------------------------------------
SELECT 
    ind.nombre_ext AS nombre_ext,
    ROUND(AVG(f.id_exposicion_ia), 4) as promedio_exposicion_ia,
    SUM(f.conteo_despidos) as total_despidos_estimados,
    COUNT(*) as volumen_puestos_evaluados
FROM public.fact_impacto_ia f
JOIN public.dim_industria ind ON f.id_industria = ind.id_industria
GROUP BY ind.nombre_ext
ORDER BY total_despidos_estimados DESC;