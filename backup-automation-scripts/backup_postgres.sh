#!/bin/bash
# Backup Postgres Script
# Realiza backups de bases de datos PostgreSQL

# CONFIGURACION - MODIFICAR SEGUN AMBIENTE
BACKUP_DIR="/path/to/backup"
RETENTION_DAYS=30
EMAIL_TO="admin@domain.com"

# Funciones de utilidad
log() {
    logger -t "$SCRIPT_NAME" "$1"
}

send_notification() {
    echo "$1" | mail -s "Backup Notification" "$EMAIL_TO"
}

cleanup() {
    log "Limpiando recursos..."
}

# Manejo de errores
set -e
trap cleanup EXIT

# Verificar dependencias
if ! command -v pg_dump &> /dev/null; then
    log "Error: pg_dump no está instalado."
    exit 1
fi

# Backup de bases de datos
databases=$(psql -U postgres -d postgres -c '\l' | awk '{print $1}' | grep -v '^$' | grep -v 'template')
for db in $databases; do
    pg_dump "$db" | gzip > "$BACKUP_DIR/$db-$(date +%Y%m%d).sql.gz"
    log "Backup de la base de datos $db realizado."
done

# Enviar notificación
send_notification "Backups de bases de datos completados."
