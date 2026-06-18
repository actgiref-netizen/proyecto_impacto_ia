-- ============================================================================
-- PROYECTO FINAL: ESTRUCTURACIÓN DEL DATA WAREHOUSE (MODELO DIMENSIONAL)
-- NOMBRE:CANO REYES GIREF MICAL
-- AMBIENTE: AMAZON AURORA POSTGRESQL (AWS ACADEMY)
============================================================================

-- 1.  ESQUEMA PÚBLICO EN LA NUBE
SET search_path TO public;

-- 2. LIMPIEZA PREVENTIVA (Eliminar estructuras previas si existen)
DROP TABLE IF EXISTS public.fact_impacto_ia CASCADE;
DROP TABLE IF EXISTS public.dim_industria CASCADE;
DROP TABLE IF EXISTS public.dim_puesto_trabajo CASCADE;
DROP TABLE IF EXISTS public.dim_tiempo CASCADE;
DROP TABLE IF EXISTS public.log_auditoria_ia CASCADE;

-- ============================================================================
-- 3. DECLARACIÓN DE TABLAS DE DIMENSIONES (NORMALIZACIÓN)
-- ============================================================================

-- Dimensión 1: Sectores Industriales
CREATE TABLE public.dim_industria (
    id_industria SERIAL PRIMARY KEY,
    nombre_ext VARCHAR(150) NOT NULL UNIQUE
);

-- Dimensión 2: Catálogo de Puestos de Trabajo y Riesgo Base
CREATE TABLE public.dim_puesto_trabajo (
    id_puesto SERIAL PRIMARY KEY,
    titulo_puesto VARCHAR(150) NOT NULL,
    categoria_riesgo VARCHAR(50) NOT NULL
);

-- Dimensión 3: Tiempo (Perspectiva Anual de Proyección)
CREATE TABLE public.dim_tiempo (
    id_tiempo INT PRIMARY KEY,
    anio INT NOT NULL
);

-- ============================================================================
-- 4. DECLARACIÓN DE LA TABLA DE HECHOS (CENTRALIZACIÓN DE MÉTRICAS)
-- ============================================================================
CREATE TABLE public.fact_impacto_ia (
    id_impacto SERIAL PRIMARY KEY,
    id_industria INT NOT NULL,
    id_puesto INT NOT NULL,
    id_tiempo INT NOT NULL,
    id_exposicion_ia NUMERIC(5,2),          -- Índice calculado de exposición
    probabilidad_automatizacion NUMERIC(5,2),-- % de tareas automatizables
    conteo_despidos INT DEFAULT 0,          -- Proyección analítica de desplazamiento
    nivel_habilidad_analisis INT,            -- Escala de requerimiento humano
    nivel_habilidad_creatividad INT,         -- Escala de requerimiento humano
    FOREIGN KEY (id_industria) REFERENCES public.dim_industria(id_industria),
    FOREIGN KEY (id_puesto) REFERENCES public.dim_puesto_trabajo(id_puesto),
    FOREIGN KEY (id_tiempo) REFERENCES public.dim_tiempo(id_tiempo)
);

-- ============================================================================
-- 5. CAPA SEMIESTRUCTURADA: TABLA DE AUDITORÍA (REQUERIMIENTO NOSQL / JSONB)
-- ============================================================================
CREATE TABLE public.log_auditoria_ia (
    id_log SERIAL PRIMARY KEY,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detalles_json JSONB
);

-- ============================================================================
-- 6. PROCESO ETL TRANSFORMACIONAL EN MOTOR 
-- ============================================================================

-- A. Extraer y normalizar las industrias únicas del dataset crudo
INSERT INTO public.dim_industria (nombre_ext)
SELECT DISTINCT TRIM("Industry") 
FROM public.ia_impact_on_jobs 
WHERE "Industry" IS NOT NULL
ON CONFLICT (nombre_ext) DO NOTHING;

-- B. Extraer y mapear puestos de trabajo únicos
INSERT INTO public.dim_puesto_trabajo (titulo_puesto, categoria_riesgo)
SELECT DISTINCT TRIM("Job_Role"), COALESCE(TRIM("AI_Adoption_Level"), 'Medium')
FROM public.ia_impact_on_jobs 
WHERE "Job_Role" IS NOT NULL;

-- C. Inicializar el año de estudio del benchmark (2030)
INSERT INTO public.dim_tiempo (id_tiempo, anio) 
VALUES (2030, 2030) 
ON CONFLICT DO NOTHING;

-- D. Construcción de registros de la Tabla de Hechos mediante cruce relacional (JOINs)
INSERT INTO public.fact_impacto_ia (
    id_industria, id_puesto, id_tiempo, id_exposicion_ia, 
    probabilidad_automatizacion, conteo_despidos, 
    nivel_habilidad_analisis, nivel_habilidad_creatividad
)
SELECT 
    ind.id_industria,
    pue.id_puesto,
    2030,
    orig."Tasks_Automated_Percentage"::NUMERIC / 100.0, -- Normalización a índice decimal
    orig."Routine_Task_Percentage"::NUMERIC / 100.0,    -- Normalización a probabilidad
    (orig."Years_of_Experience" * 15),                  -- Estimación analítica simulada de despidos
    orig."Human_Interaction_Level",
    orig."Creativity_Requirement"
FROM public.ia_impact_on_jobs orig
JOIN public.dim_industria ind ON TRIM(orig."Industry") = ind.nombre_ext
JOIN public.dim_puesto_trabajo pue ON TRIM(orig."Job_Role") = pue.titulo_puesto;

-- ============================================================================
-- 7. POBLAR ELEMENTOS DE CONTROL SEMIESTRUCTURADOS (REGISTROS LOGS JSONB)
-- ============================================================================
INSERT INTO public.log_auditoria_ia (detalles_json) VALUES 
('{"origen_proceso": "ETL_SQL_DBeaver", "metadatos": {"filas_afectadas": 5200, "ambiente": "Produccion"}, "flags": {"estructura_ok": true}}'),
('{"origen_proceso": "Dashboard_Matplotlib", "metadatos": {"consultas_servidas": 5, "latencia_ms": 12}, "flags": {"cache_utilizada": false}}');

-- ============================================================================
-- FIN DEL SCRIPT MAESTRO DDL/ETL
-- ============================================================================