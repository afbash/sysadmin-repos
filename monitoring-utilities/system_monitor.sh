#!/bin/bash
# System Monitor Script
# Monitorea recursos del sistema

# CONFIGURACION - MODIFICAR SEGUN AMBIENTE
THRESHOLD_CPU=80
THRESHOLD_MEM=80
EMAIL_TO="admin@domain.com"

# Funciones de utilidad
log() {
    logger -t "$SCRIPT_NAME" "$1"
}

send_alert() {
    echo "$1" | mail -s "Alerta de Monitoreo" "$EMAIL_TO"
}

# Verificación de CPU
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
if (( $(echo "$cpu_usage > $THRESHOLD_CPU" | bc -l) )); then
    send_alert "Alerta: Uso de CPU alto: $cpu_usage%"
fi

# Verificación de memoria
mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
if (( $(echo "$mem_usage > $THRESHOLD_MEM" | bc -l) )); then
    send_alert "Alerta: Uso de Memoria alto: $mem_usage%"
fi

log "Monitoreo de recursos completado."
