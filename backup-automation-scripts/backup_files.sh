#!/bin/bash
# Backup Files Script
# Realiza backup incremental de directorios

# CONFIGURACION - MODIFICAR SEGUN AMBIENTE
SOURCE_DIR="/path/to/source"
BACKUP_DIR="/path/to/backup"
EXCLUDES="*.tmp"
RETENTION_DAYS=30

# Funciones de utilidad
log() {
    logger -t "$SCRIPT_NAME" "$1"
}

cleanup() {
    log "Limpiando recursos..."
}

# Manejo de errores
set -e
trap cleanup EXIT

# Crear backup
rsync -av --exclude="$EXCLUDES" "$SOURCE_DIR/" "$BACKUP_DIR/"
log "Backup de $SOURCE_DIR realizado en $BACKUP_DIR."
