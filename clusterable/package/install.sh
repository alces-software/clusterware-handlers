#!/bin/bash

set -e

if [ ! -f "${cw_ROOT}/etc/config.yml" ]; then
  >&2 echo "${cw_ROOT}/etc/config.yml not found, but is required for clusterable-events-aws to function."
  exit 1
fi

require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  cw_DISTRO="$(sed 's/\(.*\) release \(.*\) .*/\1 \2/g' /etc/redhat-release)"
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  cw_DISTRO="$(grep ^DISTRIB_DESCRIPTION /etc/lsb-release | cut -f2 -d'"')"
fi

cp -R data/* "${cw_ROOT}"

sed -e "s/%_CW_DISTRO_%/${cw_DISTRO}/g" "${cw_ROOT}"/etc/profile.d/10-clusterable.sh.template > "${cw_ROOT}"/etc/profile.d/10-clusterable.sh
rm "${cw_ROOT}"/etc/profile.d/10-clusterable.sh.template

chmod 0700 "${cw_ROOT}"/libexec/share/clusterware-key-manager
chmod 0700 "${cw_ROOT}"/libexec/share/nologin-control
mkdir -p "${cw_ROOT}"/var/lib/event-periodic/scripts

"${cw_ROOT}"/etc/handlers/00-clusterable/preconfigure >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/00-clusterable/initialize >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/00-clusterable/start >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/00-clusterable/node-started >> /var/log/clusterware/clusterable.log
