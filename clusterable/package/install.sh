#!/bin/bash

set -e

if [ ! -f "${cw_ROOT}/etc/config.yml" ]; then
  >&2 echo "${cw_ROOT}/etc/config.yml not found, but is required for clusterable-events-aws to function."
  exit 1
fi

cp -R data/* "${cw_ROOT}"

chmod 0700 "${cw_ROOT}"/libexec/share/clusterware-key-manager
chmod 0700 "${cw_ROOT}"/libexec/share/nologin-control
mkdir -p "${cw_ROOT}"/var/lib/event-periodic/scripts

"${cw_ROOT}"/etc/handlers/00-clusterable/preconfigure >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/00-clusterable/initialize >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/00-clusterable/start >> /var/log/clusterware/clusterable.log
"${cw_ROOT}"/etc/handlers/00-clusterable/node-started >> /var/log/clusterware/clusterable.log
