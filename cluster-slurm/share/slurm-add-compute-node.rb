
new_node_name = ARGV[0]
slurm_config_file = "#{ENV['cw_ROOT']}/opt/slurm/etc/slurm.conf"

slurm_config = File.readlines(slurm_config_file)
node_name_regex = /(NodeName=)(\S*)([\s\S]*)/
partition_name_regex = /(PartitionName=.*Nodes=)(\S*)([\s\S]*)/

slurm_config.find { |line| line =~ node_name_regex}
nodes = ($2 == 'PLACEHOLDER') ? [] : $2.split(',')

nodes << new_node_name

# Get new list of node names with the addition of this node, ensuring that list
# will always look the same no matter the order nodes join or if node joins
# twice for some reason.
node_names = nodes.sort.uniq.join(',')

new_slurm_config = slurm_config.map do |line|
  if line =~ node_name_regex || line =~ partition_name_regex
    before = $1
    after = $3
    "#{before}#{node_names}#{after}"
  else
    line
  end
end
.join

File.write(slurm_config_file, new_slurm_config)
