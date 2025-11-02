#!/bin/bash

# Скрипт установки Hyprland с NVIDIA и ядром Zen на Arch Linux с systemd-boot

echo "Запуск установки Hyprland и драйверов NVIDIA с ядром Zen и загрузчиком systemd-boot..."

if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен от имени root."
   exit 1
fi

echo "Активация репозитория multilib..."
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf

echo "Обновление базы данных пакетов и системы..."
pacman -Syyu --noconfirm

# Пакеты драйверов NVIDIA
echo "Установка основных пакетов, драйверов"
pacman -S --noconfirm nvidia-dkms linux-zen-headers nvidia-utils  lib32-nvidia-utils egl-wayland libva-nvidia-driver



echo "Настройка modeset для NVIDIA..."
echo 'options nvidia_drm modeset=1' > /etc/modprobe.d/nvidia.conf

echo "Настройка загрузки модулей в /etc/mkinitcpio.conf..."
sed -i 's/^MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

echo "Пересборка initramfs..."
mkinitcpio -P

echo "Добавление параметра ядра nvidia.NVreg_PreserveVideoMemoryAllocations=1 для systemd-boot..."

BOOT_LOADER_PATH="/boot/loader/entries"
ZEN_ENTRY_FILE=$(ls $BOOT_LOADER_PATH | grep zen | head -n 1)

if [[ -z "$ZEN_ENTRY_FILE" ]]; then
    echo "Не найден файл записи ядра Zen в $BOOT_LOADER_PATH"
    echo "Добавьте параметр nvidia.NVreg_PreserveVideoMemoryAllocations=1 вручную."
else
    ENTRY_PATH="$BOOT_LOADER_PATH/$ZEN_ENTRY_FILE"
    if grep -q "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "$ENTRY_PATH"; then
        echo "Параметр ядра уже присутствует в $ENTRY_PATH"
    else
        sed -i "/^options / s/$/ nvidia.NVreg_PreserveVideoMemoryAllocations=1/" "$ENTRY_PATH"
        echo "Параметр ядра добавлен в $ENTRY_PATH"
    fi
fi

echo "Настройка окружения Hyprland..."
echo "Добавьте в ~/.config/hypr/hyprland.conf следующие строки:"
echo 'env = LIBVA_DRIVER_NAME,nvidia'
echo 'env = __GLX_VENDOR_LIBRARY_NAME,nvidia'
echo 'env = NVD_BACKEND,direct'
echo 'env = ELECTRON_OZONE_PLATFORM_HINT,auto'
echo "--------------------------------------"

echo "Активация служб для режима сна NVIDIA..."
systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service

echo "Установка завершена. Перезагрузите систему для применения всех изменений."
echo "Проверка modeset: cat /sys/module/nvidia_drm/parameters/modeset"
echo "Для перезагрузки выполните: reboot"
