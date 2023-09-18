#!/bin/bash
echo "Raspi-Setup Config script"
echo " - - - RUN THIS SCRIPT AS SUDO - - - "
echo "MAKE SURE YOU HAVE PRECONFIGURED THE REQUIRED THINGS BEFORE LAUNCHING THE SCRIPT!!!"
echo "For more information visit https://gitlab.com/itsoctotv/sickesprojekt/-/wikis/Setup%20RPI4%20with%20Raspberry%20Pi%20OS%20and%20Ubuntu%2022.04%20LTS#install-and-setup-raspberry-pi-os"
read -p "Proceed [y/n]?: " var_choice
if [ $var_choice != "y" ]; then

echo "Aborted."
exit

fi

read -p "Enter hostname: " var_hostname

echo "normal config phase" 
echo "Setting Timezone to Europe/Berlin..."
sudo raspi-config nonint do_change_timezone Europe/Berlin
echo "Done."
echo "Setting Language de_DE, en_GB, en_US..."
sudo raspi-config nonint do_change_locale de_DE.UTF-8 UTF-8
sudo raspi-config nonint do_change_locale en_US.UTF-8 UTF-8
sudo raspi-config nonint do_change_locale en_GB.UTF-8 UTF-8
echo "Done."
echo "Setting Hostname..."
sudo raspi-config nonint do_hostname "$var_hostname"
echo "Done."
echo "Enabling Serial Console..."
sudo raspi-config nonint do_serial 0
echo "Done."
echo "Enabling SSH Server..."
sudo raspi-config nonint do_ssh 0
echo "Done."
echo "advanced config phase"
echo "installing packages..."
sudo apt install --yes pigpiod pigpio-tools i2c-tools spi-tools
echo "Done."
echo "Setting Boot order to USB first..."
sudo raspi-config nonint do_boot_order B2
echo "Done."
echo "Enabling SPI, I2C, 1-Write and Remote-GPIO..."
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_onewire 0
sudo raspi-config nonint do_rgpio 0
echo "Done."
echo "Installing miscellaneous utilities..."
sudo apt install --yes libraspberrypi-bin gawk
echo "Done."
echo "Setting up udev rules..."
sudo bash -c 'cat > /etc/udev/rules.d/92-local-vchiq-permissions.rules' << :EOF SUBSYSTEM=="vchiq",GROUP="video",MODE="0660" 
SUBSYSTEM=="vc-sm",GROUP="video",MODE="0660" SUBSYSTEM=="bcm2708_vcio",GROUP="video",MODE="0660" 
:EOF
sudo udevadm trigger /dev/vchiq
echo "Done."

echo "Creating temperature program..."
sudo bash -c 'cat > /usr/local/bin/rpitemp' << :EOF 
#!/bin/bash 
echo "GPU:" $(vcgencmd measure_temp | egrep -o '[0-9]*\.[0-9]*') 
echo "CPU:" $(gawk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp) 
:EOF
sudo chmod +x /usr/local/bin/rpitemp
rpitemp
echo "Done."
echo " - - - SCRIPT FINISHED FOLLOW WIKI FOR FOR SETUP RTC-MODULE - - - "
echo " - - - SYSTEM WILL REBOOT IN 5 SECONDS... - - - "
sleep 5
sudo reboot
