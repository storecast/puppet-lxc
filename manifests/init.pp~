class virt {
  case $operatingsystem {
    debian: { include virt::debian }
  }
}

class virt::debian {
	package { ["lxc", "lvm2", "reiserfsprogs", "bridge-utils", "debootstrap"]:
		ensure => latest;
	}
}

