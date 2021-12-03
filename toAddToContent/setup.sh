#!/bin/bash
sudo usermod -a -G dialout $USER

cd /
sudo apt-get install -y git
# download the repo, or update it, if it already exists, and if it can't update, check if there's internet and if so clean the folder and redownload the repo
git clone https://github.com/DominicHarrisStudio/content.git /content || ( ping -c 2 google.com &>/dev/null && sudo rm -rf /content && sudo git clone https://github.com/DominicHarrisStudio/content.git /content )
# download the repo, or update it, if it already exists, and if it can't update, check if there's internet and if so clean the folder and redownload the repo
git clone https://github.com/DominicHarrisStudio/DHArtworkDemoSelector.git /demoApp || ( ping -c 2 google.com &>/dev/null && sudo rm -rf /demoApp && sudo git clone https://github.com/DominicHarrisStudio/DHArtworkDemoSelector.git /demoApp )
# download the repo, or update it, if it already exists
git clone https://github.com/DominicHarrisStudio/dependencies.git /dependencies || (  git -C /dependencies/ rm --cached -r . && git -C /dependencies/ reset --hard && git -C /dependencies/ pull )

#sudo mkdir /Scripts
# download the "DHS_Stat-Collector repo, or update it, if it already exists
sudo git clone https://github.com/DominicHarrisStudio/DHS_Stat-Collector.git /Scripts/DHS_Stat-Collector || (  git -C /Scripts/ rm --cached -r . && git -C /Scripts/ reset --hard && git -C /Scripts/ pull )
sudo git clone -b butterfly https://github.com/williamparry1/ScreenTester.git /artwork || (  git -C /artwork/ rm --cached -r . && git -C /artwork/ reset --hard && git -C /artwork/ pull )

#create sudoers file for adminScript.sh
sudo echo "dhstudio ALL=(ALL) NOPASSWD: /content/adminScript.sh" > ~/adminScript
sudo chmod 440 ~/adminScript
sudo chown root:root ~/adminScript
sudo cp ~/adminScript /etc/sudoers.d/
sudo rm -f ~/adminScript

sudo echo "dhstudio ALL=(ALL) NOPASSWD: /content/autosudoscript.sh" > ~/autoSudoScript
sudo chmod 440 ~/autoSudoScript
sudo chown root:root ~/autoSudoScript
sudo cp ~/autoSudoScript /etc/sudoers.d/
sudo rm -f ~/autoSudoScript

#create sudoers file for set_brightness.sh for autoDim
sudo echo "dhstudio ALL=(ALL) NOPASSWD: /content/set_brightness.sh" > ~/set_brightness
sudo chmod 440 ~/set_brightness
sudo chown root:root ~/set_brightness
sudo cp ~/set_brightness /etc/sudoers.d/
sudo rm -f ~/set_brightness

#create sudoers file for set_brightness.sh for autoDim
sudo echo "dhstudio ALL=(ALL) NOPASSWD: /content/gst.sh" > ~/gst_restart
sudo chmod 440 ~/gst_restart
sudo chown root:root ~/gst_restart
sudo cp ~/gst_restart /etc/sudoers.d/
sudo rm -f ~/gst_restart

#create backup of deactivateKiosk mode, in case someone screws up
sudo cp /content/deactivateKioskMode.sh ~/
sudo cp /content/adminScript.sh ~/

#Remove White Crosshair
sudo echo 'xsetroot -cursor /content/emptycursor /content/emptycursor' > /removeCursor
sudo chmod +x ~/removeCursor
sudo cp ~/removeCursor /etc/init.d/
sudo rm ~/removeCursor

# platform specific commands
cpuArchitecture=$(lscpu | grep -i architecture | xargs | cut -d " " -f 2)
echo cpuArchitecture = $cpuArchitecture
if [[ "$cpuArchitecture" == "x86_64" ]]; then
	echo This is a desktop computer
	##### Desktop specific commands #####
	cpuModel=$(lscpu | grep -i "model name" | xargs | cut -d " " -f 3-1000)
	if [[ "$cpuModel" == *"Vega"* ]]; then
		echo "This is a Ryzen APU, and there is no official support for Vulkan on Linux"
		echo "Unreal Artworks will run under OpenGL and show a warning from the engine"
		# If we want to use ryzen APUs, put here whatever we need to install later to get Unreal artworks to work without the openGL warning
	else
		echo Installing Vulkan. CPU = $cpuModel
		# install Vulkan
		sudo apt install libvulkan1 mesa-vulkan-drivers vulkan-utils
	fi
else
if [[ "$cpuArchitecture" == "aarch64" ]]; then
	echo This is an embedded computer
	##### Jetson specific commands #####
	/content/autoDim/ads1015Requirement.sh


	# set board to max peformance mode
	isJetsonNX=$(sudo lshw | grep -i nx)
	if [ -z "$isJetsonNX" ]; then
		sudo nvpmodel -m 0
	else
		#jetson nx has a different order, where max performance is 2, not 0
		sudo nvpmodel -m 2
	fi

	# FIX SCREEN TEARING ISSUE

	#read simlink
	videoDriver=$( readlink -f /etc/X11/xorg.conf )
	#make backup of original nvidia's ref file
	sudo cp -n $videoDriver /etc/X11/xorg.conf.bckp
	#this is a new file we put alongside nvidia's reference files
	videoDriverCustomFile=xorg.conf.dhs
	#variables do not work inside awk, therefore we need to repeat this value below
	option=ForceFullCompositionPipeline

	# to see current video driver file use that in a terminal: cat /etc/X11/xorg.conf
	# if for some reason you want to delete the  option (a line), use the line below
	#cat $videoDriver | sed '/ForceCompositionPipeline/d' > ~/$videoDriverCustomFile && sudo mv -f ~/$videoDriverCustomFile $videoDriver
	#exit
	# To restore backup use line below in the terminal
	#sudo mv -f /etc/X11/xorg.conf.bckp $( readlink -f /etc/X11/xorg.conf )

	if grep -q "$option" "$videoDriver"; then
	    echo Skipped adding option "$option" - it already exists
	else
	    # search for the second occurance of "EndSection" in the videoDriver file, and use replace method to add a line above with the desired option
	    sudo awk '/EndSection/{c++;if(c==2){sub("EndSection","    Option      \"ForceFullCompositionPipeline\" \"On\" \n EndSection");c=0}}1' $videoDriver > ~/$videoDriverCustomFile
	    # move the newly created file into the proper folder
	    sudo mv -f ~/$videoDriverCustomFile $videoDriver
	    echo "Option '$option' added to '$videoDriver'. Please restart the device for it to work"
	fi

	#sudo echo "dhstudio ALL=(ALL) NOPASSWD: /content/set_brightness.sh" > ~/setBrightness
	#sudo chmod 440 ~/setBrightness
	#sudo chown root:root ~/setBrightness
	#sudo cp ~/setBrightness /etc/sudoers.d/
	#sudo rm -f ~/setBrightness

        if [ -f "~/.config/autostart/start.sh.desktop" ]; then
		echo "startup already set"
	else
		echo '[Desktop Entry]' > ~/start.sh.desktop
		echo 'Type=Application' >> ~/start.sh.desktop
		echo 'Exec="/content/start.sh"' >> ~/start.sh.desktop
		echo 'Hidden="true"' >> ~/start.sh.desktop
		echo 'NoDisplay="false"' >> ~/start.sh.desktop
		echo 'X-GNOME-Autostart-enabled=true' >> ~/start.sh.desktop
		cp ~/start.sh.desktop ~/.config/autostart/ || sudo cp ~/start.sh.desktop ~/.config/autostart/
		rm -f ~/start.sh.desktop
	fi
fi
fi #end of platform specific commands

# ETHERNET AND OS UPDATE SETTINGS
# install command support for "ifconfig" which doesn't come by default in ubuntu desktop LTS
sudo apt-get install -y net-tools
# activate network adapter (just in case)
sudo ifconfig eth0 up
# UPDATE LINUX
sudo apt-get update
#sudo apt-get upgrade
# deactivate network adapter (if required)
#sudo ifconfig eth0 down
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl disable apt-daily-upgrade.service
sudo apt-get install -y tuptime

sudo apt-get install -y libudev-dev
sudo /content/keylok_install.sh

# reinstall gstreamer plugins (not necessary, that was a failed attempt to fix csi camera)
#sudo apt-get install gstreamer1.0-tools gstreamer1.0-alsa \
#  gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
#  gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
#  gstreamer1.0-libav
#sudo apt-get install libgstreamer1.0-dev \
#  libgstreamer-plugins-base1.0-dev \
#  libgstreamer-plugins-good1.0-dev \
#  libgstreamer-plugins-bad1.0-dev


#FIX TOUCH ISSUE
if [[ $(xinput list | grep -i -c "DHSTch") == 0 ]]; then
	echo creating DHSTch
	xinput create-master DHSTch
fi
touchDevice=$(xinput list | grep -i "touch" | head -n 1)
touchDeviceParsedID=$(echo $touchDevice | cut -d "=" -f 2 | xargs | cut -d " " -f 1)
touchDeviceParentID=$(echo $touchDevice | cut -d "=" -f 2 | xargs | cut -d "(" -f 2 | cut -d ")" -f 1)
touchMaster=$(xinput list | grep -i "DHSTch" | head -n 1)
touchMasterParsedID=$(echo $touchMaster | cut -d "=" -f 2 | xargs | cut -d " " -f 1)

#regular expression to check if value is a number
re='^[0-9]+$'
if [[ $touchDeviceParsedID =~ $re ]] && [[ $touchMasterParsedID =~ $re ]] && [[ $touchDeviceParentID =~ $re ]] && [[ $touchDeviceParentID != $touchMasterParsedID ]]; then
	echo reattaching touchDevice index $touchDeviceParsedID to touchMaster index $touchMasterParsedID
	echo  
	xinput reattach $touchDeviceParsedID $touchMasterParsedID
fi
sudo apt-get install -y unclutter

# FOLDER PERMISSIONS - need to be revisited for enforcing security later before deploying
sudo chmod +x /content/*.sh
sudo chown -R $USER:$USER /content
sudo chmod +x /Scripts/*.sh
sudo chown -R $USER:$USER /Scripts
sudo mkdir /artwork
sudo chown -R $USER:$USER /artwork
sudo mkdir /artworks
sudo chown -R $USER:$USER /artworks
sudo mkdir /demoApp
sudo chown -R $USER:$USER /demoApp
sudo mkdir /parameters
sudo chown -R $USER:$USER /parameters
sudo mkdir /dependencies
sudo chown -R $USER:$USER /dependencies
chmod ugo+rw -R /artwork
chmod ugo+rw -R /artworks

# workaround hotfix for button change scene not working
sudo chmod ugo+rw /demoApp/Content/ArtworkDemoSettings.json
sudo chown $USER:$USER /demoApp/Content/ArtworkDemoSettings.json

# used for storing test artwork paths
touch /content/artwork.txt
chmod ugo+rw /content/artwork.txt

# USB PERMISSIONS - need to be revisited for enforcing security later before deploying
sudo cp /content/50-myusb.rules /etc/udev/rules.d/50-myusb.rules
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty
sudo udevadm trigger

# KIOSK MODE (moved to deploy script)
#sudo cp /content/kiosk.desktop /usr/share/xsessions/kiosk.desktop

# add folders to bookmark for convenience
declare -a folders=("/artwork/" "/artworks/" "/content/" "/demoApp/" "/parameters/" "/Scripts/")

# start tweaking desktop settings and preferences
sudo apt-get install -y dconf-tools
sudo apt-get install -y gnome-tweaks
sudo apt-get install -y gnome-tweak-tool
sudo apt-get install -y gnome-shell-extensions
sudo apt-get install -y gnome-shell-extension-autohidetopbar

# sets power button action (only works after restarting the computer once)
gsettings set org.gnome.settings-daemon.plugins.power button-power 'shutdown'

# setting chassis type to vm (as opposed to default's desktop) on ubuntu 18 restores the ability to do clean power off without prompt when power button is pressed. this function would otherwise not work
hostnamectl set-chassis vm

# do not lock device when inactive
gsettings set org.gnome.desktop.screensaver lock-enabled false

# do not turn screen off when inactive (value in seconds, 0=off)
gsettings set org.gnome.desktop.session idle-delay 0

# disable desktop notifications
gsettings set org.gnome.desktop.notifications show-banners false

# set desktop background color to pitch black (no image)
gsettings set org.gnome.desktop.background show-desktop-icons true
sleep 3
if [ -f "/content/bg.png" ]; then
	echo already has a background image
else
	echo downloading
	wget http://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Solid_black.svg/512px-Solid_black.svg.png
	mv 512px-Solid_black.svg.png /content/bg.png
	sudo cp /content/bg.png /usr/share/backgrounds/NVIDIA_Logo.png
fi
gsettings set org.gnome.desktop.background picture-uri "file:///content/bg.png"
sleep 2
gsettings set org.gnome.desktop.background primary-color "#000000"
gsettings set org.gnome.desktop.background secondary-color "#000000"
gsettings set org.gnome.desktop.background color-shading-type "solid"

# hide desktop icons
gsettings set org.gnome.desktop.background show-desktop-icons false

# make executables clickable in nautilus
gsettings set org.gnome.nautilus.preferences executable-text-activation 'launch'

# disable desktop effects that can visually interfere when changing artworks
gsettings set org.gnome.desktop.interface enable-animations false

# make new windows come up on top when opened
# gsettings set org.gnome.desktop.wm.preferences focus-new-windows 'strict'

# install dependencies useful for python programs:
sudo apt-get install -y python3 python3-pip
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade setuptools

# 1. demo app
#python3 -m pip install --user pyqt5 #threw errors in jetson xavier
sudo apt-get install -y python3-pyqt5
sudo apt-get install -y pyqt5-dev-tools
sudo apt-get install -y qttools5-dev-tools
# configure to run default pyqt designer app from terminal, if ever needed
# qtchooser -run-tool=designer -qt=5

# 2. radar sensor data parsing from Cori quick test (never properly tested. dependencies and different versions can interfere with demo app above)
#sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.6.2
#sudo update-alternatives --config python
# Be careful, the below command takes ages! (Maybe not necessary? To be tested)
# #pip3 freeze - local | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U
# sudo pip3 install adafruit-blinka
# sudo pip3 install adafruit-circuitpython-ads1x15

# 2. dependencies (opencv for python with gstreamer on for optical flow)
if [[ "$cpuArchitecture" == "aarch64" ]]; then
    if [ -d "/lib/opencv" ]; then
        echo "opencv already installed on aarch64"
    else
        echo "opencv not installed on aarch64"
        sudo mkdir /lib/opencv
        sudo /content/install_opencv4.3.0_Jetson.sh /lib/opencv
    fi
else
if [[ "$cpuArchitecture" == "x86_64" ]]; then
    if command -v ipython &> /dev/null; then
        echo "opencv already installed on x86_64"
    else
        echo "opencv not installed on x86_64"
        cd ~/
        /content/installOpenCV-4-on-Ubuntu-18-04.sh ~/
    fi
fi
fi

# add bookmarks for convenience
bookmarksFileFolder=~/.config/gtk-3.0/
bookmarksFile=bookmarks
bookmarks=$bookmarksFileFolder$bookmarksFile

cd "$bookmarksFileFolder"
ls -l
echo 
for folder in ${folders[@]}
do
    if grep -q "${folder//'/'}" "$bookmarksFile"; then
        echo Skipped adding bookmark "$folder" - it already exists
    else
        echo Bookmark "$folder" added to $bookmarksFile
        echo "file://$folder" >> $bookmarksFile
    fi
done
