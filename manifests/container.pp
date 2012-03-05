# the container itself could be configured by puppet
class puppet-lxc::container {
  # we must remove klogd to avoid bug in multy-read kernel messages
	package { ["klogd"]: ensure => purged; }
}

