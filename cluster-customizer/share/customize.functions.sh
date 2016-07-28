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

customize_list_hooks() {
    local p paths with_events e
    if [ "$1" == "--with-events" ]; then
        with_events=true
        shift
    fi
    files_load_config cluster-customizer
    cw_CLUSTER_CUSTOMIZER_path=${cw_CLUSTER_CUSTOMIZER_path:-"${cw_ROOT}"/var/lib/customizer}
    paths="${cw_CLUSTER_CUSTOMIZER_custom_paths}"
    for p in ${cw_CLUSTER_CUSTOMIZER_path}/*; do
        paths="${paths} ${p}"
    done
    for p in ${paths}; do
        if [ "${with_events}" ]; then
            for e in "${p}"/*; do
                echo -e "\e[38;5;221m$(basename "${p}")\e[0m/\e[35m$(basename "${e}" .d)\e[0m"
            done
        else
            basename "${p}"
        fi
    done
}

customize_run_hooks() {
    local a p hook paths feature
    hook="$1"
    if [[ "$hook" == *":"* ]]; then
        feature="${hook#*:}"
        hook="${hook%:*}"
    fi
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
        if [[ -z "${feature}" || "${p}" == */"${feature}" ]]; then
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
        fi
    done
}

customize_set_region() {
    if [ -z "${_REGION}" ]; then
        if network_is_ec2; then
            eval $(network_fetch_ec2_document | "${cw_ROOT}"/opt/jq/bin/jq -r '"_REGION=\(.region)"')
        else
            _REGION="${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}"
        fi
    fi
}

customize_set_machine_type() {
    if [ -z "${_MACHINE_TYPE}" ]; then
        _MACHINE_TYPE="$(network_fetch_ec2_metadata instance-type)"
    fi
}

customize_fetch_profile() {
    local s3cfg source target host manifest f s3cmd
    s3cfg="$1"
    source="$2"
    target="$3"
    mkdir -p "${target}"
    if [ "${s3cfg}" ]; then
        "${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} --force -r get "s3://${source}"/ "${target}"
    else
        # fetch manifest file
        if [ "${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}" == "us-east-1" ]; then
            host=s3.amazonaws.com
        else
            host=s3-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}.amazonaws.com
        fi
        manifest=$(curl -s -f https://${host}/${source}/manifest.txt)
        if [ "${manifest}" ] && ! echo "${manifest[*]}" | grep -q '<Error>'; then
            # fetch each file within manifest file
            for f in ${manifest}; do
                mkdir -p "${target}/$(dirname "$f")"
                if curl -s -f -o ${target}/${f} https://${host}/${source}/${f}; then
                    echo "Fetched: ${source}/${f}"
                else
                    echo "Unable to fetch: ${source}/${f}"
                fi
            done
        else
            echo "No manifest found for: ${source}"
        fi
    fi
}

customize_fetch_machine_type() {
    local bucket prefix
    s3cfg=$1
    bucket="alces-flight-profiles-${_REGION}"
    if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
        echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
        s3cfg=""
    fi
    prefix="machines/${_MACHINE_TYPE}"
    echo "Retrieving machine type customizations from: ${bucket}/${prefix}"
    customize_fetch_profile "${s3cfg}" "${bucket}/${prefix}" \
                            "${cw_CLUSTER_CUSTOMIZER_path}"/machine-${_MACHINE_TYPE}
}

customize_fetch_features() {
    local bucket feature s3cfg
    s3cfg=$1
    bucket="alces-flight-profiles-${_REGION}"
    if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
        echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
        s3cfg=""
    fi
    for feature in ${cw_CLUSTER_CUSTOMIZER_features}; do
        echo "Retrieving feature customizations from: ${bucket}/features/$feature"
        customize_fetch_profile "${s3cfg}" "${bucket}"/features/"${feature}" \
                                "${cw_CLUSTER_CUSTOMIZER_path}"/feature-${feature}
    done
}

customize_fetch_profiles() {
    local bucket profile
    if [ -z "${cw_CLUSTER_CUSTOMIZER_bucket}" ]; then
        if network_is_ec2; then
            bucket="alces-flight-$(network_ec2_hashed_account)"
        else
            echo "Unable to determine bucket name for customizations"
            exit 0
        fi
    else
        bucket="${cw_CLUSTER_CUSTOMIZER_bucket#s3://}"
    fi
    if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
        echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
        s3cfg=""
    fi
    for profile in ${cw_CLUSTER_CUSTOMIZER_profiles}; do
        echo "Retrieving customizations from: ${bucket}/customizer/$profile"
        customize_fetch_profile "${s3cfg}" "${bucket}"/customizer/"${profile}" \
                                "${cw_CLUSTER_CUSTOMIZER_path}"/profile-${profile}
    done
}

customize_is_s3_access_available() {
    local s3cfg bucket
    s3cfg="$1"
    bucket="$2"
    "${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} ls "s3://${bucket}" 2>/dev/null
}

customize_fetch() {
    local s3cfg
    customize_set_region
    s3cfg="$(mktemp /tmp/cluster-customizer.s3cfg.XXXXXXXX)"
    cat <<EOF > "${s3cfg}"
[default]
access_key = "${cw_CLUSTER_CUSTOMIZER_access_key_id}"
secret_key = "${cw_CLUSTER_CUSTOMIZER_secret_access_key}"
security_token = ""
use_https = True
check_ssl_certificate = True
EOF
    mkdir -p "${cw_CLUSTER_CUSTOMIZER_path}"
    customize_set_machine_type
    if [ "${_MACHINE_TYPE}" ]; then
        customize_fetch_machine_type "${s3cfg}"
    fi
    customize_fetch_features "${s3cfg}"
    customize_fetch_profiles "${s3cfg}"
    chmod -R a+x "${cw_CLUSTER_CUSTOMIZER_path}"
    rm -f "${s3cfg}"
}
