#!/bin/bash
# Security Audit Script
# Verifica configuraciones de seguridad

# CONFIGURACION - MODIFICAR SEGUN AMBIENTE
LOG_FILE="/var/log/security_audit.log"

# Funciones de utilidad
log() {
    logger -t "$SCRIPT_NAME" "$1"
}

# Verificación de permisos de archivos críticos
critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")
for file in "${critical_files[@]}"; do
    if [ ! -r "$file" ] || [ ! -w "$file" ]; then
        log "Alerta: Permisos incorrectos para $file."
    fi
done

log "Auditoría de seguridad completada."
