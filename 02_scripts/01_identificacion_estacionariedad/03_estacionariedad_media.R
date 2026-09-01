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
library(urca)    # Pruebas ADF y KPSS
library(tseries) # Funciones auxiliares
library(lmtest)  # Test Breusch-Pagan

# 3. Definición de Función Reutilizable ----
estacionarizar_media <- function(archivo_rds) {
  
  # Cargar la serie logarítmica (creada en el script 2)
  df <- readRDS(here("01_data", "processed", archivo_rds))
  
  # Corrección defensiva: Garantizar estructura de Data Frame
  df <- as.data.frame(df)
  ticker <- gsub("_log\\.rds$", "", archivo_rds)
  
  # Directorios de salida
  carpeta_figuras <- here("03_outputs", "figures", "03_estacionariedad_media")
  carpeta_tablas  <- here("03_outputs", "tables", "01_pruebas_iniciales")
  
  # A. Exportar Correlograma Parcial (PACF) en Niveles Logarítmicos
  png(
    filename = file.path(carpeta_figuras, paste0(ticker, "_pacf_niveles.png")),
    width = 2400, height = 1800, res = 300
  )
  pacf(df$Log_Close, main = paste("PACF - ln(Yt) -", ticker))
  dev.off()
  
  # B. Pruebas de Raíz Unitaria (En Niveles)
  adf_nivel  <- ur.df(df$Log_Close, type = "trend", selectlags = "AIC")
  kpss_nivel <- ur.kpss(df$Log_Close, type = "tau")
  
  # C. Aplicación de la Primera Diferencia
  df$d1_Log_Close <- c(NA, diff(df$Log_Close))
  
  # D. Pruebas de Raíz Unitaria (En Primera Diferencia)
  # Se omite el NA generado en la primera posición por la diferenciación
  adf_d1  <- ur.df(na.omit(df$d1_Log_Close), type = "drift", selectlags = "AIC")
  kpss_d1 <- ur.kpss(na.omit(df$d1_Log_Close), type = "mu")
  
  # E. Test Breusch-Pagan sobre la serie diferenciada (Fórmula explícita para evitar bug de scoping)
  bp_d1 <- bptest(d1_Log_Close ~ Time_Index, data = df)
  
  # F. Estructuración Numérica y Booleana de Pruebas
  # Nota: Los objetos S4 de 'urca' utilizan "@" en lugar de "$" para acceder a sus atributos.
  resumen_estacionariedad <- data.frame(
    Ticker = ticker,
    
    # Pruebas en Niveles Logarítmicos
    ADF_Nivel_Estacionaria = ifelse(adf_nivel@teststat[1, "tau3"] < adf_nivel@cval["tau3", "5pct"], "Sí", "No (Raíz Unitaria)"),
    ADF_Nivel_Tendencia_Det = ifelse(adf_nivel@teststat[1, "phi3"] > adf_nivel@cval["phi3", "5pct"], "Sí", "No (Estocástica)"),
    KPSS_Nivel_Estacionaria = ifelse(kpss_nivel@teststat[1] < kpss_nivel@cval[1, "5pct"], "Sí", "No (Raíz Unitaria)"),
    
    # Pruebas en Primera Diferencia
    ADF_d1_Estacionaria = ifelse(adf_d1@teststat[1, "tau2"] < adf_d1@cval["tau2", "5pct"], "Sí", "No (Raíz Unitaria)"),
    ADF_d1_Deriva = ifelse(adf_d1@teststat[1, "phi1"] > adf_d1@cval["phi1", "5pct"], "Sí", "No"),
    KPSS_d1_Estacionaria = ifelse(kpss_d1@teststat[1] < kpss_d1@cval[1, "5pct"], "Sí", "No (Raíz Unitaria)"),
    
    # Varianza en serie diferenciada
    BP_d1_Heterocedasticidad = ifelse(bp_d1$p.value < 0.05, "Sí", "No (Homocedástica)")
  )
  
  # Guardar resultados individuales en tablas
  saveRDS(resumen_estacionariedad, file.path(carpeta_tablas, paste0(ticker, "_estacionariedad.rds"))) 
  
  # G. Guardar DataFrame con la nueva columna d1_Log_Close
  saveRDS(df, here("01_data", "processed", paste0(ticker, "_d1.rds")))
  
  # H. Gráfica de la Serie Diferenciada (Retornos Logarítmicos)
  p_diff <- ggplot(df, aes(x = Date, y = d1_Log_Close)) +
    geom_line(color = "#1a324b", linewidth = 0.5) +
    geom_hline(yintercept = 0, color = "#2b4c7e", linetype = "dashed", linewidth = 0.6) +
    scale_x_date() + # Eje X dinámico adaptativo
    labs(
      title = paste("Primera Diferencia de ln(Yt) -", ticker),
      subtitle = "Comportamiento alrededor de media cero",
      x = "Tiempo",
      y = expression(paste(Delta, " ln(Yt)")) # Sintaxis matemática para etiquetar el eje Y con Delta
    ) +
    theme_minimal() +
    theme(
      aspect.ratio = 0.65,
      plot.title = element_text(hjust = 0.5, size = 13, face = "bold", margin = margin(b = 5)),
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
    filename = file.path(carpeta_figuras, paste0(ticker, "_d1_log_transformed.png")),
    plot = p_diff,
    width = 9,
    height = 6,
    dpi = 300,
  )
  
  # Liberar memoria local
  rm(df, adf_nivel, kpss_nivel, adf_d1, kpss_d1, bp_d1, p_diff, resumen_estacionariedad)
}

# 4. Ejecución Masiva en Lote ----
# Leemos exclusivamente los archivos procesados en la Etapa 2 (_log.rds)
archivos_log <- list.files(here("01_data", "processed"), pattern = "_log\\.rds$")
walk(archivos_log, estacionarizar_media)

# Consolidar tablas globales de estacionariedad
tablas_est <- list.files(
  here("03_outputs", "tables", "01_pruebas_iniciales"), 
  pattern = "_estacionariedad\\.rds$", 
  full.names = TRUE
)

tabla_global_est <- map_dfr(tablas_est, readRDS)

# Exportar el gran resumen de estacionariedad
saveRDS(
  tabla_global_est, 
  here("03_outputs", "tables", "01_pruebas_iniciales", "resumen_estacionariedad_global.rds")
)
write.csv(
  tabla_global_est, 
  here("03_outputs", "tables", "01_pruebas_iniciales", "resumen_estacionariedad_global.csv"), 
  row.names = FALSE
)

# 5. Limpieza Final del Entorno y RAM ----
rm(archivos_log, tablas_est, tabla_global_est, estacionarizar_media)
gc(full = TRUE)
