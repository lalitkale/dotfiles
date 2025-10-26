#!/usr/bin/env bash

set -e

# install sudo - this is helpful to test the dotfiles in container.
apt-get update && apt-get -y install sudo
sudo apt-get upgrade && sudo apt-get update 


# Install ExFat support to expand filesystem support

# Install NFS supprt - Fastest way to access shared folders over the network (as a client)
sudo apt-get -y install \
 exfat-utils \ 
 nfs-common  
# Add an example to /etc/fstab. Create a folder in /mnt, fill in your NAS IP address (X) and folder name (Y) and uncomment. 
echo "#" | sudo tee -a /etc/fstab
echo "# Example how to mount your servers NFS shares to a client:" | sudo tee -a /etc/fstab 
echo "#192.168.68.104:8080:  /mnt/Y  nfs4  nfsvers=4,minorversion=2,proto=tcp,timeo=50,fsc,nocto  0  0" | sudo tee -a /etc/fstab

# fonts
sudo apt -y install \
 font-managers \
 fonts-powerline \ # https://github.com/powerline/fonts
 fonts-firacode \
 

fonts_dir="${HOME}/.local/share/fonts"
if [ ! -d "${fonts_dir}" ]; then
    echo "mkdir -p $fonts_dir"
    mkdir -p "${fonts_dir}"
else
    echo "Found fonts dir $fonts_dir"
fi

# update font-config and rebuild font cache
echo "rebuilding fonts cache"
fc-cache -f

echo "___________________________________"
echo "Budgie Desktop Extras & Essentials "
echo "___________________________________"
sudo apt-get install budgie-desktop-extra
# need to provide inputs to below. 8 = europe, 15=dublin
sudo apt install software-properties-common

# Add repository for recommended Budgie stuff
sudo add-apt-repository -y ppa:ubuntubudgie/backports
## sudo add-apt-repository -y ppa:costales/folder-color not supported?
sudo apt -y update

# Allow each Workspace (virtual desktop) to have its own wallpaper
sudo apt -y install budgie-workspace-wallpaper-applet

# Show a calendar when clicking on the time
sudo apt -y install budgie-calendar-applet

sudo apt -y install  \
git  \
jq   \
curl \
wget \

#________________________________________________________________________
# Perform all actions from $HOME/Downloads, this allows automated cleanup
#________________________________________________________________________
# Just in case this script was not executed from ./Downloads

if [[ -d "$HOME/Downloads" ]]
then
    cd $HOME/Downloads
fi


# Timeshift - automated system snapshots (backups) and set configuration
sudo add-apt-repository -y ppa:teejee2008/timeshift
sudo apt -y update
echo "-------------------------------------------------"
echo "Install Timeshift for automated system snapshots "
echo "-------------------------------------------------"

sudo apt -y install timeshift
sudo wget -O /etc/timeshift/timeshift.json https://raw.githubusercontent.com/zilexa/Ubuntu-Budgie-Post-Install-Script/master/timeshift/timeshift.json
sudo sed -i -e 's#asterix#'"${USER}"'#g' /etc/timeshift/timeshift.json

# Firefox
echo "___________________________________________________________________________________"
echo "Firefox: Create a default profile setting to enable syncing of your toolbar layout " 
echo "         (Applied for all Firefox profiles created in the future.)             "
echo "___________________________________________________________________________________"

sudo tee -a /usr/lib/firefox/defaults/pref/autoconfig.js &>/dev/null << EOF
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
EOF

sudo tee -a /usr/lib/firefox/firefox.cfg &>/dev/null << EOF
// IMPORTANT: Start your code on the 2nd line
defaultPref("services.sync.prefs.sync.browser.uiCustomization.state",true);
#defaultPref("identity.sync.tokenserver.uri","https://YOUR.DOMAIN.TLD/token/1.0/sync/1.5");
EOF

# CCleaner for Linux - to clean temp files etc and rescue the space.
# wget -q "https://www.bleachbit.org/download/file/t?file=bleachbit_4.4.2-0_all_ubuntu2004.deb" -o "bleachbit_4.4.2-0_all_ubuntu2004.deb"
# sudo dpkg -i bleachbit_4.2.2-0_all_ubuntu2004.deb





# set default settings for gnome
# https://askubuntu.com/questions/454279/change-default-system-font-using-terminal-only-in-14-04
# gsettings list-recursively org.gnome.desktop.interface
gsettings set org.gnome.desktop.interface text-scaling-factor '1.0'

# visual studio code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update
sudo apt install code 

# code extensions
code --install-extension ms-python.python
code --install-extension ms-dotnettools.csharp

# obsidian
wget -q https://github.com/obsidianmd/obsidian-releases/releases/download/v0.12.12/obsidian_0.12.12_amd64.snap
sudo snap install --dangerous obsidian_0.12.12_amd64.snap


# anki
wget -q https://github.com/ankitects/anki/releases/download/2.1.46/anki-2.1.46-linux.tar.bz2
tar xjf ./anki-2.1.46-linux.tar.bz2
cd anki-2.1.46-linux
sudo ./install.sh

# dropbox
wget -q https://linux.dropbox.com/packages/ubuntu/dropbox_2020.03.04_amd64.deb
sudo apt install ./dropbox_2020.03.04_amd64.deb

# development tools and languages
# git, git-extras, postman, vscode, dotnet, java, golang, python, nodejs, nvm, ypescript, intellij, docker,kubectl, cmake,
# exercism, anki, screenkeys, rustlang
# install ruby
sudo apt install ruby-full

# install docker https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install docker-ce
sudo usermod -aG docker ${USER}
su - ${USER}
sudo usermod -aG docker ${USER}



# install golang
# How to upgrade: https://buildvirtual.net/how-to-upgrade-go-on-ubuntu/
wget https://golang.org/dl/go1.17.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.17.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# nodejs and npm
#https://github.com/nodesource/distributions/blob/master/README.md#debinstall
curl -fsSL https://deb.nodesource.com/setup_17.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g npm@latest
sudo npm install -g typescript

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install packages
brew tap liamg/tfsec
brew install terraform-docs tflint tfsec checkov
brew install pre-commit gawk coreutils

# aws-cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/installs

#- Install terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform

# terrscan
# curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz
# tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz
# sudo install terrascan /usr/local/bin && rm terrascan

#terraform-docs
curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terraform-docs.tar.gz
tar -xf terraform-docs.tar.gz terraform-docs && rm terraform-docs.tar.gz
sudo install terraform-docs /usr/local/bin && rm terraform-docs

# terraform-landscape
gem install terraform_landscape

# terraform security scan tool - checkov
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.7
sudo apt install python3-pip
sudo python3.7 -m pip install -U checkov #to install or upgrade checkov)

# install .net
wget https://packages.microsoft.com/config/ubuntu/21.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# install the sdk
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-5.0

  sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y aspnetcore-runtime-5.0

# youtube.dl, command line music player or foobar2000, 


# slack, zoom
# sudo apt install slack #version 1:0.15.2-9
wget -q https://downloads.slack-edge.com/releases/linux/4.19.2/prod/x64/slack-desktop-4.19.2-amd64.deb
sudo apt install ./slack-desktop-4.19.2-amd64.deb

# zoom
url=https://zoom.us/client/latest/zoom_amd64.deb
debdir=/usr/local/zoomdebs
aptconf=/etc/apt/apt.conf.d/100update_zoom
sourcelist=/etc/apt/sources.list.d/zoomdebs.list

sudo mkdir -p $debdir
( echo 'APT::Update::Pre-Invoke {"cd '$debdir' && wget -qN '$url' && apt-ftparchive packages . > Packages && apt-ftparchive release . > Release";};' | sudo tee $aptconf
  echo 'deb [trusted=yes lang=none] file:'$debdir' ./' | sudo tee $sourcelist
) >/dev/null

sudo apt update
sudo apt install zoom

echo "--------------------------------------------------"
echo "Install Bleachbit to cleanup the system regularly "
echo "--------------------------------------------------"
# Bleachbit - system cleanup
wget -O bleachbit.deb https://download.bleachbit.org/bleachbit_4.2.0-0_all_ubuntu2010.deb
sudo apt -y install ./bleachbit.deb
rm bleachbit.deb
sudo mkdir -p /root/.config/bleachbit
sudo wget -O /root/.config/bleachbit/bleachbit.ini https://raw.githubusercontent.com/zilexa/Ubuntu-Budgie-Post-Install-Script/master/bleachbit/bleachbit-root.ini
sudo mkdir $HOME/.config/bleachbit/
wget -O $HOME/.config/bleachbit/bleachbit.ini https://raw.githubusercontent.com/zilexa/Ubuntu-Budgie-Post-Install-Script/master/bleachbit/bleachbit-user.ini


#draw.io
sudo apt update
sudo apt -y install wget
wget https://github.com/jgraph/drawio-desktop/releases/download/v15.2.7/drawio-amd64-15.2.7.deb
sudo dpkg -i drawio-amd64-15.2.7.deb
sudo apt -y -f install

# postman.io

# This script basically automates the official Postman installation guide for Linux:
# https://learning.postman.com/docs/getting-started/installation-and-updates/#installing-postman-on-linux

# 32 or 64-bit?
BIT=$(getconf LONG_BIT)

# Download the appropriate version
wget -O ~/postman.tar.gz "https://dl.pstmn.io/download/latest/linux${BIT}"

# Extract the archive in /opt
sudo tar xvf ~/postman.tar.gz -C /opt/

# Remove the downloaded archive
rm ~/postman.tar.gz

# Make the app accessible from a launcher icon 
echo "[Desktop Entry]
Encoding=UTF-8
Name=Postman
Exec=/opt/Postman/app/Postman %U
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;" >> ~/.local/share/applications/Postman.desktop


# install gohugo - static site generator framework
sudo apt-get install hugo

# qnap nas setup https://www.qnap.com/en-us/utilities/essentials
wget -q https://download.qnap.com/Storage/Utility/QNAPQsyncClientUbuntux64-1.0.5.0305.deb
sudo dpkg -i ./QNAPQsyncClientUbuntux64-1.0.5.0305.deb

wget -q https://download.qnap.com/Storage/Utility/QNAPQfinderProUbuntux64-7.5.1.0708a.deb
sudo dpkg -i ./QNAPQfinderProUbuntux64-7.5.1.0708a.deb

# Canon MG2900 Series Printer
wget -q https://gdlp01.c-wss.com/gds/5/0100006265/01/cnijfilter2-5.00-1-deb.tar.gz
tar -xf cnijfilter2-5.00-1-deb.tar.gz 
sudo dpkg -i cnijfilter2-5.00-1-deb/packages/cnijfilter2_5.00-1_amd64.deb 
sudo apt-get install -f

# Canon MG2900 Series Scanner
wget -q https://gdlp01.c-wss.com/gds/1/0100006271/01/scangearmp2-3.00-1-deb.tar.gz
tar -xf scangearmp2-3.00-1-deb.tar.gz 
sudo dpkg -i scangearmp2-3.00-1-deb/packages/scangearmp2_3.00-1_amd64.deb 
sudo apt-get install -f

# Install Spotify
echo "======================================="
echo "---------------------------------------"
read -p "Install Spotify (y/n)?" answer
case ${answer:0:1} in
    y|Y )
        echo Installing Spotify by adding its repository...
        # Add encryption key for the repository
        curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add -
        # Add the repository
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
        # Refresh repositories and install spotify
        sudo apt -y update && sudo apt -y install spotify-client
    ;;
    * )
        echo "Skipping Spotify..." 
    ;;
esac

sudo apt-get upgrade && sudo apt-get update 
sudo apt update && sudo apt upgrade

echo "DONE! please REBOOT now, type sudo reboot now and hit enter."