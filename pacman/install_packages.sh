#!/bin/bash

# Путь к файлу со списком пакетов
PACKAGE_LIST="pkglist.txt"

# Обновляем системную базу данных перед установкой
sudo pacman -Syu --noconfirm

# Устанавливаем пакеты из списка
# sed '/^#/d' pkglist.txt - удаляет закомментированные строки
# xargs sudo pacman -S --needed --noconfirm - передает список в pacman
cat "$PACKAGE_LIST" | sed '/^#/d' | xargs sudo pacman -S --needed --noconfirm
