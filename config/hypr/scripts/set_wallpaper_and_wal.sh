#!/bin/bash

# Путь к вашему изображению
WALLPAPER="$HOME/.config/hypr/current_wallpaper/1374466.png" # Измените путь к вашему файлу

# 1. Генерируем цветовую схему с помощью pywal (-n не уведомляет)
wal -n -i "$WALLPAPER"

# 2. Обновляем конфигурацию hyprpaper
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Очищаем старую конфигурацию и добавляем новую
echo "" > "$HYPRPAPER_CONF"
echo "preload = $WALLPAPER" >> "$HYPRPAPER_CONF"
echo "wallpaper = ,$WALLPAPER" >> "$HYPRPAPER_CONF" # Пустой первый аргумент означает все мониторы
echo "splash = false" >> "$HYPRPAPER_CONF" # Отключаем splash, если не нужен

# 3. Перезагружаем конфигурации приложений, отправляя сигналы
hyprctl reload # Перезагрузит конфиг Hyprland и запустит hyprpaper с новым конфигом
killall -SIGUSR2 waybar
# makoctl reload
