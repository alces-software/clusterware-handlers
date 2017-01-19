#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
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
require network

_job_queue_bucket_path() {
  local queue relative_path
  queue="$1"
  relative_path="$2"

  if [ "${relative_path}" == "" ] ; then
    echo "${BUCKET}"/customizer/"${queue}"/job-queue.d/"${cw_CLUSTER_name}"
  else
    echo "${BUCKET}"/customizer/"${queue}"/job-queue.d/"${cw_CLUSTER_name}"/"${relative_path}"
  fi
}

# Adds job queue customizers to the `job_queues` array.
_job_queue_get_job_queues() {
    local customizer all_customizers
    _job_queue_s3cmd_setup

    all_customizers=$( "${cw_ROOT}"/opt/s3cmd/s3cmd ls "${BUCKET}/customizer/" | awk '{ print $2 }' )
    for customizer in ${all_customizers} ; do 
        if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${customizer}job-queue.d | wc -l ) -ne 0 ] ; then
            job_queues+=($(echo ${customizer} | cut -f5 -d/))
        fi
    done
}

_job_queue_s3cmd_setup() {
    files_load_config cluster-customizer
    files_load_config config config/cluster

    BUCKET="${cw_CLUSTER_CUSTOMIZER_bucket:-s3://alces-flight-$(network_ec2_hashed_account)}"
    export AWS_ACCESS_KEY_ID="${cw_CLUSTER_CUSTOMIZER_access_key_id}"
    export AWS_SECRET_ACCESS_KEY="${cw_CLUSTER_CUSTOMIZER_secret_access_key}"
}

job_queue_list_queues() {
    local job_queues q queue
    job_queues=()
    queue="$1"

    _job_queue_get_job_queues
    for q in ${job_queues[@]} ; do
        echo $q
    done
}

job_queue_list_jobs_in_queue() {
    local queue job_status s3_prefix
    queue="$1"
    job_status="$2"

    _job_queue_s3cmd_setup
    s3_prefix=$(_job_queue_bucket_path "${queue}" "${job_status}"/ )

    "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_prefix} \
        | rev \
        | cut -d/ -f1 \
        | rev
}

job_queue_put() {
    local queue job_file job_id s3_key
    queue="$1"
    job_file="$2"
    job_id="$3"

    _job_queue_s3cmd_setup
    s3_key=$(_job_queue_bucket_path "${queue}" pending/"${job_id}" )

    "${cw_ROOT}"/opt/s3cmd/s3cmd put --quiet ${job_file} ${s3_key}
}

job_queue_list_output_files() {
    local queue job_id s3_key s3cmd_args job_status
    queue="$1"
    job_id="$2"

    _job_queue_s3cmd_setup
    job_status=$(job_queue_get_job_status "${queue}" "${job_id}")
    s3_key=$(_job_queue_bucket_path "${queue}" "${job_status}"/"${job_id}"/ )

    "${cw_ROOT}"/opt/s3cmd/s3cmd ls --recursive ${s3_key} \
        | awk '{print $4}' \
        | rev \
        | cut -d/ -f1 \
        | rev
}

job_queue_get_output_file() {
    local queue job_id output_file job_status s3_key s3cmd_args
    queue="$1"
    job_id="$2"
    output_file="$3"
    s3cmd_args=(--quiet)

    _job_queue_s3cmd_setup
    job_status=$(job_queue_get_job_status "${queue}" "${job_id}")
    s3_key=$(_job_queue_bucket_path "${queue}" "${job_status}"/"${job_id}"/"${output_file}" )

    "${cw_ROOT}"/opt/s3cmd/s3cmd get ${s3cmd_args[@]} ${s3_key} -
}

job_queue_get_job_status() {
    local queue job_id s3_key s3cmd_args
    queue="$1"
    job_id="$2"

    _job_queue_s3cmd_setup

    s3_key=$(_job_queue_bucket_path "${queue}" pending/"${job_id}" )
    if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_key} | wc -l ) -ne 0 ] ; then
        echo "pending"
        return 0
    fi

    s3_key=$(_job_queue_bucket_path "${queue}" completed/"${job_id}" )
    if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_key} | wc -l ) -ne 0 ] ; then
        echo "completed"
        return 0
    fi

    s3_key=$(_job_queue_bucket_path "${queue}" rejected/"${job_id}" )
    if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_key} | wc -l ) -ne 0 ] ; then
        echo "rejected"
        return 0
    fi
}

job_queue_delete_job() {
    local queue job_id s3_key s3cmd_args
    queue="$1"
    job_id="$2"

    _job_queue_s3cmd_setup
    s3_key=$(_job_queue_bucket_path "${queue}" pending/"${job_id}" )
    "${cw_ROOT}"/opt/s3cmd/s3cmd rm --quiet ${s3_key}
}
