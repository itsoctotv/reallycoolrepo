#!/bin/bash
echo "Setup script for ubuntu LTS"
echo " - - - RUN THIS SCRIPT WITH SUDO - - - "
echo "PROCEED ONLY WHEN THE PRECONFIGURED SETUP WAS TAKEN"
echo "for more information visit: https://gitlab.com/itsoctotv/sickesprojekt/-/wikis/Setup-RPI4-with-Raspberry-Pi-OS-and-Ubuntu-22.04-LTS-Scripted-Install/"
read -p "Proceed [y/n]?: " var_choice

if [ $var_choice != "y" ]; then

echo "Aborted."
exit

fi

echo "installing packages..."
sudo apt install --yes wiringpi pigpio-tools i2c-tools spi-tools
sudo apt install --yes raspi-config
echo "Done."
echo "Setting up via raspi-config..."
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_onewire 0
echo "Done."
echo "Setting up GPIO and Remote GPIO..."

sudo raspi-config nonint do_rgpio 0
sudo apt install python3-lgpio -y

echo "Done."

echo "Installing miscellaneous utilities..."
sudo apt install -y libraspberrypi-bin
echo "Done."
echo "Setting up udev rules..."
sudo bash -c 'cat > /etc/udev/rules.d/92-local-vchiq-permissions.rules' << :EOF 
SUBSYSTEM=="vchiq",GROUP="video",MODE="0660" 
SUBSYSTEM=="vc-sm",GROUP="video",MODE="0660" 
SUBSYSTEM=="bcm2708_vcio",GROUP="video",MODE="0660" 
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
echo "First phase completed."
echo "Phase 2 started..."
echo "Removing Canonical's cloud-init..."
sudo apt remove -y --purge cloud-init
sudo rm -rf /etc/cloud
sudo systemctl mask systemd-networkd-wait-online
echo "Done."
echo "Network setup Systemd/Networkd"
sudo systemctl enable systemd-networkd

echo "Purge all Netplan system packages and setups..."
sudo apt purge -y netplan.io
sudo apt autoremove --purge -y
sudo rm -f /etc/netplan/*.yaml
sudo rm -rf /usr/share/netplan
echo "Done."
echo "Purge all Avahi mDNS/DNS-SD daemon system packages and setups..."
sudo apt purge -y avahi-daemon
sudo apt autoremove --purge -y
echo "Done."
echo "Setup ethernet with LLMNR/mDNS..."

sudo cat <<EOF >> /etc/systemd/network/eth.network
[Match]
Name=eth*

[Network]
DHCP=yes
LLMNR=yes
MulticastDNS=yes
EOF

sudo cat <<EOF >> /etc/systemd/resolved.conf
[Resolve]
LLMNR=yes
MulticastDNS=yes
EOF

echo "Done."
echo "Restarting services..."
sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved

echo "Done."
echo " - - - SCRIPT HAS FINISHED FOR FURTHER SETUP VISIT THE WIKI AT:"
echo "https://gitlab.com/itsoctotv/sickesprojekt/-/wikis/Setup-RPI4-with-Raspberry-Pi-OS-and-Ubuntu-22.04-LTS-Scripted-Install - - - "
echo "SYSTEM WILL REBOOT IN 5 SECONDS..."
sleep 5
sudo reboot
