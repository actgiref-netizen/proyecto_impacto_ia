-- ============================================================================
-- PROYECTO FINAL: EXTRACCIÓN DE METADATOS SEMIESTRUCTURADOS (NoSQL / JSONB)
-- ============================================================================

SET search_path TO public;

-- Extraer propiedades anidadas utilizando operadores nativos (-> y ->>)
SELECT 
    id_log,
    fecha_registro,
    detalles_json->>'origen_proceso' as componente_origen,
    detalles_json->'metadatos'->>'ambiente' as entorno_ambiente,
    detalles_json->'metadatos'->>'filas_afectadas' as registros_procesados,
    detalles_json->'flags'->>'estructura_ok' as validacion_estado
FROM public.log_auditoria_ia
ORDER BY fecha_registro DESC;