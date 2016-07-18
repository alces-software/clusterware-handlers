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
require member
require ruby

autoscaling_unexhausted_nodes() {
    local node nodelist ctime
    nodelist="$*"
    for node in ${nodelist}; do
        ctime=$(member_get_member_tag "${node}" "aws_ctime")
        if [ "${ctime}" ]; then
            ruby_run <<RUBY
require 'time'
delta = Time.now - Time.parse('${ctime}')
print "${node} " if delta % 3600 <= 3180
RUBY
        else
            # unable to find ctime, assume unexhausted
            echo -n "${node} "
        fi
    done
}

autoscaling_collate_group_dimensions() {
    local dims groups g

    groups=()
    _gather_groups() {
        while [ "$1" != "--" ]; do shift; done
        groups+=($(member_find_tag "aws_group" "$5"))
    }
    member_each _gather_groups
    groups=($(printf "%s\n" "${groups[@]}" | sort -u | tr '\n' ' '))
    log "[autoscaler:groups] Found groups: ${groups[*]}"

    dims=()
    for g in "${groups[@]}"; do
        dims+=("$("${cw_ROOT}"/opt/jo/bin/jo Name=AutoScalingGroupName Value=${g})")
    done
    if [ "${#dims}" -gt 0 ]; then
        "${cw_ROOT}"/opt/jo/bin/jo -a "${dims[@]}"
    fi
}

autoscaling_cores_for_group() {
    local group_cores groups_cores g
    group="$1"

    groups_cores=()
    _gather_group_cores() {
        local group
        while [ "$1" != "--" ]; do shift; done
        group=$(member_find_tag "aws_group" "$5")
        if [ "${group}" ]; then
            groups_cores+=(${group}:$(member_find_tag "aws_group_cores" "$5"))
        fi
    }
    member_each _gather_group_cores
    groups_cores=($(printf "%s\n" "${groups_cores[@]}" | sort -u | tr '\n' ' '))
    log "[autoscaler:cores_for_group] Found cores for groups: ${groups_cores[*]}"

    if [ ${#group_cores[@]} -gt 1 -a -n "${group}" ]; then
        log "[autoscaler:cores_for_group] Looking for group: ${group}"
        for g in "${groups_cores[@]}"; do
            if [[ $g == ${group}:* ]]; then
                group_cores=$(echo "${g}" | cut -f2 -d":")
                log "[autoscaler:cores_for_group] Found group '${group}' has cores: ${group_cores}"
            fi
        done
    else
        group_cores=$(echo "${groups_cores[0]}" | cut -f2 -d":")
        log "[autoscaler:cores_for_group] Selecting first group '${groups_cores[0]}' with cores: ${group_cores}"
    fi

    if [ "${group_cores}" ]; then
        echo "${group_cores}"
    else
        return 1
    fi
}

autoscaling_shoot_node() {
    local aws_exit_code node instanceid group
    node="$1"
    group="$2"
    instanceid=$(member_get_member_tag "${node}" "aws_instanceid")

    # scale in the capacity
    log "[autoscaler:shoot] Shooting node ${instanceid} in group ${group}"
    set -o pipefail
    "${cw_ROOT}"/opt/aws/bin/aws --region "${cw_INSTANCE_aws_region}" \
                autoscaling terminate-instance-in-auto-scaling-group \
                --instance-id ${instanceid} \
                --should-decrement-desired-capacity 2>&1 | _log_blob "autoscaling:aws"
    aws_exit_code=$?
    set +o pipefail
    return ${aws_exit_code}
}
