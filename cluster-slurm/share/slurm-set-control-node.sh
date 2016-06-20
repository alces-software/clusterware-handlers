
node_name="$1"
slurm_config="${cw_ROOT}/opt/slurm/etc/slurm.conf"

sed --in-place "s/^ControlMachine=.*$/ControlMachine=${node_name}/" "${slurm_config}"
