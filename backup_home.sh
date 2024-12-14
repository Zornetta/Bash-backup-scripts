#!/bin/bash

# Obtener la fecha actual en formato YYYY-MM-DD
FECHA_ACTUAL=$(date +%Y-%m-%d)

# Nombre del archivo ZIP
ZIP_FILE="bkp-home-$FECHA_ACTUAL.zip"

# Directorios y archivos a incluir
INCLUDE=(
  "$HOME/.config"
  "$HOME/Documents"
  "$HOME/Dictures"
  "$HOME/.bashrc.bak"
  "$HOME/.zshrc.bak"
)

# Archivo temporal para errores
SKIPPED_FILES=$(mktemp)
LOG_FILE="backup-home.log"

# Redirigir salida estándar y de error a un archivo de log
exec > >(tee -a "$LOG_FILE") 2>&1

# Calcular el total de archivos para la barra de progreso
TOTAL_ARCHIVOS=$(find "${INCLUDE[@]}" -type f 2>/dev/null | wc -l)

# Crear el archivo ZIP con barra de progreso
if [ $TOTAL_ARCHIVOS -gt 0 ]; then
    echo "Creando backup con $TOTAL_ARCHIVOS archivos..."
    zip -r -v "$ZIP_FILE" "${INCLUDE[@]}" 2> "$SKIPPED_FILES" | pv -l -s $TOTAL_ARCHIVOS > /dev/null

    # Verificar si el ZIP se creó correctamente
    if [ $? -eq 0 ]; then
        echo "Backup creado exitosamente: $ZIP_FILE"
    else
        echo "Error al crear el backup."
    fi

    # Verificar si hubo archivos no legibles
    if [ -s "$SKIPPED_FILES" ]; then
        echo "Se omitieron los siguientes archivos por no ser legibles:"
        cat "$SKIPPED_FILES"
    fi
else
    echo "No se encontraron archivos para incluir en el backup."
fi

# Subir el archivo a OneDrive
rclone copy "$ZIP_FILE" onedrive:bkpsLinux/ -P

# Limpiar archivo temporal
rm -f "$SKIPPED_FILES"

