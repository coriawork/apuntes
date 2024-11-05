#!/bin/bash
to_remove=()

# Listar todos los directorios en la carpeta actual
for dir in $(ls -d */); do
    newest_file=""
    newest_date=0
    declare -A files_with_dates
    # Recorro todos los archivos de cada directorio
    for arch in $(ls "$dir"); do
        # Si el archivo es un excalidraw
        if [[ $(echo "$arch" | cut -d. -f2) == 'excalidraw' ]]; then
            # Si el archivo tiene una fecha en el nombre
            if [[ $(echo "$arch" | grep -oP '\(\d{1,2}-\d{1,2}-\d{2}\)') ]]; then
                # Extraer la fecha
                fecha=$(echo "$arch" | grep -oP '\(\d{1,2}-\d{1,2}-\d{2}\)' | tr -d '()')
                # Convertir la fecha a un formato comparable (yyyymmdd)
                fecha_comparable=$(date -d "$fecha" +%Y%m%d)
                # Guardar el archivo y su fecha en un array asociativo
                files_with_dates["$dir$arch"]=$fecha_comparable
                # Comparar fechas y seleccionar el archivo más reciente
                if [[ $fecha_comparable -gt $newest_date ]]; then
                    newest_date=$fecha_comparable
                    newest_file="$dir$arch"
                fi
            fi
        fi
    done
    # Agregar todos los archivos excepto el más reciente al arreglo
    for file in "${!files_with_dates[@]}"; do
        if [[ "$file" != "$newest_file" ]]; then
            to_remove+=("$file")
        fi
    done
done
echo a eliminar -----
for i in ${to_remove[@]}; do
	echo $i
done

#echo "${to_remove[@]}"
