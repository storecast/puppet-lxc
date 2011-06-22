class puppet-lxc::controlling_host {
	package { ["lxc", "lvm2", "reiserfsprogs", "bridge-utils", "debootstrap"]:
		ensure => latest;
	}

	file { '/cgroup' : ensure => directory; }

	mount {'mount_cgroup' : 
		name => '/cgroup',
		atbout => true,
		device => 'cgroup',
		ensure => mounted,
		fstype => 'cgroup',
		options => 'defaults',
		remounts => false;
	}
}

