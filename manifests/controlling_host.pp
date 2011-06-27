class puppet-lxc::controlling_host {
	package { ["lxc", "lvm2", "reiserfsprogs", "bridge-utils", "debootstrap"]:
		ensure => latest;
	}

	file { '/cgroup' : ensure => directory; }

	file { '/etc/sysctl.conf' :
		source => "puppet:///modules/puppet-lxc/etc/sysctl.conf",
		owner   => root,
		group   => root,
		mode    => 444;
	}

	file {'/usr/local/bin/build_vm':
		source  => "puppet:///modules/puppet-lxc/usr/local/bin/build_vm",
		owner   => root,
		group   => root,
		mode    => 555;
	}

	mount {'mount_cgroup' : 
		name => '/cgroup',
		atboot => true,
		device => 'cgroup',
		ensure => mounted,
		fstype => 'cgroup',
		options => 'defaults',
		remounts => false;
	}
}

