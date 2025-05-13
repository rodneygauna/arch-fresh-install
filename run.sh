#!/bin/bash

# Print the logo
print_logo() {
    cat << "EOF"
              ___         ___   __ _  _   _     _      _     
	 ___ / _ \ _ __  / _ \ / _| || | | |   / | ___| |__  
	/ __| | | | '_ \| | | | |_| || |_| |   | |/ __| '_ \ 
	\__ \ |_| | | | | |_| |  _|__   _| |___| | (__| | | |
	|___/\___/|_| |_|\___/|_|    |_| |_____|_|\___|_| |_|

EOF
}

# Clear screen and show the logo
clear
print_logo

# Exit on any errors
set -e

# Source utility function
if [ ! -f "utils.sh" ]; then
	echo "Error: utils.sh not found!"
fi

source utils.sh

# Source the package list
if [ ! -f "packages.conf" ]; then
	echo "Error: packages.conf not found!"
	exit 1
fi

source packages.conf

echo "Starting full system setup..."

# Update the system first
sudo pacman -Syu --noconfirm

# Install yay AUR helper if not present
if ! command -v yay &> /dev/null; then
	echo "Installing yay AUR helper"
	sudo pacman -S --needed git base-devel --noconfirm
	if [[ ! -d "yay" ]]; then
		echo "Cloning yay repository..."
	else
		echo "yay directory already exists, removing it..."
		rm -rf yay
	fi
	git clone https://aur.archlinux.org/yay.git
	cd yay
	echo "building yay..."
	makepkg -si --noconfirm
	cd ..
	rm -rf yay
else
	echo "yay already installed"
fi

# Install packages by category
echo "Installing system utilities..."
install_packages "${SYSTEM_UTILS[@]}"
  
echo "Installing development tools..."
install_packages "${DEV_TOOLS[@]}"
  
echo "Installing system maintenance tools..."
install_packages "${MAINTENANCE[@]}"
  
echo "Installing desktop environment..."
install_packages "${DESKTOP[@]}"
  
echo "Installing desktop environment..."
install_packages "${OFFICE[@]}"
  
echo "Installing media packages..."
install_packages "${MEDIA[@]}"
  
echo "Installing fonts..."
install_packages "${FONTS[@]}"
  
# Enable services
echo "Configuring services..."
for service in "${SERVICES[@]}"; do
  if ! systemctl is-enabled "$service" &> /dev/null; then
    echo "Enabling $service..."
    sudo systemctl enable "$service"
  else
    echo "$service is already enabled"
  fi
done
  
# Install gnome specific things to make it like a tiling WM
echo "Installing Gnome extensions..."
. gnome/gnome-extensions.sh
echo "Setting Gnome hotkeys..."
. gnome/gnome-hotkeys.sh
echo "Configuring Gnome..."
. gnome/gnome-settings.sh
  
# Some programs just run better as flatpaks. Like discord/spotify
echo "Installing flatpaks (like discord and spotify)"
. install-flatpaks.sh

echo "Setup complete! You may want to reboot your system."
