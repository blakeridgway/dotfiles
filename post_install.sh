#!/bin/bash

# A script for setting up post install
# Relies on Flatpak to be installed
# Created by Blake Ridgway

# Check to see if running as sudo/root

if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi

# Update system 
apt update && apt upgrade

# Verify flatpak is engaged properly
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

PACKAGE_LIST=(
	bpytop
	cargo
	git
	golang
	fd-find
	kitty
	java-openjdk
	neofetch
	neovim
	python3
	python3-pip
	ripgrep
	ruby
	solaar
	tilix
	virt-manager
	zsh
)

FLATPAK_LIST=(
	com.bitwarden.desktop
	net.davidotek.pupgui2
	net.veloren.airshipper
)

echo #######################
echo # Installing Packages #
echo #######################

for package_name in ${PACKAGE_LIST[@]}; do
	if ! apt list --installed | grep -q "^\<$package_name\>"; then
		echo "Installing $package_name..."
		sleep .5
		apt install "$package_name" -y
		echo "$package_name has been installed"
	else
		echo "$package_name already installed"
	fi
done

for flatpak_name in ${FLATPAK_LIST[@]}; do
	if ! flatpak list | grep -q $flatpak_name; then
		flatpak --user install "$flatpak_name" -y
	else
		echo "$package_name already installed"
	fi
done

echo #######
echo # SSH #
echo #######

ssh-keygen -t ed25519 -C ${USER}@$(hostname --fqdn)


echo ##########
echo # pynvim #
echo ##########

/usr/bin/python3 -m pip install pynvim

echo #####################
echo # Install Nerd Font #
echo #####################

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip && unzip Hack.zip -d Hack
mkdir -p ~/.local/share/fonts && cp Hack/HackNerdFont-Regular.ttf ~/.local/share/fonts
fc-cache -f -v

echo ######################
echo # Installing OhMyZSH #
echo ######################

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo ##################
echo # Setup Starship #
echo ##################

curl -sS https://starship.rs/install.sh | sh

echo ###############
echo # Config File #
echo ###############

cp terminal/starship.toml ~/.config/starship.toml

echo ###################
echo # Setting up nvim #
echo ###################

cp -r nvim/ ~/.config/nvim/

echo #######################
echo # Cleanup and Updates #
echo #######################

apt upgrade
flatpak update

echo ################
echo # File Cleanup #
echo ################

rm -r *.ttf *.zip

# Symlink files

FILES=('vimrc' 'vim' 'zshrc' 'zsh' 'agignore' 'gitconfig' 'gitignore' 'gitmessage' 'aliases')
for file in ${FILES[@]}; do
	echo ""
	echo "Simlinking $file to $HOME"
	ln -sf "$PWD/$file" "$HOME/.$file"
	if [ $? -eq 0 ]; then
		echo "$PWD/$file ~> $HOME/.$file"
	else
		echo 'Install failed to symlink.'
		exit 1
	fi
done