#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  cw_DISTRO="$(sed 's/\(.*\) release \(.*\) .*/\1 \2/g' /etc/redhat-release)"
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  cw_DISTRO="$(grep ^DISTRIB_DESCRIPTION /etc/lsb-release | cut -f2 -d'"')"
fi

cp -R data/* "${cw_ROOT}"

grep -e "s/%_CW_DISTRO_%/${cw_DISTRO}/g" "${cw_ROOT}"/etc/profile.d/10-clusterable.sh.template > "${cw_ROOT}"/etc/profile.d/10-clusterable.sh
rm "${cw_ROOT}"/etc/profile.d/10-clusterable.sh.template

chmod 0700 "${cw_ROOT}"/libexec/share/clusterware-key-manager
chmod 0700 "${cw_ROOT}"/libexec/share/nologin-control
mkdir -p "${cw_ROOT}"/var/lib/event-periodic/scripts

echo "Running preconfigure hook..." > /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/clusterable/preconfigure >> /var/log/clusterware/clusterable.log
echo "Running start hook..." >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/clusterable/start >> /var/log/clusterware/clusterable.log
echo "Running node-started hook..." >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/clusterable/node-started >> /var/log/clusterware/clusterable.log
