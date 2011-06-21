class lxc::controlling_host {
	package { ["lxc", "lvm2", "reiserfsprogs", "bridge-utils", "debootstrap"]:
		ensure => latest;
	}
}

