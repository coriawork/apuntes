#!/bin/bash

# Definir el color (aproximación más cercana en códigos ANSI a #1a84fc)
BLUE='\033[38;2;26;132;252m'
ORANGE='\033[38;2;255;140;0m'  # Ajustado para ser más visible
RED='\033[38;2;255;0;0m'
RESET='\033[0m'
GREEN='\033[38;2;0;255;0m'

# Inicializar variables para opciones
SHOW_FILES=true

# Procesar parámetros
while getopts "d" opt; do
    case $opt in
        d)
            SHOW_FILES=false
            ;;
        \?)
            echo "Uso inválido: [-d] para no mostrar archivos"
            exit 1
            ;;
    esac
done

# Función para mostrar el loader
loader() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  Procesando archivos..." "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        echo -ne "\r"
        sleep $delay
    done
    echo -ne "\r\033[K"
}

# Función principal que procesa los archivos
process_files() {
    to_remove=()

    # Declarar array asociativo para agrupar archivos por nombre base
    declare -A groups

    # Listar todos los directorios en la carpeta actual
    for dir in $(ls -d */); do
        # Recorro todos los archivos de cada directorio
        for arch in $(ls "$dir"); do
            # Si el archivo es un excalidraw
            if [[ $(echo "$arch" | cut -d. -f2) == 'excalidraw' ]]; then
                # Si el archivo tiene una fecha en el nombre
                if [[ $(echo "$arch" | grep -oP '\(\d{1,2}-\d{1,2}-\d{2}\)') ]]; then
                    # Extraer el nombre base (antes del paréntesis)
                    base_name=$(echo "$arch" | sed 's/(.*)\..*$//')
                    # Extraer la fecha
                    fecha=$(echo "$arch" | grep -oP '\(\d{1,2}-\d{1,2}-\d{2}\)' | tr -d '()')
                    # Convertir la fecha a un formato comparable (yyyymmdd)
                    fecha_comparable=$(date -d "$fecha" +%Y%m%d)
                    # Agregar al grupo correspondiente
                    groups["$base_name"]+="$dir$arch:$fecha_comparable "
                fi
            fi
        done
    done

    # Procesar cada grupo de archivos con el mismo nombre base
    for base_name in "${!groups[@]}"; do
        newest_file=""
        newest_date=0
        
        # Procesar cada archivo en el grupo
        for file_info in ${groups["$base_name"]}; do
            file_path=${file_info%:*}
            file_date=${file_info#*:}
            
            if [[ $file_date -gt $newest_date ]]; then
                newest_date=$file_date
                newest_file=$file_path
            fi
        done
        
        # Agregar todos los archivos excepto el más reciente al arreglo to_remove
        for file_info in ${groups["$base_name"]}; do
            file_path=${file_info%:*}
            if [[ "$file_path" != "$newest_file" ]]; then
                to_remove+=("$file_path")
            fi
        done
    done

    # En lugar de usar una variable global, imprimir los resultados a un archivo temporal
    printf "%s\n" "${to_remove[@]}" > /tmp/files_to_remove.tmp
}

# Función para mostrar el loader sin afectar el proceso principal
show_loader() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "${BLUE} [%c]  Procesando archivos...${RESET}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        echo -ne "\r"
        sleep $delay
    done
    echo -ne "\r\033[K"
}

# Funcion para hacer un push con git
backup() {
    echo -ne "\n ${BLUE}Haciendo backup...${RESET}"
    git add .
    git commit -m "Backup"
    git push origin main
}

# Función para manejar la eliminación
handle_deletion() {

    # Leer los archivos del archivo temporal
    mapfile -t FILES_TO_REMOVE < /tmp/files_to_remove.tmp
    rm -f /tmp/files_to_remove.tmp  # Limpiar archivo temporal
    
    # Mostrar archivos a eliminar solo si SHOW_FILES es true
    if $SHOW_FILES; then
        echo -e "${BLUE}Archivos a eliminar -----${RESET}"
        for i in "${FILES_TO_REMOVE[@]}"; do
            echo -e "${RED}$i${RESET}"
        done
        echo -en "${ORANGE}¿Desea eliminar estos archivos? (s/n): ${RESET}"
        read confirm
    else
        echo -en "${ORANGE}¿Desea eliminar los archivos? (s/n): ${RESET}"
        read confirm
    fi
    # Preguntar al usuario
    if [[ $confirm == [sS] ]]; then
        backup
        echo -e "${BLUE}Eliminando archivos...${RESET}"
        for file in "${FILES_TO_REMOVE[@]}"; do
            if [ -f "$file" ]; then
                rm -f "$file" && echo -e "${BLUE}Eliminado: $file${RESET}" || echo -e "${BLUE}Error al eliminar: $file${RESET}"
            else
                echo -e "${BLUE}No se encontró el archivo: $file${RESET}"
            fi
        done
        echo -e "${GREEN}Proceso completado.${RESET}"
    else
        echo -e "${RED}Operación cancelada. No se eliminaron archivos.${RESET}"
    fi
}

# Ejecutar el procesamiento y mostrar el loader
process_files & 
pid=$!
show_loader $pid
wait $pid

# Manejar la eliminación
handle_deletion
