#!/bin/bash

# ======= Configuración del backup =======

# Servidores y rutas de origen y destino
ORIGEN_SERVIDOR="usuario@origen_servidor"
ORIGEN_RUTA="/ruta/origen"
DESTINO_SERVIDOR_1="usuario@destino_servidor1"
DESTINO_RUTA_1="/ruta/destino1"
DESTINO_SERVIDOR_2="usuario@destino_servidor2"  # Destino redundante opcional
DESTINO_RUTA_2="/ruta/destino2"

# Opciones de backup
NUMERO_COPIAS=5                   # Número de copias de backup a mantener (retención)
LIMIT_BANDWIDTH=1000              # Límite de ancho de banda en KB/s para rsync
EXCLUDE_PATTERNS=("*.tmp" "*.cache" "node_modules" "tmp/")  # Patrones a excluir
SSH_KEY="/ruta/a/llave_privada"   # Ruta a la llave privada SSH

# Directorios y archivos de log
LOG_DIR="/var/log/backup"
LOG_FILE="$LOG_DIR/backup_$(date +'%Y%m%d').log"
LOCK_FILE="/tmp/backup_script.lock"

# ======= Funciones auxiliares =======

# Verificar conectividad
verificar_conectividad() {
    if ! ping -c 1 -W 1 "$1" &> /dev/null; then
        echo "Error: No se puede conectar al servidor $1." | tee -a "$LOG_FILE"
        return 1
    fi
    return 0
}

# Crear un archivo de bloqueo para evitar ejecuciones simultáneas
crear_bloqueo() {
    if [[ -e "$LOCK_FILE" ]]; then
        echo "Script de backup ya en ejecución." | tee -a "$LOG_FILE"
        exit 1
    fi
    touch "$LOCK_FILE"
}

# Eliminar el archivo de bloqueo
eliminar_bloqueo() {
    rm -f "$LOCK_FILE"
}

# Rotación de backups antiguos
rotacion_backups() {
    local destino=$1
    ssh -i "$SSH_KEY" "$destino" "ls -1t ${DESTINO_RUTA_1} | tail -n +$((NUMERO_COPIAS + 1)) | xargs -I {} rm -rf ${DESTINO_RUTA_1}/{}"
}

# Enviar alerta en caso de fallo
enviar_alerta() {
    echo "Fallo en el backup: $1" | mail -s "Alerta de fallo en backup" tu_email@example.com
}

# ======= Inicio del proceso de backup =======

# Crear el directorio de log si no existe
mkdir -p "$LOG_DIR"

# Verificar conectividad con el servidor origen y destino
verificar_conectividad "$ORIGEN_SERVIDOR" || exit 1
verificar_conectividad "$DESTINO_SERVIDOR_1" || exit 1
[[ -n "$DESTINO_SERVIDOR_2" ]] && verificar_conectividad "$DESTINO_SERVIDOR_2" || exit 1

# Crear el archivo de bloqueo
crear_bloqueo
trap eliminar_bloqueo EXIT  # Asegurar que se elimine el bloqueo al salir

# Ejecutar el backup
for DESTINO in "$DESTINO_SERVIDOR_1" "$DESTINO_SERVIDOR_2"; do
    if [[ -n "$DESTINO" ]]; then
        echo "Iniciando backup a $DESTINO..." | tee -a "$LOG_FILE"
        rsync -avz \
            --delete \
            --bwlimit="$LIMIT_BANDWIDTH" \
            --exclude="${EXCLUDE_PATTERNS[@]}" \
            --checksum \
            --timeout=600 \
            -e "ssh -i $SSH_KEY" \
            "$ORIGEN_SERVIDOR:$ORIGEN_RUTA" "$DESTINO:$DESTINO_RUTA" >> "$LOG_FILE" 2>&1
        
        if [[ $? -ne 0 ]]; then
            echo "Error: Fallo en el backup a $DESTINO." | tee -a "$LOG_FILE"
            enviar_alerta "Fallo en el backup a $DESTINO"
        else
            echo "Backup a $DESTINO completado con éxito." | tee -a "$LOG_FILE"
            rotacion_backups "$DESTINO"
        fi
    fi
done

# ======= Fin del proceso de backup =======

echo "Backup finalizado el $(date)" | tee -a "$LOG_FILE"

