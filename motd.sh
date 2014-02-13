#! /bin/bash
##############################################
#          Created by Thomas Butz            #
#   E-Mail: btom1990(at)googlemail(dot)com   #
#   Feel free to copy & share this script    #
##############################################


################### HOWTO ####################
# 1. Save this script as /usr/local/bin/motd
# 2. sudo chmod +x /usr/local/bin/motd
# 3. Edit /etc/profile to call the script in the last line(simply type: motd)
# 4. sudo echo '' > /etc/motd
# 5. sudo echo '' > /etc/motd.tail
# 6. sudo echo '' > /var/run/motd.dynamic
# 7. sudo sed -i "/.*uname/s/^/#/g" /etc/init.d/motd
# 8. Reconnect and admire your shiny new SSH greeting!
##############################################

# Hostname
host=$(uname -n)

# Kernel
kernel=$(uname -r)

# Public IP
ip=$(curl -sm 3 http://icanhazip.com)

# Uptime
up[0]=$(cat /proc/uptime | cut -d. -f1)
let up[1]=${up[0]}/60/60/24 # days
let up[2]=${up[0]}/60/60%24 # hours
let up[3]=${up[0]}/60%60    # minutes
let up[4]=${up[0]}%60       # seconds

# Sysload
load=($(cat /proc/loadavg))

# Memory
mem[0]=$(free -mo | tr -dc '[:digit:][:blank:]' | tr -s ' ')
mem[1]=$(echo ${mem[0]} | cut -d' ' -f1) # total
mem[2]=$(echo ${mem[0]} | cut -d' ' -f2) # used
mem[3]=$(echo ${mem[0]} | cut -d' ' -f8) # used Swap

# Temperature
temp=$(vcgencmd measure_temp | tr -dc '[:digit:].')

# Disk Usage
usage=$(df / | tail -n 1 |tr -s ' ' | cut -d' ' -f5) # Root filesystem

# Logins
let log=$(w -s | wc -l)-2

# Processes
psu=$(ps U $USER h | wc -l)
psa=$(ps -A h | wc -l)

# Text colors
blk='\e[0;30m' # black
red='\e[0;31m' # red
grn='\e[0;32m' # green
nc='\e[0m'     # no color

# Print info
echo
echo -e "${grn}     .~~.   .~~.     ${red}Hostname...:${grn} $host${nc}"
echo -e "${grn}    '. \ ' ' / .'    ${red}Kernel.....:${grn} $kernel${nc}"
echo -e "${grn}     .~ .~~~..~.     ${red}Public IP..:${grn} $ip${nc}"
echo -e "${red}    : .~.'~'.~. :    ${red}Uptime.....:${grn} ${up[1]} days, ${up[2]} hours, ${up[3]} minutes, ${up[4]} seconds${nc}"
echo -e "${red}   ~ (   ) (   ) ~   ${red}Load.......:${grn} ${load[0]} (1min) ${load[1]} (5min) ${load[2]} (15min)${nc}"
echo -e "${red}  ( : '~'.~.'~' : )  ${red}Memory ....:${grn} Total: ${mem[1]} MB, Used: ${mem[2]} MB, Swap: ${mem[3]} MB${nc}"
echo -e "${red}   ~ .~ (   ) ~. ~   ${red}Temperature:${grn} $temp°C${nc}"
echo -e "${red}    (  : '~' :  )    ${red}Disk Usage.:${grn} ${usage}${nc}"
echo -e "${red}     '~ .~~~. ~'     ${red}Logins.....:${grn} There are currently $log users logged in${nc}"
echo -e "${red}         '~'         ${red}Processes..:${grn} Total: $psa, User: $psu${nc}"
echo