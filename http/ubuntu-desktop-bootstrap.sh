# This script configures the system (executed from preseed late_command)
# 2013-02-14 / Philipp Gassmann / gassmann@puzzle.ch

set -x

# Ensure proper logging
if [ "$1" != "stage2" ]; then
  mkdir /root/log
  /bin/bash /root/desktop-bootstrap.sh 'stage2' &> /root/log/desktop-bootstrap.log
  exit
fi

HTTP_SERVER="http://10.0.2.2:9000"

# get desktop-bootrap file
wget -qO /root/desktop-bootstrap-user.sh "$HTTP_SERVER/ubuntu-desktop-bootstrap-user.sh"
chmod +x /root/desktop-bootstrap-user.sh

# Activate firstboot-custom (user setup)
wget -qO /etc/init/firstboot-custom.conf "$HTTP_SERVER/firstboot-custom.conf"

# Installationsdatum speichern
date +%c > /root/install-date
