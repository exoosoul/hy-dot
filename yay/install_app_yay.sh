#!/bin/bash

# Путь к файлу со списком пакетов
PACKAGE_LIST="pkglist.txt"

# Обновляем системную базу данных перед установкой
sudo pacman -Syu --noconfirm

# Установка yay из GitHub, если он еще не установлен
if ! command -v yay &> /dev/null; then
    echo "Yay не установлен. Устанавливаем..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# Устанавливаем пакеты из списка
cat "$PACKAGE_LIST" | sed '/^#/d' | xargs yay -S --needed --noconfirm
