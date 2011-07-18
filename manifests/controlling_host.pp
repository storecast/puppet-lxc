class puppet-lxc::controlling_host {
	package { ["lxc", "lvm2", "reiserfsprogs", "bridge-utils", "debootstrap"]:
		ensure => latest;
	}

	file { '/cgroup' : ensure => directory; }

	file { '/etc/sysctl.conf' :
		source => "puppet:///modules/puppet-lxc/etc/sysctl.conf",
		owner  => root,
		group  => root,
		mode   => 444;
	}

	file {'/usr/local/bin/build_vm':
		content => template("puppet-lxc/build_vm.erb"),
		owner   => root,
		group   => root,
		mode    => 555;
	}

	file { "/etc/default/grub" :
		source => "puppet:///modules/puppet-lxc/etc_default_grub"
		owner  => root,
		group  => root,
		mode   => 444;
	}

	exec{"/usr/sbin/update-grub":
		command     => "/usr/sbin/update-grub",
		refreshonly => true,
		subscribe   => File["/etc/default/grub"]
	}

	moun {'mount_cgroup' : 
		name => '/cgroup',
		atboot => true,
		device => 'cgroup',
		ensure => mounted,
		fstype => 'cgroup',
		options => 'defaults',
		remounts => false;
	}
}

