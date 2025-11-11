# 📖 Tutorial: Automatización con Snowflake Tasks

## Tabla de Contenidos

1. [Prerrequisitos](#prerrequisitos)
2. [Configuración Inicial](#configuración-inicial)
3. [Paso a Paso](#paso-a-paso)
4. [Verificación y Testing](#verificación-y-testing)
5. [Troubleshooting](#troubleshooting)
6. [Siguiente Nivel](#siguiente-nivel)

---

## Prerrequisitos

### Acceso y Permisos

Antes de comenzar, asegúrate de tener:

- ✅ Cuenta activa en Snowflake (trial o producción)
- ✅ Rol con permisos para:
  - Crear SCHEMA
  - Crear TABLE
  - Crear TASK
  - Ejecutar ALTER TASK
- ✅ Acceso a un WAREHOUSE con permisos de uso
- ✅ Dataset Smart Desk cargado en `SANDBOX.SMART_DESK.SALES`

### Verificar Permisos

```sql
-- Verificar tu contexto actual
SELECT 
    CURRENT_ROLE() AS mi_rol,
    CURRENT_USER() AS mi_usuario,
    CURRENT_WAREHOUSE() AS mi_warehouse,
    CURRENT_DATABASE() AS mi_database;

-- Verificar permisos en el database
SHOW GRANTS TO ROLE TRAINING_ROLE;  -- Ajusta tu rol

-- Verificar acceso al dataset
SELECT COUNT(*) FROM SANDBOX.SMART_DESK.SALES;
```

---

## Configuración Inicial

### 1. Preparar tu Entorno

```sql
-- Establecer contexto
USE DATABASE SANDBOX;
USE WAREHOUSE COMPUTE_WH;  -- Ajusta a tu warehouse
USE SCHEMA SMART_DESK;

-- Optimizar tamaño de warehouse para pruebas
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = XSmall;
```

### 2. Explorar los Datos

```sql
-- Ver estructura de la tabla
DESCRIBE TABLE SANDBOX.SMART_DESK.SALES;

-- Ver muestra de datos
SELECT * FROM SANDBOX.SMART_DESK.SALES LIMIT 10;

-- Estadísticas básicas
SELECT 
    COUNT(*) AS total_registros,
    COUNT(DISTINCT CATEGORY) AS categorias_unicas,
    COUNT(DISTINCT YEAR) AS años_distintos,
    MIN(YEAR) AS año_minimo,
    MAX(YEAR) AS año_maximo
FROM SANDBOX.SMART_DESK.SALES;
```

---

## Paso a Paso

### PASO 1: Crear Schema de Automatización

**¿Por qué?** Separar objetos de automatización facilita gobernanza y permisos.

```sql
CREATE SCHEMA IF NOT EXISTS SANDBOX.AUTOMATION
    COMMENT = 'Schema para Tasks y procesos automatizados';

USE SCHEMA SANDBOX.AUTOMATION;

-- Verificar creación
SHOW SCHEMAS LIKE 'AUTOMATION' IN DATABASE SANDBOX;
```

### PASO 2: Crear Tabla de Métricas

**¿Qué hace?** Almacena las métricas calculadas automáticamente.

```sql
CREATE OR REPLACE TABLE SHIPPING_METRICS(
    category VARCHAR(100),
    year INTEGER,
    quarter VARCHAR(10),
    total_sales DECIMAL(18,2),
    total_units INTEGER,
    avg_profit_per_unit DECIMAL(18,2),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Métricas automatizadas - Smart Desk';

-- Verificar estructura
DESCRIBE TABLE SHIPPING_METRICS;
```

### PASO 3: Validar la Query de Agregación

**⚠️ CRÍTICO:** Siempre valida tu query ANTES de crear el Task.

```sql
-- Esta es la query que se ejecutará automáticamente
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
```

✅ **Checkpoint:** Si esta query funciona, puedes continuar.

### PASO 4: Crear el Task

**¿Qué hace?** Define la automatización con schedule CRON.

```sql
CREATE OR REPLACE TASK refresh_metrics_task
    WAREHOUSE = 'COMPUTE_WH'  -- ⚠️ Ajusta a tu warehouse
    SCHEDULE = 'USING CRON 0-59 0-23 * * * America/Chicago'
    COMMENT = 'Actualiza métricas cada minuto - Smart Desk'
AS    
    INSERT OVERWRITE INTO SANDBOX.AUTOMATION.SHIPPING_METRICS 
        (category, year, quarter, total_sales, total_units, avg_profit_per_unit, updated_at)
    SELECT
        CATEGORY,
        YEAR,
        QUARTER,
        SUM(TOTAL),
        SUM(UNITS_SOLD),
        ROUND(SUM(PROFIT) / NULLIF(SUM(UNITS_SOLD), 0), 2),
        CURRENT_TIMESTAMP()
    FROM SANDBOX.SMART_DESK.SALES
    WHERE YEAR >= 2020
    GROUP BY CATEGORY, YEAR, QUARTER
    ORDER BY YEAR DESC, QUARTER DESC;
```

**Alternativas de Schedule:**

```sql
-- Cada 15 minutos
SCHEDULE = 'USING CRON */15 * * * * America/Chicago'

-- Cada hora (al minuto 0)
SCHEDULE = 'USING CRON 0 * * * * America/Chicago'

-- Cada día a las 6 AM
SCHEDULE = 'USING CRON 0 6 * * * America/Chicago'

-- Cada día laborable a las 9 AM
SCHEDULE = 'USING CRON 0 9 * * 1-5 America/Chicago'
```

### PASO 5: Verificar el Task

```sql
-- Ver el task creado
SHOW TASKS LIKE 'refresh_metrics_task';

-- Ver detalles completos
DESCRIBE TASK refresh_metrics_task;
```

**Campos importantes a verificar:**
- `state`: Debe ser `suspended` (estado inicial)
- `schedule`: Debe mostrar tu CRON expression
- `warehouse`: Debe mostrar tu warehouse
- `definition`: Debe mostrar tu query

### PASO 6: Iniciar el Task

**⚠️ ATENCIÓN:** Desde este momento el Task comenzará a consumir créditos.

```sql
-- Iniciar el task
ALTER TASK refresh_metrics_task RESUME;

-- Verificar que está activo
DESCRIBE TASK refresh_metrics_task;
-- state debe cambiar a "started"
```

---

## Verificación y Testing

### Monitoreo en Tiempo Real

**Espera 60-90 segundos** después de iniciar el Task, luego ejecuta:

```sql
-- Ver datos en la tabla de métricas
SELECT * 
FROM SHIPPING_METRICS
ORDER BY updated_at DESC;

-- Ver el campo updated_at
-- Debería actualizarse cada minuto
```

### Historial de Ejecuciones

```sql
-- Ver todas las ejecuciones (última hora)
SELECT 
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    TASK_NAME => 'REFRESH_METRICS_TASK'
))
ORDER BY SCHEDULED_TIME DESC;
```

**Estados posibles:**
- ✅ `SUCCEEDED`: Ejecución exitosa
- ❌ `FAILED`: Ejecución fallida (ver ERROR_MESSAGE)
- ⏸️ `SKIPPED`: Saltada (ejecución anterior aún corriendo)
- 🔄 `EXECUTING`: Ejecutándose ahora

### Tiempos de Ejecución

```sql
-- Ver performance del task
SELECT 
    SCHEDULED_TIME,
    DATEDIFF('second', QUERY_START_TIME, COMPLETED_TIME) AS execution_seconds
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    TASK_NAME => 'REFRESH_METRICS_TASK'
))
WHERE STATE = 'SUCCEEDED'
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;
```

### ⏹️ Suspender el Task

**🔴 CRÍTICO:** Siempre suspende el Task después de validar.

```sql
-- Suspender task
ALTER TASK refresh_metrics_task SUSPEND;

-- Verificar
DESCRIBE TASK refresh_metrics_task;
-- state debe cambiar a "suspended"

-- Suspender warehouse
ALTER WAREHOUSE COMPUTE_WH SUSPEND;
```

---

## Troubleshooting

### Problema 1: Task no se ejecuta

**Síntomas:**
- Task en estado "started" pero no hay ejecuciones en TASK_HISTORY()
- Tabla SHIPPING_METRICS vacía después de varios minutos

**Soluciones:**

```sql
-- 1. Verificar estado del task
DESCRIBE TASK refresh_metrics_task;

-- 2. Verificar que el warehouse está disponible
SHOW WAREHOUSES;

-- 3. Manualmente ejecutar la query para verificar errores
SELECT * FROM SANDBOX.SMART_DESK.SALES LIMIT 1;

-- 4. Ver errores en task history
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
))
WHERE NAME = 'REFRESH_METRICS_TASK' 
  AND STATE = 'FAILED';
```

### Problema 2: Errores de permisos

**Síntomas:**
- Error: "Insufficient privileges to operate on task"

**Soluciones:**

```sql
-- Verificar permisos del rol
SHOW GRANTS TO ROLE TRAINING_ROLE;  -- Ajusta tu rol

-- El rol necesita:
-- - USAGE en warehouse
-- - CREATE TASK en schema
-- - INSERT/SELECT en tablas involucradas
```

### Problema 3: Consumo excesivo de créditos

**Síntomas:**
- Warehouse consumiendo más créditos de lo esperado
- Task ejecutándose muy frecuentemente

**Soluciones:**

```sql
-- 1. Suspender el task inmediatamente
ALTER TASK refresh_metrics_task SUSPEND;

-- 2. Cambiar el schedule a menos frecuente
ALTER TASK refresh_metrics_task SET SCHEDULE = 'USING CRON 0 * * * * America/Chicago';  -- Cada hora

-- 3. Reducir tamaño del warehouse
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = XSmall;

-- 4. Verificar consumo
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'COMPUTE_WH'
ORDER BY START_TIME DESC
LIMIT 20;
```

### Problema 4: Query lenta

**Síntomas:**
- Task tarda mucho en ejecutarse
- Timeout errors

**Soluciones:**

```sql
-- 1. Optimizar la query (agregar filtros)
WHERE YEAR >= 2020  -- Limitar datos procesados

-- 2. Crear índices si es necesario (cluster key)
ALTER TABLE SANDBOX.SMART_DESK.SALES 
CLUSTER BY (YEAR, QUARTER);

-- 3. Aumentar warehouse temporalmente
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = Small;
```

---

## Siguiente Nivel

### 1. Tasks con Dependencias

Crear un Task que se ejecute después de otro:

```sql
CREATE TASK child_task
    WAREHOUSE = 'COMPUTE_WH'
    AFTER refresh_metrics_task  -- Se ejecuta después del padre
AS
    -- Tu código aquí
    SELECT * FROM SHIPPING_METRICS;
```

### 2. Tasks con Streams (CDC)

Procesar solo cambios incrementales:

```sql
-- Crear stream en tabla source
CREATE STREAM sales_stream ON TABLE SANDBOX.SMART_DESK.SALES;

-- Task que procesa solo cambios
CREATE TASK process_changes
    WAREHOUSE = 'COMPUTE_WH'
    SCHEDULE = 'USING CRON 0 * * * * America/Chicago'
    WHEN SYSTEM$STREAM_HAS_DATA('sales_stream')
AS
    -- Procesar solo cambios
    MERGE INTO SHIPPING_METRICS...
```

### 3. Notificaciones por Email

Enviar alerta si el Task falla:

```sql
-- Configurar email notification
CREATE NOTIFICATION INTEGRATION my_email
    TYPE = EMAIL
    ENABLED = TRUE;

-- Task con error handling
CREATE TASK refresh_with_alerts
    WAREHOUSE = 'COMPUTE_WH'
    SCHEDULE = 'USING CRON 0 * * * * America/Chicago'
    ERROR_INTEGRATION = my_email
AS
    -- Tu código aquí
```

### 4. Task Observability Avanzada

```sql
-- Crear vista de monitoreo
CREATE VIEW task_monitoring AS
SELECT 
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    DATEDIFF('second', QUERY_START_TIME, COMPLETED_TIME) AS duration_seconds,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -7, CURRENT_TIMESTAMP())
))
WHERE NAME LIKE '%metrics%';

-- Dashboard de tasks
SELECT 
    NAME,
    STATE,
    COUNT(*) AS executions,
    AVG(duration_seconds) AS avg_duration,
    MAX(duration_seconds) AS max_duration,
    SUM(CASE WHEN STATE = 'FAILED' THEN 1 ELSE 0 END) AS failures
FROM task_monitoring
GROUP BY NAME, STATE;
```

---

## 🎓 Recursos Adicionales

- [Documentación Oficial: Tasks](https://docs.snowflake.com/en/user-guide/tasks-intro)
- [CRON Expression Generator](https://crontab.guru/)
- [Best Practices: Cost Management](https://www.snowflake.com/blog/best-practices-cost-management/)
- [Repositorio GitHub](https://github.com/juanfersanchez/snowflake-tasks-automation)

---

## 💬 ¿Necesitas Ayuda?

- 📧 Email: [tu-email@ucm.es]
- 💼 LinkedIn: [linkedin.com/in/juanfersanchez](https://www.linkedin.com/in/juanfersanchez/)
- 🐛 Issues: [GitHub Issues](../../issues)

---

**¡Felicidades! 🎉** Has completado el tutorial. Ahora sabes cómo automatizar procesos en Snowflake sin herramientas externas.
