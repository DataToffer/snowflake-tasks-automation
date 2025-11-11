-- ============================================================================
-- 🚀 AUTOMATIZACIÓN EN SNOWFLAKE: TASKS EN ACCIÓN
-- Caso Real: Smart Desk - Métricas de Negocio Actualizadas Automáticamente
-- ============================================================================
-- 
-- 📚 CONTEXTO ACADÉMICO:
-- Desarrollado para el Máster en Data Science, Big Data & Business Analytics
-- Universidad Complutense de Madrid (UCM) + Ntic Master
-- Profesor: Juan Fernando Sánchez Martínez
--
-- ⏱️ Tiempo de implementación: 10 minutos
-- 💡 Nivel: Intermedio
-- 🎯 Objetivo: Automatizar actualización de métricas sin herramientas externas
--
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PASO 0: VERIFICACIÓN PREVIA
-- ----------------------------------------------------------------------------
-- Ejecuta estas queries para asegurarte que tienes los permisos necesarios

-- Verificar tu rol y permisos
SELECT CURRENT_ROLE(), CURRENT_USER(), CURRENT_WAREHOUSE();

-- Verificar que tu warehouse está activo
SHOW WAREHOUSES;

-- Verificar que puedes ver la tabla de datos
DESCRIBE TABLE SANDBOX.SMART_DESK.SALES;

-- Vista previa de los datos
SELECT * FROM SANDBOX.SMART_DESK.SALES LIMIT 5;

-- ----------------------------------------------------------------------------
-- PASO 1: CONFIGURACIÓN DEL CONTEXTO
-- ----------------------------------------------------------------------------
-- ⚠️ IMPORTANTE: Ajusta estos valores según tu entorno

USE DATABASE SANDBOX;
USE WAREHOUSE COMPUTE_WH;  -- ⚠️ CAMBIA esto por tu warehouse
USE SCHEMA SMART_DESK;

-- Opcional: Ajustar tamaño de warehouse para optimizar costos
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = XSmall;

-- ----------------------------------------------------------------------------
-- PASO 2: CREAR SCHEMA DEDICADO PARA AUTOMATIZACIÓN
-- ----------------------------------------------------------------------------
-- Best Practice: Separar objetos de automatización en schemas dedicados
-- Facilita gobernanza, permisos y mantenimiento

CREATE SCHEMA IF NOT EXISTS SANDBOX.AUTOMATION
    COMMENT = 'Schema dedicado para Tasks y procesos automatizados';

USE SCHEMA SANDBOX.AUTOMATION;

-- Verificar que el schema se creó correctamente
SHOW SCHEMAS LIKE 'AUTOMATION' IN DATABASE SANDBOX;

-- ----------------------------------------------------------------------------
-- PASO 3: CREAR TABLA DE MÉTRICAS DE NEGOCIO
-- ----------------------------------------------------------------------------
-- Esta tabla almacenará las métricas calculadas automáticamente por el Task

CREATE OR REPLACE TABLE SHIPPING_METRICS(
    category VARCHAR(100) COMMENT 'Categoría de producto',
    year INTEGER COMMENT 'Año de la transacción',
    quarter VARCHAR(10) COMMENT 'Trimestre (Q1, Q2, Q3, Q4)',
    total_sales DECIMAL(18,2) COMMENT 'Ventas totales en USD',
    total_units INTEGER COMMENT 'Unidades vendidas totales',
    avg_profit_per_unit DECIMAL(18,2) COMMENT 'Profit promedio por unidad',
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Timestamp de última actualización'
)
COMMENT = 'Tabla de métricas automatizadas - Smart Desk Supply Chain Performance';

-- Verificar estructura de la tabla
DESCRIBE TABLE SHIPPING_METRICS;

-- ----------------------------------------------------------------------------
-- PASO 3.5: VALIDAR LA QUERY ANTES DE CREAR EL TASK
-- ----------------------------------------------------------------------------
-- ⚡ CRÍTICO: Siempre valida que tu query funciona correctamente ANTES de
-- crear el Task. Esto evita errores y consumo innecesario de créditos.

SELECT
    CATEGORY,
    YEAR,
    QUARTER,
    SUM(TOTAL) AS TOTAL_SALES,
    SUM(UNITS_SOLD) AS TOTAL_UNITS,
    ROUND(SUM(PROFIT) / NULLIF(SUM(UNITS_SOLD), 0), 2) AS AVG_PROFIT_PER_UNIT,
    CURRENT_TIMESTAMP() AS UPDATED_AT
FROM SANDBOX.SMART_DESK.SALES
WHERE YEAR >= 2020
GROUP BY CATEGORY, YEAR, QUARTER
ORDER BY YEAR DESC, QUARTER DESC;

-- ✅ Si esta query funciona correctamente, continúa al siguiente paso
-- ❌ Si hay errores, corrígelos antes de crear el Task

-- ----------------------------------------------------------------------------
-- PASO 4: CREAR EL TASK DE AUTOMATIZACIÓN
-- ----------------------------------------------------------------------------
-- Este Task ejecutará la query de agregación automáticamente según el schedule
-- 
-- 📅 SCHEDULE ACTUAL: Cada minuto (CRON 0-59 0-23 * * *)
-- ⚠️ NOTA: En producción, ajusta según necesidad real del negocio
--
-- Alternativas comunes:
-- - Cada 15 minutos: 'USING CRON */15 * * * * America/Chicago'
-- - Cada hora: 'USING CRON 0 * * * * America/Chicago'
-- - Cada día a las 6 AM: 'USING CRON 0 6 * * * America/Chicago'
-- - Solo días laborables: 'USING CRON 0 9 * * 1-5 America/Chicago'

CREATE OR REPLACE TASK refresh_metrics_task
    WAREHOUSE = 'COMPUTE_WH'  -- ⚠️ CAMBIA esto por tu warehouse
    SCHEDULE = 'USING CRON 0-59 0-23 * * * America/Chicago'
    COMMENT = 'Actualiza métricas de shipping por categoría - Smart Desk (Creado: 2025-11-11)'
AS    
    INSERT OVERWRITE INTO SANDBOX.AUTOMATION.SHIPPING_METRICS 
        (category, year, quarter, total_sales, total_units, avg_profit_per_unit, updated_at)
    SELECT
        CATEGORY,
        YEAR,
        QUARTER,
        SUM(TOTAL) AS TOTAL_SALES,
        SUM(UNITS_SOLD) AS TOTAL_UNITS,
        ROUND(SUM(PROFIT) / NULLIF(SUM(UNITS_SOLD), 0), 2) AS AVG_PROFIT_PER_UNIT,
        CURRENT_TIMESTAMP() AS UPDATED_AT
    FROM SANDBOX.SMART_DESK.SALES
    WHERE YEAR >= 2020
    GROUP BY CATEGORY, YEAR, QUARTER
    ORDER BY YEAR DESC, QUARTER DESC;

-- ----------------------------------------------------------------------------
-- PASO 5: VERIFICAR QUE EL TASK SE CREÓ CORRECTAMENTE
-- ----------------------------------------------------------------------------

-- Ver todos los tasks en el schema actual
SHOW TASKS LIKE 'refresh_metrics_task' IN SCHEMA SANDBOX.AUTOMATION;

-- Ver detalles específicos del task
DESCRIBE TASK refresh_metrics_task;

-- 📊 Campos importantes en el resultado:
-- - state: Debe ser "suspended" (los tasks se crean suspendidos por defecto)
-- - schedule: Debe mostrar tu CRON expression
-- - warehouse: Debe mostrar tu warehouse
-- - definition: Debe mostrar tu query completa

-- ----------------------------------------------------------------------------
-- PASO 6: INICIAR EL TASK
-- ----------------------------------------------------------------------------
-- ⚠️ IMPORTANTE: Una vez iniciado, el Task comenzará a ejecutarse según el
-- schedule definido y consumirá créditos del warehouse

ALTER TASK refresh_metrics_task RESUME;

-- Verificar que el estado cambió a 'started'
DESCRIBE TASK refresh_metrics_task;

-- Deberías ver: state = "started"

-- ----------------------------------------------------------------------------
-- PASO 7: MONITOREAR LA EJECUCIÓN DEL TASK
-- ----------------------------------------------------------------------------
-- ⏳ Espera aproximadamente 60 segundos para que el Task se ejecute al menos una vez

-- Ver los datos en la tabla de métricas
SELECT * 
FROM SHIPPING_METRICS
ORDER BY updated_at DESC, year DESC, quarter DESC;

-- 💡 TIP: Ejecuta esta query varias veces cada minuto para ver cómo
-- se actualiza el campo updated_at automáticamente

-- Ver historial completo de ejecuciones del task (última hora)
SELECT 
    NAME AS TASK_NAME,
    DATABASE_NAME,
    SCHEMA_NAME,
    STATE AS EXECUTION_STATE,
    SCHEDULED_TIME,
    QUERY_START_TIME,
    COMPLETED_TIME,
    DATEDIFF('second', QUERY_START_TIME, COMPLETED_TIME) AS EXECUTION_TIME_SECONDS,
    RETURN_VALUE,
    ERROR_CODE,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    TASK_NAME => 'REFRESH_METRICS_TASK'
))
ORDER BY SCHEDULED_TIME DESC;

-- 📊 Estados posibles:
-- - SCHEDULED: El task está programado para ejecutarse
-- - EXECUTING: El task se está ejecutando ahora
-- - SUCCEEDED: El task se ejecutó correctamente
-- - FAILED: El task falló (ver ERROR_MESSAGE para detalles)
-- - SKIPPED: El task se saltó (puede pasar si el anterior aún no terminó)

-- Ver solo ejecuciones exitosas
SELECT 
    SCHEDULED_TIME,
    COMPLETED_TIME,
    DATEDIFF('second', QUERY_START_TIME, COMPLETED_TIME) AS EXECUTION_TIME_SECONDS
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    TASK_NAME => 'REFRESH_METRICS_TASK'
))
WHERE STATE = 'SUCCEEDED'
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;

-- Ver solo ejecuciones fallidas (troubleshooting)
SELECT 
    SCHEDULED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE,
    QUERY_TEXT
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -24, CURRENT_TIMESTAMP()),
    TASK_NAME => 'REFRESH_METRICS_TASK'
))
WHERE STATE = 'FAILED'
ORDER BY SCHEDULED_TIME DESC;

-- ----------------------------------------------------------------------------
-- PASO 8: ANÁLISIS DE LAS MÉTRICAS GENERADAS
-- ----------------------------------------------------------------------------
-- Ahora que tienes datos actualizados automáticamente, puedes analizarlos

-- ¿Qué categorías son más rentables por unidad?
SELECT 
    category,
    year,
    quarter,
    avg_profit_per_unit,
    total_units,
    total_sales
FROM SHIPPING_METRICS
WHERE year = 2021
ORDER BY avg_profit_per_unit DESC
LIMIT 5;

-- Tendencia de ventas por categoría en el tiempo
SELECT 
    category,
    year,
    quarter,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category ORDER BY year, quarter) AS prev_quarter_sales,
    ROUND(
        ((total_sales - LAG(total_sales) OVER (PARTITION BY category ORDER BY year, quarter)) 
        / NULLIF(LAG(total_sales) OVER (PARTITION BY category ORDER BY year, quarter), 0)) * 100, 
        2
    ) AS growth_percentage
FROM SHIPPING_METRICS
WHERE total_sales IS NOT NULL
ORDER BY category, year, quarter;

-- Ranking de categorías por ventas totales
SELECT 
    category,
    SUM(total_sales) AS total_sales_all_periods,
    SUM(total_units) AS total_units_all_periods,
    ROUND(AVG(avg_profit_per_unit), 2) AS avg_profit_across_periods
FROM SHIPPING_METRICS
GROUP BY category
ORDER BY total_sales_all_periods DESC;

-- ----------------------------------------------------------------------------
-- PASO 9: SUSPENDER EL TASK (¡MUY IMPORTANTE!)
-- ----------------------------------------------------------------------------
-- ⚠️ CRÍTICO: Siempre suspende Tasks de prueba para evitar consumo de créditos
-- Los Tasks en estado RESUMED consumen créditos del warehouse incluso cuando
-- no están ejecutándose activamente

ALTER TASK refresh_metrics_task SUSPEND;

-- Verificar que se suspendió correctamente
DESCRIBE TASK refresh_metrics_task;
-- Deberías ver: state = "suspended"

-- Ver el estado de todos los tasks en el schema
SHOW TASKS IN SCHEMA SANDBOX.AUTOMATION;

-- 💡 TIP: Si necesitas reactivar el task más tarde:
-- ALTER TASK refresh_metrics_task RESUME;

-- ----------------------------------------------------------------------------
-- PASO 10: SUSPENDER WAREHOUSE (OPTIMIZACIÓN DE COSTOS)
-- ----------------------------------------------------------------------------
-- ⚠️ IMPORTANTE: Suspender el warehouse cuando no lo estés usando

ALTER WAREHOUSE COMPUTE_WH SUSPEND;  -- ⚠️ CAMBIA esto por tu warehouse

-- Verificar que se suspendió
SHOW WAREHOUSES LIKE 'COMPUTE_WH';

-- ----------------------------------------------------------------------------
-- PASO 11: LIMPIEZA (OPCIONAL - SOLO SI QUIERES BORRAR TODO)
-- ----------------------------------------------------------------------------
-- ⚠️ WARNING: Esto eliminará todos los objetos creados en este ejercicio
-- Descomenta solo si estás seguro de querer eliminar todo

-- DROP TASK IF EXISTS refresh_metrics_task;
-- DROP TABLE IF EXISTS SHIPPING_METRICS;
-- DROP SCHEMA IF EXISTS SANDBOX.AUTOMATION;

-- ============================================================================
-- 📚 CONCEPTOS CLAVE APRENDIDOS
-- ============================================================================
--
-- 1️⃣ TASKS EN SNOWFLAKE:
--    - Objetos que ejecutan SQL de forma programada
--    - Requieren un warehouse para ejecutarse
--    - Se crean en estado SUSPENDED por defecto
--    - Consumen créditos mientras están en estado RESUMED
--
-- 2️⃣ EXPRESIONES CRON:
--    - Formato: minuto hora día_mes mes día_semana zona_horaria
--    - CRON 0-59 0-23 * * * = cada minuto de cada hora
--    - Permite control granular del scheduling
--    - Incluye timezone para precisión
--
-- 3️⃣ INSERT OVERWRITE:
--    - Reemplaza completamente los datos de la tabla
--    - Más eficiente que DELETE + INSERT para refresh completo
--    - Ideal para tablas de métricas agregadas
--    - Evita duplicados y mantiene schema consistente
--
-- 4️⃣ TASK_HISTORY():
--    - Función de tabla para auditar ejecuciones
--    - Muestra éxitos, fallos y mensajes de error
--    - Esencial para troubleshooting y monitoreo
--    - Retorna datos históricos configurables
--
-- 5️⃣ GESTIÓN DE CRÉDITOS:
--    - SUSPEND tasks cuando no los necesites (CRÍTICO)
--    - SUSPEND warehouses después de usarlos
--    - Monitorea consumo con QUERY_HISTORY y WAREHOUSE_METERING_HISTORY
--    - Ajusta tamaño de warehouse según workload
--
-- ============================================================================
-- 💡 CASOS DE USO REALES EN SMART DESK Y OTRAS EMPRESAS
-- ============================================================================
--
-- ✅ Dashboards en tiempo real de KPIs operacionales
-- ✅ Alertas automáticas cuando métricas caen bajo umbrales
-- ✅ Reportes ejecutivos actualizados cada hora/día
-- ✅ Sincronización de datos entre sistemas (ETL ligero)
-- ✅ Cálculos complejos programados en horarios de bajo uso
-- ✅ Mantenimiento automático (VACUUM, ANALYZE, etc.)
-- ✅ Snapshots históricos de tablas críticas
-- ✅ Procesamiento incremental con STREAMS + TASKS
--
-- ============================================================================
-- 🎓 PRÓXIMOS PASOS SUGERIDOS
-- ============================================================================
--
-- 1. Experimenta con diferentes CRON schedules
-- 2. Crea tasks con dependencias (child tasks con AFTER)
-- 3. Combina tasks con STREAMS para procesamiento incremental (CDC)
-- 4. Implementa notificaciones con SYSTEM$SEND_EMAIL
-- 5. Explora task observability con QUERY_HISTORY
-- 6. Aprende sobre Task DAGs (Directed Acyclic Graphs)
-- 7. Integra con dbt para transformaciones más complejas
--
-- ============================================================================
-- 📖 RECURSOS ADICIONALES
-- ============================================================================
--
-- Documentación oficial de Snowflake:
-- - Tasks: https://docs.snowflake.com/en/user-guide/tasks-intro
-- - CRON: https://docs.snowflake.com/en/sql-reference/sql/create-task#schedule
-- - TASK_HISTORY: https://docs.snowflake.com/en/sql-reference/functions/task_history
--
-- Repositorio GitHub:
-- - https://github.com/juanfersanchez/snowflake-tasks-automation
--
-- ============================================================================
-- 👨‍💻 AUTOR Y CONTEXTO ACADÉMICO
-- ============================================================================
-- 
-- Autor: Juan Fernando Sánchez Martínez
-- Rol: Profesor de Bases de Datos SQL
-- Institución: Universidad Complutense de Madrid (UCM)
-- Programa: Máster en Data Science, Big Data & Business Analytics
-- Partner: Ntic Master
-- LinkedIn: linkedin.com/in/juanfersanchez
-- 
-- 📅 Fecha de creación: Noviembre 2025
-- 🔄 Última actualización: Noviembre 2025
-- 📝 Versión: 1.0
-- 
-- ============================================================================
-- 📄 LICENCIA
-- ============================================================================
-- 
-- MIT License - Libre para uso educativo y comercial
-- Ver LICENSE file en el repositorio para más detalles
-- 
-- ============================================================================
