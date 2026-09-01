# 1. Limpieza de Entorno y RAM Inicial ----
if (!is.null(dev.list())) dev.off()
closeAllConnections()
rm(list = ls())
gc(full = TRUE)
cat("\014")

# 2. Configuración y Librerías ----
library(here)
library(ggplot2)
library(dplyr)
library(purrr)
library(MASS)    # Para prueba de Box-Cox
library(lmtest)  # Para test de Breusch-Pagan

# 3. Definición de Función Reutilizable ----
estabilizar_varianza <- function(archivo_rds) {
  
  # Cargar la serie limpia desde 01_data/02_processed
  df <- readRDS(here("01_data", "processed", archivo_rds))
  ticker <- gsub("_clean\\.rds$", "", archivo_rds)
  
  # Directorio de salida para gráficas de la Etapa 2
  carpeta_figuras <- here("03_outputs", "figures", "02_estabilizacion_varianza")
  carpeta_tablas  <- here("03_outputs", "tables", "01_pruebas_iniciales")
  
  # A. Modelo Auxiliar respecto al Tiempo para Pruebas
  # Y_t = beta_0 + beta_1 * t + epsilon_t
  modelo_nivel <- lm(Close ~ Time_Index, data = df)
  
  # B. Test de Breusch-Pagan en Niveles
  bp_nivel <- bptest(Close ~ Time_Index, data = df)
  
  # C. Exportar Gráfica de Verosimilitud de Box-Cox
  png(
    filename = file.path(carpeta_figuras, paste0(ticker, "_boxcox_lambda.png")),
    width = 2700, height = 1800, res = 300
  )
  boxcox_result <- boxcox(Close ~ Time_Index, data = df, plotit = TRUE)
  title(main = paste("Perfil Box-Cox (95% CI) -", ticker))
  dev.off()
  
  # Extraer el lambda exacto que maximiza la verosimilitud
  lambda_optimo <- boxcox_result$x[which.max(boxcox_result$y)]
  
  # D. Transformación Logarítmica ln(Yt)
  df$Log_Close <- log(df$Close)
  modelo_log <- lm(Log_Close ~ Time_Index, data = df)
  
  # E. Test de Breusch-Pagan en Logaritmos
  bp_log <- bptest(modelo_log)

  # F. Estructurar Resultante Numérico de Pruebas
  resumen_tests <- data.frame(
    Ticker = ticker,
    BP_PValue_Nivel = round(bp_nivel$p.value, 5),
    Hetero_Nivel = ifelse(bp_nivel$p.value < 0.05, "Sí", "No"),
    Lambda_BoxCox = round(lambda_optimo, 4),
    BP_PValue_Log = round(bp_log$p.value, 5),
    Hetero_Log = ifelse(bp_log$p.value < 0.05, "Sí", "No")
  )
  
  # Guardar resultado individual de tabla
  saveRDS(resumen_tests, file.path(carpeta_tablas, paste0(ticker, "_heterocedasticidad.rds")))
  
  # G. Guardar DataFrame con nueva columna Log_Close
  saveRDS(df, here("01_data", "processed", paste0(ticker, "_log.rds")))
  
  # H. Gráfica de la Serie Transformada ln(Yt)
  p_log <- ggplot(df, aes(x = Date, y = Log_Close)) +
    geom_area(fill = "#2b4c7e", color = "#1a324b", linewidth = 0.85, alpha = 0.45) +
    scale_x_date() +
    labs(
      title = paste("Serie en Logaritmos ln(Yt) de", ticker),
      subtitle = paste("Lambda óptimo Box-Cox estimado:", round(lambda_optimo, 4)),
      x = "Tiempo",
      y = "ln(Precio de Cierre)"
    ) +
    theme_minimal() +
    theme(
      aspect.ratio = 0.65,
      plot.title = element_text(hjust = 0.5, size = 14.5, face = "bold", margin = margin(b = 5)),
      plot.subtitle = element_text(hjust = 0.5, size = 10, face = "italic", margin = margin(b = 10)),
      axis.title.x = element_text(margin = margin(t = 15)),
      axis.title.y = element_text(margin = margin(r = 15)),
      axis.text.x = element_text(hjust = 1, angle = 45),
      axis.text.y = element_text(hjust = 1, angle = 0),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "darkgray", linetype = "dashed", linewidth = 0.23),
      panel.grid.minor = element_blank()
    )
  
  ggsave(
    filename = file.path(carpeta_figuras, paste0(ticker, "_log_transformed.png")),
    plot = p_log,
    width = 9,
    height = 6,
    dpi = 300
  )
  
  # Liberar memoria local de la iteración
  rm(df, modelo_nivel, modelo_log, boxcox_result, p_log, resumen_tests)
}

# 4. Ejecución Masiva en Lote ----
archivos_clean <- list.files(here("01_data", "processed"), pattern = "_clean\\.rds$")
walk(archivos_clean, estabilizar_varianza)

# Consolidar todas las tablas de heterocedasticidad en una sola tabla global
tablas_hetero <- list.files(
  here("03_outputs", "tables", "01_pruebas_iniciales"), 
  pattern = "_heterocedasticidad\\.rds$", 
  full.names = TRUE
)

tabla_global_hetero <- map_dfr(tablas_hetero, readRDS)

# Exportar tabla consolidada
saveRDS(
  tabla_global_hetero, 
  here("03_outputs", "tables", "01_pruebas_iniciales", "resumen_heterocedasticidad_global.rds")
)
write.csv(
  tabla_global_hetero, 
  here("03_outputs", "tables", "01_pruebas_iniciales", "resumen_heterocedasticidad_global.csv"), 
  row.names = FALSE
)

# 5. Limpieza Final del Entorno y RAM ----
rm(archivos_clean, tablas_hetero, tabla_global_hetero, estabilizar_varianza)
gc(full = TRUE)