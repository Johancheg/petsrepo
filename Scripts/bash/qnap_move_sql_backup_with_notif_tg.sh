#!/bin/bash

SOURCE="/share/CACHEDEV1_DATA/sql_backup/sqlserver/"
TARGET="/share/CACHEDEV2_DATA/arch_sql_backup/"
LOG="/share/CACHEDEV1_DATA/logs/sql_move.log"

# Telegram настройки
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

echo "$(date): Начало перемещения SQL backup файлов" >> "$LOG"

if [ ! -d "$SOURCE" ]; then
    echo "$(date): ОШИБКА - Источник не найден: $SOURCE" >> "$LOG"
    exit 1
fi

mkdir -p "$TARGET"
mkdir -p "$(dirname "$LOG")"

moved_count=0

find "$SOURCE" -type f -mtime +2 | while read file; do
    rel_path="${file#$SOURCE}"
    target_file="$TARGET$rel_path"
    target_dir=$(dirname "$target_file")

    mkdir -p "$target_dir"

    if [ ! -f "$target_file" ]; then
        mv "$file" "$target_file"
        echo "$(date): Перемещен: $rel_path" >> "$LOG"
        ((moved_count++))
    fi
done

echo "$(date): Перемещение завершено" >> "$LOG"

# Отправка в Telegram без звука
MESSAGE="✅ SQL Backup перемещение завершено
Дата: $(date '+%Y-%m-%d %H:%M')
Перемещено файлов: $moved_count"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="${MESSAGE}" \
    -d disable_notification=true
