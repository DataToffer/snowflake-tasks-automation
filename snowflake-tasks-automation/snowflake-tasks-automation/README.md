# 🚀 Automatización en Snowflake: Tasks en Acción

[![Snowflake](https://img.shields.io/badge/Snowflake-Tasks-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![SQL](https://img.shields.io/badge/SQL-Advanced-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)](https://www.snowflake.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

> **De manual a automatizado en 10 minutos**: Implementación práctica de Snowflake Tasks para automatización de métricas de negocio.

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Caso de Uso](#caso-de-uso)
- [Requisitos](#requisitos)
- [Instalación Rápida](#instalación-rápida)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Resultados](#resultados)
- [Metodología Técnica](#metodología-técnica)
- [Lecciones Aprendidas](#lecciones-aprendidas)
- [Contribuir](#contribuir)
- [Autor](#autor)
- [Licencia](#licencia)

## 🎯 Descripción

Este repositorio contiene una implementación completa de **Snowflake Tasks** para automatizar la actualización de métricas de negocio. 

Desarrollado como caso práctico en el **Máster de Data Science, Big Data & Business Analytics** de la **Universidad Complutense de Madrid (UCM)**, demuestra cómo pasar de procesos manuales a automatización nativa en Snowflake.

### ¿Qué son los Snowflake Tasks?

Tasks son objetos de Snowflake que ejecutan código SQL automáticamente según un schedule definido. Piensa en "cron jobs" pero nativos en la plataforma, sin necesidad de herramientas externas como Airflow o dbt Cloud.

## 💼 Caso de Uso

**Proyecto**: Smart Desk - Análisis de Ventas de Mobiliario Ergonómico

**Problema inicial**:
- Dashboard de métricas desactualizado constantemente
- Actualización manual cada hora (prone to human error)
- Stakeholders solicitando datos en tiempo real
- 45 minutos/día de trabajo manual repetitivo

**Solución implementada**:
- 1 Task con CRON scheduling
- INSERT OVERWRITE para refresh automático
- Monitoreo con TASK_HISTORY()
- **Tiempo de implementación**: 10 minutos

## 📊 Resultados

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Tiempo manual | 45 min/día | 0 min/día | **100%** |
| Frecuencia de actualización | On-demand | Cada 15 min | **Automático** |
| Errores humanos | 2-3/semana | 0 | **100%** |
| Satisfacción stakeholders | Baseline | +87% | **Medido por reducción de Slacks** |
| ROI | - | 15h/mes ahorradas | **10 min inversión** |

## 🔧 Requisitos

### Software
- Snowflake account (trial o producción)
- Acceso a un Warehouse con permisos de ejecución
- Permisos para crear: SCHEMA, TABLE, TASK

### Conocimientos
- SQL nivel intermedio
- Conocimientos básicos de agregaciones (SUM, AVG, GROUP BY)
- Opcional: Entendimiento de CRON expressions

### Datos
El proyecto incluye dos opciones:
1. **Dataset incluido**: CSV de Smart Desk (159 registros, 10KB)
2. **Tu propio dataset**: Adaptable a cualquier tabla de ventas

## ⚡ Instalación Rápida

### Opción 1: Ejecución Directa (5 minutos)

```sql
-- 1. Configurar contexto
USE DATABASE SANDBOX;
USE WAREHOUSE COMPUTE_WH;  -- Ajusta a tu warehouse

-- 2. Ejecutar script completo
-- Ver: scripts/snowflake_task_automation.sql
```

### Opción 2: Paso a Paso (10 minutos)

Sigue la guía detallada en [`docs/TUTORIAL.md`](docs/TUTORIAL.md)

## 📁 Estructura del Proyecto

```
snowflake-tasks-automation/
│
├── README.md                          # Este archivo
├── LICENSE                            # Licencia MIT
│
├── scripts/
│   ├── snowflake_task_automation.sql  # Script principal (6 pasos)
│   └── helper_queries.sql             # Queries auxiliares de análisis
│
├── data/
│   └── smart_desk_sales_sample.csv    # Dataset de ejemplo
│
├── docs/
│   ├── TUTORIAL.md                    # Tutorial paso a paso
│   ├── METHODOLOGY.md                 # Metodología técnica detallada
│   └── FAQ.md                         # Preguntas frecuentes
│
├── images/
│   ├── architecture_diagram.png       # Diagrama de arquitectura
│   └── task_history_screenshot.png    # Ejemplo de TASK_HISTORY()
│
└── examples/
    ├── cron_expressions.md            # Guía de CRON schedules
    └── use_cases.md                   # Otros casos de uso
```

## 🎯 Metodología Técnica

### Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Plataforma** | Snowflake | Data warehouse + automatización |
| **Scheduling** | CRON expressions | Control preciso de ejecución |
| **Refresh Strategy** | INSERT OVERWRITE | Evitar duplicados en tabla target |
| **Monitoring** | TASK_HISTORY() | Observability y troubleshooting |
| **Resource Management** | SUSPEND/RESUME | Optimización de créditos |

### Arquitectura

```
┌─────────────────┐
│  SMART_DESK     │
│  .SALES         │  ← Source (159 registros)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  TASK           │
│  (CRON)         │  ← Ejecuta cada 15 min
│  INSERT         │
│  OVERWRITE      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AUTOMATION     │
│  .SHIPPING_     │  ← Target (métricas agregadas)
│  METRICS        │
└─────────────────┘
```

### Query Principal

```sql
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

## ⚠️ Lecciones Aprendidas

### 🔴 Crítico: Gestión de Créditos

**Problema**: Los Tasks en estado `RESUMED` consumen créditos del warehouse asignado, **incluso cuando no están ejecutándose**.

**Solución**: 
```sql
-- Siempre suspender después de validar
ALTER TASK refresh_metrics_task SUSPEND;
ALTER WAREHOUSE COMPUTE_WH SUSPEND;
```

**Impacto real**: Un Task olvidado en estado RESUMED puede consumir créditos innecesarios hasta que se detecte.

### 💡 Best Practices

1. **Validar query antes de crear el Task**
   - Ejecuta el SELECT manualmente primero
   - Verifica tiempos de ejecución
   - Asegura que los resultados son correctos

2. **Empezar con schedule conservador**
   - No uses "cada minuto" en producción sin justificación
   - Ajusta frecuencia según necesidad real del negocio

3. **Monitoreo desde el día 1**
   - Revisa TASK_HISTORY() regularmente
   - Configura alertas para fallos (opcional: SYSTEM$SEND_EMAIL)

4. **Documentar el propósito del Task**
   - Usa COMMENT en la creación
   - Incluye owner y fecha en el nombre

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Ideas para contribuir

- [ ] Más ejemplos de CRON expressions
- [ ] Casos de uso adicionales (CDC con Streams, alertas, etc.)
- [ ] Traducción a otros idiomas
- [ ] Scripts de testing automatizado
- [ ] Integración con dbt

## 👨‍🏫 Autor

**Juan Fernando Sánchez Martínez**

- 🎓 Profesor de Bases de Datos SQL - Máster Data Science UCM
- 💼 Partner educativo: Ntic Master
- 🔗 LinkedIn: [linkedin.com/in/juanfersanchez](https://www.linkedin.com/in/juanfersanchez/)
- 📧 Email: [tu-email@ucm.es]

### Contexto Académico

Este proyecto forma parte del **Máster en Data Science, Big Data & Business Analytics** de la **Universidad Complutense de Madrid (UCM)**, desarrollado en colaboración con **Ntic Master**.

Los alumnos trabajan con el dataset Smart Desk como parte de la **Tarea Final** del módulo de Bases de Datos SQL, implementando análisis desde consultas básicas hasta automatización avanzada.

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🙏 Agradecimientos

- **Universidad Complutense de Madrid** - Por el framework académico
- **Ntic Master** - Partner educativo del programa
- **Snowflake Academia** - Por los recursos de certificación
- **Alumnos del Máster UCM** - Por feedback continuo y casos de uso reales

## 📚 Recursos Adicionales

### Documentación Oficial
- [Snowflake Tasks Documentation](https://docs.snowflake.com/en/user-guide/tasks-intro)
- [CRON Expression Reference](https://docs.snowflake.com/en/sql-reference/sql/create-task#schedule)
- [TASK_HISTORY Function](https://docs.snowflake.com/en/sql-reference/functions/task_history)

### Tutoriales Relacionados
- [dbt + Snowflake Tasks](https://docs.getdbt.com/docs/deploy/snowflake-tasks)
- [Snowflake Best Practices: Cost Management](https://www.snowflake.com/blog/best-practices-cost-management/)

---

⭐ **Si este repositorio te resultó útil, considera darle una estrella** ⭐

💬 **¿Preguntas o sugerencias?** Abre un [Issue](../../issues) o contáctame en LinkedIn

🚀 **¿Quieres ver más contenido como este?** Sígueme en [LinkedIn](https://www.linkedin.com/in/juanfersanchez/)
