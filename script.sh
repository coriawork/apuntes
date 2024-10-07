#!/bin/bash
to_remove=()
for dir in $(ls); do
	min_dia=0
	min_mes=0
	for arch in $(ls $dir); do
		if [[ $(echo $arch | cut -d. -f2) == 'excalidraw' ]]; then	
			if [[ $(echo $arch | cut -d'(' -f1) != $arch ]]; then
				to_remove+=($dir/$arch)
				fecha=$(echo $arch | cut -d'(' -f2 | cut -d')' -f1 )
			fi
		fi
	done
done

echo ${to_remove[@]}
