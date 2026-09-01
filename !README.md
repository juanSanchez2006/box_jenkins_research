# Automatización de Metodología Box-Jenkins para Series de Tiempo Financieras

**Autor:** Juan Manuel Sánchez Jiménez  
**Institución:** Universidad EAFIT - Pregrado en Finanzas  

## Descripción del Proyecto

Este repositorio contiene un pipeline cuantitativo automatizado desarrollado en R para el modelado econométrico de series de tiempo financieras (precios de cierre de acciones). El proyecto implementa de manera secuencial y rigurosa la metodología empírica de **Box-Jenkins** para la estimación de modelos ARIMA(p,d,q).

El flujo de trabajo está diseñado para procesar múltiples activos de forma masiva (en lote), optimizando el consumo de memoria RAM y garantizando la trazabilidad metodológica desde la limpieza de datos hasta la generación de diagnósticos y pronósticos para la toma de decisiones.

## Características Técnicas Principales

*   **Procesamiento Vectorizado y Eficiente:** Uso de programación funcional con `purrr::walk()` para iterar sobre múltiples bases de datos sin saturar el entorno global de R.
*   **Gestión Estricta de Memoria:** Recolección de basura activa (`gc()`) y eliminación de objetos temporales tras cada ciclo de procesamiento.
*   **Almacenamiento Binario Optimizado:** Transición de datos crudos (`.csv`) a formatos comprimidos nativos (`.rds`) para preservar esquemas de datos, fechas y metadatos entre scripts.
*   **Visualización de Alta Calidad (300 DPI):** Generación automática de gráficos estandarizados con `ggplot2` y `Base R`, exportados en subcarpetas específicas según la etapa econométrica.
*   **Reporting Integrado:** Consolidación de estadísticos de prueba (Breusch-Pagan, ADF, KPSS, Ljung-Box) en matrices globales listas para su invocación en documentos finales de LaTeX o Quarto.

## Estructura del Repositorio

El proyecto sigue una arquitectura de directorios orientada a la reproducibilidad científica:

```text
📦 BOX_JENKINS_RESEARCH
 ┣ 📂 01_data
 ┃ ┣ 📂 raw                # Series de tiempo descargadas en formato .csv
 ┃ ┗ 📂 processed          # Archivos .rds limpios y transformados por el pipeline
 ┣ 📂 02_scripts
 ┃ ┣ 📜 01_carga_y_limpieza.R          # Parseo de fechas, ordenamiento y exportación
 ┃ ┣ 📜 02_transformacion_varianza.R   # Test Breusch-Pagan, Box-Cox (Lambda) y logaritmos
 ┃ ┣ 📜 03_estacionariedad_media.R     # Correlogramas y pruebas de raíz unitaria
 ┃ ┣ 📜 04_identificacion_modelos.R    # Estimación de parámetros AR y MA
 ┃ ┗ 📜 05_diagnosticos_pronosticos.R  # Análisis de residuales y proyecciones
 ┣ 📂 03_outputs
 ┃ ┣ 📂 figures            # Gráficas guardadas automáticamente a 300 DPI
 ┃ ┃ ┣ 📂 01_series_originales
 ┃ ┃ ┣ 📂 02_estabilizacion_varianza
 ┃ ┃ ┣ 📂 03_estacionariedad_media
 ┃ ┃ ┗ 📂 ...
 ┃ ┗ 📂 tables             # Tablas consolidadas de resultados estadísticos (.rds y .csv)
 ┗ 📂 04_report            # Entregables técnicos, documentos maestros y anexos