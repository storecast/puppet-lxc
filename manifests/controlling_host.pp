class lxc::controlling_host ($ensure = "present",
	$provider = "",
	$bridge) inherits lxc {

	package {
		["lxc", "lvm2", "bridge-utils", "debootstrap"] :
			ensure => $ensure ;
	}
	File {
		ensure => $ensure,
		owner => root,
		group => root,
	}
	file{"/etc/default/lxc":
		source => "puppet:///modules/lxc/etc_default_lxc",
	}
		
	file {
		['/cgroup',"$mdir","$mdir/templates"] :
			ensure => directory ;

		'/etc/sysctl.d/ipv4_forward.conf' :
			source => "puppet:///modules/lxc/etc/sysctl.conf",
			mode => 444 ;

		'/usr/local/bin/build_vm' :
			content => template("lxc/build_vm.erb"),
			mode => 555 ;

		'/etc/default/grub' :
			source => "puppet:///modules/lxc/etc_default_grub",
			mode => 444 ;

		"${mdir}/templates/lxc-debian" :
			recurse => true,
			content => template("lxc/lxc-debian.erb"),
			require => File["$mdir/templates"] ;
	}
	exec {
		"/usr/sbin/update-grub" :
			command => "/usr/sbin/update-grub",
			refreshonly => true,
			subscribe => File["/etc/default/grub"] ;
	}
	$mtpt = $lsbdistcodename ? {
		"oneiric" => "/sys/fs/cgroup",
		default => "/cgroup",
	}
	mount {
		'mount_cgroup' :
			name => $mtpt,
			atboot => true,
			device => 'cgroup',
			ensure => mounted,
			fstype => 'cgroup',
			options => 'defaults',
			remounts => false ;
	}
}

