# ❓ Preguntas Frecuentes (FAQ)

## General

### ¿Qué son los Snowflake Tasks?

Los Tasks son objetos de Snowflake que ejecutan código SQL automáticamente según un schedule que tú defines. Son similares a "cron jobs" pero nativos en la plataforma, sin necesidad de herramientas externas.

### ¿Por qué usar Tasks en lugar de Airflow o dbt Cloud?

**Ventajas de Tasks:**
- ✅ Nativos en Snowflake (sin infraestructura adicional)
- ✅ Configuración rápida (minutos vs horas)
- ✅ Sin costos adicionales de herramientas
- ✅ Latencia mínima (ejecución dentro de Snowflake)

**Cuándo usar Airflow/dbt:**
- Orquestación compleja con múltiples sistemas
- DAGs con decenas de pasos
- Necesitas integraciones con servicios externos
- Requieres UI rica para monitoring

**La respuesta honesta:** No es "uno u otro", sino cuándo usar cada uno. Para procesos simples dentro de Snowflake, Tasks son perfectos.

### ¿Los Tasks son gratis?

No exactamente. Los Tasks en sí no tienen costo adicional, PERO:
- ⚠️ Consumen créditos del warehouse asignado
- ⚠️ Warehouses en estado RESUMED consumen créditos incluso sin queries
- ⚠️ Es crucial usar SUSPEND cuando no se necesiten

**Costo real:** Depende de tu warehouse size y frecuencia de ejecución.

---

## Implementación

### ¿Cuánto tiempo tarda implementar un Task?

**Setup inicial:** 10-15 minutos (primera vez)
**Tasks adicionales:** 2-5 minutos (una vez familiarizado)

### ¿Puedo usar Tasks sin conocer CRON expressions?

Sí. Ejemplos listos para usar:

```sql
-- Cada 15 minutos
'USING CRON */15 * * * * America/Chicago'

-- Cada hora
'USING CRON 0 * * * * America/Chicago'

-- Todos los días a las 6 AM
'USING CRON 0 6 * * * America/Chicago'

-- Lunes a Viernes a las 9 AM
'USING CRON 0 9 * * 1-5 America/Chicago'
```

Generador online: [crontab.guru](https://crontab.guru/)

### ¿Necesito saber programación para usar Tasks?

No. Si sabes escribir queries SQL, puedes crear Tasks. El código es 100% SQL.

---

## Costos y Optimización

### ¿Cómo controlar el consumo de créditos?

**Best practices:**

1. **Suspender cuando no uses:**
```sql
ALTER TASK mi_task SUSPEND;
ALTER WAREHOUSE mi_warehouse SUSPEND;
```

2. **Schedule realista:**
```sql
-- ❌ NO: Cada minuto si no lo necesitas
SCHEDULE = 'USING CRON 0-59 0-23 * * *'

-- ✅ SÍ: Según necesidad real
SCHEDULE = 'USING CRON 0 9 * * 1-5'  -- Solo días laborables
```

3. **Warehouse size apropiado:**
```sql
-- Para queries simples
ALTER WAREHOUSE mi_wh SET WAREHOUSE_SIZE = XSmall;
```

4. **Monitorear consumo:**
```sql
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'MI_WAREHOUSE'
ORDER BY START_TIME DESC;
```

### ¿Cuánto cuesta ejecutar un Task cada hora?

**Ejemplo de cálculo:**

Asumiendo:
- Warehouse: XSmall (1 crédito/hora)
- Query execution: 5 segundos
- Frecuencia: Cada hora (24 veces/día)

**Costo diario:**
- Tiempo total ejecutando: 24 × 5 seg = 120 seg = 2 minutos
- Créditos consumidos: 2 min / 60 min × 1 crédito = 0.033 créditos/día
- **Costo mensual:** ~1 crédito/mes

**⚠️ PERO:** Si el warehouse no se suspende, consumirá 24 créditos/día (costoso).

### ¿Qué pasa si olvido suspender un Task?

**Escenario real:**
- Task ejecutándose cada minuto
- Warehouse: Small (2 créditos/hora)
- 24 horas × 2 créditos = **48 créditos/día**
- Costo: $48-240/día (según precio de crédito)

**Solución:**
- Siempre usar SUSPEND después de validar
- Configurar alertas de consumo en Snowflake
- Revisar tasks activos regularmente

---

## Troubleshooting

### Mi Task no se ejecuta, ¿qué hago?

**Checklist de diagnóstico:**

1. **Verificar estado:**
```sql
DESCRIBE TASK mi_task;
-- state debe ser "started"
```

2. **Verificar warehouse:**
```sql
SHOW WAREHOUSES;
-- Tu warehouse debe existir y ser accesible
```

3. **Ver historial:**
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
WHERE NAME = 'MI_TASK';
```

4. **Probar query manualmente:**
```sql
-- Ejecuta la query del task directamente
```

### ¿Cómo debuggear un Task que falla?

```sql
-- Ver errores detallados
SELECT 
    SCHEDULED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE,
    QUERY_TEXT
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
))
WHERE NAME = 'MI_TASK'
  AND STATE = 'FAILED'
ORDER BY SCHEDULED_TIME DESC;
```

**Errores comunes:**

| Error | Causa | Solución |
|-------|-------|----------|
| Insufficient privileges | Faltan permisos | Verifica GRANTS del rol |
| Object does not exist | Tabla/schema no existe | Verifica rutas completas |
| Warehouse suspended | Warehouse apagado | Inicia warehouse o asigna otro |
| Timeout | Query muy lenta | Optimiza query o aumenta warehouse |

### Mi Task se ejecuta pero la tabla no se actualiza

**Posibles causas:**

1. **INSERT sin datos:**
```sql
-- Verifica que la query retorna datos
SELECT COUNT(*) FROM (
    -- Tu query aquí
);
```

2. **Filtros muy restrictivos:**
```sql
-- ¿Hay datos en el rango?
SELECT COUNT(*) FROM tabla WHERE YEAR >= 2020;
```

3. **Error silencioso:**
```sql
-- Ver resultados del task
SELECT 
    SCHEDULED_TIME,
    RETURN_VALUE,  -- NULL = no insertó nada
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(...));
```

---

## Avanzado

### ¿Puedo crear Tasks con dependencias?

Sí. Usa la cláusula `AFTER`:

```sql
-- Task padre
CREATE TASK parent_task
    WAREHOUSE = 'WH'
    SCHEDULE = 'USING CRON 0 * * * *'
AS SELECT ...;

-- Task hijo (se ejecuta después del padre)
CREATE TASK child_task
    WAREHOUSE = 'WH'
    AFTER parent_task
AS SELECT ...;

-- Iniciar en orden inverso
ALTER TASK child_task RESUME;
ALTER TASK parent_task RESUME;
```

### ¿Puedo pausar un Task temporalmente?

Sí, usa `SUSPEND`:

```sql
-- Pausar
ALTER TASK mi_task SUSPEND;

-- Reanudar cuando quieras
ALTER TASK mi_task RESUME;
```

### ¿Cómo proceso solo datos nuevos (incremental)?

Usa STREAMS:

```sql
-- Crear stream en tabla source
CREATE STREAM mi_stream ON TABLE datos_source;

-- Task que procesa solo cambios
CREATE TASK process_incremental
    WAREHOUSE = 'WH'
    SCHEDULE = 'USING CRON 0 * * * *'
    WHEN SYSTEM$STREAM_HAS_DATA('mi_stream')
AS
    MERGE INTO tabla_target t
    USING mi_stream s
    ON t.id = s.id
    WHEN MATCHED THEN UPDATE SET ...
    WHEN NOT MATCHED THEN INSERT ...;
```

### ¿Puedo ejecutar un Task manualmente (on-demand)?

Sí:

```sql
EXECUTE TASK mi_task;
```

⚠️ **Nota:** Esto NO afecta el schedule. El task seguirá ejecutándose según su CRON.

### ¿Los Tasks pueden llamar stored procedures?

Sí:

```sql
CREATE TASK call_proc_task
    WAREHOUSE = 'WH'
    SCHEDULE = 'USING CRON 0 * * * *'
AS
    CALL mi_stored_procedure();
```

---

## Casos de Uso

### ¿Cuándo debo usar Tasks vs. Streams?

**TASKS:** Para procesamiento basado en tiempo
- "Actualizar dashboard cada hora"
- "Enviar reporte todos los lunes"
- "Limpiar datos antiguos semanalmente"

**STREAMS:** Para procesamiento basado en cambios
- "Procesar nuevos pedidos en tiempo real"
- "Sincronizar cambios con otro sistema"
- "Auditar modificaciones en tablas críticas"

**MEJOR JUNTOS:**
```sql
-- Stream detecta cambios
CREATE STREAM cambios ON TABLE pedidos;

-- Task procesa cuando hay cambios
CREATE TASK procesar_pedidos
    SCHEDULE = '5 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('cambios')
AS ...
```

### ¿Tasks para alertas automáticas?

Sí. Ejemplo real:

```sql
CREATE TASK alert_low_inventory
    WAREHOUSE = 'WH'
    SCHEDULE = 'USING CRON 0 */4 * * *'  -- Cada 4 horas
AS
    -- Insertar en tabla de alertas si hay stock bajo
    INSERT INTO alertas (tipo, mensaje, timestamp)
    SELECT 
        'LOW_INVENTORY',
        'Producto ' || producto || ' con solo ' || stock || ' unidades',
        CURRENT_TIMESTAMP()
    FROM inventario
    WHERE stock < umbral_minimo;
```

Luego otro proceso lee la tabla `alertas` y envía emails.

### ¿Tasks para backup/snapshots?

Absolutamente:

```sql
CREATE TASK daily_snapshot
    WAREHOUSE = 'WH'
    SCHEDULE = 'USING CRON 0 2 * * *'  -- Todos los días a las 2 AM
AS
    CREATE TABLE IF NOT EXISTS tabla_snapshot_$(TO_VARCHAR(CURRENT_DATE(), 'YYYYMMDD'))
    CLONE tabla_produccion;
```

---

## Comparaciones

### Tasks vs. Airflow

| Aspecto | Tasks | Airflow |
|---------|-------|---------|
| Setup | Minutos | Horas/días |
| Infraestructura | Ninguna | Servidor/cluster |
| Costo adicional | No | Sí (hosting) |
| Complejidad | Baja | Media-alta |
| Orquestación | Básica (AFTER) | Avanzada (DAGs) |
| UI | Snowsight básico | UI rica |
| Integrations | Solo Snowflake | Multi-sistema |
| **Mejor para** | ETL simple en SF | Pipelines complejos |

### Tasks vs. dbt Cloud

| Aspecto | Tasks | dbt Cloud |
|---------|-------|-----------|
| Propósito | Scheduling | Transformaciones + scheduling |
| Transformaciones | SQL básico | dbt models + tests |
| Lineage | No | Sí (avanzado) |
| Testing | Manual | Automatizado |
| Documentation | Manual | Auto-generado |
| Costo | Solo SF | SF + dbt Cloud |
| **Mejor para** | Updates simples | Data transformations |

---

## Seguridad

### ¿Qué permisos necesito para crear Tasks?

**Mínimos requeridos:**

```sql
-- Permiso para crear tasks
GRANT CREATE TASK ON SCHEMA mi_schema TO ROLE mi_rol;

-- Permiso de uso del warehouse
GRANT USAGE ON WAREHOUSE mi_wh TO ROLE mi_rol;

-- Permisos en tablas involucradas
GRANT SELECT ON TABLE source_table TO ROLE mi_rol;
GRANT INSERT ON TABLE target_table TO ROLE mi_rol;
```

### ¿Los Tasks se ejecutan con mi usuario?

No. Se ejecutan con el `TASK_OWNER` (el rol que creó el task).

**Implicación:** El rol owner necesita permisos permanentes en los objetos utilizados.

### ¿Puedo compartir Tasks entre roles?

Sí, con `GRANT OWNERSHIP`:

```sql
GRANT OWNERSHIP ON TASK mi_task TO ROLE otro_rol;
```

⚠️ **Cuidado:** El nuevo owner necesita todos los permisos necesarios.

---

## Preguntas del Curso UCM

### ¿Este ejercicio cuenta para la nota del máster?

No directamente, pero:
- Es práctica recomendada para la Tarea Final
- Demuestra dominio de automatización (valorado positivamente)
- Puede incluirse en el caso práctico libre

### ¿Debo suspender los Tasks después del ejercicio?

**SÍ, SIEMPRE.** Tasks activos consumen créditos de la cuenta académica. No suspenderlos puede:
- Agotar créditos del trial
- Bloquear acceso a otros estudiantes
- Resultar en penalización académica

### ¿Puedo usar Tasks en mi proyecto final?

Sí, incluso es recomendado si tu caso práctico lo justifica:
- "Automatización de actualización de métricas"
- "Pipeline de datos con refresh programado"
- "Sistema de alertas basado en umbrales"

**Importante:** Documenta claramente en tu PDF la automatización implementada.

---

## Recursos

### ¿Dónde aprendo más?

**Documentación oficial:**
- [Snowflake Tasks Intro](https://docs.snowflake.com/en/user-guide/tasks-intro)
- [CREATE TASK Reference](https://docs.snowflake.com/en/sql-reference/sql/create-task)
- [TASK_HISTORY Function](https://docs.snowflake.com/en/sql-reference/functions/task_history)

**Tutoriales:**
- [Snowflake Tasks Best Practices](https://www.snowflake.com/blog/)
- [GitHub: Este repositorio](https://github.com/juanfersanchez/snowflake-tasks-automation)

**Comunidad:**
- [Snowflake Community](https://community.snowflake.com/)
- [Stack Overflow - Snowflake Tag](https://stackoverflow.com/questions/tagged/snowflake)

### ¿Certificación relacionada?

Sí, en **SnowPro Core Certification** hay preguntas sobre Tasks:
- Creación y gestión de tasks
- CRON expressions
- Task monitoring
- Cost optimization

---

## Contacto

¿No encuentras respuesta a tu pregunta?

- 📧 **Email:** [tu-email@ucm.es]
- 💼 **LinkedIn:** [linkedin.com/in/juanfersanchez](https://www.linkedin.com/in/juanfersanchez/)
- 🐛 **GitHub Issues:** [Abre un issue](../../issues)
- 💬 **Foro UCM:** Campus Virtual del Máster

---

**Última actualización:** Noviembre 2025
