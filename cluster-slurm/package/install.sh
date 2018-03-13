#!/bin/bash
require files
require member

cp -R data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Slurm configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/cluster-slurm/configure"
  member_each "${cw_ROOT}/etc/handlers/cluster-slurm/member-join"
fi
