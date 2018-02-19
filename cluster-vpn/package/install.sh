#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -y -e0 zip
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y zip
fi

cp -R data/* "${cw_ROOT}"

"${cw_ROOT}"/etc/handlers/cluster-vpn/configure
"${cw_ROOT}"/etc/handlers/cluster-vpn/start
