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
NVIDIA_DRIVER_PACKAGE="nvidia-dkms"
NVIDIA_UTILS_PACKAGE="nvidia-utils"
LIB32_NVIDIA_UTILS_PACKAGE="lib32-nvidia-utils"

echo "Установка основных пакетов, драйверов, Hyprland и утилит..."
pacman -S --noconfirm base base-devel linux-zen linux-zen-headers intel-ucode \
  $NVIDIA_DRIVER_PACKAGE $NVIDIA_UTILS_PACKAGE $LIB32_NVIDIA_UTILS_PACKAGE nvidia-settings \
  networkmanager iwd wpa_supplicant networkmanager-applet \
  pipewire wireplumber alsa-utils pipewire-pulse pipewire-alsa \
  hyprland waybar wofi wl-clipboard grim slurp kitty mako \
  xdg-utils xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-hyprland \
  polkit polkit-gnome brightnessctl dislocker usb_modeswitch yay egl-wayland libva-nvidia-driver

sudo pacman -S --noconfirm thunar thunar-volman thunar-archive-plugin thunar-media-tags-plugin gvfs tumbler catfish

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
