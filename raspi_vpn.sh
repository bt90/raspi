#! /bin/bash
###########################################
#          Created by Thomas Butz         #
#   E-Mail: btom1990(at)googlemail.com    #
#  Feel free to copy & share this script  #
###########################################

# the IP of your raspberry
raspi_client_ip="192.168.2.2"
# subnetmask
raspi_client_nm="255.255.255.0"
# the IP of your router
raspi_client_gw="192.168.2.1"
# second IP of the raspberry(gateway address for the clients)
raspi_gateway_ip="192.168.2.3"

# Your hide.me credentials
username="sample_user"
password="sample_password"

# Choose a server
server="https://hide.me/setup/ovpn/type/ovpn/server/17"  # Netherlands (default)
#server="https://hide.me/setup/ovpn/type/ovpn/server/71" # Germany
#server="https://hide.me/setup/ovpn/type/ovpn/server/21" # Switzerland 
#server="https://hide.me/setup/ovpn/type/ovpn/server/62" # United Kingdom

# Don't change anything beyond this point
###########################################

# Check for root priviliges
if [[ $EUID -ne 0 ]]; then
   printf "Please run as root:\nsudo %s\n" "${0}" 
   exit 1
fi

# Install required packages
apt-get update && apt-get -y install openvpn iptables-persistent sipcalc

# Create config
cd /etc/openvpn
wget $server -O config.zip
unzip config.zip
rm config.zip
shopt -s nullglob
for f in *.ovpn
do
    sed -i 's/^auth-user-pass$/auth-user-pass user_pass.txt/' $f
    echo 'script-security 2' >> $f
    echo 'up update-resolv-conf' >> $f
    echo 'down update-resolv-conf' >> $f
    rename 's/.ovpn/.conf/' $f
done
cat > user_pass.txt <<EOF
$username
$password
EOF

# Reconfigure interfaces
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $raspi_client_ip
gateway $raspi_client_gw
netmask $raspi_client_nm

auto eth0:0
iface eth0:0 inet static
address $raspi_gateway_ip
EOF

# Setup IPTables
raspi_client_nw=$(sipcalc $raspi_client_ip $raspi_client_nm | grep 'Network address' | rev | cut -d' ' -f1 | rev)
iptables -A FORWARD -s $raspi_client_nw/$raspi_client_nm -i eth0:0 -o eth0 -m conntrack --ctstate NEW -j REJECT
iptables -A FORWARD -s $raspi_client_nw/$raspi_client_nm -i eth0:0 -o tun0 -m conntrack --ctstate NEW -j ACCEPT
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# Enable IP forwarding
cp /etc/sysctl.conf /etc/sysctl.conf.old
sed -i 's/.*net\.ipv4\.ip_forward=.*/net\.ipv4\.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Start the virtual interface
ifdown eth0:0 && ifup eth0:0

# Start OpenVPN
/etc/init.d/openvpn start
