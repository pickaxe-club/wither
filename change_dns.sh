#!/bin/bash

# http://www.kirya.net/articles/running-a-secure-ddns-service-with-bind/

host=$1
ipaddr=$2

echo "Aliasing host $host to ip $ipaddr"
nsupdate -k ./Kpickaxe.+157+50170.private <<EOF
server ns1.phoenyx.net
zone pickaxe.club
update add $host. 60 A $ipaddr
send
EOF

exit
