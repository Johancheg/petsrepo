#!/bin/bash

# Настройка логирования
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/upscale_$(date +%Y%m%d_%H%M%S).log"

# Создание директории для логов
mkdir -p "$LOG_DIR"

# Функция логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "=== Запуск скрипта улучшения видео ==="

# Проверка наличия ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "Ошибка: ffmpeg не установлен"
    log "ОШИБКА: ffmpeg не установлен"
    exit 1
fi

# Проверка аргумента
if [ $# -eq 0 ]; then
    echo "Использование: $0 <путь_к_папке_с_фильмами>"
    log "ОШИБКА: Не указана директория"
    exit 1
fi

MOVIES_DIR="$1"

if [ ! -d "$MOVIES_DIR" ]; then
    echo "Ошибка: Директория $MOVIES_DIR не существует"
    log "ОШИБКА: Директория $MOVIES_DIR не существует"
    exit 1
fi

echo "Сканирование папки: $MOVIES_DIR"
log "Начало сканирования: $MOVIES_DIR"

# Поиск видеофайлов и обработка
find "$MOVIES_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" \) | while read -r file; do
    echo "Обработка: $file"
    log "Начало обработки: $file"
    
    # Получение информации о разрешении
    echo "Проверяем файл: $file"
    resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$file" 2>&1)
    echo "Результат ffprobe: '$resolution'"
    
    if [ -z "$resolution" ] || [[ "$resolution" == *"error"* ]] || [[ ! "$resolution" =~ ^[0-9]+,[0-9]+$ ]]; then
        echo "Ошибка получения разрешения для: $file"
        echo "Вывод ffprobe: $resolution"
        continue
    fi
    
    width=$(echo "$resolution" | cut -d',' -f1)
    height=$(echo "$resolution" | cut -d',' -f2)
    
    # Проверка, нужно ли улучшение
    if [ "$width" -ge 3840 ] && [ "$height" -ge 2160 ]; then
        echo "Файл уже в 4K или выше, пропускаем: $file"
        continue
    fi
    
    # Создание имени выходного файла
    dir=$(dirname "$file")
    filename=$(basename "$file")
    name="${filename%.*}"
    ext="${filename##*.}"
    output="$dir/${name}_4K.$ext"
    
    # Проверка существования выходного файла
    if [ -f "$output" ]; then
        echo "4K версия уже существует, пропускаем: $output"
        continue
    fi
    
    echo "Улучшение до 4K: $file -> $output"
    
    # Улучшение качества до 4K с FPS 30 и улучшением звука
    ffmpeg -nostdin -i "$file" -vf "scale=3840:2160:flags=lanczos,fps=30" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 320k -ar 48000 "$output" -y
    
    if [ $? -eq 0 ] && [ -f "$output" ] && [ -s "$output" ]; then
        echo "Успешно обработан: $output"
        log "УСПЕХ: $file -> $output"
        link_count=$(stat -c %h "$file")
        if [ "$link_count" -gt 1 ]; then
            echo "Файл имеет $link_count жестких ссылок, не удаляем: $file"
            log "Сохранен исходный файл (жесткие ссылки): $file"
        else
            echo "Удаляем исходный файл: $file"
            rm "$file"
            echo "Исходный файл удален"
            log "Удален исходный файл: $file"
        fi
    else
        echo "Ошибка при обработке: $file"
        log "ОШИБКА обработки: $file"
        if [ -f "$output" ]; then
            echo "Удаляем поврежденный выходной файл: $output"
            rm "$output"
        fi
    fi
done

echo "Обработка завершена"
log "=== Обработка завершена ==="
