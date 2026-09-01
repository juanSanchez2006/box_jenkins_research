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

# 3. Definición de Función Reutilizable ----
procesar_serie <- function(nombre_archivo) {
  
  # Cargar datos desde la ruta con here()
  ruta <- here("01_data", "raw", nombre_archivo)
  df <- read.csv(ruta)
  
  # Seleccionar columnas y ajustar formatos
  df <- df[, c("Date", "Price")]
  colnames(df) <- c("Date", "Close")
  df$Date <- as.Date(df$Date, format = "%m/%d/%Y")
  df <- df[order(df$Date, decreasing = FALSE), ]
  
  # Agregar índice de tiempo
  df$Time_Index <- 1:nrow(df)
  
  # Extraer ticker (nombre del activo)
  ticker <- gsub(" .*$", "", nombre_archivo)
  
  # Guardar objeto procesado en .rds (formato comprimido y liviano)
  saveRDS(df, here("01_data", "processed", paste0(ticker, "_clean.rds")))
  
  # Generar y guardar gráfica
  p <- ggplot(df, aes(x = Date, y = Close)) +
    geom_area(fill = "#2b4c7e", color = "#1a324b", linewidth = 0.85, alpha = 0.45) +
    scale_x_date() +
    labs(
      title = paste("Serie de Tiempo de", ticker),
      x = "Tiempo",
      y = "Precio de Cierre (Yt)"
    ) +
    theme_minimal() +
    theme(
      aspect.ratio = 0.65,
      plot.title = element_text(hjust = 0.5, size = 14.5, face = "bold", margin = margin(b = 10)),
      axis.title.x = element_text(margin = margin(t = 15)),
      axis.title.y = element_text(margin = margin(r = 15)),
      axis.text.x = element_text(hjust = 1, angle = 45),
      axis.text.y = element_text(hjust = 1, angle = 0),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "darkgray", linetype = "dashed", linewidth = 0.23),
      panel.grid.minor = element_blank()
    )
  
  # Exportar gráfica a la carpeta de salidas
  ggsave(
    filename = here("03_outputs", "figures", "01_series_originales", paste0(ticker, "_original.png")), 
    plot = p,
    width = 9,
    height = 6,
    dpi = 300
  )

  # Liberar variable de la gráfica
  rm(p, df)
}

# 4. Ejecución Masiva Eficiente ----
archivos_csv <- list.files(here("01_data", "raw"), pattern = "\\.csv$")

# walk() ejecuta la función archivo por archivo sin guardar una lista pesada en RAM
walk(archivos_csv, procesar_serie)

# 5. Limpieza Final de Objetos Temporales y Recolección de Basura ----
rm(archivos_csv, procesar_serie)
gc(full = TRUE)