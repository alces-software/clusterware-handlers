#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
require files

_run_custom_hooks() {
    local a p hook paths
    hook="$1"
    shift
    files_load_config config config/cluster
    files_load_config instance config/cluster
    files_load_config cluster-customizer
    cw_CLUSTER_CUSTOMIZER_path=${cw_CLUSTER_CUSTOMIZER_path:-"${cw_ROOT}"/var/lib/customizer}
    paths="${cw_CLUSTER_CUSTOMIZER_custom_paths}"
    for p in ${cw_CLUSTER_CUSTOMIZER_path}/*; do
        paths="${paths} ${p}"
    done
    for p in ${paths}; do
        if [ -d "${p}"/${hook}.d ]; then
            for a in "${p}"/${hook}.d/*; do
                if [ -x "$a" -a ! -d "$a" ] && [[ "$a" != *~ ]]; then
                    echo "Running $hook hook: ${a}"
                    "${a}" "${hook}" \
                           "${cw_INSTANCE_role}" \
                           "${cw_CLUSTER_name}" \
                           "$@"
                elif [[ "$a" != *~ ]]; then
                    echo "Skipping non-executable $hook hook: ${a}"
                fi
            done
        else
            echo "No $hook hooks found in ${p}"
        fi
    done
}
