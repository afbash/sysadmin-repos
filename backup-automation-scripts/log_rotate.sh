#!/bin/bash
# Log Rotation Script
# Rota y comprime logs automáticamente

# CONFIGURACION - MODIFICAR SEGUN AMBIENTE
LOG_DIR="/var/log"
RETENTION_DAYS=30
COMPRESS=true
EMAIL_TO="admin@domain.com"
SMTP_SERVER="smtp.company.com"

# Funciones de utilidad
log() {
    logger -t "$SCRIPT_NAME" "$1"
}

send_notification() {
    echo "$1" | mail -s "Log Rotation Notification" "$EMAIL_TO"
}

cleanup() {
    # Limpiar recursos
    log "Limpiando recursos..."
}

# Manejo de errores
set -e
trap cleanup EXIT

# Verificar dependencias
if ! command -v logrotate &> /dev/null; then
    log "Error: logrotate no está instalado."
    exit 1
fi

# Rote y comprima logs
logrotate -f /etc/logrotate.conf

# Enviar notificación
send_notification "Logs rotados y comprimidos correctamente."
log "Logs rotados y comprimidos."
