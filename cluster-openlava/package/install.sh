#!/bin/bash

cp -R data/* "${cw_ROOT}"

_handle_members() {
  shift  # Gets rid of the '--' that member_each starts with
  echo "$@" | "${cw_ROOT}/etc/handlers/cluster-openlava/member-join"
}

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring OpenLava configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/cluster-openlava/configure"
  "${cw_ROOT}/etc/handlers/cluster-openlava/start"
  member_each _handle_members
fi
