# Alces Clusterware Handlers

Handler plugins for [Alces Clusterware](https://github.com/alces-software/clusterware) that customize the behaviour of a cluster when events occur.

## Installation

You should use these handlers in conjunction with Alces Clusterware.  Installation of Clusterware handlers occurs as part of the Alces Clusterware installation.  Refer to the Alces Clusterware documentation for details of how to enable, disable and manage handlers.

## Core handlers

### `clusterable`

Perform key configuration tasks for Alces Clusterware.

### `cluster-appliances`

Configure and start Alces Flight appliance cluster-side services.

### `cluster-customizer`

Fetch account-specific scripts from Amazon S3 to respond to Clusterware events with custom behaviour.

### `cluster-firewall`

Use Clusterware configuration data to handle the addition and removal of firewall rules when members join and leave the cluster.

### `cluster-galaxy`

Configure the [Galaxy](https://galaxyproject.org/) web service and job handling for processing Galaxy-driven workloads.

### `cluster-gridware`

Provide access to the [Alces Gridware](https://github.com/alces-software/gridware-packages-main) repository of scientific and engineering applications across a cluster.

### `cluster-nfs`

Use Clusterware configuration data for managing NFS shares across the cluster.

### `cluster-sge`

Configure [Open Grid Scheduler](http://gridscheduler.sourceforge.net/) for the cluster.

### `cluster-vpn`

Configure [OpenVPN](https://openvpn.net/) to provide secure access to the cluster.

### `clusterable-aws-compat`

Add autodiscovery compatibility on AWS so slave instances don't have to be provided with the location of a master instance. Note that this requires additional set up within your AWS account.

### `session-firewall`

Specific firewall handling for Alces Clusterware interactive desktop sessions.

## Experimental handlers

The following handlers are experimental and should be used with caution.

### `flight`

Provide integration with enhanced Alces Flight orchestration services.

### `taskable`

Create users, groups and configure SSH keys to provide multiple users access to a cluster.  Provide infrastructure for operating "one-shot" clusters.

### `task-session`

Run a one-shot cluster running a simple interactive desktop session.

### `task-session-gnome`

Run a one-shot cluster running a GNOME interactive desktop session.

## Contributing

Fork the project. Make your feature addition or bug fix. Send a pull request. Bonus points for topic branches.

## Copyright and License

Creative Commons Attribution-ShareAlike 4.0 License, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2015-2016 Alces Software Ltd.

You should have received a copy of the license along with this work.  If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

Alces Clusterware Handlers by Alces Software Ltd is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at <https://github.com/alces-software/clusterware-handlers>.

Alces Clusterware Handlers is made available under a dual licensing model whereby use of the package in projects that are licensed so as to be compatible with the Creative Commons Attribution-ShareAlike 4.0 International License may use the package under the terms of that license. However, if these terms are incompatible with your planned use of this package, alternative license terms are available from Alces Software Ltd - please direct inquiries about licensing to [licensing@alces-software.com](mailto:licensing@alces-software.com).
