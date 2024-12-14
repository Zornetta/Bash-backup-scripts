#!/bin/bash

# Verificar si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ser ejecutado como root."
    exit 1
fi

# Verificar si las herramientas necesarias están instaladas
command -v zip >/dev/null 2>&1 || { echo >&2 "El comando 'zip' no está instalado. Instalalo y vuelve a intentarlo."; exit 1; }
command -v pv >/dev/null 2>&1 || { echo >&2 "El comando 'pv' no está instalado. Instalalo y vuelve a intentarlo."; exit 1; }
command -v rclone >/dev/null 2>&1 || { echo >&2 "El comando 'rclone' no está instalado. Instalalo y vuelve a intentarlo."; exit 1; }

# Obtener la fecha actual en formato YYYY-MM-DD
FECHA_ACTUAL=$(date +%Y-%m-%d)

# Nombre del archivo ZIP
ZIP_FILE="bkp-etc-$FECHA_ACTUAL.zip"

# Directorios a incluir
INCLUDE=("/etc")

# Archivo temporal para errores
SKIPPED_FILES=$(mktemp)
LOG_FILE="backup-etc.log"

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

# Establecer la ruta del archivo de configuración de rclone del usuario ale
RCLONE_CONFIG_PATH="/home/ale/.config/rclone/rclone.conf"
export RCLONE_CONFIG="$RCLONE_CONFIG_PATH"

# Subir el archivo a OneDrive
rclone copy "$ZIP_FILE" onedrive:bkpsLinux/ -P

# Verificar si la subida fue exitosa
if [ $? -eq 0 ]; then
    echo "Backup subido exitosamente a OneDrive."
else
    echo "Error al subir el backup a OneDrive."
fi

# Limpiar archivos temporales
rm -f "$SKIPPED_FILES"

# Fin del script
echo "Proceso de backup completado."
