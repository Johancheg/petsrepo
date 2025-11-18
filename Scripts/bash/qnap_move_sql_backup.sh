#!/bin/bash

SOURCE="/share/CACHEDEV1_DATA/sql_backup/sqlserver/"
TARGET="/share/CACHEDEV2_DATA/arch_sql_backup/"
LOG="/share/CACHEDEV1_DATA/logs/sql_move.log"

echo "$(date): Начало перемещения SQL backup файлов" >> "$LOG"

if [ ! -d "$SOURCE" ]; then
    echo "$(date): ОШИБКА - Источник не найден: $SOURCE" >> "$LOG"
    exit 1
fi

mkdir -p "$TARGET"
mkdir -p "$(dirname "$LOG")"

find "$SOURCE" -type f -mtime +2 | while read file; do
    rel_path="${file#$SOURCE}"
    target_file="$TARGET$rel_path"
    target_dir=$(dirname "$target_file")
    
    mkdir -p "$target_dir"
    
    if [ ! -f "$target_file" ]; then
        mv "$file" "$target_file"
        echo "$(date): Перемещен: $rel_path" >> "$LOG"
    fi
done

echo "$(date): Перемещение завершено" >> "$LOG"
